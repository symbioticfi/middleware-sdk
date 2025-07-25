// SPDX-License-Identifier: MIT
// This file was procedurally generated from scripts/generate/templates/Checkpoints.t.js.

pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Checkpoints} from "../../../src/libraries/structs/Checkpoints.sol";

contract CheckpointsTrace208Test is Test {
    using Checkpoints for Checkpoints.Trace208;

    // Maximum gap between keys used during the fuzzing tests: the `_prepareKeys` function with make sure that
    // key#n+1 is in the [key#n, key#n + _KEY_MAX_GAP] range.
    uint8 internal constant _KEY_MAX_GAP = 64;

    Checkpoints.Trace208 internal _ckpts;

    // helpers
    function _boundUint48(uint48 x, uint48 min, uint48 max) internal pure returns (uint48) {
        return SafeCast.toUint48(bound(uint256(x), uint256(min), uint256(max)));
    }

    function _prepareKeys(uint48[] memory keys, uint48 maxSpread) internal pure {
        uint48 lastKey = 0;
        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 key = _boundUint48(keys[i], lastKey, lastKey + maxSpread);
            keys[i] = key;
            lastKey = key;
        }
    }

    function _prepareKeysUnrepeated(uint48[] memory keys, uint48 maxSpread) internal pure {
        uint48 lastKey = 0;
        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 key = _boundUint48(keys[i], lastKey + 1, lastKey + maxSpread);
            keys[i] = key;
            lastKey = key;
        }
    }

    function _assertLatestCheckpoint(bool exist, uint48 key, uint208 value) internal {
        (bool _exist, uint48 _key, uint208 _value) = _ckpts.latestCheckpoint();
        assertEq(_exist, exist);
        assertEq(_key, key);
        assertEq(_value, value);
    }

    // tests
    function testPush(uint48[] memory keys, uint208[] memory values, uint48 pastKey) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        // initial state
        assertEq(_ckpts.length(), 0);
        assertEq(_ckpts.latest(), 0);
        _assertLatestCheckpoint(false, 0, 0);

        uint256 duplicates = 0;
        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 key = keys[i];
            uint208 value = values[i % values.length];
            if (i > 0 && key == keys[i - 1]) ++duplicates;

            // push
            (uint208 oldValue, uint208 newValue) = _ckpts.push(key, value);

            assertEq(oldValue, i == 0 ? 0 : values[(i - 1) % values.length]);
            assertEq(newValue, value);

            // check length & latest
            assertEq(_ckpts.length(), i + 1 - duplicates);
            assertEq(_ckpts.latest(), value);
            _assertLatestCheckpoint(true, key, value);
        }

        if (keys.length > 0) {
            uint48 lastKey = keys[keys.length - 1];
            if (lastKey > 0) {
                pastKey = _boundUint48(pastKey, 0, lastKey - 1);

                vm.expectRevert();
                this.push(pastKey, values[keys.length % values.length]);
            }
        }

        assertEq(_ckpts.pop(), values[(keys.length - 1) % values.length]);

        uint208 oldValue_ = _ckpts.latest();
        (uint208 oldValue, uint208 newValue) =
            _ckpts.push(keys[keys.length - 1], values[(keys.length - 1) % values.length]);

        assertEq(oldValue, oldValue_);
        assertEq(newValue, values[(keys.length - 1) % values.length]);
    }

    // used to test reverts
    function push(uint48 key, uint208 value) external {
        _ckpts.push(key, value);
    }

    function testLookup(uint48[] memory keys, uint208[] memory values, uint48 lookup) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        uint48 lastKey = keys.length == 0 ? 0 : keys[keys.length - 1];
        lookup = _boundUint48(lookup, 0, lastKey + _KEY_MAX_GAP);

        uint208 upper = 0;
        uint208 lower = 0;
        uint48 lowerKey = type(uint48).max;
        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 key = keys[i];
            uint208 value = values[i % values.length];

            // push
            _ckpts.push(key, value);

            // track expected result of lookups
            if (key <= lookup) {
                upper = value;
            }
            // find the first key that is not smaller than the lookup key
            if (key >= lookup && (i == 0 || keys[i - 1] < lookup)) {
                lowerKey = key;
            }
            if (key == lowerKey) {
                lower = value;
            }
        }

        assertEq(_ckpts.upperLookupRecent(lookup), upper);
        assertEq(_ckpts.upperLookupRecent(lookup, new bytes(0)), upper);
    }

    function testUpperLookupRecentWithHint(
        uint48[] memory keys,
        uint208[] memory values,
        uint48 lookup,
        uint32 hintIndex
    ) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        // Build checkpoints
        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], values[i % values.length]);
        }

        uint32 len = uint32(_ckpts.length());
        if (len == 0) return;
        hintIndex = uint32(bound(hintIndex, 0, len - 1));

        bytes memory hint = abi.encode(hintIndex);

        uint208 resultWithHint = _ckpts.upperLookupRecent(lookup, hint);
        uint208 resultWithoutHint = _ckpts.upperLookupRecent(lookup);

        assertEq(resultWithHint, resultWithoutHint);
    }

    // Test upperLookupRecentCheckpoint without hint
    function testUpperLookupRecentCheckpoint(uint48[] memory keys, uint208[] memory values, uint48 lookup) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        // Build checkpoints
        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], values[i % values.length]);
        }

        // Expected values
        (bool expectedExists, uint48 expectedKey, uint208 expectedValue, uint32 expectedIndex) = (false, 0, 0, 0);
        for (uint32 i = 0; i < _ckpts.length(); ++i) {
            uint48 key = _ckpts.at(i)._key;
            uint208 value = _ckpts.at(i)._value;
            if (key <= lookup) {
                expectedExists = true;
                expectedKey = key;
                expectedValue = value;
                expectedIndex = i;
            } else {
                break;
            }
        }

        // Test function
        (bool exists, uint48 key, uint208 value, uint32 index) = _ckpts.upperLookupRecentCheckpoint(lookup);
        assertEq(exists, expectedExists);
        if (exists) {
            assertEq(key, expectedKey);
            assertEq(value, expectedValue);
            assertEq(index, expectedIndex);
        }
    }

    // Test upperLookupRecentCheckpoint with hint
    function testUpperLookupRecentCheckpointWithHint(
        uint48[] memory keys,
        uint208[] memory values,
        uint48 lookup,
        uint32 hintIndex
    ) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        // Build checkpoints
        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], values[i % values.length]);
        }

        uint32 len = uint32(_ckpts.length());
        if (len == 0) return;
        hintIndex = uint32(bound(hintIndex, 0, len - 1));

        bytes memory hint = abi.encode(hintIndex);

        (bool existsWithHint, uint48 keyWithHint, uint208 valueWithHint, uint32 indexWithHint) =
            _ckpts.upperLookupRecentCheckpoint(lookup, hint);
        (bool existsWithoutHint, uint48 keyWithoutHint, uint208 valueWithoutHint, uint32 indexWithoutHint) =
            _ckpts.upperLookupRecentCheckpoint(lookup);

        assertEq(existsWithHint, existsWithoutHint);
        if (existsWithHint) {
            assertEq(keyWithHint, keyWithoutHint);
            assertEq(valueWithHint, valueWithoutHint);
            assertEq(indexWithHint, indexWithoutHint);
        }
    }

    // Test latest
    function testLatest(uint48[] memory keys, uint208[] memory values) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        uint208 expectedLatest = 0;

        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], values[i % values.length]);
            expectedLatest = values[i % values.length];
            assertEq(_ckpts.latest(), expectedLatest);
        }
    }

    // Test latestCheckpoint
    function testLatestCheckpoint(uint48[] memory keys, uint208[] memory values) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 expectedKey = keys[i];
            uint208 expectedValue = values[i % values.length];
            _ckpts.push(expectedKey, expectedValue);

            (bool exists, uint48 key, uint208 value) = _ckpts.latestCheckpoint();
            assertTrue(exists);
            assertEq(key, expectedKey);
            assertEq(value, expectedValue);
        }
    }

    // Test length
    function testLength(uint48[] memory keys, uint208[] memory values) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        uint256 expectedLength = 0;
        for (uint256 i = 0; i < keys.length; ++i) {
            bool isDuplicate = (i > 0 && keys[i] == keys[i - 1]);
            if (!isDuplicate) {
                expectedLength += 1;
            }
            _ckpts.push(keys[i], values[i % values.length]);
            assertEq(_ckpts.length(), expectedLength);
        }
    }

    // Test at
    function testAt(uint48[] memory keys, uint208[] memory values, uint32 index) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeysUnrepeated(keys, _KEY_MAX_GAP);

        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], values[i % values.length]);
        }

        uint256 len = _ckpts.length();
        vm.assume(len > 0);
        index = uint32(bound(index, 0, len - 1));

        Checkpoints.Checkpoint208 memory checkpoint = _ckpts.at(index);
        assertEq(checkpoint._key, keys[index]);
        assertEq(checkpoint._value, values[index % values.length]);
    }

    function pop() external {
        _ckpts.pop();
    }

    // Test pop
    function testPop(uint48[] memory keys, uint208[] memory values) public {
        vm.assume(values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        for (uint256 i = 0; i < values.length; ++i) {
            _ckpts.push(keys[i], values[i % values.length]);
        }

        uint256 initialLength = _ckpts.length();

        if (initialLength == 0) {
            vm.expectRevert();
            this.pop();
            return;
        }

        uint208 lastValue = _ckpts.latest();
        uint208 poppedValue = _ckpts.pop();
        assertEq(poppedValue, lastValue);
        assertEq(_ckpts.length(), initialLength - 1);
    }
}

contract CheckpointsTrace256Test is Test {
    using Checkpoints for Checkpoints.Trace256;

    Checkpoints.Trace256 internal _ckpts;

    // helpers
    function _boundUint48(uint48 x, uint48 min, uint48 max) internal pure returns (uint48) {
        return SafeCast.toUint48(bound(uint256(x), uint256(min), uint256(max)));
    }

    // Maximum gap between keys used during the fuzzing tests: the `_prepareKeys` function with make sure that
    // key#n+1 is in the [key#n, key#n + _KEY_MAX_GAP] range.
    uint8 internal constant _KEY_MAX_GAP = 64;

    function _prepareKeys(uint48[] memory keys, uint48 maxSpread) internal pure {
        uint48 lastKey = 0;
        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 key = _boundUint48(keys[i], lastKey, lastKey + maxSpread);
            keys[i] = key;
            lastKey = key;
        }
    }

    function _prepareKeysUnrepeated(uint48[] memory keys, uint48 maxSpread) internal pure {
        uint48 lastKey = 0;
        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 key = _boundUint48(keys[i], lastKey + 1, lastKey + maxSpread);
            keys[i] = key;
            lastKey = key;
        }
    }

    function _assertLatestCheckpoint(bool exist, uint48 key, uint256 value) internal {
        (bool _exist, uint48 _key, uint256 _value) = _ckpts.latestCheckpoint();
        assertEq(_exist, exist);
        assertEq(_key, key);
        assertEq(_value, value);
    }

    // tests
    function testPush(uint48[] memory keys, uint256[] memory values, uint48 pastKey) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        // initial state
        assertEq(_ckpts.length(), 0);
        assertEq(_ckpts.latest(), 0);
        _assertLatestCheckpoint(false, 0, 0);

        uint256 duplicates = 0;
        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 key = keys[i];
            uint256 value = values[i % values.length];
            if (i > 0 && key == keys[i - 1]) ++duplicates;

            // push
            (uint256 oldValue, uint256 newValue) = _ckpts.push(key, value);

            assertEq(oldValue, i == 0 ? 0 : values[(i - 1) % values.length]);
            assertEq(newValue, value);

            // check length & latest
            assertEq(_ckpts.length(), i + 1 - duplicates);
            assertEq(_ckpts.latest(), value);
            _assertLatestCheckpoint(true, key, value);
        }

        if (keys.length > 0) {
            uint48 lastKey = keys[keys.length - 1];
            if (lastKey > 0) {
                pastKey = _boundUint48(pastKey, 0, lastKey - 1);

                vm.expectRevert();
                this.push(pastKey, values[keys.length % values.length]);
            }
        }

        assertEq(_ckpts.pop(), values[(keys.length - 1) % values.length]);

        uint256 oldValue_ = _ckpts.latest();
        (uint256 oldValue, uint256 newValue) =
            _ckpts.push(keys[keys.length - 1], values[(keys.length - 1) % values.length]);

        assertEq(oldValue, oldValue_);
        assertEq(newValue, values[(keys.length - 1) % values.length]);
    }

    // used to test reverts
    function push(uint48 key, uint256 value) external {
        _ckpts.push(key, value);
    }

    function testLookup(uint48[] memory keys, uint256[] memory values, uint48 lookup) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        uint48 lastKey = keys.length == 0 ? 0 : keys[keys.length - 1];
        lookup = _boundUint48(lookup, 0, lastKey + _KEY_MAX_GAP);

        uint256 upper = 0;
        uint256 lower = 0;
        uint48 lowerKey = type(uint48).max;
        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 key = keys[i];
            uint256 value = values[i % values.length];

            // push
            _ckpts.push(key, value);

            // track expected result of lookups
            if (key <= lookup) {
                upper = value;
            }
            // find the first key that is not smaller than the lookup key
            if (key >= lookup && (i == 0 || keys[i - 1] < lookup)) {
                lowerKey = key;
            }
            if (key == lowerKey) {
                lower = value;
            }
        }

        assertEq(_ckpts.upperLookupRecent(lookup), upper);
        assertEq(_ckpts.upperLookupRecent(lookup, new bytes(0)), upper);
    }

    function testUpperLookupRecentWithHint(
        uint48[] memory keys,
        uint256[] memory values,
        uint48 lookup,
        uint32 hintIndex
    ) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        // Build checkpoints
        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], values[i % values.length]);
        }

        uint32 len = uint32(_ckpts.length());
        if (len == 0) return;
        hintIndex = uint32(bound(hintIndex, 0, len - 1));

        bytes memory hint = abi.encode(hintIndex);

        uint256 resultWithHint = _ckpts.upperLookupRecent(lookup, hint);
        uint256 resultWithoutHint = _ckpts.upperLookupRecent(lookup);

        assertEq(resultWithHint, resultWithoutHint);
    }

    // Test upperLookupRecentCheckpoint without hint
    function testUpperLookupRecentCheckpoint(uint48[] memory keys, uint256[] memory values, uint48 lookup) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        // Build checkpoints
        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], values[i % values.length]);
        }

        // Expected values
        (bool expectedExists, uint48 expectedKey, uint256 expectedValue, uint32 expectedIndex) = (false, 0, 0, 0);
        for (uint32 i = 0; i < _ckpts.length(); ++i) {
            uint48 key = _ckpts.at(i)._key;
            uint256 value = _ckpts.at(i)._value;
            if (key <= lookup) {
                expectedExists = true;
                expectedKey = key;
                expectedValue = value;
                expectedIndex = i;
            } else {
                break;
            }
        }

        // Test function
        (bool exists, uint48 key, uint256 value, uint32 index) = _ckpts.upperLookupRecentCheckpoint(lookup);
        assertEq(exists, expectedExists);
        if (exists) {
            assertEq(key, expectedKey);
            assertEq(value, expectedValue);
            assertEq(index, expectedIndex);
        }
    }

    // Test upperLookupRecentCheckpoint with hint
    function testUpperLookupRecentCheckpointWithHint(
        uint48[] memory keys,
        uint256[] memory values,
        uint48 lookup,
        uint32 hintIndex
    ) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        // Build checkpoints
        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], values[i % values.length]);
        }

        uint32 len = uint32(_ckpts.length());
        if (len == 0) return;
        hintIndex = uint32(bound(hintIndex, 0, len - 1));

        bytes memory hint = abi.encode(hintIndex);

        (bool existsWithHint, uint48 keyWithHint, uint256 valueWithHint, uint32 indexWithHint) =
            _ckpts.upperLookupRecentCheckpoint(lookup, hint);
        (bool existsWithoutHint, uint48 keyWithoutHint, uint256 valueWithoutHint, uint32 indexWithoutHint) =
            _ckpts.upperLookupRecentCheckpoint(lookup);

        assertEq(existsWithHint, existsWithoutHint);
        if (existsWithHint) {
            assertEq(keyWithHint, keyWithoutHint);
            assertEq(valueWithHint, valueWithoutHint);
            assertEq(indexWithHint, indexWithoutHint);
        }
    }

    // Test latest
    function testLatest(uint48[] memory keys, uint256[] memory values) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        uint256 expectedLatest = 0;

        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], values[i % values.length]);
            expectedLatest = values[i % values.length];
            assertEq(_ckpts.latest(), expectedLatest);
        }
    }

    // Test latestCheckpoint
    function testLatestCheckpoint(uint48[] memory keys, uint256[] memory values) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 expectedKey = keys[i];
            uint256 expectedValue = values[i % values.length];
            _ckpts.push(expectedKey, expectedValue);

            (bool exists, uint48 key, uint256 value) = _ckpts.latestCheckpoint();
            assertTrue(exists);
            assertEq(key, expectedKey);
            assertEq(value, expectedValue);
        }
    }

    // Test length
    function testLength(uint48[] memory keys, uint256[] memory values) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        uint256 expectedLength = 0;
        for (uint256 i = 0; i < keys.length; ++i) {
            bool isDuplicate = (i > 0 && keys[i] == keys[i - 1]);
            if (!isDuplicate) {
                expectedLength += 1;
            }
            _ckpts.push(keys[i], values[i % values.length]);
            assertEq(_ckpts.length(), expectedLength);
        }
    }

    // Test at
    function testAt(uint48[] memory keys, uint256[] memory values, uint32 index) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeysUnrepeated(keys, _KEY_MAX_GAP);

        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], values[i % values.length]);
        }

        uint256 len = _ckpts.length();
        vm.assume(len > 0);
        index = uint32(bound(index, 0, len - 1));

        Checkpoints.Checkpoint256 memory checkpoint = _ckpts.at(index);
        assertEq(checkpoint._key, keys[index]);
        assertEq(checkpoint._value, values[index % values.length]);
    }

    function pop() external {
        _ckpts.pop();
    }

    // Test pop
    function testPop(uint48[] memory keys, uint256[] memory values) public {
        vm.assume(values.length <= keys.length);
        _prepareKeys(keys, _KEY_MAX_GAP);

        for (uint256 i = 0; i < values.length; ++i) {
            _ckpts.push(keys[i], values[i % values.length]);
        }

        uint256 initialLength = _ckpts.length();

        if (initialLength == 0) {
            vm.expectRevert();
            this.pop();
            return;
        }

        uint256 lastValue = _ckpts.latest();
        uint256 poppedValue = _ckpts.pop();
        assertEq(poppedValue, lastValue);
        assertEq(_ckpts.length(), initialLength - 1);
    }
}

contract CheckpointsTrace512Test is Test {
    using Checkpoints for Checkpoints.Trace512;

    Checkpoints.Trace512 internal _ckpts;

    function _assertEqPair(uint256[2] memory a, uint256[2] memory b) internal {
        assertEq(a[0], b[0], "First element mismatch");
        assertEq(a[1], b[1], "Second element mismatch");
    }

    function _assertLatestCheckpointPair(bool exist, uint48 key, uint256[2] memory value) internal {
        (bool _exist, uint48 _key, uint256[2] memory _value) = _ckpts.latestCheckpoint();
        assertEq(_exist, exist, "exists mismatch");
        assertEq(_key, key, "key mismatch");
        _assertEqPair(_value, value);
    }

    function testPush(uint48[] memory keys, uint256[] memory values, uint48 pastKey) public {
        vm.assume(values.length > 0 && values.length <= keys.length);

        _prepareKeys(keys, 64);

        assertEq(_ckpts.length(), 0);
        _assertLatestCheckpointPair(false, 0, [uint256(0), uint256(0)]);
        uint256 duplicates = 0;

        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 key = keys[i];
            uint256[2] memory newVal = [values[i % values.length], uint256(i)];

            if (i > 0 && key == keys[i - 1]) {
                duplicates++;
            }

            (uint256[2] memory oldValue, uint256[2] memory updatedValue) = _ckpts.push(key, newVal);

            if (i == 0) {
                _assertEqPair(oldValue, [uint256(0), uint256(0)]);
            } else {
                _assertEqPair(oldValue, [values[(i - 1) % values.length], uint256(i - 1)]);
            }
            _assertEqPair(updatedValue, newVal);

            assertEq(_ckpts.length(), i + 1 - duplicates);
            _assertEqPair(_ckpts.latest(), newVal);

            _assertLatestCheckpointPair(true, key, newVal);
        }

        if (keys.length > 0) {
            uint48 lastKey = keys[keys.length - 1];
            if (lastKey > 0) {
                pastKey = _boundUint48(pastKey, 0, lastKey - 1);

                vm.expectRevert();
                this.push(pastKey, [uint256(999), uint256(999)]);
            }
        }

        uint256[2] memory lastValBeforePop = [values[(keys.length - 1) % values.length], uint256(keys.length - 1)];

        _assertEqPair(_ckpts.pop(), lastValBeforePop);

        uint256[2] memory oldValue3 = _ckpts.latest();
        (uint256[2] memory oldVal2, uint256[2] memory newVal2) = _ckpts.push(keys[keys.length - 1], lastValBeforePop);

        _assertEqPair(oldVal2, oldValue3);
        _assertEqPair(newVal2, lastValBeforePop);
    }

    function push(uint48 key, uint256[2] memory value) external {
        _ckpts.push(key, value);
    }

    function testLookup(uint48[] memory keys, uint256[] memory values, uint48 lookup) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, 64);

        if (keys.length == 0) {
            assertEq(_ckpts.upperLookupRecent(lookup)[0], 0);
            assertEq(_ckpts.upperLookupRecent(lookup)[1], 0);
            assertEq(_ckpts.upperLookupRecent(lookup, new bytes(0))[0], 0);
            assertEq(_ckpts.upperLookupRecent(lookup, new bytes(0))[1], 0);
            return;
        }

        uint48 lastKey = keys[keys.length - 1];
        lookup = _boundUint48(lookup, 0, lastKey + 64);

        uint256[2] memory upperVal;
        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 key = keys[i];
            uint256[2] memory pushVal = [values[i % values.length], uint256(i)];

            _ckpts.push(key, pushVal);

            if (key <= lookup) {
                upperVal = pushVal;
            }
        }

        _assertEqPair(_ckpts.upperLookupRecent(lookup), upperVal);
        _assertEqPair(_ckpts.upperLookupRecent(lookup, new bytes(0)), upperVal);
    }

    function testUpperLookupRecentWithHint(
        uint48[] memory keys,
        uint256[] memory values,
        uint48 lookup,
        uint32 hintIndex
    ) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, 64);

        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], [values[i % values.length], uint256(i)]);
        }

        uint32 len = uint32(_ckpts.length());
        if (len == 0) return;

        hintIndex = uint32(bound(hintIndex, 0, len - 1));
        bytes memory hint = abi.encode(hintIndex);

        uint256[2] memory resultWithHint = _ckpts.upperLookupRecent(lookup, hint);
        uint256[2] memory resultWithoutHint = _ckpts.upperLookupRecent(lookup);

        _assertEqPair(resultWithHint, resultWithoutHint);
    }

    function testUpperLookupRecentCheckpoint(uint48[] memory keys, uint256[] memory values, uint48 lookup) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, 64);

        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], [values[i % values.length], uint256(i)]);
        }

        (bool expectedExists, uint48 expectedKey, uint256[2] memory expectedValue, uint32 expectedIndex) =
            (false, 0, [uint256(0), uint256(0)], 0);

        for (uint32 i = 0; i < _ckpts.length(); i++) {
            (uint48 ckKey, uint256[2] memory ckVal) = _getCheckpointAt(i);
            if (ckKey <= lookup) {
                expectedExists = true;
                expectedKey = ckKey;
                expectedValue = ckVal;
                expectedIndex = i;
            } else {
                break;
            }
        }

        (bool exists, uint48 key, uint256[2] memory val, uint32 index) = _ckpts.upperLookupRecentCheckpoint(lookup);
        assertEq(exists, expectedExists, "exists mismatch");
        if (exists) {
            assertEq(key, expectedKey, "key mismatch");
            _assertEqPair(val, expectedValue);
            assertEq(index, expectedIndex, "index mismatch");
        }
    }

    function testUpperLookupRecentCheckpointWithHint(
        uint48[] memory keys,
        uint256[] memory values,
        uint48 lookup,
        uint32 hintIndex
    ) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, 64);

        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], [values[i % values.length], uint256(i)]);
        }

        uint32 len = uint32(_ckpts.length());
        if (len == 0) return;
        hintIndex = uint32(bound(hintIndex, 0, len - 1));

        bytes memory hint = abi.encode(hintIndex);

        (bool existHint, uint48 keyHint, uint256[2] memory valHint, uint32 indexHint) =
            _ckpts.upperLookupRecentCheckpoint(lookup, hint);
        (bool existBase, uint48 keyBase, uint256[2] memory valBase, uint32 indexBase) =
            _ckpts.upperLookupRecentCheckpoint(lookup);

        assertEq(existHint, existBase);
        if (existHint) {
            assertEq(keyHint, keyBase);
            _assertEqPair(valHint, valBase);
            assertEq(indexHint, indexBase);
        }
    }

    function testLatest(uint48[] memory keys, uint256[] memory values) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, 64);

        uint256[2] memory expectedLatest = [uint256(0), uint256(0)];

        for (uint256 i = 0; i < keys.length; ++i) {
            uint256[2] memory pairVal = [values[i % values.length], i];
            _ckpts.push(keys[i], pairVal);
            expectedLatest = pairVal;
            _assertEqPair(_ckpts.latest(), expectedLatest);
        }
    }

    function testLatestCheckpoint(uint48[] memory keys, uint256[] memory values) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, 64);

        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 expectedKey = keys[i];
            uint256[2] memory expectedVal = [values[i % values.length], i];
            _ckpts.push(expectedKey, expectedVal);

            (bool exists, uint48 key, uint256[2] memory val) = _ckpts.latestCheckpoint();
            assertTrue(exists, "Checkpoint should exist");
            assertEq(key, expectedKey, "Key mismatch");
            _assertEqPair(val, expectedVal);
        }
    }

    function testLength(uint48[] memory keys, uint256[] memory values) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeys(keys, 64);

        uint256 expectedLength = 0;
        for (uint256 i = 0; i < keys.length; ++i) {
            bool isDuplicate = (i > 0 && keys[i] == keys[i - 1]);
            if (!isDuplicate) {
                expectedLength += 1;
            }
            _ckpts.push(keys[i], [values[i % values.length], i]);
            assertEq(_ckpts.length(), expectedLength);
        }
    }

    function testAt(uint48[] memory keys, uint256[] memory values, uint32 index) public {
        vm.assume(values.length > 0 && values.length <= keys.length);
        _prepareKeysUnrepeated(keys, 64);

        for (uint256 i = 0; i < keys.length; ++i) {
            _ckpts.push(keys[i], [values[i % values.length], i]);
        }

        uint256 len = _ckpts.length();
        vm.assume(len > 0);
        index = uint32(bound(index, 0, len - 1));

        Checkpoints.Checkpoint512 memory checkpoint = _ckpts.at(index);
        assertEq(checkpoint._key, keys[index], "Key mismatch");
        _assertEqPair(checkpoint._value, [values[index % values.length], uint256(index)]);
    }

    function pop() external {
        _ckpts.pop();
    }

    function testPop(uint48[] memory keys, uint256[] memory values) public {
        vm.assume(values.length <= keys.length);
        _prepareKeys(keys, 64);

        for (uint256 i = 0; i < values.length; ++i) {
            _ckpts.push(keys[i], [values[i % values.length], i]);
        }

        uint256 initialLength = _ckpts.length();

        if (initialLength == 0) {
            vm.expectRevert();
            this.pop();
            return;
        }

        uint256[2] memory lastVal = [values[(values.length - 1) % values.length], uint256(values.length - 1)];
        uint256[2] memory poppedVal = _ckpts.pop();
        _assertEqPair(poppedVal, lastVal);

        assertEq(_ckpts.length(), initialLength - 1, "Length not decremented");
    }

    uint8 internal constant _KEY_MAX_GAP = 64;

    function _prepareKeys(uint48[] memory keys, uint48 maxSpread) internal pure {
        uint48 lastKey = 0;
        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 bounded = _boundUint48(keys[i], lastKey, lastKey + maxSpread);
            keys[i] = bounded;
            lastKey = bounded;
        }
    }

    function _prepareKeysUnrepeated(uint48[] memory keys, uint48 maxSpread) internal pure {
        uint48 lastKey = 0;
        for (uint256 i = 0; i < keys.length; ++i) {
            uint48 bounded = _boundUint48(keys[i], lastKey + 1, lastKey + maxSpread);
            keys[i] = bounded;
            lastKey = bounded;
        }
    }

    function _boundUint48(uint48 x, uint48 min, uint48 max) internal pure returns (uint48) {
        return _safe48(bound(uint256(x), uint256(min), uint256(max)));
    }

    function _safe48(
        uint256 val
    ) internal pure returns (uint48) {
        require(val <= type(uint48).max, "overflow");
        return uint48(val);
    }

    function _getCheckpointAt(
        uint32 i
    ) internal view returns (uint48, uint256[2] memory) {
        Checkpoints.Checkpoint512 memory ck = _ckpts.at(i);
        return (ck._key, ck._value);
    }
}
