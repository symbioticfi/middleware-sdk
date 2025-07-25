// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerProvider} from "../VotingPowerProvider.sol";

import {ISharedVaults} from "../../../interfaces/modules/voting-power/extensions/ISharedVaults.sol";

/**
 * @title SharedVaults
 * @notice Contract for registering and unregistering shared vaults.
 */
abstract contract SharedVaults is VotingPowerProvider, ISharedVaults {
    function __SharedVaults_init() internal virtual onlyInitializing {}

    /**
     * @inheritdoc ISharedVaults
     */
    function registerSharedVault(
        address sharedVault
    ) public virtual checkPermission {
        _registerSharedVault(sharedVault);
    }

    /**
     * @inheritdoc ISharedVaults
     */
    function unregisterSharedVault(
        address sharedVault
    ) public virtual checkPermission {
        _unregisterSharedVault(sharedVault);
    }
}
