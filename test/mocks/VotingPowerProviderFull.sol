// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerProvider} from "../../src/contracts/modules/voting-power/VotingPowerProvider.sol";
import {OzOwnable} from "../../src/contracts/modules/common/permissions/OzOwnable.sol";
import {EqualStakeVPCalc} from "../../src/contracts/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {SharedVaults} from "../../src/contracts/modules/voting-power/extensions/SharedVaults.sol";
import {OperatorsBlacklist} from "../../src/contracts/modules/voting-power/extensions/OperatorsBlacklist.sol";
import {OperatorsWhitelist} from "../../src/contracts/modules/voting-power/extensions/OperatorsWhitelist.sol";
import {NetworkManager} from "../../src/contracts/modules/base/NetworkManager.sol";
import {OpNetVaultAutoDeploy} from "../../src/contracts/modules/voting-power/extensions/OpNetVaultAutoDeploy.sol";
import {OperatorVaults} from "../../src/contracts/modules/voting-power/extensions/OperatorVaults.sol";
import {BaseSlashing} from "../../src/contracts/modules/voting-power/extensions/BaseSlashing.sol";
import {BaseRewards} from "../../src/contracts/modules/voting-power/extensions/BaseRewards.sol";
import {IBaseRewards} from "../../src/interfaces/modules/voting-power/extensions/IBaseRewards.sol";

contract VotingPowerProviderFull is
    OzOwnable,
    EqualStakeVPCalc,
    OperatorVaults,
    SharedVaults,
    OperatorsBlacklist,
    OperatorsWhitelist,
    OpNetVaultAutoDeploy,
    BaseSlashing,
    BaseRewards
{
    constructor(
        address operatorRegistry,
        address vaultFactory,
        address networkMiddlewareService,
        address vaultConfigurator
    ) VotingPowerProvider(operatorRegistry, vaultFactory) OpNetVaultAutoDeploy(vaultConfigurator) {}

    function initialize(
        VotingPowerProviderInitParams memory votingPowerProviderInitParams,
        OzOwnableInitParams memory ozOwnableInitParams,
        OperatorsWhitelistInitParams memory operatorsWhitelistInitParams,
        OpNetVaultAutoDeployInitParams memory opNetVaultAutoDeployInitParams
    ) public virtual initializer {
        __VotingPowerProvider_init(votingPowerProviderInitParams);
        __OzOwnable_init(ozOwnableInitParams);
        __EqualStakeVPCalc_init();
        __OperatorVaults_init();
        __SharedVaults_init();
        __OperatorsBlacklist_init();
        __OperatorsWhitelist_init(operatorsWhitelistInitParams);
        __OpNetVaultAutoDeploy_init(opNetVaultAutoDeployInitParams);
        __BaseSlashing_init(BaseSlashingInitParams({slasher: address(this)}));
        __BaseRewards_init(BaseRewardsInitParams({rewarder: address(this)}));
    }

    function _registerOperatorImpl(
        address operator
    ) internal override(OperatorsBlacklist, OperatorsWhitelist, VotingPowerProvider, OpNetVaultAutoDeploy) {
        super._registerOperatorImpl(operator);
    }

    function _unregisterOperatorVaultImpl(
        address operator,
        address vault
    ) internal override(VotingPowerProvider, OpNetVaultAutoDeploy) {
        super._unregisterOperatorVaultImpl(operator, vault);
    }
}
