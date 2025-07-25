// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {PermissionManager} from "../../base/PermissionManager.sol";

import {IOzOwnable} from "../../../interfaces/modules/common/permissions/IOzOwnable.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title OzOwnable
 * @notice Contract for permission management based on OpenZeppelin's Ownable.
 */
abstract contract OzOwnable is PermissionManager, OwnableUpgradeable, IOzOwnable {
    function __OzOwnable_init(
        OzOwnableInitParams memory initParams
    ) internal virtual onlyInitializing {
        __Ownable_init(initParams.owner);
    }

    /**
     * @inheritdoc PermissionManager
     */
    function _checkPermission() internal view virtual override {
        _checkOwner();
    }
}
