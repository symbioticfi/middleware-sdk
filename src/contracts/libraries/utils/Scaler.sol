// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

library Scaler {
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

    function invert(uint256 value, uint8 decimals) internal pure returns (uint256) {
        return 10 ** (uint256(decimals) << 1) / value;
    }
}
