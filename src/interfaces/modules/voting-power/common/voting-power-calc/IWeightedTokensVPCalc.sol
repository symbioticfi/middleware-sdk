// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Checkpoints} from "../../../../../libraries/structs/Checkpoints.sol";

interface IWeightedTokensVPCalc {
    struct WeightedTokensVPCalcStorage {
        mapping(address token => Checkpoints.Trace208 weight) _tokenWeight;
    }

    event SetTokenWeight(address indexed token, uint208 weight);

    function getTokenWeightAt(address token, uint48 timestamp) external view returns (uint208);

    function getTokenWeight(
        address token
    ) external view returns (uint208);

    function setTokenWeight(address token, uint208 weight) external;
}
