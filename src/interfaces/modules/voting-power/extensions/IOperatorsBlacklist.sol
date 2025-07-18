// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVotingPowerProvider} from "../IVotingPowerProvider.sol";

interface IOperatorsBlacklist {
    /**
     * @notice Reverts when the operator is already blacklisted.
     */
    error OperatorsBlacklist_OperatorBlacklisted();

    /**
     * @notice The storage of the OperatorsBlacklist contract.
     * @param _blacklisted The mapping from the operator to the blacklisted operator status.
     * @custom:storage-location erc7201:symbiotic.storage.OperatorsBlacklist
     */
    struct OperatorsBlacklistStorage {
        mapping(address operator => bool value) _blacklisted;
    }

    /**
     * @notice Emitted when the operator is blacklisted.
     * @param operator The address of the operator.
     */
    event BlacklistOperator(address indexed operator);

    /**
     * @notice Emitted when the operator is unblacklisted.
     * @param operator The address of the operator.
     */
    event UnblacklistOperator(address indexed operator);

    /**
     * @notice Returns the blacklist status of the operator.
     * @param operator The address of the operator.
     * @return The blacklist status of the operator.
     */
    function isOperatorBlacklisted(
        address operator
    ) external view returns (bool);

    /**
     * @notice Blacklists the operator.
     * @param operator The address of the operator.
     * @dev The caller must have the needed permission.
     *      The operator will be unregistered if currently registered.
     */
    function blacklistOperator(
        address operator
    ) external;

    /**
     * @notice Unblacklists the operator.
     * @param operator The address of the operator.
     * @dev The caller must have the needed permission.
     */
    function unblacklistOperator(
        address operator
    ) external;
}
