// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Checkpoints} from "../structs/Checkpoints.sol";

/**
 * @title PersistentSet
 * @notice Library implementing a persistent set using Checkpoints.
 * @dev The library is optimized towards "write" operations, so, in general, "read" batch operations
 *      like `values()` and `valuesAt()` should not be used on-chain.
 */
library PersistentSet {
    using Checkpoints for Checkpoints.Trace208;

    /**
     * @notice Reverts when the key is too old.
     */
    error InvalidKey();

    /**
     * @notice The status of an element.
     * @param isAdded If the element was ever added to the set.
     * @param addedAt The key (e.g., block timestamp or block number) at which the element was firstly added to the set.
     * @param isRemoved The trace of keys at which the element was removed from the set.
     */
    struct Status {
        bool isAdded;
        uint48 addedAt;
        Checkpoints.Trace208 isRemoved;
    }

    /**
     * @notice The set.
     * @param _elements The elements of the set which were ever added to the set.
     * @param _statuses The statuses of the elements.
     * @param _length The number of elements which are currently in the set.
     */
    struct Set {
        bytes32[] _elements;
        mapping(bytes32 => Status) _statuses;
        uint256 _length;
    }

    /**
     * @notice Adds an element to the set.
     * @param set The set.
     * @param key The key to add element at.
     * @param value The element.
     * @return If the element was added to the set.
     * @dev It is possible to add an element only at the same or greater key than the previous one for this value.
     */
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

    /**
     * @notice Removes an element from the set.
     * @param set The set.
     * @param key The key to remove element at.
     * @param value The element.
     * @return If the element was removed from the set.
     * @dev It is possible to remove an element only at the same or greater key than the previous one for this value.
     */
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

    /**
     * @notice Checks if an element is in the set at a given key.
     * @param set The set.
     * @param key The key to check element at.
     * @param value The element.
     * @param hint The hint to use for the lookup.
     * @return If the element is in the set at the given key.
     */
    function _containsAt(Set storage set, uint48 key, bytes32 value, bytes memory hint) private view returns (bool) {
        return set._statuses[value].isAdded && key >= set._statuses[value].addedAt
            && set._statuses[value].isRemoved.upperLookupRecent(key, hint) == 0;
    }

    /**
     * @notice Checks if an element is in the set at a given key.
     * @param set The set.
     * @param key The key to check element at.
     * @param value The element.
     * @return If the element is in the set at the given key.
     */
    function _containsAt(Set storage set, uint48 key, bytes32 value) private view returns (bool) {
        return _containsAt(set, key, value, new bytes(0));
    }

    /**
     * @notice Checks if an element is in the set.
     * @param set The set.
     * @param value The element.
     * @return If the element is in the set.
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._statuses[value].isAdded && set._statuses[value].isRemoved.latest() == 0;
    }

    /**
     * @notice Returns the number of elements in the set.
     * @param set The set.
     * @return The number of elements in the set.
     */
    function _length(
        Set storage set
    ) private view returns (uint256) {
        return set._length;
    }

    /**
     * @notice Returns the elements in the set at a given key.
     * @param set The set.
     * @param key The key to get elements at.
     * @return values_ The elements in the set at the given key.
     */
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

    /**
     * @notice Returns the elements in the set.
     * @param set The set.
     * @return values_ The elements in the set.
     */
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

    /**
     * @notice The set of bytes32 values.
     * @param _inner The set.
     */
    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @notice Adds an element to the set.
     * @param set The set.
     * @param key The key to add element at.
     * @param value The element.
     * @return If the element was added to the set.
     */
    function add(Bytes32Set storage set, uint48 key, bytes32 value) internal returns (bool) {
        return _add(set._inner, key, value);
    }

    /**
     * @notice Removes an element from the set.
     * @param set The set.
     * @param key The key to remove element at.
     * @param value The element.
     * @return If the element was removed from the set.
     */
    function remove(Bytes32Set storage set, uint48 key, bytes32 value) internal returns (bool) {
        return _remove(set._inner, key, value);
    }

    /**
     * @notice Checks if an element is in the set at a given key.
     * @param set The set.
     * @param key The key to check element at.
     * @param value The element.
     * @param hint The hint to use for the lookup.
     * @return If the element is in the set at the given key.
     */
    function containsAt(
        Bytes32Set storage set,
        uint48 key,
        bytes32 value,
        bytes memory hint
    ) internal view returns (bool) {
        return _containsAt(set._inner, key, value, hint);
    }

    /**
     * @notice Checks if an element is in the set at a given key.
     * @param set The set.
     * @param key The key to check element at.
     * @param value The element.
     * @return If the element is in the set at the given key.
     */
    function containsAt(Bytes32Set storage set, uint48 key, bytes32 value) internal view returns (bool) {
        return _containsAt(set._inner, key, value);
    }

    /**
     * @notice Checks if an element is in the set.
     * @param set The set.
     * @param value The element.
     * @return If the element is in the set.
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @notice Returns the number of elements in the set.
     * @param set The set.
     * @return The number of elements in the set.
     */
    function length(
        Bytes32Set storage set
    ) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @notice Returns the elements in the set at a given key.
     * @param set The set.
     * @param key The key to get elements at.
     * @return result The elements in the set at the given key.
     */
    function valuesAt(Bytes32Set storage set, uint48 key) internal view returns (bytes32[] memory result) {
        bytes32[] memory store = _valuesAt(set._inner, key);
        assembly ("memory-safe") {
            result := store
        }
    }

    /**
     * @notice Returns the elements in the set.
     * @param set The set.
     * @return result The elements in the set.
     */
    function values(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory result) {
        bytes32[] memory store = _values(set._inner);
        assembly ("memory-safe") {
            result := store
        }
    }

    // AddressSet

    /**
     * @notice The set of address values.
     * @param _inner The set.
     */
    struct AddressSet {
        Set _inner;
    }

    /**
     * @notice Adds an element to the set.
     * @param set The set.
     * @param key The key to add element at.
     * @param value The element.
     * @return If the element was added to the set.
     */
    function add(AddressSet storage set, uint48 key, address value) internal returns (bool) {
        return _add(set._inner, key, bytes32(uint256(uint160(value))));
    }

    /**
     * @notice Removes an element from the set.
     * @param set The set.
     * @param key The key to remove element at.
     * @param value The element.
     * @return If the element was removed from the set.
     */
    function remove(AddressSet storage set, uint48 key, address value) internal returns (bool) {
        return _remove(set._inner, key, bytes32(uint256(uint160(value))));
    }

    /**
     * @notice Checks if an element is in the set at a given key.
     * @param set The set.
     * @param key The key to check element at.
     * @param value The element.
     * @param hint The hint to use for the lookup.
     * @return If the element is in the set at the given key.
     */
    function containsAt(
        AddressSet storage set,
        uint48 key,
        address value,
        bytes memory hint
    ) internal view returns (bool) {
        return _containsAt(set._inner, key, bytes32(uint256(uint160(value))), hint);
    }

    /**
     * @notice Checks if an element is in the set at a given key.
     * @param set The set.
     * @param key The key to check element at.
     * @param value The element.
     * @return If the element is in the set at the given key.
     */
    function containsAt(AddressSet storage set, uint48 key, address value) internal view returns (bool) {
        return _containsAt(set._inner, key, bytes32(uint256(uint160(value))));
    }

    /**
     * @notice Checks if an element is in the set.
     * @param set The set.
     * @param value The element.
     * @return If the element is in the set.
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @notice Returns the number of elements in the set.
     * @param set The set.
     * @return The number of elements in the set.
     */
    function length(
        AddressSet storage set
    ) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @notice Returns the elements in the set at a given key.
     * @param set The set.
     * @param key The key to get elements at.
     * @return result The elements in the set at the given key.
     */
    function valuesAt(AddressSet storage set, uint48 key) internal view returns (address[] memory result) {
        bytes32[] memory store = _valuesAt(set._inner, key);
        assembly ("memory-safe") {
            result := store
        }
    }

    /**
     * @notice Returns the elements in the set.
     * @param set The set.
     * @return result The elements in the set.
     */
    function values(
        AddressSet storage set
    ) internal view returns (address[] memory result) {
        bytes32[] memory store = _values(set._inner);
        assembly ("memory-safe") {
            result := store
        }
    }
}
