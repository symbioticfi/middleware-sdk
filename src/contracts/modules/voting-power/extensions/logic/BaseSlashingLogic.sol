// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IVault} from "@symbioticfi/core/src/interfaces/vault/IVault.sol";
import {IBaseDelegator} from "@symbioticfi/core/src/interfaces/delegator/IBaseDelegator.sol";
import {IRegistry} from "@symbioticfi/core/src/interfaces/common/IRegistry.sol";
import {IEntity} from "@symbioticfi/core/src/interfaces/common/IEntity.sol";
import {IVetoSlasher} from "@symbioticfi/core/src/interfaces/slasher/IVetoSlasher.sol";
import {Subnetwork} from "@symbioticfi/core/src/contracts/libraries/Subnetwork.sol";
import {ISlasher as IInstantSlasher} from "@symbioticfi/core/src/interfaces/slasher/ISlasher.sol";
import {IOperatorSpecificDelegator} from "@symbioticfi/core/src/interfaces/delegator/IOperatorSpecificDelegator.sol";
import {IOperatorNetworkSpecificDelegator} from
    "@symbioticfi/core/src/interfaces/delegator/IOperatorNetworkSpecificDelegator.sol";

import {IBaseSlashing} from "../../../../../interfaces/modules/voting-power/extensions/IBaseSlashing.sol";
import {VotingPowerProvider} from "../../VotingPowerProvider.sol";
import {VotingPowerProviderLogic} from "../../logic/VotingPowerProviderLogic.sol";

import {IVotingPowerProvider} from "../../../../../interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {INetworkManager} from "../../../../../interfaces/modules/base/INetworkManager.sol";

library BaseSlashingLogic {
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

        uint48 slashingWindow = VotingPowerProviderLogic.getSlashingWindowAt(timestamp, slashHints.slashingWindowHint);
        if (block.timestamp - timestamp > slashingWindow) {
            return (false, new bytes(0));
        }

        uint64 slasherType = IEntity(slasher).TYPE();
        if (slasherType == uint64(IVotingPowerProvider.SlasherType.INSTANT)) {
            (success, response) = slasher.call(
                abi.encodeCall(
                    IInstantSlasher.slash,
                    (
                        INetworkManager(address(this)).SUBNETWORK(),
                        operator,
                        amount,
                        timestamp,
                        slashHints.slashCoreHints
                    )
                )
            );
            emit IBaseSlashing.InstantSlash(slasher, operator, success, success ? abi.decode(response, (uint256)) : 0);
        } else if (slasherType == uint64(IVotingPowerProvider.SlasherType.VETO)) {
            (success, response) = slasher.call(
                abi.encodeCall(
                    IVetoSlasher.requestSlash,
                    (
                        INetworkManager(address(this)).SUBNETWORK(),
                        operator,
                        amount,
                        timestamp,
                        slashHints.slashCoreHints
                    )
                )
            );
            emit IBaseSlashing.VetoSlash(slasher, operator, success, success ? abi.decode(response, (uint256)) : 0);
        } else {
            revert IBaseSlashing.BaseSlashing_UnknownSlasherType();
        }
    }

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
        if (slasherType == uint64(IVotingPowerProvider.SlasherType.VETO)) {
            (,,, uint48 timestamp,,) = IVetoSlasher(slasher).slashRequests(slashIndex);
            uint48 slashingWindow =
                VotingPowerProviderLogic.getSlashingWindowAt(timestamp, executeSlashHints.slashingWindowHint);
            if (block.timestamp - timestamp > slashingWindow) {
                return (false, 0);
            }

            bytes memory response;
            (success, response) = slasher.call(
                abi.encodeCall(IVetoSlasher.executeSlash, (slashIndex, executeSlashHints.executeSlashCoreHints))
            );
            slashedAmount = success ? abi.decode(response, (uint256)) : 0;
            emit IBaseSlashing.ExecuteSlash(slasher, slashIndex, success, slashedAmount);
        } else {
            revert IBaseSlashing.BaseSlashing_NotVetoSlasher();
        }
    }
}
