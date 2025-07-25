// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IVotingPowerCalcManager} from "../../../interfaces/modules/voting-power/base/IVotingPowerCalcManager.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title VotingPowerCalcManager
 * @notice Base contract for voting power calculations.
 */
abstract contract VotingPowerCalcManager is Initializable, IVotingPowerCalcManager {
    /**
     * @inheritdoc IVotingPowerCalcManager
     */
    function stakeToVotingPowerAt(
        address vault,
        uint256 stake,
        bytes memory extraData,
        uint48 timestamp
    ) public view virtual returns (uint256 power);

    /**
     * @inheritdoc IVotingPowerCalcManager
     */
    function stakeToVotingPower(
        address vault,
        uint256 stake,
        bytes memory extraData
    ) public view virtual returns (uint256 power);
}
