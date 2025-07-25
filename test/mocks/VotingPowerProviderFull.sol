// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerProvider} from "../../src/modules/voting-power/VotingPowerProvider.sol";
import {OzOwnable} from "../../src/modules/common/permissions/OzOwnable.sol";
import {EqualStakeVPCalc} from "../../src/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {SharedVaults} from "../../src/modules/voting-power/extensions/SharedVaults.sol";
import {OperatorsBlacklist} from "../../src/modules/voting-power/extensions/OperatorsBlacklist.sol";
import {OperatorsWhitelist} from "../../src/modules/voting-power/extensions/OperatorsWhitelist.sol";
import {NetworkManager} from "../../src/modules/base/NetworkManager.sol";
import {OpNetVaultAutoDeploy} from "../../src/modules/voting-power/extensions/OpNetVaultAutoDeploy.sol";
import {OperatorVaults} from "../../src/modules/voting-power/extensions/OperatorVaults.sol";
import {BaseSlashing} from "../../src/modules/voting-power/extensions/BaseSlashing.sol";
import {BaseRewards} from "../../src/modules/voting-power/extensions/BaseRewards.sol";
import {IBaseRewards} from "../../src/interfaces/modules/voting-power/extensions/IBaseRewards.sol";
import {PricedTokensChainlinkVPCalc} from
    "../../src/modules/voting-power/common/voting-power-calc/PricedTokensChainlinkVPCalc.sol";
import {WeightedTokensVPCalc} from "../../src/modules/voting-power/common/voting-power-calc/WeightedTokensVPCalc.sol";
import {WeightedVaultsVPCalc} from "../../src/modules/voting-power/common/voting-power-calc/WeightedVaultsVPCalc.sol";
import {VotingPowerCalcManager} from "../../src/modules/voting-power/base/VotingPowerCalcManager.sol";

contract VotingPowerProviderFull is
    OzOwnable,
    OperatorVaults,
    SharedVaults,
    OperatorsBlacklist,
    OperatorsWhitelist,
    OpNetVaultAutoDeploy,
    BaseSlashing,
    BaseRewards,
    PricedTokensChainlinkVPCalc,
    WeightedTokensVPCalc,
    WeightedVaultsVPCalc
{
    constructor(
        address operatorRegistry,
        address vaultFactory,
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

    function stakeToVotingPowerAt(
        address vault,
        uint256 stake,
        bytes memory extraData,
        uint48 timestamp
    )
        public
        view
        override(VotingPowerCalcManager, PricedTokensChainlinkVPCalc, WeightedTokensVPCalc, WeightedVaultsVPCalc)
        returns (uint256)
    {
        return super.stakeToVotingPowerAt(vault, stake, extraData, timestamp);
    }

    function stakeToVotingPower(
        address vault,
        uint256 stake,
        bytes memory extraData
    )
        public
        view
        override(VotingPowerCalcManager, PricedTokensChainlinkVPCalc, WeightedTokensVPCalc, WeightedVaultsVPCalc)
        returns (uint256)
    {
        return super.stakeToVotingPower(vault, stake, extraData);
    }
}
