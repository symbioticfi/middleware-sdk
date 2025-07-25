// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVotingPowerProvider} from "../IVotingPowerProvider.sol";

interface IOperatorsJail {
    /**
     * @notice Reverts when the duration is invalid.
     */
    error OperatorsJail_InvalidDuration();

    /**
     * @notice Reverts when the operator is jailed.
     */
    error OperatorsJail_OperatorJailed();

    /**
     * @notice The storage of the OperatorsJail contract.
     * @param _jailedUntil The mapping from the operator to the jailed until timestamp.
     * @custom:storage-location erc7201:symbiotic.storage.OperatorsJail
     */
    struct OperatorsJailStorage {
        mapping(address operator => uint48 timestamp) _jailedUntil;
    }

    /**
     * @notice Emitted when the operator is jailed.
     * @param operator The address of the operator.
     */
    event JailOperator(address indexed operator);

    /**
     * @notice Emitted when the operator is forcefully unjailed.
     * @param operator The address of the operator.
     */
    event UnjailOperator(address indexed operator);

    /**
     * @notice Returns the jail status of the operator.
     * @param operator The address of the operator.
     * @return The jail status of the operator.
     */
    function isOperatorJailed(
        address operator
    ) external view returns (bool);

    /**
     * @notice Returns the timestamp the operator is jailed until.
     * @param operator The address of the operator.
     * @return The timestamp the operator is jailed until.
     */
    function getOperatorJailedUntil(
        address operator
    ) external view returns (uint48);

    /**
     * @notice Jails the operator.
     * @param operator The address of the operator.
     * @param duration The duration of the jail.
     * @dev The caller must have the needed permission.
     *      The operator will be unregistered if currently registered.
     */
    function jailOperator(address operator, uint48 duration) external;

    /**
     * @notice Unjails the operator.
     * @param operator The address of the operator.
     * @dev The caller must have the needed permission.
     */
    function unjailOperator(
        address operator
    ) external;
}
