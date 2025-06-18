// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IBaseSlashing} from "../../../../interfaces/modules/voting-power/extensions/IBaseSlashing.sol";
import {VotingPowerProvider} from "../VotingPowerProvider.sol";
import {BaseSlashingLogic} from "./logic/BaseSlashingLogic.sol";

abstract contract BaseSlashing is VotingPowerProvider, IBaseSlashing {
    modifier onlySlasher() {
        if (msg.sender != getSlasher()) {
            revert BaseSlashing_NotSlasher();
        }
        _;
    }

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.BaseSlashing")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant BaseSlashingStorageLocation =
        0xcd08f9337bf45f7ebac10e65ed25c2483d3efb012be3dbf2b4de227af3bf9400;

    function _getBaseSlashingStorage() internal pure returns (IBaseSlashing.BaseSlashingStorage storage $) {
        bytes32 location = BaseSlashingStorageLocation;
        assembly {
            $.slot := location
        }
    }

    function __BaseSlashing_init(
        BaseSlashingInitParams memory initParams
    ) internal virtual onlyInitializing {
        _setSlasher(initParams.slasher);
    }

    /**
     * @inheritdoc IBaseSlashing
     */
    function getSlasher() public view virtual returns (address) {
        return _getBaseSlashingStorage()._slasher;
    }

    /**
     * @inheritdoc IBaseSlashing
     */
    function setSlasher(
        address slasher
    ) public virtual checkPermission {
        _setSlasher(slasher);
    }

    /**
     * @inheritdoc IBaseSlashing
     */
    function slashVault(
        uint48 timestamp,
        address vault,
        address operator,
        uint256 amount,
        bytes memory hints
    ) public virtual onlySlasher returns (bool success, bytes memory response) {
        return BaseSlashingLogic.slashVault(timestamp, vault, operator, amount, hints);
    }

    /**
     * @inheritdoc IBaseSlashing
     */
    function slashVaultUnsafe(
        uint48 timestamp,
        address vault,
        address operator,
        uint256 amount,
        bytes memory hints
    ) public virtual onlySlasher returns (bool success, bytes memory response) {
        return BaseSlashingLogic.slashVaultUnsafe(timestamp, vault, operator, amount, hints);
    }

    /**
     * @inheritdoc IBaseSlashing
     */
    function executeSlashVault(
        address vault,
        uint256 slashIndex,
        bytes memory hints
    ) public virtual onlySlasher returns (bool success, uint256 slashedAmount) {
        return BaseSlashingLogic.executeSlashVault(vault, slashIndex, hints);
    }

    function _setSlasher(
        address slasher
    ) internal virtual {
        if (slasher == address(0)) {
            revert BaseSlashing_InvalidSlasher();
        }
        _getBaseSlashingStorage()._slasher = slasher;
        emit SetSlasher(slasher);
    }
}
