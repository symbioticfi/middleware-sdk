// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {OzAccessManaged} from "../../../../src/modules/common/permissions/OzAccessManaged.sol";

import {IAuthority} from "@openzeppelin/contracts/access/manager/IAuthority.sol";

contract MockAuthority is IAuthority {
    address public admin;

    constructor(
        address _admin
    ) {
        admin = _admin;
    }

    function canCall(address caller, address target, bytes4 selector) external view returns (bool) {
        return caller == admin;
    }
}

contract TestOzAccessManaged is OzAccessManaged {
    function protectedAction() external checkPermission {}

    function initialize(
        address authority
    ) external initializer {
        OzAccessManagedInitParams memory initParams = OzAccessManagedInitParams({authority: authority});
        __OzAccessManaged_init(initParams);
    }
}

contract OzAccessManagedTest is Test {
    TestOzAccessManaged private ozAccessManaged;
    MockAuthority private authority;

    address private admin = address(0xABCD);
    address private nonAdmin = address(0x1234);

    function setUp() public {
        authority = new MockAuthority(admin);

        ozAccessManaged = new TestOzAccessManaged();
        ozAccessManaged.initialize(address(authority));
    }

    function testProtectedAction_SucceedsForAdmin() public {
        vm.startPrank(admin);
        ozAccessManaged.protectedAction();
        vm.stopPrank();
    }

    function testProtectedAction_RevertsForNonAdmin() public {
        vm.startPrank(nonAdmin);

        vm.expectRevert();
        ozAccessManaged.protectedAction();

        vm.stopPrank();
    }

    function testCannotChangeAuthority() public {
        vm.expectRevert();
        ozAccessManaged.initialize(address(0xDEAD));
    }
}
