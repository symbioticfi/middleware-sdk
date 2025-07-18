// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerProvider} from "../../src/modules/voting-power/VotingPowerProvider.sol";
import {OzOwnable} from "../../src/modules/common/permissions/OzOwnable.sol";
import {EqualStakeVPCalc} from "../../src/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {SharedVaults} from "../../src/modules/voting-power/extensions/SharedVaults.sol";

contract VotingPowerProviderSharedVaults is VotingPowerProvider, OzOwnable, EqualStakeVPCalc, SharedVaults {
    constructor(address operatorRegistry, address vaultFactory) VotingPowerProvider(operatorRegistry, vaultFactory) {}

    function initialize(
        VotingPowerProviderInitParams memory votingPowerProviderInitParams,
        OzOwnableInitParams memory ozOwnableInitParams
    ) public virtual initializer {
        __VotingPowerProvider_init(votingPowerProviderInitParams);
        __OzOwnable_init(ozOwnableInitParams);
    }
}
