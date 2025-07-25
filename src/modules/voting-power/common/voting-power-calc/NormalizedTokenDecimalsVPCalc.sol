// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {EqualStakeVPCalc} from "./EqualStakeVPCalc.sol";

import {Scaler} from "../../../../libraries/utils/Scaler.sol";

import {INormalizedTokenDecimalsVPCalc} from
    "../../../../interfaces/modules/voting-power/common/voting-power-calc/INormalizedTokenDecimalsVPCalc.sol";
import {IVotingPowerCalcManager} from "../../../../interfaces/modules/voting-power/base/IVotingPowerCalcManager.sol";

import {IVault} from "@symbioticfi/core/src/interfaces/vault/IVault.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title NormalizedTokenDecimalsVPCalc
 * @notice Contract for calculating the voting power, normalizing the stakes in different tokens to the same decimals.
 */
abstract contract NormalizedTokenDecimalsVPCalc is EqualStakeVPCalc, INormalizedTokenDecimalsVPCalc {
    using Scaler for uint256;

    uint8 internal constant BASE_DECIMALS = 24;

    function __NormalizedTokenDecimalsVPCalc_init() internal virtual onlyInitializing {}

    /**
     * @inheritdoc IVotingPowerCalcManager
     */
    function stakeToVotingPowerAt(
        address vault,
        uint256 stake,
        bytes memory extraData,
        uint48 timestamp
    ) public view virtual override returns (uint256) {
        return _normalizeVaultTokenDecimals(vault, super.stakeToVotingPowerAt(vault, stake, extraData, timestamp));
    }

    /**
     * @inheritdoc IVotingPowerCalcManager
     */
    function stakeToVotingPower(
        address vault,
        uint256 stake,
        bytes memory extraData
    ) public view virtual override returns (uint256) {
        return _normalizeVaultTokenDecimals(vault, super.stakeToVotingPower(vault, stake, extraData));
    }

    function _getCollateral(
        address vault
    ) internal view virtual returns (address) {
        return IVault(vault).collateral();
    }

    function _normalizeVaultTokenDecimals(address vault, uint256 votingPower) internal view virtual returns (uint256) {
        return votingPower.scale(IERC20Metadata(_getCollateral(vault)).decimals(), BASE_DECIMALS);
    }
}
