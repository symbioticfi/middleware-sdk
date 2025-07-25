// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerProvider} from "../VotingPowerProvider.sol";

import {OpNetVaultAutoDeployLogic} from "./logic/OpNetVaultAutoDeployLogic.sol";

import {IOpNetVaultAutoDeploy} from "../../../interfaces/modules/voting-power/extensions/IOpNetVaultAutoDeploy.sol";
import {ISetMaxNetworkLimitHook} from "../../../interfaces/modules/network/ISetMaxNetworkLimitHook.sol";

/**
 * @title OpNetVaultAutoDeploy
 * @notice Contract for auto-deploying vaults for operators on their registration.
 */
abstract contract OpNetVaultAutoDeploy is VotingPowerProvider, IOpNetVaultAutoDeploy {
    /**
     * @inheritdoc IOpNetVaultAutoDeploy
     */
    address public immutable VAULT_CONFIGURATOR;

    constructor(
        address vaultConfigurator
    ) {
        VAULT_CONFIGURATOR = vaultConfigurator;
    }

    /**
     * @dev Must be called after __VotingPowerProvider_init().
     */
    function __OpNetVaultAutoDeploy_init(
        OpNetVaultAutoDeployInitParams memory initParams
    ) internal virtual onlyInitializing {
        OpNetVaultAutoDeployLogic.initialize(initParams);
    }

    /**
     * @inheritdoc IOpNetVaultAutoDeploy
     */
    function isAutoDeployEnabled() public view virtual returns (bool) {
        return OpNetVaultAutoDeployLogic.isAutoDeployEnabled();
    }

    /**
     * @inheritdoc IOpNetVaultAutoDeploy
     */
    function getAutoDeployedVault(
        address operator
    ) public view virtual returns (address) {
        return OpNetVaultAutoDeployLogic.getAutoDeployedVault(operator);
    }

    /**
     * @inheritdoc IOpNetVaultAutoDeploy
     */
    function getAutoDeployConfig() public view virtual returns (AutoDeployConfig memory) {
        return OpNetVaultAutoDeployLogic.getAutoDeployConfig();
    }

    /**
     * @inheritdoc IOpNetVaultAutoDeploy
     */
    function isSetMaxNetworkLimitHookEnabled() public view virtual returns (bool) {
        return OpNetVaultAutoDeployLogic.isSetMaxNetworkLimitHookEnabled();
    }

    /**
     * @inheritdoc IOpNetVaultAutoDeploy
     */
    function setAutoDeployStatus(
        bool status
    ) public virtual checkPermission {
        OpNetVaultAutoDeployLogic.setAutoDeployStatus(status);
    }

    /**
     * @inheritdoc IOpNetVaultAutoDeploy
     */
    function setAutoDeployConfig(
        AutoDeployConfig memory config
    ) public virtual checkPermission {
        OpNetVaultAutoDeployLogic.setAutoDeployConfig(config);
    }

    /**
     * @inheritdoc IOpNetVaultAutoDeploy
     */
    function setSetMaxNetworkLimitHookStatus(
        bool status
    ) public virtual checkPermission {
        OpNetVaultAutoDeployLogic.setSetMaxNetworkLimitHookStatus(status);
    }

    function _registerOperatorImpl(
        address operator
    ) internal virtual override {
        super._registerOperatorImpl(operator);
        if (isAutoDeployEnabled() && getAutoDeployedVault(operator) == address(0)) {
            (address vault, address delegator,) = OpNetVaultAutoDeployLogic.createVault(operator);
            _registerOperatorVault(operator, vault);
            if (isSetMaxNetworkLimitHookEnabled()) {
                ISetMaxNetworkLimitHook(NETWORK()).setMaxNetworkLimit(
                    delegator, SUBNETWORK_IDENTIFIER(), type(uint256).max
                );
            }
        }
    }

    function _unregisterOperatorVaultImpl(address operator, address vault) internal virtual override {
        super._unregisterOperatorVaultImpl(operator, vault);
        if (getAutoDeployedVault(operator) == vault) {
            OpNetVaultAutoDeployLogic.setAutoDeployedVault(operator, address(0));
        }
    }
}
