// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IPermissionManager} from "../../interfaces/modules/base/IPermissionManager.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title PermissionManager
 * @notice Base contract for managing permissions.
 */
abstract contract PermissionManager is Initializable, IPermissionManager {
    modifier checkPermission() {
        _checkPermission();
        _;
    }

    function _checkPermission() internal virtual;
}
