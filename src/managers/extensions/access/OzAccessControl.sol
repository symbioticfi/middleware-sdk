// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessManager} from "../../base/AccessManager.sol";

/**
 * @title OzAccessControl
 * @notice A middleware extension that implements role-based access control
 * @dev Implements AccessManager with role-based access control functionality
 */
abstract contract OzAccessControl is AccessManager {
    uint64 public constant OzAccessControl_VERSION = 1;

    struct RoleData {
        mapping(address account => bool) hasRole;
        bytes32 adminRole;
    }

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @custom:storage-location erc7201:symbiotic.storage.OzAccessControl
    struct OzAccessControlStorage {
        mapping(bytes32 role => RoleData) _roles;
        mapping(bytes4 selector => bytes32 role) _selectorRoles;
    }

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.OzAccessControl")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OzAccessControlStorageLocation =
        0xbe09a78a256419d2b885312b60a13e8082d8ab3c36c463fff4fbb086f1e96f00;

    function _getOzAccessControlStorage() internal pure returns (OzAccessControlStorage storage $) {
        assembly {
            $.slot := OzAccessControlStorageLocation
        }
    }

    error AccessControlUnauthorizedAccount(address account, bytes32 role);
    error AccessControlBadConfirmation();

    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event SelectorRoleSet(bytes4 indexed selector, bytes32 indexed role);

    /**
     * @notice Initializes the contract with a default admin
     * @param defaultAdmin The address to set as the default admin
     */
    function __OzAccessControl_init(
        address defaultAdmin
    ) internal onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
    }

    /**
     * @notice Returns true if account has been granted role
     * @param role The role to check
     * @param account The account to check
     * @return bool True if account has role
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        OzAccessControlStorage storage $ = _getOzAccessControlStorage();
        return $._roles[role].hasRole[account];
    }

    /**
     * @notice Returns the admin role that controls the specified role
     * @param role The role to get the admin for
     * @return bytes32 The admin role
     */
    function getRoleAdmin(
        bytes32 role
    ) public view virtual returns (bytes32) {
        OzAccessControlStorage storage $ = _getOzAccessControlStorage();
        return $._roles[role].adminRole;
    }

    /**
     * @notice Returns the role required for a function selector
     * @param selector The function selector
     * @return bytes32 The required role
     */
    function getRole(
        bytes4 selector
    ) public view virtual returns (bytes32) {
        OzAccessControlStorage storage $ = _getOzAccessControlStorage();
        return $._selectorRoles[selector];
    }

    /**
     * @notice Grants role to account if caller has admin role
     * @param role The role to grant
     * @param account The account to grant the role to
     */
    function grantRole(bytes32 role, address account) public virtual {
        bytes32 adminRole = getRoleAdmin(role);
        if (!hasRole(adminRole, msg.sender)) {
            revert AccessControlUnauthorizedAccount(msg.sender, adminRole);
        }
        _grantRole(role, account);
    }

    /**
     * @notice Revokes role from account if caller has admin role
     * @param role The role to revoke
     * @param account The account to revoke the role from
     */
    function revokeRole(bytes32 role, address account) public virtual {
        bytes32 adminRole = getRoleAdmin(role);
        if (!hasRole(adminRole, msg.sender)) {
            revert AccessControlUnauthorizedAccount(msg.sender, adminRole);
        }
        _revokeRole(role, account);
    }

    /**
     * @notice Allows an account to renounce a role they have
     * @param role The role to renounce
     * @param callerConfirmation Address of the caller for confirmation
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != msg.sender) {
            revert AccessControlBadConfirmation();
        }
        _revokeRole(role, callerConfirmation);
    }

    /**
     * @notice Sets the role required for a function selector
     * @param selector The function selector
     * @param role The required role
     */
    function _setSelectorRole(bytes4 selector, bytes32 role) public virtual {
        OzAccessControlStorage storage $ = _getOzAccessControlStorage();
        $._selectorRoles[selector] = role;
        emit SelectorRoleSet(selector, role);
    }

    /**
     * @notice Sets the admin role for a role
     * @param role The role to set admin for
     * @param adminRole The new admin role
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) public virtual {
        OzAccessControlStorage storage $ = _getOzAccessControlStorage();
        bytes32 previousAdminRole = getRoleAdmin(role);
        $._roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @notice public function to grant a role
     * @param role The role to grant
     * @param account The account to grant the role to
     * @return bool True if role was granted
     */
    function _grantRole(bytes32 role, address account) public virtual returns (bool) {
        if (!hasRole(role, account)) {
            OzAccessControlStorage storage $ = _getOzAccessControlStorage();
            $._roles[role].hasRole[account] = true;
            emit RoleGranted(role, account, msg.sender);
            return true;
        }
        return false;
    }

    /**
     * @notice public function to revoke a role
     * @param role The role to revoke
     * @param account The account to revoke the role from
     * @return bool True if role was revoked
     */
    function _revokeRole(bytes32 role, address account) public virtual returns (bool) {
        if (hasRole(role, account)) {
            OzAccessControlStorage storage $ = _getOzAccessControlStorage();
            $._roles[role].hasRole[account] = false;
            emit RoleRevoked(role, account, msg.sender);
            return true;
        }
        return false;
    }

    /**
     * @notice Checks access based on role required for the function selector
     * @dev Implements BaseMiddleware's _checkAccess function
     */
    function _checkAccess() internal view virtual override {
        if (!hasRole(getRole(msg.sig), msg.sender)) {
            revert AccessControlUnauthorizedAccount(msg.sender, getRole(msg.sig));
        }
    }
}
