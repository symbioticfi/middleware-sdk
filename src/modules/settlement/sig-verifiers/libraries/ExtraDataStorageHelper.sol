// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title ExtraDataStorageHelper
 * @notice Library for convenient and safe extra data storage slots derivation.
 */
library ExtraDataStorageHelper {
    bytes32 public constant KEY_TAG_PREFIX_HASH = keccak256("keyTag.");

    /**
     * @notice Derives a key from a name hash.
     * @param nameHash The name hash.
     * @return The key.
     * @dev It can be used, e.g., to store some global data like number of validators.
     */
    function getKeyGlobal(
        bytes32 nameHash
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(nameHash));
    }

    /**
     * @notice Derives a key from a key tag and a name hash.
     * @param keyTag The key tag.
     * @param nameHash The name hash.
     * @return The key.
     * @dev It can be used, e.g., to store some data dependent on the key tag like quorum threshold.
     */
    function getKeyGlobal(uint8 keyTag, bytes32 nameHash) internal pure returns (bytes32) {
        return keccak256(abi.encode(KEY_TAG_PREFIX_HASH, keyTag, nameHash));
    }

    /**
     * @notice Derives a key from a key tag, a name hash and an index.
     * @param keyTag The key tag.
     * @param nameHash The name hash.
     * @param index The index.
     * @return The key.
     * @dev It can be used, e.g., to store some data dependent on the key tag, which needs more than 1 storage slot (32 bytes),
     *      like aggregated BLS12-381 public key.
     */
    function getKeyGlobal(uint8 keyTag, bytes32 nameHash, uint256 index) internal pure returns (bytes32) {
        return bytes32(uint256(keccak256(abi.encode(KEY_TAG_PREFIX_HASH, keyTag, nameHash))) + index);
    }

    /**
     * @notice Derives a key from a verification type and a name hash.
     * @param verificationType The verification type.
     * @param nameHash The name hash.
     * @return The key.
     * @dev It can be used, e.g., to store some data dependent on the verification type like number of validators
     *      with a possibility to have multiple verification types simultaneously without collisions.
     */
    function getKey(uint32 verificationType, bytes32 nameHash) internal pure returns (bytes32) {
        return keccak256(abi.encode(verificationType, nameHash));
    }

    /**
     * @notice Derives a key from a verification type, a key tag and a name hash.
     * @param verificationType The verification type.
     * @param keyTag The key tag.
     * @param nameHash The name hash.
     * @return The key.
     * @dev It can be used, e.g., to store some data dependent on the verification type and the key tag like quorum threshold
     *      with a possibility to have multiple verification types simultaneously without collisions.
     */
    function getKey(uint32 verificationType, uint8 keyTag, bytes32 nameHash) internal pure returns (bytes32) {
        return keccak256(abi.encode(verificationType, KEY_TAG_PREFIX_HASH, keyTag, nameHash));
    }

    /**
     * @notice Derives a key from a verification type, a key tag, a name hash and an index.
     * @param verificationType The verification type.
     * @param keyTag The key tag.
     * @param nameHash The name hash.
     * @param index The index.
     * @return The key.
     * @dev It can be used, e.g., to store some data dependent on the verification type and the key tag,
     *      which needs more than 1 storage slot (32 bytes), like aggregated BLS12-381 public key
     *      with a possibility to have multiple verification types simultaneously without collisions.
     */
    function getKey(
        uint32 verificationType,
        uint8 keyTag,
        bytes32 nameHash,
        uint256 index
    ) internal pure returns (bytes32) {
        return bytes32(uint256(keccak256(abi.encode(verificationType, KEY_TAG_PREFIX_HASH, keyTag, nameHash))) + index);
    }
}
