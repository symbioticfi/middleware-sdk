// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {OzOwnable} from "../../../../src/modules/common/permissions/OzOwnable.sol";

contract TestOzOwnable is OzOwnable {
    function initialize(
        address owner_
    ) external initializer {
        OzOwnableInitParams memory initParams = OzOwnableInitParams({owner: owner_});
        __OzOwnable_init(initParams);
    }

    function protectedAction() external checkPermission {}
}

contract OzOwnableTest is Test {
    TestOzOwnable private testOwnable;

    address private owner = address(0xABCD);
    address private nonOwner = address(0x1234);

    function setUp() public {
        testOwnable = new TestOzOwnable();
        testOwnable.initialize(owner);
    }

    function testProtectedAction_SucceedsForOwner() public {
        vm.startPrank(owner);
        testOwnable.protectedAction();
        vm.stopPrank();
    }

    function testProtectedAction_RevertsForNonOwner() public {
        vm.startPrank(nonOwner);
        vm.expectRevert();
        testOwnable.protectedAction();
        vm.stopPrank();
    }

    function testReinitializeReverts() public {
        vm.expectRevert();
        testOwnable.initialize(owner);
    }

    function testTransferOwnership() public {
        vm.startPrank(owner);
        testOwnable.transferOwnership(nonOwner);
        vm.stopPrank();

        vm.startPrank(nonOwner);
        testOwnable.protectedAction(); // should succeed
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert();
        testOwnable.protectedAction();
        vm.stopPrank();
    }
}
