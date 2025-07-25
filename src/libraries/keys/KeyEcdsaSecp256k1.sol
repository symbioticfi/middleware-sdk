// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title KeyEcdsaSecp256k1
 * @notice Library for interacting with ECDSA public keys on the secp256k1 curve, including validation and serialization.
 * @dev The keys are represented as addresses.
 */
library KeyEcdsaSecp256k1 {
    using KeyEcdsaSecp256k1 for address;
    using KeyEcdsaSecp256k1 for KEY_ECDSA_SECP256K1;

    /**
     * @notice Reverts when the key bytes are invalid.
     */
    error KeyEcdsaSecp256k1_InvalidBytes();

    /**
     * @notice The key wrapper.
     * @param value The address.
     */
    struct KEY_ECDSA_SECP256K1 {
        address value;
    }

    /**
     * @notice Wraps an address.
     * @param keyRaw The address.
     * @return key The wrapped key.
     * @dev Allows to wrap zero address.
     */
    function wrap(
        address keyRaw
    ) internal view returns (KEY_ECDSA_SECP256K1 memory key) {
        if (keyRaw == address(0)) {
            return zeroKey();
        }
        key = KEY_ECDSA_SECP256K1(keyRaw);
    }

    /**
     * @notice Unwraps a key.
     * @param key The key.
     * @return keyRaw The address.
     */
    function unwrap(
        KEY_ECDSA_SECP256K1 memory key
    ) internal view returns (address keyRaw) {
        keyRaw = key.value;
    }

    /**
     * @notice Serializes a key.
     * @param key The key.
     * @return keySerialized The serialized key.
     * @dev Serializes address to 32 bytes.
     */
    function serialize(
        KEY_ECDSA_SECP256K1 memory key
    ) internal view returns (bytes memory keySerialized) {
        keySerialized = abi.encode(key.value);
    }

    /**
     * @notice Deserializes a serialized key.
     * @param keySerialized The serialized key.
     * @return key The key.
     */
    function deserialize(
        bytes memory keySerialized
    ) internal view returns (KEY_ECDSA_SECP256K1 memory key) {
        key = KEY_ECDSA_SECP256K1(abi.decode(keySerialized, (address)));
    }

    /**
     * @notice Converts a key to bytes.
     * @param key The key.
     * @return keyBytes The bytes representation of the key.
     */
    function toBytes(
        KEY_ECDSA_SECP256K1 memory key
    ) internal view returns (bytes memory keyBytes) {
        keyBytes = abi.encode(key.value);
    }

    /**
     * @notice Converts bytes to a key.
     * @param keyBytes The bytes representation of the key.
     * @return key The key.
     */
    function fromBytes(
        bytes memory keyBytes
    ) internal view returns (KEY_ECDSA_SECP256K1 memory key) {
        key = abi.decode(keyBytes, (KEY_ECDSA_SECP256K1));
        if (keccak256(key.unwrap().wrap().toBytes()) != keccak256(keyBytes)) {
            revert KeyEcdsaSecp256k1_InvalidBytes();
        }
    }

    /**
     * @notice Returns a zero key.
     * @return key The zero key.
     */
    function zeroKey() internal view returns (KEY_ECDSA_SECP256K1 memory key) {
        key = KEY_ECDSA_SECP256K1(address(0));
    }

    /**
     * @notice Checks if two keys are equal.
     * @param key1 The first key.
     * @param key2 The second key.
     * @return If the keys are equal.
     */
    function equal(KEY_ECDSA_SECP256K1 memory key1, KEY_ECDSA_SECP256K1 memory key2) internal view returns (bool) {
        return key1.value == key2.value;
    }
}
