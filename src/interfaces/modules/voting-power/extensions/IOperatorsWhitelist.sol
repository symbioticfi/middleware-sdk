// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVotingPowerProvider} from "../IVotingPowerProvider.sol";

interface IOperatorsWhitelist {
    /**
     * @notice Reverts when the operator is not whitelisted.
     */
    error OperatorsWhitelist_OperatorNotWhitelisted();

    /**
     * @notice The storage of the OperatorsWhitelist contract.
     * @param _whitelisted The mapping from the operator to the whitelisted operator status.
     * @param _isWhitelistEnabled The status of the whitelist.
     * @custom:storage-location erc7201:symbiotic.storage.OperatorsWhitelist
     */
    struct OperatorsWhitelistStorage {
        mapping(address operator => bool value) _whitelisted;
        bool _isWhitelistEnabled;
    }

    /**
     * @notice The parameters for the initialization of the OperatorsWhitelist contract.
     * @param isWhitelistEnabled The status of the whitelist.
     */
    struct OperatorsWhitelistInitParams {
        bool isWhitelistEnabled;
    }

    /**
     * @notice Emitted when the whitelist status is set.
     * @param status The status of the whitelist.
     */
    event SetWhitelistStatus(bool status);

    /**
     * @notice Emitted when the operator is whitelisted.
     * @param operator The address of the operator.
     */
    event WhitelistOperator(address indexed operator);

    /**
     * @notice Emitted when the operator is unwhitelisted.
     * @param operator The address of the operator.
     */
    event UnwhitelistOperator(address indexed operator);

    /**
     * @notice Returns the whitelist status.
     * @return The whitelist status.
     */
    function isWhitelistEnabled() external view returns (bool);

    /**
     * @notice Returns the whitelist status of the operator.
     * @param operator The address of the operator.
     * @return The whitelist status of the operator.
     */
    function isOperatorWhitelisted(
        address operator
    ) external view returns (bool);

    /**
     * @notice Sets the whitelist status.
     * @param status The status of the whitelist.
     * @dev The caller must have the needed permission.
     */
    function setWhitelistStatus(
        bool status
    ) external;

    /**
     * @notice Whitelists the operator.
     * @param operator The address of the operator.
     * @dev The caller must have the needed permission.
     */
    function whitelistOperator(
        address operator
    ) external;

    /**
     * @notice Unwhitelists the operator.
     * @param operator The address of the operator.
     * @dev The caller must have the needed permission.
     *      The operator will be unregistered if currently registered and the whitelist is enabled.
     */
    function unwhitelistOperator(
        address operator
    ) external;
}
