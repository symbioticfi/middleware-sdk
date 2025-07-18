// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerProvider} from "../../src/modules/voting-power/VotingPowerProvider.sol";
import {OzOwnable} from "../../src/modules/common/permissions/OzOwnable.sol";
import {EqualStakeVPCalc} from "../../src/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {SharedVaults} from "../../src/modules/voting-power/extensions/SharedVaults.sol";
import {MultiToken} from "../../src/modules/voting-power/extensions/MultiToken.sol";
import {OperatorsBlacklist} from "../../src/modules/voting-power/extensions/OperatorsBlacklist.sol";
import {OperatorsWhitelist} from "../../src/modules/voting-power/extensions/OperatorsWhitelist.sol";
import {NetworkManager} from "../../src/modules/base/NetworkManager.sol";
import {OpNetVaultAutoDeploy} from "../../src/modules/voting-power/extensions/OpNetVaultAutoDeploy.sol";
import {OperatorVaults} from "../../src/modules/voting-power/extensions/OperatorVaults.sol";
import {BaseSlashing} from "../../src/modules/voting-power/extensions/BaseSlashing.sol";
import {BaseRewards} from "../../src/modules/voting-power/extensions/BaseRewards.sol";

contract VotingPowerProviderSemiFull is
    OzOwnable,
    EqualStakeVPCalc,
    OperatorVaults,
    SharedVaults,
    MultiToken,
    OperatorsBlacklist,
    OperatorsWhitelist,
    BaseSlashing,
    BaseRewards
{
    constructor(address operatorRegistry, address vaultFactory) VotingPowerProvider(operatorRegistry, vaultFactory) {}

    function initialize(
        VotingPowerProviderInitParams memory votingPowerProviderInitParams,
        OzOwnableInitParams memory ozOwnableInitParams,
        OperatorsWhitelistInitParams memory operatorsWhitelistInitParams,
        BaseSlashingInitParams memory baseSlashingInitParams,
        BaseRewardsInitParams memory baseRewardsInitParams
    ) public virtual initializer {
        __VotingPowerProvider_init(votingPowerProviderInitParams);
        __OzOwnable_init(ozOwnableInitParams);
        __OperatorsWhitelist_init(operatorsWhitelistInitParams);
        __BaseSlashing_init(baseSlashingInitParams);
        __BaseRewards_init(baseRewardsInitParams);
    }

    function _registerOperatorImpl(
        address operator
    ) internal override(OperatorsBlacklist, OperatorsWhitelist, VotingPowerProvider) {
        super._registerOperatorImpl(operator);
    }
}
