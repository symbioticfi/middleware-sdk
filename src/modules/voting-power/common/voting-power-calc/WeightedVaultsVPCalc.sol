// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {EqualStakeVPCalc} from "./EqualStakeVPCalc.sol";
import {PermissionManager} from "../../../base/PermissionManager.sol";

import {Checkpoints} from "../../../../libraries/structs/Checkpoints.sol";

import {IVotingPowerCalcManager} from "../../../../interfaces/modules/voting-power/base/IVotingPowerCalcManager.sol";
import {IWeightedVaultsVPCalc} from
    "../../../../interfaces/modules/voting-power/common/voting-power-calc/IWeightedVaultsVPCalc.sol";

/**
 * @title WeightedVaultsVPCalc
 * @notice Contract for calculating the voting power, weighting the vaults.
 */
abstract contract WeightedVaultsVPCalc is EqualStakeVPCalc, PermissionManager, IWeightedVaultsVPCalc {
    using Checkpoints for Checkpoints.Trace208;

    uint208 internal constant DEFAULT_VAULT_WEIGHT = 1e4;

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.WeightedVaultsVPCalc")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant WeightedVaultsVPCalcStorageLocation =
        0x939e246f03c984a4a087feb13b6dd8d9a00ff873e1061be489800f8d9c2cbf00;

    function _getWeightedVaultsVPCalcStorage() internal pure returns (WeightedVaultsVPCalcStorage storage $) {
        bytes32 location = WeightedVaultsVPCalcStorageLocation;
        assembly {
            $.slot := location
        }
    }

    function __WeightedVaultsVPCalc_init() internal virtual onlyInitializing {}

    /**
     * @inheritdoc IWeightedVaultsVPCalc
     */
    function getVaultWeightAt(address vault, uint48 timestamp) public view virtual returns (uint208) {
        (bool exists,, uint208 weight,) =
            _getWeightedVaultsVPCalcStorage()._vaultWeight[vault].upperLookupRecentCheckpoint(timestamp);
        return exists ? weight : DEFAULT_VAULT_WEIGHT;
    }

    /**
     * @inheritdoc IWeightedVaultsVPCalc
     */
    function getVaultWeight(
        address vault
    ) public view virtual returns (uint208) {
        (bool exists,, uint208 weight) = _getWeightedVaultsVPCalcStorage()._vaultWeight[vault].latestCheckpoint();
        return exists ? weight : DEFAULT_VAULT_WEIGHT;
    }

    /**
     * @inheritdoc IVotingPowerCalcManager
     */
    function stakeToVotingPowerAt(
        address vault,
        uint256 stake,
        bytes memory extraData,
        uint48 timestamp
    ) public view virtual override returns (uint256) {
        return super.stakeToVotingPowerAt(vault, stake, extraData, timestamp) * getVaultWeightAt(vault, timestamp);
    }

    /**
     * @inheritdoc IVotingPowerCalcManager
     */
    function stakeToVotingPower(
        address vault,
        uint256 stake,
        bytes memory extraData
    ) public view virtual override returns (uint256) {
        return super.stakeToVotingPower(vault, stake, extraData) * getVaultWeight(vault);
    }

    /**
     * @inheritdoc IWeightedVaultsVPCalc
     */
    function setVaultWeight(address vault, uint208 weight) public virtual checkPermission {
        _setVaultWeight(vault, weight);
    }

    function _setVaultWeight(address vault, uint208 weight) internal virtual {
        _getWeightedVaultsVPCalcStorage()._vaultWeight[vault].push(uint48(block.timestamp), weight);
        emit SetVaultWeight(vault, weight);
    }
}
