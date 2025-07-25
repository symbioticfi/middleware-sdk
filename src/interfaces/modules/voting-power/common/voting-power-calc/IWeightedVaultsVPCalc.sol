// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Checkpoints} from "../../../../../libraries/structs/Checkpoints.sol";

interface IWeightedVaultsVPCalc {
    /**
     * @notice The storage of the WeightedVaultsVPCalc contract.
     * @param _vaultWeight The weight for each vault.
     */
    struct WeightedVaultsVPCalcStorage {
        mapping(address vault => Checkpoints.Trace208 weight) _vaultWeight;
    }

    /**
     * @notice Emitted when the weight for a vault is set.
     * @param vault The vault.
     * @param weight The weight.
     */
    event SetVaultWeight(address indexed vault, uint208 weight);

    /**
     * @notice Returns the weight for a vault at a given timestamp.
     * @param vault The vault.
     * @param timestamp The timestamp.
     * @return The weight.
     * @dev Returns 1e4 if the weight wasn't explicitly set yet.
     */
    function getVaultWeightAt(address vault, uint48 timestamp) external view returns (uint208);

    /**
     * @notice Returns the weight for a vault.
     * @param vault The vault.
     * @return The weight.
     * @dev Returns 1e4 if the weight wasn't explicitly set yet.
     */
    function getVaultWeight(
        address vault
    ) external view returns (uint208);

    /**
     * @notice Sets the weight for a vault.
     * @param vault The vault.
     * @param weight The weight.
     */
    function setVaultWeight(address vault, uint208 weight) external;
}
