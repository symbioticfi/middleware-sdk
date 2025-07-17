// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Checkpoints} from "../../../../../contracts/libraries/structs/Checkpoints.sol";

interface IWeightedVaultsVPCalc {
    struct WeightedVaultsVPCalcStorage {
        mapping(address vault => Checkpoints.Trace208 weight) _vaultWeight;
    }

    event SetVaultWeight(address indexed vault, uint208 weight);

    function getVaultWeightAt(address vault, uint48 timestamp) external view returns (uint208);

    function getVaultWeight(
        address vault
    ) external view returns (uint208);

    function setVaultWeight(address vault, uint208 weight) external;
}
