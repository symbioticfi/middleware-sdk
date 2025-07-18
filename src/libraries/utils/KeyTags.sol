// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

library KeyTags {
    using KeyTags for uint128;

    error InvalidKeyType();
    error InvalidKeyTag();
    error Duplicate();

    // 3 bits for type, 4 bits for tag
    uint256 internal constant TOTAL_KEY_TAGS = 128;

    uint8 internal constant MAX_KEY_TYPE = 7;

    uint8 internal constant MAX_KEY_TAG = 15;

    function validateKeyTag(
        uint8 keyTag
    ) internal pure {
        if (keyTag >= TOTAL_KEY_TAGS) {
            revert InvalidKeyTag();
        }
    }

    function validateType(
        uint8 type_
    ) internal pure {
        if (type_ > MAX_KEY_TYPE) {
            revert InvalidKeyType();
        }
    }

    function validateTag(
        uint8 tag
    ) internal pure {
        if (tag > MAX_KEY_TAG) {
            revert InvalidKeyTag();
        }
    }

    function getKeyTag(uint8 type_, uint8 tag) internal pure returns (uint8) {
        validateType(type_);
        validateTag(tag);
        return type_ << 4 | tag;
    }

    function getType(
        uint8 keyTag
    ) internal pure returns (uint8) {
        validateKeyTag(keyTag);
        return keyTag >> 4;
    }

    function getTag(
        uint8 keyTag
    ) internal pure returns (uint8) {
        validateKeyTag(keyTag);
        return keyTag & 0x0F;
    }

    function contains(uint128 keyTagsSerialized, uint8 keyTag) internal pure returns (bool) {
        validateKeyTag(keyTag);
        return keyTagsSerialized & (1 << keyTag) > 0;
    }

    function add(uint128 keyTagsSerialized, uint8 keyTag) internal pure returns (uint128) {
        validateKeyTag(keyTag);
        return keyTagsSerialized | uint128(1 << keyTag);
    }

    function remove(uint128 keyTagsSerialized, uint8 keyTag) internal pure returns (uint128) {
        validateKeyTag(keyTag);
        return keyTagsSerialized & ~uint128(1 << keyTag);
    }

    function serialize(
        uint8[] memory keyTags
    ) internal pure returns (uint128 keyTagsSerialized) {
        unchecked {
            for (uint256 i; i < keyTags.length; ++i) {
                uint128 oldKeyTagsSerialized = keyTagsSerialized;
                keyTagsSerialized = keyTagsSerialized.add(keyTags[i]);
                if (oldKeyTagsSerialized == keyTagsSerialized) {
                    revert Duplicate();
                }
            }
        }
    }

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
