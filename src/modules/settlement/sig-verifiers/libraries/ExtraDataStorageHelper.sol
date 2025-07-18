// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

library ExtraDataStorageHelper {
    bytes32 public constant GLOBAL_KEY_PREFIX_HASH = keccak256("symbiotic.Settlement.extraData.");

    bytes32 public constant KEY_TAG_PREFIX_HASH = keccak256("keyTag.");

    function getKey(uint32 verificationType, bytes32 nameHash) internal pure returns (bytes32) {
        return keccak256(abi.encode(GLOBAL_KEY_PREFIX_HASH, verificationType, nameHash));
    }

    function getKey(uint32 verificationType, uint8 keyTag, bytes32 nameHash) internal pure returns (bytes32) {
        return keccak256(abi.encode(GLOBAL_KEY_PREFIX_HASH, verificationType, KEY_TAG_PREFIX_HASH, keyTag, nameHash));
    }

    function getKey(
        uint32 verificationType,
        uint8 keyTag,
        bytes32 nameHash,
        uint256 index
    ) internal pure returns (bytes32) {
        return bytes32(
            uint256(
                keccak256(abi.encode(GLOBAL_KEY_PREFIX_HASH, verificationType, KEY_TAG_PREFIX_HASH, keyTag, nameHash))
            ) + index
        );
    }
}
