// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BN254} from "../utils/BN254.sol";

/**
 * @title KeyBlsBn254
 * @notice Library for interacting with BLS public keys on the BN254 curve, including validation, serialization, and compression.
 * @dev The keys are represented as G1 points on the BN254 curve.
 */
library KeyBlsBn254 {
    using KeyBlsBn254 for BN254.G1Point;
    using KeyBlsBn254 for KEY_BLS_BN254;

    /**
     * @notice Reverts when the key bytes are invalid.
     */
    error KeyBlsBn254_InvalidBytes();

    /**
     * @notice Reverts when the key is invalid.
     */
    error KeyBlsBn254_InvalidKey();

    /**
     * @notice The key wrapper.
     * @param value The G1 public key.
     */
    struct KEY_BLS_BN254 {
        BN254.G1Point value;
    }

    /**
     * @notice Wraps a G1 public key.
     * @param keyRaw The G1 public key.
     * @return key The wrapped key.
     * @dev Allows to wrap zero G1 point.
     */
    function wrap(
        BN254.G1Point memory keyRaw
    ) internal view returns (KEY_BLS_BN254 memory key) {
        if (keyRaw.X == 0 && keyRaw.Y == 0) {
            return zeroKey();
        }
        if (keyRaw.X >= BN254.FP_MODULUS || keyRaw.Y >= BN254.FP_MODULUS) {
            revert KeyBlsBn254_InvalidKey();
        }
        if (
            mulmod(keyRaw.Y, keyRaw.Y, BN254.FP_MODULUS)
                != addmod(
                    mulmod(keyRaw.X, mulmod(keyRaw.X, keyRaw.X, BN254.FP_MODULUS), BN254.FP_MODULUS), 3, BN254.FP_MODULUS
                )
        ) {
            revert KeyBlsBn254_InvalidKey();
        }
        key = KEY_BLS_BN254(keyRaw);
    }

    /**
     * @notice Unwraps a key.
     * @param key The key.
     * @return keyRaw The G1 public key.
     */
    function unwrap(
        KEY_BLS_BN254 memory key
    ) internal view returns (BN254.G1Point memory keyRaw) {
        keyRaw = key.value;
    }

    /**
     * @notice Serializes a key.
     * @param key The key.
     * @return keySerialized The serialized key.
     * @dev Compresses G1 point to 32 bytes (255 bits).
     */
    function serialize(
        KEY_BLS_BN254 memory key
    ) internal view returns (bytes memory keySerialized) {
        if (key.value.X == 0 && key.value.Y == 0) {
            return abi.encode(bytes32(0));
        }
        (, uint256 derivedY) = BN254.findYFromX(key.value.X);
        keySerialized = abi.encode(bytes32((key.value.X << 1) | (derivedY == key.value.Y ? 0 : 1)));
    }

    /**
     * @notice Deserializes a serialized key.
     * @param keySerialized The serialized key.
     * @return key The key.
     */
    function deserialize(
        bytes memory keySerialized
    ) internal view returns (KEY_BLS_BN254 memory key) {
        bytes32 compressedKey = abi.decode(keySerialized, (bytes32));
        if (compressedKey == bytes32(0)) {
            return KEY_BLS_BN254(BN254.G1Point({X: 0, Y: 0}));
        }
        uint256 X = uint256(compressedKey) >> 1;
        (, uint256 derivedY) = BN254.findYFromX(X);
        key.value = BN254.G1Point({X: X, Y: derivedY});
        if (uint256(compressedKey) & 1 > 0) {
            key.value = BN254.negate(key.value);
        }
    }

    /**
     * @notice Converts a key to bytes.
     * @param key The key.
     * @return keyBytes The bytes representation of the key.
     */
    function toBytes(
        KEY_BLS_BN254 memory key
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
    ) internal view returns (KEY_BLS_BN254 memory key) {
        key = abi.decode(keyBytes, (KEY_BLS_BN254));
        if (keccak256(key.unwrap().wrap().toBytes()) != keccak256(keyBytes)) {
            revert KeyBlsBn254_InvalidBytes();
        }
    }

    /**
     * @notice Returns a zero key.
     * @return key The zero key.
     */
    function zeroKey() internal view returns (KEY_BLS_BN254 memory key) {
        key = KEY_BLS_BN254(BN254.G1Point({X: 0, Y: 0}));
    }

    /**
     * @notice Checks if two keys are equal.
     * @param key1 The first key.
     * @param key2 The second key.
     * @return If the keys are equal.
     */
    function equal(KEY_BLS_BN254 memory key1, KEY_BLS_BN254 memory key2) internal view returns (bool) {
        return key1.value.X == key2.value.X && key1.value.Y == key2.value.Y;
    }
}
