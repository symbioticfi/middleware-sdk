// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {OzAccessControl} from "../../../../src/modules/common/permissions/OzAccessControl.sol";
import {IOzAccessControl} from "../../../../src/interfaces/modules/common/permissions/IOzAccessControl.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract TestOzAccessControl is OzAccessControl {
    bytes32 public constant ADMIN_ROLE = bytes32(0);

    function initialize() external initializer {
        _grantRole(ADMIN_ROLE, msg.sender);
        _setSelectorRole(TestOzAccessControl.protectedFunction.selector, ADMIN_ROLE);
    }

    function protectedFunction() external checkPermission {}

    function setSelectorRole(bytes4 selector, bytes32 role) external {
        _checkRole(ADMIN_ROLE);
        _setSelectorRole(selector, role);
    }
}

contract OzAccessControlTest is Test {
    TestOzAccessControl private testAccessControl;

    address private nonAdmin = address(0x1234);
    bytes32 private constant MY_ROLE = keccak256("MY_ROLE");

    function setUp() public {
        testAccessControl = new TestOzAccessControl();
        testAccessControl.initialize();
    }

    function test_Location() public {
        bytes32 location =
            keccak256(abi.encode(uint256(keccak256("symbiotic.storage.OzAccessControl")) - 1)) & ~bytes32(uint256(0xff));
        assertEq(location, 0xbe09a78a256419d2b885312b60a13e8082d8ab3c36c463fff4fbb086f1e96f00);
    }

    function test_ProtectedFunction_DefaultAdminCanCall() public {
        testAccessControl.protectedFunction();
    }

    function testProtectedFunction_RevertIfCallerDoesNotHaveRole() public {
        vm.startPrank(nonAdmin);

        vm.expectRevert();
        testAccessControl.protectedFunction();

        vm.stopPrank();
    }

    function testChangeRoleForProtectedFunction() public {
        testAccessControl.setSelectorRole(TestOzAccessControl.protectedFunction.selector, MY_ROLE);

        testAccessControl.grantRole(MY_ROLE, nonAdmin);

        vm.startPrank(nonAdmin);
        testAccessControl.protectedFunction();
        vm.stopPrank();
    }

    function testGetRoleForFunctionSelector() public {
        bytes32 defaultRole = testAccessControl.getRole(TestOzAccessControl.protectedFunction.selector);
        assertEq(defaultRole, testAccessControl.ADMIN_ROLE(), "Expected ADMIN_ROLE");

        testAccessControl.setSelectorRole(TestOzAccessControl.protectedFunction.selector, MY_ROLE);
        bytes32 newRole = testAccessControl.getRole(TestOzAccessControl.protectedFunction.selector);
        assertEq(newRole, MY_ROLE, "Expected MY_ROLE after reassign");
    }

    function testSetNoRoleForSelector() public {
        testAccessControl.setSelectorRole(TestOzAccessControl.protectedFunction.selector, bytes32(0));

        vm.startPrank(nonAdmin);
        vm.expectRevert();
        testAccessControl.protectedFunction();
        vm.stopPrank();

        vm.startPrank(address(this));
        testAccessControl.protectedFunction();
        vm.stopPrank();
    }
}
