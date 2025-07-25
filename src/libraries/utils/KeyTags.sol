// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title KeyTags
 * @notice Library for working with key tags which represent the keys' types and arbitrary purpose identifiers.
 */
library KeyTags {
    using KeyTags for uint128;

    /**
     * @notice Reverts when the key tag is duplicated.
     */
    error DuplicateKeyTag();

    /**
     * @notice Reverts when the key type is invalid.
     */
    error InvalidKeyType();

    /**
     * @notice Reverts when the key tag is invalid.
     */
    error InvalidKeyTag();

    /**
     * @notice The total number of key tags.
     * @dev 3 bits for type, 4 bits for tag
     */
    uint256 internal constant TOTAL_KEY_TAGS = 128;

    /**
     * @notice The maximum key type.
     */
    uint8 internal constant MAX_KEY_TYPE = 7;

    /**
     * @notice The maximum key tag.
     */
    uint8 internal constant MAX_KEY_TAG = 15;

    /**
     * @notice Validates a key tag.
     * @param keyTag The key tag.
     */
    function validateKeyTag(
        uint8 keyTag
    ) internal pure {
        if (keyTag >= TOTAL_KEY_TAGS) {
            revert InvalidKeyTag();
        }
    }

    /**
     * @notice Validates a key type.
     * @param type_ The key type.
     */
    function validateType(
        uint8 type_
    ) internal pure {
        if (type_ > MAX_KEY_TYPE) {
            revert InvalidKeyType();
        }
    }

    /**
     * @notice Validates a key tag identifier.
     * @param tag The key tag identifier.
     */
    function validateTag(
        uint8 tag
    ) internal pure {
        if (tag > MAX_KEY_TAG) {
            revert InvalidKeyTag();
        }
    }

    /**
     * @notice Returns a key tag.
     * @param type_ The key type.
     * @param tag The key tag identifier.
     * @return The key tag.
     */
    function getKeyTag(uint8 type_, uint8 tag) internal pure returns (uint8) {
        validateType(type_);
        validateTag(tag);
        return type_ << 4 | tag;
    }

    /**
     * @notice Returns a key type.
     * @param keyTag The key tag.
     * @return The key type.
     */
    function getType(
        uint8 keyTag
    ) internal pure returns (uint8) {
        validateKeyTag(keyTag);
        return keyTag >> 4;
    }

    /**
     * @notice Returns a key tag identifier.
     * @param keyTag The key tag.
     * @return The key tag identifier.
     */
    function getTag(
        uint8 keyTag
    ) internal pure returns (uint8) {
        validateKeyTag(keyTag);
        return keyTag & 0x0F;
    }

    /**
     * @notice Checks if a key tag is in the serialized key tags.
     * @param keyTagsSerialized The serialized key tags.
     * @param keyTag The key tag.
     * @return If the key tag is in the serialized key tags.
     */
    function contains(uint128 keyTagsSerialized, uint8 keyTag) internal pure returns (bool) {
        validateKeyTag(keyTag);
        return keyTagsSerialized & (1 << keyTag) > 0;
    }

    /**
     * @notice Adds a key tag to the serialized key tags.
     * @param keyTagsSerialized The serialized key tags.
     * @param keyTag The key tag.
     * @return The serialized key tags with the key tag added.
     * @dev Doesn't revert when the key tag is already in the serialized key tags.
     */
    function add(uint128 keyTagsSerialized, uint8 keyTag) internal pure returns (uint128) {
        validateKeyTag(keyTag);
        return keyTagsSerialized | uint128(1 << keyTag);
    }

    /**
     * @notice Removes a key tag from the serialized key tags.
     * @param keyTagsSerialized The serialized key tags.
     * @param keyTag The key tag.
     * @return The serialized key tags with the key tag removed.
     * @dev Doesn't revert when the key tag is not in the serialized key tags.
     */
    function remove(uint128 keyTagsSerialized, uint8 keyTag) internal pure returns (uint128) {
        validateKeyTag(keyTag);
        return keyTagsSerialized & ~uint128(1 << keyTag);
    }

    /**
     * @notice Serializes an array of key tags.
     * @param keyTags The array of key tags.
     * @return keyTagsSerialized The serialized key tags.
     * @dev Reverts when the key tags are duplicated.
     */
    function serialize(
        uint8[] memory keyTags
    ) internal pure returns (uint128 keyTagsSerialized) {
        unchecked {
            for (uint256 i; i < keyTags.length; ++i) {
                uint128 oldKeyTagsSerialized = keyTagsSerialized;
                keyTagsSerialized = keyTagsSerialized.add(keyTags[i]);
                if (oldKeyTagsSerialized == keyTagsSerialized) {
                    revert DuplicateKeyTag();
                }
            }
        }
    }

    /**
     * @notice Deserializes a serialized key tags.
     * @param keyTagsSerialized The serialized key tags.
     * @return keyTags The array of key tags.
     */
    function deserialize(
        uint128 keyTagsSerialized
    ) internal pure returns (uint8[] memory keyTags) {
        unchecked {
            uint256 length;
            keyTags = new uint8[](KeyTags.TOTAL_KEY_TAGS);
            for (uint8 i; i < KeyTags.TOTAL_KEY_TAGS; ++i) {
                if (keyTagsSerialized.contains(i)) {
                    keyTags[length++] = i;
                }
            }
            assembly ("memory-safe") {
                mstore(keyTags, length)
            }
        }
    }
}
