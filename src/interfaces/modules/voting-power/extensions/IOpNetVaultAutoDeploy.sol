// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVotingPowerProvider} from "../IVotingPowerProvider.sol";

interface IOpNetVaultAutoDeploy {
    /**
     * @notice Reverts when the burner hook is enabled but the slasher is not.
     */
    error OpNetVaultAutoDeploy_InvalidBurnerHook();

    /**
     * @notice Reverts when the collateral is zero address.
     */
    error OpNetVaultAutoDeploy_InvalidCollateral();

    /**
     * @notice Reverts when the epoch duration is zero or less than the slashing window.
     */
    error OpNetVaultAutoDeploy_InvalidEpochDuration();

    /**
     * @notice Reverts when the with slasher is disabled but the slashing window is not zero.
     */
    error OpNetVaultAutoDeploy_InvalidWithSlasher();

    /**
     * @notice The storage of the OpNetVaultAutoDeploy contract.
     * @param _isAutoDeployEnabled The status of the auto deploy.
     * @param _isSetMaxNetworkLimitHookEnabled The status of the set max network limit hook.
     * @param _autoDeployedVault The mapping from the operator to the auto deployed vault.
     * @param _config The configuration of the auto deploy.
     * @custom:storage-location erc7201:symbiotic.storage.OpNetVaultAutoDeploy
     */
    struct OpNetVaultAutoDeployStorage {
        bool _isAutoDeployEnabled;
        bool _isSetMaxNetworkLimitHookEnabled;
        mapping(address operator => address vault) _autoDeployedVault;
        AutoDeployConfig _config;
    }

    /**
     * @notice The parameters for the initialization of the OpNetVaultAutoDeploy contract.
     * @param isAutoDeployEnabled The status of the auto deploy.
     * @param config The configuration of the auto deploy.
     * @param isSetMaxNetworkLimitHookEnabled The status of the set max network limit hook.
     */
    struct OpNetVaultAutoDeployInitParams {
        bool isAutoDeployEnabled;
        AutoDeployConfig config;
        bool isSetMaxNetworkLimitHookEnabled;
    }

    /**
     * @notice The configuration of the auto deploy.
     * @param epochDuration The duration of the epoch.
     * @param collateral The address of the collateral.
     * @param burner The address of the burner.
     * @param withSlasher The status of the with slasher.
     * @param isBurnerHook The status of the burner hook.
     */
    struct AutoDeployConfig {
        uint48 epochDuration;
        address collateral;
        address burner;
        bool withSlasher;
        bool isBurnerHook;
    }

    /**
     * @notice Emitted when the auto deploy status is set.
     * @param status The status of the auto deploy.
     */
    event SetAutoDeployStatus(bool status);

    /**
     * @notice Emitted when the auto deploy config is set.
     */
    event SetAutoDeployConfig(AutoDeployConfig config);

    /**
     * @notice Emitted when the set max network limit hook status is set.
     * @param status The status of the set max network limit hook.
     */
    event SetSetMaxNetworkLimitHookStatus(bool status);

    /**
     * @notice Returns the address of the vault configurator.
     * @return The address of the vault configurator.
     */
    function VAULT_CONFIGURATOR() external view returns (address);

    /**
     * @notice Returns the status of the auto deploy.
     * @return The status of the auto deploy.
     */
    function isAutoDeployEnabled() external view returns (bool);

    /**
     * @notice Returns the address of the auto deployed vault of the operator.
     * @param operator The address of the operator.
     * @return The address of the auto deployed vault of the operator.
     */
    function getAutoDeployedVault(
        address operator
    ) external view returns (address);

    /**
     * @notice Returns the configuration of the auto deploy.
     * @return The configuration of the auto deploy.
     */
    function getAutoDeployConfig() external view returns (AutoDeployConfig memory);

    /**
     * @notice Returns the status of the set max network limit hook.
     * @return The status of the set max network limit hook.
     */
    function isSetMaxNetworkLimitHookEnabled() external view returns (bool);

    /**
     * @notice Sets the status of the auto deploy.
     * @param status The status of the auto deploy.
     * @dev The caller must have the needed permission.
     */
    function setAutoDeployStatus(
        bool status
    ) external;

    /**
     * @notice Sets the configuration of the auto deploy.
     * @param config The configuration of the auto deploy.
     * @dev The caller must have the needed permission.
     */
    function setAutoDeployConfig(
        AutoDeployConfig memory config
    ) external;

    /**
     * @notice Sets the status of the set max network limit hook.
     * @param status The status of the set max network limit hook.
     * @dev The caller must have the needed permission.
     */
    function setSetMaxNetworkLimitHookStatus(
        bool status
    ) external;
}
