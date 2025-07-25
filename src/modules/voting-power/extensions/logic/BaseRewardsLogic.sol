// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IBaseRewards} from "../../../../interfaces/modules/voting-power/extensions/IBaseRewards.sol";
import {INetworkManager} from "../../../../interfaces/modules/base/INetworkManager.sol";

import {IDefaultOperatorRewards} from
    "@symbioticfi/rewards/src/interfaces/defaultOperatorRewards/IDefaultOperatorRewards.sol";
import {IStakerRewards} from "@symbioticfi/rewards/src/interfaces/stakerRewards/IStakerRewards.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title BaseRewardsLogic
 * @notice Library with bindings for distributing rewards to stakers and operators.
 */
library BaseRewardsLogic {
    using SafeERC20 for IERC20;

    /**
     * @notice Distributes staker rewards.
     * @param stakerRewards The address of the staker rewards contract.
     * @param token The address of the token to distribute.
     * @param amount The amount of the token to distribute.
     * @param data The data to pass to the staker rewards contract.
     * @dev The funds should be transferred to this contract separately before the call.
     */
    function distributeStakerRewards(address stakerRewards, address token, uint256 amount, bytes memory data) public {
        IERC20(token).forceApprove(stakerRewards, amount);
        IStakerRewards(stakerRewards).distributeRewards(INetworkManager(address(this)).NETWORK(), token, amount, data);
        emit IBaseRewards.DistributeStakerRewards(stakerRewards, token, amount, data);
    }

    /**
     * @notice Distributes operator rewards.
     * @param operatorRewards The address of the operator rewards contract.
     * @param token The address of the token to distribute.
     * @param amount The amount of the token to distribute.
     * @param root The root of the distribution Merkle tree.
     * @dev The funds should be transferred to this contract separately before the call.
     */
    function distributeOperatorRewards(address operatorRewards, address token, uint256 amount, bytes32 root) public {
        IERC20(token).forceApprove(operatorRewards, amount);
        IDefaultOperatorRewards(operatorRewards).distributeRewards(
            INetworkManager(address(this)).NETWORK(), token, amount, root
        );
        emit IBaseRewards.DistributeOperatorRewards(operatorRewards, token, amount, root);
    }
}
