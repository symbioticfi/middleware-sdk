// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

library KeyEcdsaSecp256k1 {
    using KeyEcdsaSecp256k1 for KEY_ECDSA_SECP256K1;
    using KeyEcdsaSecp256k1 for address;

    error KeyEcdsaSecp256k1_InvalidBytes();

    struct KEY_ECDSA_SECP256K1 {
        address value;
    }

    function wrap(
        address keyRaw
    ) internal view returns (KEY_ECDSA_SECP256K1 memory key) {
        if (keyRaw == address(0)) {
            return zeroKey();
        }
        key = KEY_ECDSA_SECP256K1(keyRaw);
    }

    function unwrap(
        KEY_ECDSA_SECP256K1 memory key
    ) internal view returns (address keyRaw) {
        keyRaw = key.value;
    }

    function serialize(
        KEY_ECDSA_SECP256K1 memory key
    ) internal view returns (bytes memory keySerialized) {
        keySerialized = abi.encode(key.value);
    }

    function deserialize(
        bytes memory keySerialized
    ) internal view returns (KEY_ECDSA_SECP256K1 memory key) {
        key = KEY_ECDSA_SECP256K1(abi.decode(keySerialized, (address)));
    }

    function toBytes(
        KEY_ECDSA_SECP256K1 memory key
    ) internal view returns (bytes memory keyBytes) {
        keyBytes = abi.encode(key.value);
    }

    function fromBytes(
        bytes memory keyBytes
    ) internal view returns (KEY_ECDSA_SECP256K1 memory key) {
        key = abi.decode(keyBytes, (KEY_ECDSA_SECP256K1));
        if (keccak256(key.unwrap().wrap().toBytes()) != keccak256(keyBytes)) {
            revert KeyEcdsaSecp256k1_InvalidBytes();
        }
    }

    function zeroKey() internal view returns (KEY_ECDSA_SECP256K1 memory key) {
        key = KEY_ECDSA_SECP256K1(address(0));
    }

    function equal(KEY_ECDSA_SECP256K1 memory key1, KEY_ECDSA_SECP256K1 memory key2) internal view returns (bool) {
        return key1.value == key2.value;
    }
}
