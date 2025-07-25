// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {VotingPowerCalcManager} from "../../../src/modules/voting-power/base/VotingPowerCalcManager.sol";

contract TestVotingPowerCalcManager is VotingPowerCalcManager {
    bool public initialized;

    function initialize() external initializer {
        initialized = true;
    }

    function stakeToVotingPowerAt(
        address vault,
        uint256 stake,
        bytes memory extraData,
        uint48 timestamp
    ) public view override returns (uint256 power) {
        return stake / 10;
    }

    function stakeToVotingPower(
        address vault,
        uint256 stake,
        bytes memory extraData
    ) public view override returns (uint256 power) {
        return stake / 10;
    }
}

contract VotingPowerCalcManagerTest is Test {
    TestVotingPowerCalcManager private manager;

    function setUp() public {
        manager = new TestVotingPowerCalcManager();
        manager.initialize();
    }

    function testReInitializeReverts() public {
        vm.expectRevert();
        manager.initialize();
    }

    function testStakeToVotingPowerAt() public {
        uint256 stake = 1000;
        uint48 timestamp = uint48(vm.getBlockTimestamp());
        // We'll pass in some dummy values for the other arguments.
        uint256 power = manager.stakeToVotingPowerAt(address(0x1234), stake, bytes("extra"), timestamp);
        assertEq(power, 100, "Expect stake/10");
    }

    function testStakeToVotingPower() public {
        uint256 stake = 5000;
        uint256 power = manager.stakeToVotingPower(address(0x4567), stake, bytes(""));
        assertEq(power, 500, "Expect stake/10");
    }

    function testWithExtraData() public {
        uint256 stake = 2000;
        bytes memory myExtraData = abi.encode("some info", uint256(123));
        uint256 power = manager.stakeToVotingPower(address(0xABC), stake, myExtraData);
        assertEq(power, 200, "still stake/10 ignoring extra data");
    }
}
