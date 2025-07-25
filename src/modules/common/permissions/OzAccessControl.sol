// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {PermissionManager} from "../../base/PermissionManager.sol";

import {IOzAccessControl} from "../../../interfaces/modules/common/permissions/IOzAccessControl.sol";

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title OzAccessControl
 * @notice Contract for permission management based on OpenZeppelin's AccessControl.
 */
abstract contract OzAccessControl is PermissionManager, AccessControlUpgradeable, IOzAccessControl {
    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.OzAccessControl")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OzAccessControlStorageLocation =
        0xbe09a78a256419d2b885312b60a13e8082d8ab3c36c463fff4fbb086f1e96f00;

    function _getOzAccessControlStorage() internal pure returns (OzAccessControlStorage storage $) {
        assembly {
            $.slot := OzAccessControlStorageLocation
        }
    }

    function __OzAccessControl_init() internal virtual onlyInitializing {
        __AccessControl_init();
    }

    /**
     * @inheritdoc IOzAccessControl
     */
    function getRole(
        bytes4 selector
    ) public view virtual returns (bytes32) {
        return _getOzAccessControlStorage()._selectorRoles[selector];
    }

    /**
     * @inheritdoc PermissionManager
     */
    function _checkPermission() internal view virtual override {
        _checkRole(getRole(msg.sig));
    }

    function _setSelectorRole(bytes4 selector, bytes32 role) internal virtual {
        _getOzAccessControlStorage()._selectorRoles[selector] = role;
        emit SetSelectorRole(selector, role);
    }
}
