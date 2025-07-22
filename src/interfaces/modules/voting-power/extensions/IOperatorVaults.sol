// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOperatorVaults {
    /**
     * @notice Registers the operator vault.
     * @param operator The address of the operator.
     * @param vault The address of the vault.
     * @dev The caller must have the needed permission.
     */
    function registerOperatorVault(address operator, address vault) external;

    /**
     * @notice Unregisters the operator vault.
     * @param operator The address of the operator.
     * @param vault The address of the vault.
     * @dev The caller must have the needed permission.
     */
    function unregisterOperatorVault(address operator, address vault) external;

    /**
     * @notice Unregisters the operator vault.
     * @param vault The address of the vault.
     * @dev The caller must be the operator of the vault.
     */
    function unregisterOperatorVault(
        address vault
    ) external;
}
