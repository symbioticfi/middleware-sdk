// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {KeyEcdsaSecp256k1} from "../../src/libraries/keys/KeyEcdsaSecp256k1.sol";

contract KeyEcdsaSecp256k1Mock {
    function wrap(
        address keyRaw
    ) public view returns (KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory key) {
        return KeyEcdsaSecp256k1.wrap(keyRaw);
    }

    function unwrap(
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory key
    ) public view returns (address keyRaw) {
        return KeyEcdsaSecp256k1.unwrap(key);
    }

    function serialize(
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory key
    ) public view returns (bytes memory keySerialized) {
        return KeyEcdsaSecp256k1.serialize(key);
    }

    function deserialize(
        bytes memory keySerialized
    ) public view returns (KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory key) {
        return KeyEcdsaSecp256k1.deserialize(keySerialized);
    }

    function toBytes(
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory key
    ) public view returns (bytes memory keyBytes) {
        return KeyEcdsaSecp256k1.toBytes(key);
    }

    function fromBytes(
        bytes memory keyBytes
    ) public view returns (KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory key) {
        return KeyEcdsaSecp256k1.fromBytes(keyBytes);
    }

    function zeroKey() public view returns (KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory key) {
        return KeyEcdsaSecp256k1.zeroKey();
    }

    function equal(
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory key1,
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory key2
    ) public view returns (bool) {
        return KeyEcdsaSecp256k1.equal(key1, key2);
    }
}
