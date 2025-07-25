// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {NormalizedTokenDecimalsVPCalc} from "./NormalizedTokenDecimalsVPCalc.sol";
import {PermissionManager} from "../../../base/PermissionManager.sol";

import {Checkpoints} from "../../../../libraries/structs/Checkpoints.sol";

import {IVotingPowerCalcManager} from "../../../../interfaces/modules/voting-power/base/IVotingPowerCalcManager.sol";
import {IWeightedTokensVPCalc} from
    "../../../../interfaces/modules/voting-power/common/voting-power-calc/IWeightedTokensVPCalc.sol";

/**
 * @title WeightedTokensVPCalc
 * @notice Contract for calculating the voting power, weighting the tokens.
 */
abstract contract WeightedTokensVPCalc is NormalizedTokenDecimalsVPCalc, PermissionManager, IWeightedTokensVPCalc {
    using Checkpoints for Checkpoints.Trace208;

    uint208 internal constant DEFAULT_TOKEN_WEIGHT = 1e12;

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.WeightedTokensVPCalc")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant WeightedTokensVPCalcStorageLocation =
        0xf5262741ca6f55e787f6eaf4de4fb0649de696baa9c333fb294f86e4baf7a100;

    function _getWeightedTokensVPCalcStorage() internal pure returns (WeightedTokensVPCalcStorage storage $) {
        bytes32 location = WeightedTokensVPCalcStorageLocation;
        assembly {
            $.slot := location
        }
    }

    function __WeightedTokensVPCalc_init() internal virtual onlyInitializing {}

    /**
     * @inheritdoc IWeightedTokensVPCalc
     */
    function getTokenWeightAt(address token, uint48 timestamp) public view virtual returns (uint208) {
        (bool exists,, uint208 weight,) =
            _getWeightedTokensVPCalcStorage()._tokenWeight[token].upperLookupRecentCheckpoint(timestamp);
        return exists ? weight : DEFAULT_TOKEN_WEIGHT;
    }

    /**
     * @inheritdoc IWeightedTokensVPCalc
     */
    function getTokenWeight(
        address token
    ) public view virtual returns (uint208) {
        (bool exists,, uint208 weight) = _getWeightedTokensVPCalcStorage()._tokenWeight[token].latestCheckpoint();
        return exists ? weight : DEFAULT_TOKEN_WEIGHT;
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
        return super.stakeToVotingPowerAt(vault, stake, extraData, timestamp)
            * getTokenWeightAt(_getCollateral(vault), timestamp);
    }

    /**
     * @inheritdoc IVotingPowerCalcManager
     */
    function stakeToVotingPower(
        address vault,
        uint256 stake,
        bytes memory extraData
    ) public view virtual override returns (uint256) {
        return super.stakeToVotingPower(vault, stake, extraData) * getTokenWeight(_getCollateral(vault));
    }

    /**
     * @inheritdoc IWeightedTokensVPCalc
     */
    function setTokenWeight(address token, uint208 weight) public virtual checkPermission {
        _setTokenWeight(token, weight);
    }

    function _setTokenWeight(address token, uint208 weight) internal virtual {
        _getWeightedTokensVPCalcStorage()._tokenWeight[token].push(uint48(block.timestamp), weight);
        emit SetTokenWeight(token, weight);
    }
}
