// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerCalcManager} from "../../base/VotingPowerCalcManager.sol";

import {IEqualStakeVPCalc} from
    "../../../../interfaces/modules/voting-power/common/voting-power-calc/IEqualStakeVPCalc.sol";
import {IVotingPowerCalcManager} from "../../../../interfaces/modules/voting-power/base/IVotingPowerCalcManager.sol";

/**
 * @title EqualStakeVPCalc
 * @notice Contract for calculating the voting power, making it equal to the stake.
 */
abstract contract EqualStakeVPCalc is VotingPowerCalcManager, IEqualStakeVPCalc {
    function __EqualStakeVPCalc_init() internal virtual onlyInitializing {}

    /**
     * @inheritdoc IVotingPowerCalcManager
     */
    function stakeToVotingPowerAt(
        address, /* vault */
        uint256 stake,
        bytes memory, /* extraData */
        uint48 /* timestamp */
    ) public view virtual override returns (uint256) {
        return stake;
    }

    /**
     * @inheritdoc IVotingPowerCalcManager
     */
    function stakeToVotingPower(
        address, /* vault */
        uint256 stake,
        bytes memory /* extraData */
    ) public view virtual override returns (uint256) {
        return stake;
    }
}
