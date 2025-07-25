// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {NoPermissionManager} from "../../mocks/NoPermissionManager.sol";
import {EpochManager} from "../../../src/modules/valset-driver/EpochManager.sol";
import {IEpochManager} from "../../../src/interfaces/modules/valset-driver/IEpochManager.sol";
import {Checkpoints} from "../../../src/libraries/structs/Checkpoints.sol";

contract TestEpochManager is EpochManager, NoPermissionManager {
    using Checkpoints for Checkpoints.Trace208;

    Checkpoints.Trace208 private _testTrace;

    function initialize(
        EpochManagerInitParams memory initParams
    ) external initializer {
        __EpochManager_init(initParams);
    }

    function getEpochDurationDataByTimestamp(
        uint48 timestamp
    ) public view returns (uint48, uint48, uint48) {
        return _getEpochDurationDataByTimestamp(timestamp);
    }

    function getEpochDurationDataByIndex(
        uint48 index
    ) public view returns (uint48, uint48, uint48) {
        return _getEpochDurationDataByIndex(index);
    }

    function getCurrentEpochDurationData() public view returns (uint48, uint48, uint48) {
        return _getCurrentEpochDurationData();
    }

    function setEpochDuration(uint48 epochDuration, uint48 epochDurationTimestamp, uint48 epochDurationIndex) public {
        _setEpochDuration(epochDuration, epochDurationTimestamp, epochDurationIndex);
    }

    function serializeEpochDurationData(
        uint48 epochDuration,
        uint48 epochDurationTimestamp,
        uint48 epochDurationIndex
    ) public pure returns (uint208) {
        return _serializeEpochDurationData(epochDuration, epochDurationTimestamp, epochDurationIndex);
    }

    function deserializeEpochDurationData(
        uint208 epochDurationData
    ) public pure returns (uint48, uint48, uint48) {
        return _deserializeEpochDurationData(epochDurationData);
    }

    function getCurrentValuePublic(
        uint48 currentTimepoint
    ) public view returns (uint208) {
        return _getCurrentValue(_testTrace, currentTimepoint);
    }

    function pushTestCheckpoint(uint48 key, uint208 value) public {
        _testTrace.push(key, value);
    }
}

contract EpochManagerTest is Test {
    TestEpochManager internal epochManager;

    bytes4 private ERR_INVALID_EPOCH_DURATION = IEpochManager.EpochManager_InvalidEpochDuration.selector;
    bytes4 private ERR_INVALID_EPOCH_DURATION_TIMESTAMP =
        IEpochManager.EpochManager_InvalidEpochDurationTimestamp.selector;

    function setUp() public {
        epochManager = new TestEpochManager();
    }

    function test_Initialize_SetsEpochDuration() public {
        vm.expectRevert();
        epochManager.getCurrentEpoch();

        uint48 startTime = uint48(vm.getBlockTimestamp()) + 200;
        IEpochManager.EpochManagerInitParams memory initParams =
            IEpochManager.EpochManagerInitParams({epochDuration: 100, epochDurationTimestamp: startTime});

        epochManager.initialize(initParams);

        assertEq(epochManager.getNextEpoch(), 0);
        assertEq(epochManager.getNextEpochStart(), startTime);
        assertEq(epochManager.getNextEpochDuration(), 100);

        vm.warp(startTime);

        uint48 currentEpoch = epochManager.getCurrentEpoch();
        assertEq(currentEpoch, 0, "Initially, epoch should be 0 if we haven't reached startTime");

        uint48 currentEpochStart = epochManager.getCurrentEpochStart();
        assertEq(currentEpochStart, startTime, "Epoch start mismatch");

        assertEq(epochManager.getNextEpoch(), 1);
        assertEq(epochManager.getNextEpochStart(), startTime + 100);
        assertEq(epochManager.getNextEpochDuration(), 100);

        bytes32 location =
            keccak256(abi.encode(uint256(keccak256("symbiotic.storage.EpochManager")) - 1)) & ~bytes32(uint256(0xff));
        assertEq(location, 0xab930e9b836b4d72502da14061937ab080936446173403910135ea983863d400);
    }

    function test_Initialize_SetsEpochDuration_WithZeroTimestamp() public {
        vm.expectRevert();
        epochManager.getCurrentEpoch();

        IEpochManager.EpochManagerInitParams memory initParams =
            IEpochManager.EpochManagerInitParams({epochDuration: 100, epochDurationTimestamp: 0});

        epochManager.initialize(initParams);
        uint48 currentEpoch = epochManager.getCurrentEpoch();
        assertEq(currentEpoch, 0, "Initially, epoch should be 0 if we haven't reached startTime");

        uint48 currentEpochStart = epochManager.getCurrentEpochStart();
        assertEq(currentEpochStart, uint48(vm.getBlockTimestamp()), "Epoch start mismatch");

        assertEq(epochManager.getNextEpoch(), 1);
        assertEq(epochManager.getNextEpochStart(), uint48(vm.getBlockTimestamp()) + 100);
        assertEq(epochManager.getNextEpochDuration(), 100);
    }

    function test_Initialize_RevertOnZeroEpochDuration() public {
        IEpochManager.EpochManagerInitParams memory initParams = IEpochManager.EpochManagerInitParams({
            epochDuration: 0,
            epochDurationTimestamp: uint48(vm.getBlockTimestamp() + 100)
        });

        vm.expectRevert(ERR_INVALID_EPOCH_DURATION);
        epochManager.initialize(initParams);
    }

    function test_Initialize_RevertOnPastTimestamp() public {
        vm.warp(100);
        IEpochManager.EpochManagerInitParams memory initParams = IEpochManager.EpochManagerInitParams({
            epochDuration: 100,
            epochDurationTimestamp: uint48(vm.getBlockTimestamp() - 1)
        });

        vm.expectRevert(ERR_INVALID_EPOCH_DURATION_TIMESTAMP);
        epochManager.initialize(initParams);
    }

    function test_AdvanceTimeAndCheckEpoch() public {
        IEpochManager.EpochManagerInitParams memory initParams = IEpochManager.EpochManagerInitParams({
            epochDuration: 100,
            epochDurationTimestamp: uint48(vm.getBlockTimestamp() + 10)
        });
        epochManager.initialize(initParams);

        vm.expectRevert();
        assertEq(epochManager.getCurrentEpoch(), 0);
        vm.warp(vm.getBlockTimestamp() + 50);
        assertEq(epochManager.getCurrentEpoch(), 0);
        vm.warp(vm.getBlockTimestamp() + 70);
        assertEq(epochManager.getCurrentEpoch(), 1, "We should be in epoch #1 now");

        assertEq(epochManager.getNextEpoch(), 2);

        uint48 expectedNextEpochStart = uint48(initParams.epochDurationTimestamp + 2 * 100);
        assertEq(epochManager.getNextEpochStart(), expectedNextEpochStart);
        assertEq(epochManager.getNextEpochDuration(), 100);
    }

    function test_SetEpochDuration_RevertIfIndexLessThanCurrent() public {
        IEpochManager.EpochManagerInitParams memory initParams = IEpochManager.EpochManagerInitParams({
            epochDuration: 100,
            epochDurationTimestamp: uint48(vm.getBlockTimestamp() + 10)
        });
        epochManager.initialize(initParams);

        vm.warp(vm.getBlockTimestamp() + 110);
        assertEq(epochManager.getCurrentEpoch(), 1);

        assertEq(epochManager.getNextEpochDuration(), 100);
        epochManager.setEpochDuration(50);
        assertEq(epochManager.getNextEpochDuration(), 50);

        vm.warp(epochManager.getNextEpochStart() + 1);
        assertEq(epochManager.getCurrentEpochDuration(), 50, "Should have updated duration for epoch #2 onward");
    }

    function test_SetEpochDuration_RevertOnZeroDuration() public {
        IEpochManager.EpochManagerInitParams memory initParams = IEpochManager.EpochManagerInitParams({
            epochDuration: 100,
            epochDurationTimestamp: uint48(vm.getBlockTimestamp())
        });
        epochManager.initialize(initParams);

        vm.expectRevert(ERR_INVALID_EPOCH_DURATION);
        epochManager.setEpochDuration(0);
    }

    function test_GetEpochIndex() public {
        IEpochManager.EpochManagerInitParams memory initParams = IEpochManager.EpochManagerInitParams({
            epochDuration: 60,
            epochDurationTimestamp: uint48(vm.getBlockTimestamp() + 10)
        });
        epochManager.initialize(initParams);

        uint48 someFuture = initParams.epochDurationTimestamp + 130;

        uint48 epochIndex = epochManager.getEpochIndex(someFuture);
        assertEq(epochIndex, 2, "Should be epoch #2 for that timestamp");
    }

    function test_GetEpochDurationAndStart() public {
        IEpochManager.EpochManagerInitParams memory initParams = IEpochManager.EpochManagerInitParams({
            epochDuration: 50,
            epochDurationTimestamp: uint48(vm.getBlockTimestamp() + 10)
        });
        epochManager.initialize(initParams);

        assertEq(epochManager.getNextEpoch(), 0);
        assertEq(epochManager.getNextEpochStart(), uint48(vm.getBlockTimestamp() + 10));
        assertEq(epochManager.getNextEpochDuration(), 50);

        epochManager.setEpochDuration(200);

        assertEq(epochManager.getNextEpoch(), 0);
        assertEq(epochManager.getNextEpochStart(), uint48(vm.getBlockTimestamp() + 10));
        assertEq(epochManager.getNextEpochDuration(), 200);

        epochManager.setEpochDuration(50);

        uint48 startTime = initParams.epochDurationTimestamp;
        vm.warp(startTime + 120);
        assertEq(epochManager.getCurrentEpoch(), 2);

        epochManager.setEpochDuration(100);

        uint48 dur2 = epochManager.getEpochDuration(2);
        assertEq(dur2, 50, "epoch #2 is still 50s");

        uint48 dur3 = epochManager.getEpochDuration(3);
        assertEq(dur3, 100, "epoch #3 must be 100s now");

        uint48 start2 = epochManager.getEpochStart(2);
        assertEq(start2, startTime + 2 * 50, "Start of epoch #2 mismatch");

        uint48 start3 = epochManager.getEpochStart(3);
        assertEq(start3, startTime + 150, "Start of epoch #3 mismatch");
    }

    function test_SerializeDeserializeEpochDurationData() public {
        uint48 epochDuration = 100;
        uint48 epochDurationTimestamp = 200;
        uint48 epochDurationIndex = 2;

        uint208 serialized =
            epochManager.serializeEpochDurationData(epochDuration, epochDurationTimestamp, epochDurationIndex);

        (uint48 d, uint48 ts, uint48 idx) = epochManager.deserializeEpochDurationData(serialized);

        assertEq(d, epochDuration, "epochDuration mismatch");
        assertEq(ts, epochDurationTimestamp, "epochDurationTimestamp mismatch");
        assertEq(idx, epochDurationIndex, "epochDurationIndex mismatch");
    }

    function test_GetEpochDurationDataByTimestamp() public {
        uint48 now_ = uint48(vm.getBlockTimestamp());
        IEpochManager.EpochManagerInitParams memory initParams =
            IEpochManager.EpochManagerInitParams({epochDuration: 100, epochDurationTimestamp: now_ + 10});
        epochManager.initialize(initParams);

        uint48 midTimestamp = now_ + 50;
        (uint48 duration, uint48 durationTimestamp, uint48 durationIndex) =
            epochManager.getEpochDurationDataByTimestamp(midTimestamp);

        assertEq(duration, 100, "duration mismatch");
        assertEq(durationTimestamp, now_ + 10, "timestamp mismatch");
        assertEq(durationIndex, 0, "index mismatch");
    }

    function test_GetEpochDurationDataByIndex() public {
        uint48 now_ = uint48(vm.getBlockTimestamp());
        IEpochManager.EpochManagerInitParams memory initParams =
            IEpochManager.EpochManagerInitParams({epochDuration: 200, epochDurationTimestamp: now_ + 100});
        epochManager.initialize(initParams);

        (uint48 dur, uint48 durTS, uint48 durIndex) = epochManager.getEpochDurationDataByIndex(0);
        assertEq(dur, 200);
        assertEq(durTS, now_ + 100);
        assertEq(durIndex, 0);
    }

    function test_GetCurrentEpochDurationData() public {
        vm.expectRevert();
        epochManager.getCurrentEpochDurationData();

        uint48 now_ = uint48(vm.getBlockTimestamp());
        IEpochManager.EpochManagerInitParams memory initParams =
            IEpochManager.EpochManagerInitParams({epochDuration: 60, epochDurationTimestamp: now_});
        epochManager.initialize(initParams);

        (uint48 d, uint48 ts, uint48 idx) = epochManager.getCurrentEpochDurationData();
        assertEq(d, 60);
        assertEq(ts, now_);
        assertEq(idx, 0);
    }

    function test_DirectSetEpochDuration() public {
        uint48 now_ = uint48(vm.getBlockTimestamp());
        epochManager.initialize(IEpochManager.EpochManagerInitParams({epochDuration: 50, epochDurationTimestamp: now_}));

        vm.warp(now_ + 50);

        assertEq(epochManager.getCurrentEpoch(), 1, "Should be in epoch #1");

        epochManager.setEpochDuration(75, now_ + 200, 3);

        (uint48 dur, uint48 durTS, uint48 durIdx) = epochManager.getEpochDurationDataByIndex(3);
        assertEq(dur, 75, "Updated duration mismatch");
        assertEq(durTS, now_ + 200, "Updated timestamp mismatch");
        assertEq(durIdx, 3, "Updated index mismatch");
    }

    function test_GetCurrentValue_NoCheckpoint() public {
        vm.expectRevert();
        epochManager.getCurrentValuePublic(100);
    }

    function test_GetCurrentValue_SingleCheckpoint() public {
        epochManager.pushTestCheckpoint(100, 999);

        vm.expectRevert();
        epochManager.getCurrentValuePublic(99);

        uint208 val = epochManager.getCurrentValuePublic(100);
        assertEq(val, 999, "Should match the single checkpoint's value");
        val = epochManager.getCurrentValuePublic(200);
        assertEq(val, 999, "Should remain the same for any time >= last checkpoint key");
    }

    function test_GetCurrentValue_MultipleCheckpoints() public {
        epochManager.pushTestCheckpoint(50, 1000);
        epochManager.pushTestCheckpoint(100, 2000);
        epochManager.pushTestCheckpoint(150, 3000);

        // getCurrentValuePublic is unreliable for cases when there are more than 1 checkpoint in the future
        assertEq(epochManager.getCurrentValuePublic(49), 2000);
        assertEq(epochManager.getCurrentValuePublic(50), 2000);
        assertEq(epochManager.getCurrentValuePublic(99), 2000);

        assertEq(epochManager.getCurrentValuePublic(100), 2000);
        assertEq(epochManager.getCurrentValuePublic(149), 2000);
        assertEq(epochManager.getCurrentValuePublic(150), 3000);
        assertEq(epochManager.getCurrentValuePublic(9999), 3000);
    }
}
