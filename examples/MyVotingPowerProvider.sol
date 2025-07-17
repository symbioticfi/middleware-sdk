// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerProvider} from "../src/contracts/modules/voting-power/VotingPowerProvider.sol";
import {OzOwnable} from "../src/contracts/modules/common/permissions/OzOwnable.sol";
import {EqualStakeVPCalc} from "../src/contracts/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {OperatorVaults} from "../src/contracts/modules/voting-power/extensions/OperatorVaults.sol";

contract MyVotingPowerProvider is VotingPowerProvider, OzOwnable, EqualStakeVPCalc, OperatorVaults {
    constructor(address operatorRegistry, address vaultFactory) VotingPowerProvider(operatorRegistry, vaultFactory) {}

    function initialize(
        VotingPowerProviderInitParams memory votingPowerProviderInitParams,
        OzOwnableInitParams memory ozOwnableInitParams
    ) public virtual initializer {
        __VotingPowerProvider_init(votingPowerProviderInitParams);
        __OzOwnable_init(ozOwnableInitParams);
    }
}
