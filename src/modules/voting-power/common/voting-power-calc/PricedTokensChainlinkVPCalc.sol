// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {NormalizedTokenDecimalsVPCalc} from "./NormalizedTokenDecimalsVPCalc.sol";
import {PermissionManager} from "../../../base/PermissionManager.sol";

import {ChainlinkPriceFeed} from "./libraries/ChainlinkPriceFeed.sol";
import {Checkpoints} from "../../../../libraries/structs/Checkpoints.sol";

import {IPricedTokensChainlinkVPCalc} from
    "../../../../interfaces/modules/voting-power/common/voting-power-calc/IPricedTokensChainlinkVPCalc.sol";
import {IVotingPowerCalcManager} from "../../../../interfaces/modules/voting-power/base/IVotingPowerCalcManager.sol";

/**
 * @title PricedTokensChainlinkVPCalc
 * @notice Contract for calculating the voting power, pricing the tokens using Chainlink.
 */
abstract contract PricedTokensChainlinkVPCalc is
    NormalizedTokenDecimalsVPCalc,
    PermissionManager,
    IPricedTokensChainlinkVPCalc
{
    using Checkpoints for Checkpoints.Trace512;

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.PricedTokensChainlinkVPCalc")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PricedTokensChainlinkVPCalcStorageLocation =
        0x3733a7bfa4de50ec8f69170bdfa9615f7ae85991d75509d95aa3fcefb58efe00;

    function _getPricedTokensChainlinkVPCalcStorage()
        internal
        pure
        returns (PricedTokensChainlinkVPCalcStorage storage $)
    {
        bytes32 location = PricedTokensChainlinkVPCalcStorageLocation;
        assembly {
            $.slot := location
        }
    }

    function __PricedTokensChainlinkVPCalc_init() internal virtual onlyInitializing {}

    /**
     * @inheritdoc IPricedTokensChainlinkVPCalc
     */
    function getTokenHopsAt(
        address token,
        uint48 timestamp
    ) public view virtual override returns (address[2] memory, bool[2] memory, uint48[2] memory) {
        return _deserializeHops(_getPricedTokensChainlinkVPCalcStorage()._tokenHops[token].upperLookupRecent(timestamp));
    }

    /**
     * @inheritdoc IPricedTokensChainlinkVPCalc
     */
    function getTokenHops(
        address token
    ) public view virtual override returns (address[2] memory, bool[2] memory, uint48[2] memory) {
        return _deserializeHops(_getPricedTokensChainlinkVPCalcStorage()._tokenHops[token].latest());
    }

    /**
     * @inheritdoc IPricedTokensChainlinkVPCalc
     */
    function getTokenPriceAt(address token, uint48 timestamp) public view virtual override returns (uint256) {
        (address[2] memory aggregators, bool[2] memory inverts, uint48[2] memory stalenessDurations) =
            getTokenHopsAt(token, timestamp);
        return ChainlinkPriceFeed.getPriceAt(aggregators, timestamp, inverts, stalenessDurations);
    }

    /**
     * @inheritdoc IPricedTokensChainlinkVPCalc
     */
    function getTokenPrice(
        address token
    ) public view virtual override returns (uint256) {
        (address[2] memory aggregators, bool[2] memory inverts, uint48[2] memory stalenessDurations) =
            getTokenHops(token);
        return ChainlinkPriceFeed.getLatestPrice(aggregators, inverts, stalenessDurations);
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
            * getTokenPriceAt(_getCollateral(vault), timestamp);
    }

    /**
     * @inheritdoc IVotingPowerCalcManager
     */
    function stakeToVotingPower(
        address vault,
        uint256 stake,
        bytes memory extraData
    ) public view virtual override returns (uint256) {
        return super.stakeToVotingPower(vault, stake, extraData) * getTokenPrice(_getCollateral(vault));
    }

    /**
     * @inheritdoc IPricedTokensChainlinkVPCalc
     */
    function setTokenHops(
        address token,
        address[2] memory aggregators,
        bool[2] memory inverts,
        uint48[2] memory stalenessDurations
    ) public virtual checkPermission {
        _setTokenHops(token, aggregators, inverts, stalenessDurations);
    }

    function _setTokenHops(
        address token,
        address[2] memory aggregators,
        bool[2] memory inverts,
        uint48[2] memory stalenessDurations
    ) internal virtual {
        _getPricedTokensChainlinkVPCalcStorage()._tokenHops[token].push(
            uint48(block.timestamp), _serializeHops(aggregators, inverts, stalenessDurations)
        );
        emit SetTokenHops(token, aggregators, inverts, stalenessDurations);
    }

    function _serializeHop(
        address aggregator,
        bool invert,
        uint48 stalenessDuration
    ) internal pure virtual returns (uint256) {
        return uint256(uint160(aggregator)) << 49 | uint256(stalenessDuration) << 1 | (invert ? 1 : 0);
    }

    function _serializeHops(
        address[2] memory aggregators,
        bool[2] memory inverts,
        uint48[2] memory stalenessDurations
    ) internal pure virtual returns (uint256[2] memory hops) {
        if (aggregators[0] == address(0)) {
            revert PricedTokensChainlinkVPCalc_InvalidAggregator();
        }
        hops[0] = _serializeHop(aggregators[0], inverts[0], stalenessDurations[0]);
        if (aggregators[1] != address(0)) {
            hops[1] = _serializeHop(aggregators[1], inverts[1], stalenessDurations[1]);
        }
    }

    function _deserializeHop(
        uint256 hop
    ) internal pure virtual returns (address aggregator, bool invert, uint48 stalenessDuration) {
        return (address(uint160(hop >> 49)), hop & 1 > 0, uint48(hop >> 1));
    }

    function _deserializeHops(
        uint256[2] memory hops
    )
        internal
        pure
        virtual
        returns (address[2] memory aggregators, bool[2] memory inverts, uint48[2] memory stalenessDurations)
    {
        (aggregators[0], inverts[0], stalenessDurations[0]) = _deserializeHop(hops[0]);
        (aggregators[1], inverts[1], stalenessDurations[1]) = _deserializeHop(hops[1]);
    }
}
