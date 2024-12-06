// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ISelfRegisterOperators} from "./ISelfRegisterOperators.sol";

/**
 * @title IForcePauseSelfRegisterOperators
 * @notice Interface for force pausing operators and operator-vault pairs
 */
interface IForcePauseSelfRegisterOperators is ISelfRegisterOperators {
    error OperatorForcePaused();
    error OperatorVaultForcePaused();

    /**
     * @notice Forces an operator to be paused
     * @param operator The address of the operator to pause
     */
    function forcePauseOperator(address operator) external;

    /**
     * @notice Forces an operator to be unpaused
     * @param operator The address of the operator to unpause
     */
    function forceUnpauseOperator(address operator) external;

    /**
     * @notice Forces a specific operator-vault pair to be paused
     * @param operator The address of the operator
     * @param vault The address of the vault
     */
    function forcePauseOperatorVault(address operator, address vault) external;

    /**
     * @notice Forces a specific operator-vault pair to be unpaused
     * @param operator The address of the operator
     * @param vault The address of the vault
     */
    function forceUnpauseOperatorVault(address operator, address vault) external;
}
