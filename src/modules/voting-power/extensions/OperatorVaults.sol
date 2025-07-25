// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerProvider} from "../VotingPowerProvider.sol";

import {IOperatorVaults} from "../../../interfaces/modules/voting-power/extensions/IOperatorVaults.sol";

/**
 * @title OperatorVaults
 * @notice Contract for registering and unregistering operator vaults.
 */
abstract contract OperatorVaults is VotingPowerProvider, IOperatorVaults {
    function __OperatorVaults_init() internal virtual onlyInitializing {}

    /**
     * @inheritdoc IOperatorVaults
     */
    function registerOperatorVault(address operator, address vault) public virtual checkPermission {
        _registerOperatorVaultImpl(operator, vault);
    }

    /**
     * @inheritdoc IOperatorVaults
     */
    function unregisterOperatorVault(address operator, address vault) public virtual checkPermission {
        _unregisterOperatorVaultImpl(operator, vault);
    }

    /**
     * @inheritdoc IOperatorVaults
     */
    function unregisterOperatorVault(
        address vault
    ) public virtual {
        _unregisterOperatorVaultImpl(msg.sender, vault);
    }
}
