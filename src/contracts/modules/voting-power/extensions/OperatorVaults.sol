// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IOperatorVaults} from "../../../../interfaces/modules/voting-power/extensions/IOperatorVaults.sol";
import {VotingPowerProvider} from "../VotingPowerProvider.sol";

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
