// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {NoPermissionManager} from "../../../../test/mocks/NoPermissionManager.sol";

contract TestNoPermissionManager is NoPermissionManager {
    function initialize() external initializer {}

    function actionRequiringNoPermission() external checkPermission {}
}

contract NoPermissionManagerTest is Test {
    TestNoPermissionManager noPermManager;

    function setUp() public {
        noPermManager = new TestNoPermissionManager();
        noPermManager.initialize();
    }

    function test_NoPermissionCheck() public {
        address randomUser = address(0x12345);
        vm.startPrank(randomUser);

        noPermManager.actionRequiringNoPermission();

        vm.stopPrank();
    }
}
