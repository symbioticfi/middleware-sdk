// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AccessManager} from "../../../managers/extendable/AccessManager.sol";

/**
 * @title OwnableAccessManager
 * @notice A middleware extension that restricts access to a single owner address
 * @dev Implements AccessManager with owner-based access control
 */
abstract contract OwnableAccessManager is AccessManager {
    uint64 public constant OwnableAccessManager_VERSION = 1;

    /**
     * @notice Error thrown when a non-owner address attempts to call a restricted function
     * @param sender The address that attempted the call
     */
    error OnlyOwnerCanCall(address sender);

    /**
     * @notice Error thrown when trying to set an invalid owner address
     * @param owner The invalid owner address
     */
    error InvalidOwner(address owner);

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.OwnableAccessManager")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableAccessManagerStorageLocation =
        0xcee92923a0c63eca6fc0402d78c9efde9f9f3dc73e6f9e14501bf734ed77f100;

    function _owner() private view returns (address owner_) {
        bytes32 location = OwnableAccessManagerStorageLocation;
        assembly {
            owner_ := sload(location)
        }
    }

    /**
     * @notice Initializes the contract with an owner address
     * @param owner_ The address to set as the owner
     */
    function __OwnableAccessManager_init(
        address owner_
    ) internal onlyInitializing {
        _setOwner(owner_);
    }

    function _setOwner(
        address owner_
    ) private {
        bytes32 location = OwnableAccessManagerStorageLocation;
        assembly {
            sstore(location, owner_)
        }
    }

    /**
     * @notice Gets the current owner address
     * @return The owner address
     */
    function owner() public view returns (address) {
        return _owner();
    }

    /**
     * @notice Checks if the caller has access (is the owner)
     * @dev Reverts if the caller is not the owner
     */
    function _checkAccess() internal view virtual override {
        if (msg.sender != _owner()) {
            revert OnlyOwnerCanCall(msg.sender);
        }
    }

    /**
     * @notice Updates the owner address
     * @param owner_ The new owner address
     * @dev Can only be called by the current owner
     */
    function setOwner(
        address owner_
    ) public checkAccess {
        if (owner_ == address(0)) {
            revert InvalidOwner(address(0));
        }
        _setOwner(owner_);
    }
}