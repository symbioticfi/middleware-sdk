// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {KeyEcdsaSecp256k1} from "../../../src/libraries/keys/KeyEcdsaSecp256k1.sol";

import {KeyEcdsaSecp256k1Mock} from "../../mocks/KeyEcdsaSecp256k1Mock.sol";

contract KeyEcdsaSecp256k1Test is Test {
    using KeyEcdsaSecp256k1 for address;
    using KeyEcdsaSecp256k1 for KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1;

    KeyEcdsaSecp256k1Mock mock;

    function setUp() public {
        mock = new KeyEcdsaSecp256k1Mock();
    }

    function test_WrapUnwrap() public {
        address rawKey = makeAddr("testKey");
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory wrapped = KeyEcdsaSecp256k1.wrap(rawKey);
        address unwrapped = KeyEcdsaSecp256k1.unwrap(wrapped);
        assertEq(rawKey, unwrapped);
    }

    function test_SerializeDeserialize() public {
        address rawKey = makeAddr("testKey");
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory wrapped = KeyEcdsaSecp256k1.wrap(rawKey);
        bytes memory serialized = KeyEcdsaSecp256k1.serialize(wrapped);
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory deserialized = KeyEcdsaSecp256k1.deserialize(serialized);
        assertEq(rawKey, deserialized.value);
    }

    function test_ToBytesFromBytes() public {
        address rawKey = makeAddr("anotherKey");
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory wrapped = KeyEcdsaSecp256k1.wrap(rawKey);
        bytes memory keyBytes = KeyEcdsaSecp256k1.toBytes(wrapped);
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory unwrapped = KeyEcdsaSecp256k1.fromBytes(keyBytes);
        assertEq(rawKey, unwrapped.value);
    }

    function test_FuzzWrapUnwrap(
        address rawKey
    ) public {
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory wrapped = KeyEcdsaSecp256k1.wrap(rawKey);
        address unwrapped = KeyEcdsaSecp256k1.unwrap(wrapped);
        assertEq(rawKey, unwrapped);
    }

    function test_FuzzSerializeDeserialize(
        address rawKey
    ) public {
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory wrapped = KeyEcdsaSecp256k1.wrap(rawKey);
        bytes memory serialized = KeyEcdsaSecp256k1.serialize(wrapped);
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory deserialized = KeyEcdsaSecp256k1.deserialize(serialized);
        assertEq(rawKey, deserialized.value);
    }

    function test_FuzzToBytesFromBytes(
        address rawKey
    ) public {
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory wrapped = KeyEcdsaSecp256k1.wrap(rawKey);
        bytes memory keyBytes = KeyEcdsaSecp256k1.toBytes(wrapped);
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory unwrapped = KeyEcdsaSecp256k1.fromBytes(keyBytes);
        assertEq(rawKey, unwrapped.value);
    }

    function test_FromBytesRevertsIfNot20Bytes() public {
        bytes memory badLength = new bytes(10);
        vm.expectRevert();
        mock.fromBytes(badLength);
    }

    function test_DeserializeRevertsIfNot20Bytes() public {
        bytes memory badLength = new bytes(10);
        vm.expectRevert();
        mock.deserialize(badLength);
    }

    function test_FromBytesRevertsInvalidBytes() public {
        address rawKey = makeAddr("testKey");
        KeyEcdsaSecp256k1.fromBytes(abi.encode(rawKey));
        vm.expectRevert(KeyEcdsaSecp256k1.KeyEcdsaSecp256k1_InvalidBytes.selector);
        mock.fromBytes(abi.encode(rawKey, 1));
    }

    function test_ZeroKey() public {
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory zero = mock.zeroKey();
        assertEq(zero.value, address(0));
    }

    function test_Equal() public {
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory key1 = mock.wrap(makeAddr("testKey"));
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory key2 = mock.wrap(makeAddr("testKey"));
        assertEq(mock.equal(key1, key2), true);
    }

    function test_EqualFalse() public {
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory key1 = mock.wrap(makeAddr("testKey"));
        KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1 memory key2 = mock.wrap(makeAddr("anotherKey"));
        assertEq(mock.equal(key1, key2), false);
    }
}
