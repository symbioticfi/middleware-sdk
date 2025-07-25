// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title Scaler
 * @notice Library for scaling values between different decimals and inverting them.
 */
library Scaler {
    /**
     * @notice Scales a value given its decimals to the target decimals.
     * @param value The value to scale.
     * @param decimals The base decimals of the value.
     * @param targetDecimals The target decimals.
     * @return The scaled value.
     */
    function scale(uint256 value, uint8 decimals, uint8 targetDecimals) internal pure returns (uint256) {
        if (decimals < targetDecimals) {
            uint256 decimalsDiff;
            unchecked {
                decimalsDiff = targetDecimals - decimals;
            }
            return value * 10 ** decimalsDiff;
        }
        if (decimals > targetDecimals) {
            uint256 decimalsDiff;
            unchecked {
                decimalsDiff = decimals - targetDecimals;
            }
            return value / 10 ** decimalsDiff;
        }
        return value;
    }

    /**
     * @notice Inverts a value given its decimals.
     * @param value The value to invert.
     * @param decimals The base decimals of the value.
     * @return The inverted value.
     */
    function invert(uint256 value, uint8 decimals) internal pure returns (uint256) {
        return 10 ** (uint256(decimals) << 1) / value;
    }
}
