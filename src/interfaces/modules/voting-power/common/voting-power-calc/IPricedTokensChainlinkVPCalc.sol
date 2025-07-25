// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Checkpoints} from "../../../../../libraries/structs/Checkpoints.sol";

interface IPricedTokensChainlinkVPCalc {
    /**
     * @notice Reverts when the aggregator is zero address.
     */
    error PricedTokensChainlinkVPCalc_InvalidAggregator();

    /**
     * @notice The storage of the PricedTokensChainlinkVPCalc contract.
     * @param _tokenHops The price conversion hops for each token.
     */
    struct PricedTokensChainlinkVPCalcStorage {
        mapping(address token => Checkpoints.Trace512 hops) _tokenHops;
    }

    /**
     * @notice Emitted when the price conversion hops are set for a token.
     * @param token The token.
     * @param aggregators The price aggregators.
     * @param inverts If to invert the fetched prices.
     * @param stalenessDurations The staleness durations (if too much time passed since the last update).
     */
    event SetTokenHops(address indexed token, address[2] aggregators, bool[2] inverts, uint48[2] stalenessDurations);

    /**
     * @notice Returns the price conversion hops for a token at a given timestamp.
     * @param token The token.
     * @param timestamp The timestamp.
     * @return The price conversion hops (price aggregators, invert flags, staleness durations).
     */
    function getTokenHopsAt(
        address token,
        uint48 timestamp
    ) external view returns (address[2] memory, bool[2] memory, uint48[2] memory);

    /**
     * @notice Returns the price conversion hops for a token.
     * @param token The token.
     * @return The price conversion hops (price aggregators, invert flags, staleness durations).
     */
    function getTokenHops(
        address token
    ) external view returns (address[2] memory, bool[2] memory, uint48[2] memory);

    /**
     * @notice Returns the price for a token at a given timestamp.
     * @param token The token.
     * @param timestamp The timestamp.
     * @return The price.
     * @dev Returns zero if the data is stale or unavailable.
     *      The price is normalized to the 18 decimals.
     */
    function getTokenPriceAt(address token, uint48 timestamp) external view returns (uint256);

    /**
     * @notice Returns the price for a token.
     * @param token The token.
     * @return The price.
     * @dev Returns zero if the data is stale or unavailable.
     *      The price is normalized to the 18 decimals.
     */
    function getTokenPrice(
        address token
    ) external view returns (uint256);

    /**
     * @notice Sets the price conversion hops for a token.
     * @param token The token.
     * @param aggregators The price aggregators.
     * @param inverts If to invert the fetched prices.
     * @param stalenessDurations The staleness durations (if too much time passed since the last update).
     */
    function setTokenHops(
        address token,
        address[2] memory aggregators,
        bool[2] memory inverts,
        uint48[2] memory stalenessDurations
    ) external;
}
