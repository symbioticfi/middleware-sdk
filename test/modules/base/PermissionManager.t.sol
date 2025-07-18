// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {PermissionManager} from "../../../src/modules/base/PermissionManager.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TestPermissionManager is PermissionManager {
    address public owner;

    function initialize(
        address _owner
    ) external initializer {
        owner = _owner;
    }

    function _checkPermission() internal view override {
        require(msg.sender == owner, "Not authorized");
    }

    function protectedAction() external checkPermission {}
}

contract PermissionManagerTest is Test {
    TestPermissionManager permissionManager;

    function setUp() public {
        permissionManager = new TestPermissionManager();
        permissionManager.initialize(address(this));
    }

    function test_ProtectedAction_SucceedsForOwner() public {
        permissionManager.protectedAction();
    }

    function test_ProtectedAction_RevertIfNotOwner() public {
        address nonOwner = address(0x1234);

        vm.startPrank(nonOwner);

        vm.expectRevert(bytes("Not authorized"));
        permissionManager.protectedAction();

        vm.stopPrank();
    }
}
