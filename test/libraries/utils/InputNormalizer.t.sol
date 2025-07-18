// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import {InputNormalizer} from "../../../src/libraries/utils/InputNormalizer.sol";

contract InputNormalizerTest is Test {
    function normalizeSingleDim(bytes[] memory arr, uint256 length) public pure returns (bytes[] memory) {
        return InputNormalizer.normalize(arr, length);
    }

    function normalizeDoubleDim(bytes[][] memory arr, uint256 length) public pure returns (bytes[][] memory) {
        return InputNormalizer.normalize(arr, length);
    }

    function test_normalizeSingleDimEmpty() public {
        uint256 desiredLength = 5;
        bytes[] memory input;

        bytes[] memory output = normalizeSingleDim(input, desiredLength);

        assertEq(output.length, desiredLength, "Output array should have length=5");

        for (uint256 i = 0; i < output.length; ++i) {
            assertEq(output[i].length, 0, "Each item should be an empty bytes");
        }
    }

    function test_normalizeSingleDimExact() public {
        uint256 desiredLength = 3;
        bytes[] memory input = new bytes[](desiredLength);

        input[0] = bytes("Hello");
        input[1] = bytes("World");
        input[2] = bytes("!");

        bytes[] memory output = normalizeSingleDim(input, desiredLength);

        assertEq(output.length, desiredLength, "Output array should have length=3");
        for (uint256 i = 0; i < desiredLength; i++) {
            assertEq(output[i], input[i], "Output contents mismatch");
        }
    }

    function test_normalizeSingleDimMismatchRevert() public {
        uint256 desiredLength = 2;
        bytes[] memory input = new bytes[](desiredLength + 1);

        vm.expectRevert(InputNormalizer.InvalidLength.selector);
        this.normalizeSingleDim(input, desiredLength);
    }

    function test_normalizeDoubleDimEmpty() public {
        uint256 desiredLength = 4;
        bytes[][] memory input;

        bytes[][] memory output = normalizeDoubleDim(input, desiredLength);

        assertEq(output.length, desiredLength, "Output array should have length=4");

        for (uint256 i = 0; i < output.length; ++i) {
            assertEq(output[i].length, 0, "Each sub-array should be empty");
        }
    }

    function test_normalizeDoubleDimExact() public {
        uint256 desiredLength = 2;
        bytes[][] memory input = new bytes[][](desiredLength);

        input[0] = new bytes[](2);
        input[0][0] = bytes("foo");
        input[0][1] = bytes("bar");

        input[1] = new bytes[](1);
        input[1][0] = bytes("baz");

        bytes[][] memory output = normalizeDoubleDim(input, desiredLength);

        assertEq(output.length, desiredLength, "Output array should have length=2");
        assertEq(output[0].length, 2, "First sub-array should have length=2");
        assertEq(output[0][0], bytes("foo"));
        assertEq(output[0][1], bytes("bar"));

        assertEq(output[1].length, 1, "Second sub-array should have length=1");
        assertEq(output[1][0], bytes("baz"));
    }

    function test_normalizeDoubleDimMismatchRevert() public {
        uint256 desiredLength = 3;
        bytes[][] memory input = new bytes[][](desiredLength + 1);

        vm.expectRevert(InputNormalizer.InvalidLength.selector);
        this.normalizeDoubleDim(input, desiredLength);
    }
}
