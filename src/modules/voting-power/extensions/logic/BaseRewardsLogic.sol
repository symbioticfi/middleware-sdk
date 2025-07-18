// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IBaseRewards} from "../../../../interfaces/modules/voting-power/extensions/IBaseRewards.sol";
import {INetworkManager} from "../../../../interfaces/modules/base/INetworkManager.sol";

import {IDefaultOperatorRewards} from
    "@symbioticfi/rewards/src/interfaces/defaultOperatorRewards/IDefaultOperatorRewards.sol";
import {IStakerRewards} from "@symbioticfi/rewards/src/interfaces/stakerRewards/IStakerRewards.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library BaseRewardsLogic {
    using SafeERC20 for IERC20;

    function distributeStakerRewards(address stakerRewards, address token, uint256 amount, bytes memory data) public {
        IERC20(token).forceApprove(stakerRewards, amount);
        IStakerRewards(stakerRewards).distributeRewards(INetworkManager(address(this)).NETWORK(), token, amount, data);
        emit IBaseRewards.DistributeStakerRewards(stakerRewards, token, amount, data);
    }

    function distributeOperatorRewards(address operatorRewards, address token, uint256 amount, bytes32 root) public {
        IERC20(token).forceApprove(operatorRewards, amount);
        IDefaultOperatorRewards(operatorRewards).distributeRewards(
            INetworkManager(address(this)).NETWORK(), token, amount, root
        );
        emit IBaseRewards.DistributeOperatorRewards(operatorRewards, token, amount, root);
    }
}
