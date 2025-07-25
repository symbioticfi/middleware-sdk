// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title InputNormalizer
 * @notice Library for normalizing input arrays to a given length.
 */
library InputNormalizer {
    /**
     * @notice Reverts when the length of the input is not zero and not equal to the expected length.
     */
    error InvalidLength();

    /**
     * @notice Normalizes an array of bytes to a given length.
     * @param arr The array of bytes.
     * @param length The expected length of the array.
     * @return The normalized array of bytes.
     */
    function normalize(bytes[] memory arr, uint256 length) internal pure returns (bytes[] memory) {
        if (arr.length == 0) {
            return new bytes[](length);
        }
        if (arr.length != length) {
            revert InvalidLength();
        }
        return arr;
    }

    /**
     * @notice Normalizes an array of arrays of bytes to a given length.
     * @param arr The array of arrays of bytes.
     * @param length The expected length of the array.
     * @return The normalized array of arrays of bytes.
     */
    function normalize(bytes[][] memory arr, uint256 length) internal pure returns (bytes[][] memory) {
        if (arr.length == 0) {
            return new bytes[][](length);
        }
        if (arr.length != length) {
            revert InvalidLength();
        }
        return arr;
    }
}
