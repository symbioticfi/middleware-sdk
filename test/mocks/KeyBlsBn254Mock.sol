// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BN254} from "../../src/libraries/utils/BN254.sol";
import {KeyBlsBn254} from "../../src/libraries/keys/KeyBlsBn254.sol";

contract KeyBlsBn254Mock {
    function wrap(
        BN254.G1Point memory keyRaw
    ) public view returns (KeyBlsBn254.KEY_BLS_BN254 memory key) {
        return KeyBlsBn254.wrap(keyRaw);
    }

    function unwrap(
        KeyBlsBn254.KEY_BLS_BN254 memory key
    ) public view returns (BN254.G1Point memory keyRaw) {
        return KeyBlsBn254.unwrap(key);
    }

    function serialize(
        KeyBlsBn254.KEY_BLS_BN254 memory key
    ) public view returns (bytes memory keySerialized) {
        return KeyBlsBn254.serialize(key);
    }

    function deserialize(
        bytes memory keySerialized
    ) public view returns (KeyBlsBn254.KEY_BLS_BN254 memory key) {
        return KeyBlsBn254.deserialize(keySerialized);
    }

    function toBytes(
        KeyBlsBn254.KEY_BLS_BN254 memory key
    ) public view returns (bytes memory keyBytes) {
        return KeyBlsBn254.toBytes(key);
    }

    function fromBytes(
        bytes memory keyBytes
    ) public view returns (KeyBlsBn254.KEY_BLS_BN254 memory key) {
        return KeyBlsBn254.fromBytes(keyBytes);
    }

    function zeroKey() public view returns (KeyBlsBn254.KEY_BLS_BN254 memory key) {
        return KeyBlsBn254.zeroKey();
    }

    function equal(
        KeyBlsBn254.KEY_BLS_BN254 memory key1,
        KeyBlsBn254.KEY_BLS_BN254 memory key2
    ) public view returns (bool) {
        return KeyBlsBn254.equal(key1, key2);
    }
}
