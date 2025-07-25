// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {PermissionManager} from "../../base/PermissionManager.sol";

import {IOzAccessManaged} from "../../../interfaces/modules/common/permissions/IOzAccessManaged.sol";

import {AccessManagedUpgradeable} from "@openzeppelin/contracts-upgradeable/access/manager/AccessManagedUpgradeable.sol";

/**
 * @title OzAccessManaged
 * @notice Contract for permission management based on OpenZeppelin's AccessManaged.
 */
abstract contract OzAccessManaged is PermissionManager, AccessManagedUpgradeable, IOzAccessManaged {
    function __OzAccessManaged_init(
        OzAccessManagedInitParams memory initParams
    ) internal virtual onlyInitializing {
        __AccessManaged_init(initParams.authority);
    }

    /**
     * @inheritdoc PermissionManager
     */
    function _checkPermission() internal virtual override {
        _checkCanCall(msg.sender, msg.data);
    }
}
