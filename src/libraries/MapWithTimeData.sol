// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Checkpoints} from "@openzeppelin/contracts/utils/structs/Checkpoints.sol";
import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";
import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

library MapWithTimeData {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    error AlreadyAdded();
    error NotEnabled();
    error AlreadyEnabled();

    uint256 private constant ENABLED_TIME_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 private constant DISABLED_TIME_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFF << 48;

    function add(EnumerableMap.AddressToUintMap storage self, address addr) internal {
        if (!self.set(addr, uint256(0))) {
            revert AlreadyAdded();
        }
    }

    function disable(EnumerableMap.AddressToUintMap storage self, address addr) internal {
        uint256 value = self.get(addr);

        if (uint48(value) == 0 || uint48(value >> 48) != 0) {
            revert NotEnabled();
        }

        value |= uint256(Time.timestamp()) << 48;
        self.set(addr, value);
    }

    function enable(EnumerableMap.AddressToUintMap storage self, address addr) internal {
        uint256 value = self.get(addr);

        if (uint48(value) != 0 && uint48(value >> 48) == 0) {
            revert AlreadyEnabled();
        }

        value = uint256(Time.timestamp());
        self.set(addr, value);
    }

    function atWithStatus(EnumerableMap.AddressToUintMap storage self, uint256 idx, uint48 timestamp)
        internal
        view
        returns (address key, bool wasActiveAt)
    {
        uint256 value;
        (key, value) = self.at(idx);
        uint48 enabledTime = uint48(value);
        uint48 disabledTime = uint48(value >> 48);
        wasActiveAt = _wasActiveAt(enabledTime, disabledTime, timestamp);
    }

    function getTimes(EnumerableMap.AddressToUintMap storage self, address addr)
        internal
        view
        returns (uint48 enabledTime, uint48 disabledTime)
    {
        uint256 value = self.get(addr);
        enabledTime = uint48(value);
        disabledTime = uint48(value >> 48);
    }

    function _wasActiveAt(uint48 enabledTime, uint48 disabledTime, uint48 timestamp) private pure returns (bool) {
        return enabledTime != 0 && enabledTime <= timestamp && (disabledTime == 0 || disabledTime >= timestamp);
    }
}