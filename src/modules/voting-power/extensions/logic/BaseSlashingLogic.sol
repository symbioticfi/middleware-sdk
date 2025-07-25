// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerProviderLogic} from "../../logic/VotingPowerProviderLogic.sol";

import {IBaseSlashing} from "../../../../interfaces/modules/voting-power/extensions/IBaseSlashing.sol";
import {INetworkManager} from "../../../../interfaces/modules/base/INetworkManager.sol";
import {IVotingPowerProvider} from "../../../../interfaces/modules/voting-power/IVotingPowerProvider.sol";

import {IEntity} from "@symbioticfi/core/src/interfaces/common/IEntity.sol";
import {ISlasher as IInstantSlasher} from "@symbioticfi/core/src/interfaces/slasher/ISlasher.sol";
import {IVault} from "@symbioticfi/core/src/interfaces/vault/IVault.sol";
import {IVetoSlasher} from "@symbioticfi/core/src/interfaces/slasher/IVetoSlasher.sol";

/**
 * @title BaseSlashingLogic
 * @notice Library with bindings for slashing vaults.
 */
library BaseSlashingLogic {
    /**
     * @notice Slashes a vault.
     * @param timestamp The capture timestamp.
     * @param vault The address of the vault to slash.
     * @param operator The address of the operator to slash.
     * @param amount The amount of the tokens to slash.
     * @param hints The hints to optimize gas usage.
     * @dev It checks if the slashing was required at the given capture timestamp,
     *      and if the slashing request is not stale regarding set `minEpochDuration`.
     */
    function slashVault(
        uint48 timestamp,
        address vault,
        address operator,
        uint256 amount,
        bytes memory hints
    ) public returns (bool success, bytes memory response) {
        address slasher = IVault(vault).slasher();
        if (slasher == address(0)) {
            revert IBaseSlashing.BaseSlashing_NoSlasher();
        }

        return slash(timestamp, slasher, operator, amount, hints);
    }

    /**
     * @notice Slashes a vault.
     * @param timestamp The capture timestamp.
     * @param slasher The address of the slasher.
     * @param operator The address of the operator to slash.
     * @param amount The amount of the tokens to slash.
     * @param hints The hints to optimize gas usage.
     * @dev It checks if the slashing was required at the given capture timestamp,
     *      and if the slashing request is not stale regarding set `minEpochDuration`.
     */
    function slash(
        uint48 timestamp,
        address slasher,
        address operator,
        uint256 amount,
        bytes memory hints
    ) public returns (bool success, bytes memory response) {
        IBaseSlashing.SlashHints memory slashHints;
        if (hints.length > 0) {
            slashHints = abi.decode(hints, (IBaseSlashing.SlashHints));
        }

        (bool requireSlasher, uint48 minVaultEpochDuration) =
            VotingPowerProviderLogic.getSlashingDataAt(timestamp, slashHints.slashingDataHint);
        if (!requireSlasher) {
            revert IBaseSlashing.BaseSlashing_NoSlashing();
        }

        uint48 timePassed = uint48(block.timestamp) - timestamp;
        uint64 slasherType = IEntity(slasher).TYPE();
        if (slasherType == uint64(IVotingPowerProvider.SlasherType.VETO)) {
            timePassed += IVetoSlasher(slasher).vetoDuration();
        } else if (slasherType > uint64(type(IVotingPowerProvider.SlasherType).max)) {
            revert IBaseSlashing.BaseSlashing_UnknownSlasherType();
        }
        if (timePassed > minVaultEpochDuration) {
            return (false, new bytes(0));
        }

        return slashUnsafe(timestamp, slasher, operator, amount, slashHints.slashCoreHints);
    }

    /**
     * @notice Slashes a vault.
     * @param timestamp The capture timestamp.
     * @param slasher The address of the slasher.
     * @param operator The address of the operator to slash.
     * @param amount The amount of the tokens to slash.
     * @param hints The hints to optimize gas usage.
     */
    function slashUnsafe(
        uint48 timestamp,
        address slasher,
        address operator,
        uint256 amount,
        bytes memory hints
    ) public returns (bool success, bytes memory response) {
        uint64 slasherType = IEntity(slasher).TYPE();
        if (slasherType == uint64(IVotingPowerProvider.SlasherType.INSTANT)) {
            (success, response) = slasher.call(
                abi.encodeCall(
                    IInstantSlasher.slash,
                    (INetworkManager(address(this)).SUBNETWORK(), operator, amount, timestamp, hints)
                )
            );
            emit IBaseSlashing.InstantSlash(slasher, operator, success, success ? abi.decode(response, (uint256)) : 0);
        } else if (slasherType == uint64(IVotingPowerProvider.SlasherType.VETO)) {
            (success, response) = slasher.call(
                abi.encodeCall(
                    IVetoSlasher.requestSlash,
                    (INetworkManager(address(this)).SUBNETWORK(), operator, amount, timestamp, hints)
                )
            );
            emit IBaseSlashing.VetoSlash(slasher, operator, success, success ? abi.decode(response, (uint256)) : 0);
        } else {
            revert IBaseSlashing.BaseSlashing_UnknownSlasherType();
        }
    }

    /**
     * @notice Executes a slash request.
     * @param vault The address of the vault.
     * @param slashIndex The index of the slash request.
     * @param hints The hints to optimize gas usage.
     * @dev It checks if the slashing request is not stale regarding set `minEpochDuration`.
     */
    function executeSlashVault(
        address vault,
        uint256 slashIndex,
        bytes memory hints
    ) public returns (bool success, uint256 slashedAmount) {
        address slasher = IVault(vault).slasher();
        if (slasher == address(0)) {
            revert IBaseSlashing.BaseSlashing_NoSlasher();
        }

        return executeSlash(slasher, slashIndex, hints);
    }

    /**
     * @notice Executes a slash request.
     * @param slasher The address of the slasher.
     * @param slashIndex The index of the slash request.
     * @param hints The hints to optimize gas usage.
     * @dev It checks if the slashing request is not stale regarding set `minEpochDuration`.
     */
    function executeSlash(
        address slasher,
        uint256 slashIndex,
        bytes memory hints
    ) public returns (bool success, uint256 slashedAmount) {
        IBaseSlashing.ExecuteSlashHints memory executeSlashHints;
        if (hints.length > 0) {
            executeSlashHints = abi.decode(hints, (IBaseSlashing.ExecuteSlashHints));
        }

        uint64 slasherType = IEntity(slasher).TYPE();
        if (slasherType != uint64(IVotingPowerProvider.SlasherType.VETO)) {
            revert IBaseSlashing.BaseSlashing_NotVetoSlasher();
        }
        (,,, uint48 timestamp,,) = IVetoSlasher(slasher).slashRequests(slashIndex);
        (, uint48 minVaultEpochDuration) =
            VotingPowerProviderLogic.getSlashingDataAt(timestamp, executeSlashHints.slashingDataHint);
        if (block.timestamp - timestamp > minVaultEpochDuration) {
            return (false, 0);
        }

        return executeSlashUnsafe(slasher, slashIndex, executeSlashHints.executeSlashCoreHints);
    }

    /**
     * @notice Executes a slash request.
     * @param slasher The address of the slasher.
     * @param slashIndex The index of the slash request.
     * @param hints The hints to optimize gas usage.
     */
    function executeSlashUnsafe(
        address slasher,
        uint256 slashIndex,
        bytes memory hints
    ) public returns (bool success, uint256 slashedAmount) {
        uint64 slasherType = IEntity(slasher).TYPE();
        if (slasherType != uint64(IVotingPowerProvider.SlasherType.VETO)) {
            revert IBaseSlashing.BaseSlashing_NotVetoSlasher();
        }
        bytes memory response;
        (success, response) = slasher.call(abi.encodeCall(IVetoSlasher.executeSlash, (slashIndex, hints)));
        slashedAmount = success ? abi.decode(response, (uint256)) : 0;
        emit IBaseSlashing.ExecuteSlash(slasher, slashIndex, success, slashedAmount);
    }
}
