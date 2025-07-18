// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Checkpoints} from "../structs/Checkpoints.sol";

/**
 * @title PersistentSet
 * @notice This library implements a persistent set using Checkpoints.
 * @dev The first addition of an element to the set is optimized by using 0 as an "included" status and 1 otherwise.
 */
library PersistentSet {
    using Checkpoints for Checkpoints.Trace208;

    error InvalidKey();

    struct Status {
        bool isAdded;
        uint48 addedAt;
        Checkpoints.Trace208 isRemoved;
    }

    struct Set {
        bytes32[] _elements;
        mapping(bytes32 => Status) _statuses;
        uint256 _length;
    }

    function _add(Set storage set, uint48 key, bytes32 value) private returns (bool) {
        unchecked {
            if (set._statuses[value].isAdded) {
                if (set._statuses[value].isRemoved.latest() == 0) {
                    return false;
                }
                set._statuses[value].isRemoved.push(key, 0);
            } else {
                set._elements.push(value);
                set._statuses[value].isAdded = true;
                set._statuses[value].addedAt = key;
            }
            set._length += 1;
            return true;
        }
    }

    function _remove(Set storage set, uint48 key, bytes32 value) private returns (bool) {
        unchecked {
            if (!_contains(set, value)) {
                return false;
            }
            if (key < set._statuses[value].addedAt) {
                revert InvalidKey();
            }
            set._statuses[value].isRemoved.push(key, 1);
            set._length -= 1;
            return true;
        }
    }

    function _containsAt(Set storage set, uint48 key, bytes32 value, bytes memory hint) private view returns (bool) {
        return set._statuses[value].isAdded && key >= set._statuses[value].addedAt
            && set._statuses[value].isRemoved.upperLookupRecent(key, hint) == 0;
    }

    function _containsAt(Set storage set, uint48 key, bytes32 value) private view returns (bool) {
        return _containsAt(set, key, value, new bytes(0));
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._statuses[value].isAdded && set._statuses[value].isRemoved.latest() == 0;
    }

    function _length(
        Set storage set
    ) private view returns (uint256) {
        return set._length;
    }

    function _valuesAt(Set storage set, uint48 key) private view returns (bytes32[] memory values_) {
        unchecked {
            uint256 totalLength = set._elements.length;
            values_ = new bytes32[](totalLength);
            uint256 actualLength;
            for (uint256 i; i < totalLength; ++i) {
                if (_containsAt(set, key, set._elements[i])) {
                    values_[actualLength++] = set._elements[i];
                }
            }
            assembly ("memory-safe") {
                mstore(values_, actualLength)
            }
        }
    }

    function _values(
        Set storage set
    ) private view returns (bytes32[] memory values_) {
        unchecked {
            uint256 totalLength = set._elements.length;
            values_ = new bytes32[](totalLength);
            uint256 actualLength;
            for (uint256 i; i < totalLength; ++i) {
                if (_contains(set, set._elements[i])) {
                    values_[actualLength++] = set._elements[i];
                }
            }
            assembly ("memory-safe") {
                mstore(values_, actualLength)
            }
        }
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, uint48 key, bytes32 value) internal returns (bool) {
        return _add(set._inner, key, value);
    }

    function remove(Bytes32Set storage set, uint48 key, bytes32 value) internal returns (bool) {
        return _remove(set._inner, key, value);
    }

    function containsAt(
        Bytes32Set storage set,
        uint48 key,
        bytes32 value,
        bytes memory hint
    ) internal view returns (bool) {
        return _containsAt(set._inner, key, value, hint);
    }

    function containsAt(Bytes32Set storage set, uint48 key, bytes32 value) internal view returns (bool) {
        return _containsAt(set._inner, key, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(
        Bytes32Set storage set
    ) internal view returns (uint256) {
        return _length(set._inner);
    }

    function valuesAt(Bytes32Set storage set, uint48 key) internal view returns (bytes32[] memory result) {
        bytes32[] memory store = _valuesAt(set._inner, key);
        assembly ("memory-safe") {
            result := store
        }
    }

    function values(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory result) {
        bytes32[] memory store = _values(set._inner);
        assembly ("memory-safe") {
            result := store
        }
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, uint48 key, address value) internal returns (bool) {
        return _add(set._inner, key, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, uint48 key, address value) internal returns (bool) {
        return _remove(set._inner, key, bytes32(uint256(uint160(value))));
    }

    function containsAt(
        AddressSet storage set,
        uint48 key,
        address value,
        bytes memory hint
    ) internal view returns (bool) {
        return _containsAt(set._inner, key, bytes32(uint256(uint160(value))), hint);
    }

    function containsAt(AddressSet storage set, uint48 key, address value) internal view returns (bool) {
        return _containsAt(set._inner, key, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(
        AddressSet storage set
    ) internal view returns (uint256) {
        return _length(set._inner);
    }

    function valuesAt(AddressSet storage set, uint48 key) internal view returns (address[] memory result) {
        bytes32[] memory store = _valuesAt(set._inner, key);
        assembly ("memory-safe") {
            result := store
        }
    }

    function values(
        AddressSet storage set
    ) internal view returns (address[] memory result) {
        bytes32[] memory store = _values(set._inner);
        assembly ("memory-safe") {
            result := store
        }
    }
}
