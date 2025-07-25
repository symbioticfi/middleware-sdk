// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {PermissionManager} from "../../src/modules/base/PermissionManager.sol";

abstract contract NoPermissionManager is PermissionManager {
    function __NoPermissionManager_init() internal virtual onlyInitializing {}
    function _checkPermission() internal pure virtual override {}
}
