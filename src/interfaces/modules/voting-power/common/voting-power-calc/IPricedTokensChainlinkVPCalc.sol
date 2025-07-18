// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Checkpoints} from "../../../../../libraries/structs/Checkpoints.sol";

interface IPricedTokensChainlinkVPCalc {
    error PricedTokensChainlinkVPCalc_InvalidAggregator();

    struct PricedTokensChainlinkVPCalcStorage {
        mapping(address token => Checkpoints.Trace512 hops) _tokenHops;
    }

    struct ChainlinkStakeToVotingPowerExtraData {
        bytes chainlinkExtraData;
        bytes otherExtraData;
    }

    event SetTokenHops(address indexed token, address[2] aggregators, bool[2] inverts, uint48[2] stalenessDurations);

    function getTokenHopsAt(
        address token,
        uint48 timestamp
    ) external view returns (address[2] memory, bool[2] memory, uint48[2] memory);

    function getTokenHops(
        address token
    ) external view returns (address[2] memory, bool[2] memory, uint48[2] memory);

    function getTokenPriceAt(address token, uint48 timestamp) external view returns (uint256);

    function getTokenPrice(
        address token
    ) external view returns (uint256);

    function setTokenHops(
        address token,
        address[2] memory aggregators,
        bool[2] memory inverts,
        uint48[2] memory stalenessDurations
    ) external;
}
