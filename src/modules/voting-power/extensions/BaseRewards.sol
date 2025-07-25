// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerProvider} from "../VotingPowerProvider.sol";

import {BaseRewardsLogic} from "./logic/BaseRewardsLogic.sol";

import {IBaseRewards} from "../../../interfaces/modules/voting-power/extensions/IBaseRewards.sol";

/**
 * @title BaseRewards
 * @notice Base contract for distributing rewards to stakers and operators.
 */
abstract contract BaseRewards is VotingPowerProvider, IBaseRewards {
    modifier onlyRewarder() {
        _checkRewarder();
        _;
    }

    function _checkRewarder() internal view virtual {
        if (msg.sender != getRewarder()) {
            revert BaseRewards_NotRewarder();
        }
    }

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.BaseRewards")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant BaseRewardsStorageLocation =
        0xbda599e6417b60ef01d2592ea6468e27d9dc233383dcd1f33c49128d08d88b00;

    function _getBaseRewardsStorage() internal pure returns (IBaseRewards.BaseRewardsStorage storage $) {
        bytes32 location = BaseRewardsStorageLocation;
        assembly {
            $.slot := location
        }
    }

    function __BaseRewards_init(
        BaseRewardsInitParams memory initParams
    ) internal virtual onlyInitializing {
        _setRewarder(initParams.rewarder);
    }

    /**
     * @inheritdoc IBaseRewards
     */
    function getRewarder() public view virtual returns (address) {
        return _getBaseRewardsStorage()._rewarder;
    }

    /**
     * @inheritdoc IBaseRewards
     */
    function distributeStakerRewards(
        address stakerRewards,
        address token,
        uint256 amount,
        bytes memory data
    ) public virtual {
        _checkRewarder();
        BaseRewardsLogic.distributeStakerRewards(stakerRewards, token, amount, data);
    }

    /**
     * @inheritdoc IBaseRewards
     */
    function distributeOperatorRewards(
        address operatorRewards,
        address token,
        uint256 amount,
        bytes32 root
    ) public virtual {
        _checkRewarder();
        BaseRewardsLogic.distributeOperatorRewards(operatorRewards, token, amount, root);
    }

    /**
     * @inheritdoc IBaseRewards
     */
    function setRewarder(
        address rewarder
    ) public virtual checkPermission {
        _setRewarder(rewarder);
    }

    function _setRewarder(
        address rewarder
    ) internal virtual {
        if (rewarder == address(0)) {
            revert BaseRewards_InvalidRewarder();
        }
        _getBaseRewardsStorage()._rewarder = rewarder;
        emit SetRewarder(rewarder);
    }
}
