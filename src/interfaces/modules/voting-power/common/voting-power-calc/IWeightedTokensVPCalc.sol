// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Checkpoints} from "../../../../../libraries/structs/Checkpoints.sol";

interface IWeightedTokensVPCalc {
    /**
     * @notice The storage of the WeightedTokensVPCalc contract.
     * @param _tokenWeight The weight for each token.
     */
    struct WeightedTokensVPCalcStorage {
        mapping(address token => Checkpoints.Trace208 weight) _tokenWeight;
    }

    /**
     * @notice Emitted when the weight for a token is set.
     * @param token The token.
     * @param weight The weight.
     */
    event SetTokenWeight(address indexed token, uint208 weight);

    /**
     * @notice Returns the weight for a token at a given timestamp.
     * @param token The token.
     * @param timestamp The timestamp.
     * @return The weight.
     * @dev Returns 1e12 if the weight wasn't explicitly set yet.
     */
    function getTokenWeightAt(address token, uint48 timestamp) external view returns (uint208);

    /**
     * @notice Returns the weight for a token.
     * @param token The token.
     * @return The weight.
     * @dev Returns 1e12 if the weight wasn't explicitly set yet.
     */
    function getTokenWeight(
        address token
    ) external view returns (uint208);

    /**
     * @notice Sets the weight for a token.
     * @param token The token.
     * @param weight The weight.
     */
    function setTokenWeight(address token, uint208 weight) external;
}
