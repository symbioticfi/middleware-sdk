// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {KeyBlsBn254} from "../../../src/libraries/keys/KeyBlsBn254.sol";
import {BN254} from "../../../src/libraries/utils/BN254.sol";

import {KeyBlsBn254Mock} from "../../mocks/KeyBlsBn254Mock.sol";

contract KeyBlsBn254Test is Test {
    using KeyBlsBn254 for BN254.G1Point;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;

    KeyBlsBn254Mock mock;

    function setUp() public {
        mock = new KeyBlsBn254Mock();
    }

    function test_WrapUnwrapIdentity() public {
        BN254.G1Point memory identity = BN254.G1Point(0, 0);
        KeyBlsBn254.KEY_BLS_BN254 memory wrapped = KeyBlsBn254.wrap(identity);
        BN254.G1Point memory unwrapped = wrapped.unwrap();
        assertEq(unwrapped.X, 0);
        assertEq(unwrapped.Y, 0);
    }

    function test_WrapUnwrapNonZero() public {
        uint256 testX = 1;
        (uint256 beta, uint256 y) = BN254.findYFromX(testX);
        if (mulmod(y, y, BN254.FP_MODULUS) != beta) {
            revert();
        }
        BN254.G1Point memory pt = BN254.G1Point({X: testX, Y: y});
        KeyBlsBn254.KEY_BLS_BN254 memory wrapped = KeyBlsBn254.wrap(pt);
        BN254.G1Point memory unwrapped = wrapped.unwrap();
        assertEq(unwrapped.X, testX);
        assertEq(unwrapped.Y, y);
    }

    function test_SerializeDeserializeIdentity() public {
        BN254.G1Point memory identity = BN254.G1Point(0, 0);
        KeyBlsBn254.KEY_BLS_BN254 memory wrapped = KeyBlsBn254.wrap(identity);
        bytes memory serialized = KeyBlsBn254.serialize(wrapped);
        KeyBlsBn254.KEY_BLS_BN254 memory deserialized = KeyBlsBn254.deserialize(serialized);
        BN254.G1Point memory unwrapped = deserialized.unwrap();
        assertEq(unwrapped.X, 0);
        assertEq(unwrapped.Y, 0);
    }

    function test_SerializeDeserializeNonZero() public {
        uint256 testX = 5;
        (uint256 beta, uint256 y) = BN254.findYFromX(testX);
        if (mulmod(y, y, BN254.FP_MODULUS) != beta) {
            revert();
        }
        BN254.G1Point memory pt = BN254.G1Point({X: testX, Y: y});
        KeyBlsBn254.KEY_BLS_BN254 memory wrapped = KeyBlsBn254.wrap(pt);
        bytes memory serialized = KeyBlsBn254.serialize(wrapped);
        KeyBlsBn254.KEY_BLS_BN254 memory deserialized = KeyBlsBn254.deserialize(serialized);
        BN254.G1Point memory finalPt = deserialized.unwrap();
        assertEq(finalPt.X, testX);
        assertEq(finalPt.Y, y);
    }

    function test_SerializeDeserializeNonZeroNegate() public {
        uint256 testX = 5;
        (uint256 beta, uint256 y) = BN254.findYFromX(testX);
        if (mulmod(y, y, BN254.FP_MODULUS) != beta) {
            revert();
        }
        BN254.G1Point memory pt = BN254.negate(BN254.G1Point({X: testX, Y: y}));
        KeyBlsBn254.KEY_BLS_BN254 memory wrapped = KeyBlsBn254.wrap(pt);
        bytes memory serialized = KeyBlsBn254.serialize(wrapped);
        KeyBlsBn254.KEY_BLS_BN254 memory deserialized = KeyBlsBn254.deserialize(serialized);
        BN254.G1Point memory finalPt = deserialized.unwrap();
        assertEq(finalPt.X, testX);
        assertEq(finalPt.Y, pt.Y);
    }

    function test_ToBytesFromBytesIdentity() public {
        BN254.G1Point memory identity = BN254.G1Point(0, 0);
        KeyBlsBn254.KEY_BLS_BN254 memory wrapped = KeyBlsBn254.wrap(identity);
        bytes memory encoded = KeyBlsBn254.toBytes(wrapped);
        KeyBlsBn254.KEY_BLS_BN254 memory decoded = KeyBlsBn254.fromBytes(encoded);
        BN254.G1Point memory unwrapped = decoded.unwrap();
        assertEq(unwrapped.X, 0);
        assertEq(unwrapped.Y, 0);
    }

    function test_ToBytesFromBytesNonZero() public {
        uint256 testX = 5;
        (uint256 beta, uint256 y) = BN254.findYFromX(testX);
        if (mulmod(y, y, BN254.FP_MODULUS) != beta) {
            revert();
        }
        BN254.G1Point memory pt = BN254.G1Point({X: testX, Y: y});
        KeyBlsBn254.KEY_BLS_BN254 memory wrapped = KeyBlsBn254.wrap(pt);
        bytes memory encoded = KeyBlsBn254.toBytes(wrapped);
        KeyBlsBn254.KEY_BLS_BN254 memory decoded = KeyBlsBn254.fromBytes(encoded);
        BN254.G1Point memory finalPt = decoded.unwrap();
        assertEq(finalPt.X, testX);
        assertEq(finalPt.Y, y);
    }

    function test_FuzzWrapUnwrap(
        uint256 xIn
    ) public {
        xIn = xIn % BN254.FP_MODULUS;
        (uint256 beta, uint256 y) = BN254.findYFromX(xIn);
        if (mulmod(y, y, BN254.FP_MODULUS) != beta) {
            return;
        }
        BN254.G1Point memory pt = BN254.G1Point({X: xIn, Y: y});
        KeyBlsBn254.KEY_BLS_BN254 memory wrapped = KeyBlsBn254.wrap(pt);
        BN254.G1Point memory unwrapped = wrapped.unwrap();
        assertEq(unwrapped.X, xIn);
        assertEq(unwrapped.Y, y);
    }

    function test_FuzzSerializeDeserialize(
        uint256 xIn
    ) public {
        xIn = xIn % BN254.FP_MODULUS;
        (uint256 beta, uint256 y) = BN254.findYFromX(xIn);
        if (mulmod(y, y, BN254.FP_MODULUS) != beta) {
            return;
        }
        BN254.G1Point memory pt = BN254.G1Point(xIn, y);
        KeyBlsBn254.KEY_BLS_BN254 memory wrapped = KeyBlsBn254.wrap(pt);
        bytes memory serialized = KeyBlsBn254.serialize(wrapped);
        KeyBlsBn254.KEY_BLS_BN254 memory deserialized = KeyBlsBn254.deserialize(serialized);
        BN254.G1Point memory finalPt = deserialized.unwrap();
        assertEq(finalPt.X, xIn);
        assertEq(finalPt.Y, y);
    }

    function test_FuzzSerializeDeserializeNonZeroNegate(
        uint256 xIn
    ) public {
        xIn = xIn % BN254.FP_MODULUS;
        (uint256 beta, uint256 y) = BN254.findYFromX(xIn);
        if (mulmod(y, y, BN254.FP_MODULUS) != beta) {
            return;
        }
        BN254.G1Point memory pt = BN254.negate(BN254.G1Point({X: xIn, Y: y}));
        KeyBlsBn254.KEY_BLS_BN254 memory wrapped = KeyBlsBn254.wrap(pt);
        bytes memory serialized = KeyBlsBn254.serialize(wrapped);
        KeyBlsBn254.KEY_BLS_BN254 memory deserialized = KeyBlsBn254.deserialize(serialized);
        BN254.G1Point memory finalPt = deserialized.unwrap();
        assertEq(finalPt.X, xIn);
        assertEq(finalPt.Y, pt.Y);
    }

    function test_FuzzToBytesFromBytes(
        uint256 xIn
    ) public {
        xIn = xIn % BN254.FP_MODULUS;
        (uint256 beta, uint256 y) = BN254.findYFromX(xIn);
        if (mulmod(y, y, BN254.FP_MODULUS) != beta) {
            return;
        }
        BN254.G1Point memory pt = BN254.G1Point(xIn, y);
        KeyBlsBn254.KEY_BLS_BN254 memory wrapped = KeyBlsBn254.wrap(pt);
        bytes memory encoded = KeyBlsBn254.toBytes(wrapped);
        KeyBlsBn254.KEY_BLS_BN254 memory decoded = KeyBlsBn254.fromBytes(encoded);
        BN254.G1Point memory finalPt = decoded.unwrap();
        assertEq(finalPt.X, xIn);
        assertEq(finalPt.Y, y);
    }

    function test_SerializeRevertsInvalidKey() public {
        uint256 testX = 10;
        (, uint256 y) = BN254.findYFromX(testX);
        BN254.G1Point memory pt = BN254.G1Point(testX, y);
        vm.expectRevert(KeyBlsBn254.KeyBlsBn254_InvalidKey.selector);
        KeyBlsBn254.KEY_BLS_BN254 memory wrapped = mock.wrap(pt);
    }

    function test_DeserializeEmptyBytesIsIdentity() public {
        BN254.G1Point memory identity = BN254.G1Point(0, 0);
        bytes memory empty = abi.encode(bytes32(0));
        KeyBlsBn254.KEY_BLS_BN254 memory deserialized = KeyBlsBn254.deserialize(empty);
        BN254.G1Point memory unwrapped = deserialized.unwrap();
        assertEq(unwrapped.X, identity.X);
        assertEq(unwrapped.Y, identity.Y);
    }

    function test_DeserializeRevertsInvalidLength() public {
        bytes memory invalid = hex"1234";
        vm.expectRevert();
        mock.deserialize(invalid);
    }

    function test_FromBytesRevertsInvalidLength() public {
        bytes memory invalid = hex"123456";
        vm.expectRevert();
        mock.fromBytes(invalid);
    }

    function test_FromBytesRevertsInvalidBytes() public {
        BN254.G1Point memory pt = BN254.G1Point(1, 2);
        KeyBlsBn254.fromBytes(abi.encode(pt));
        vm.expectRevert(KeyBlsBn254.KeyBlsBn254_InvalidBytes.selector);
        mock.fromBytes(abi.encode(pt, 1));
    }

    function test_WrapRevertsInvalidKey(
        uint256 X
    ) public {
        X = X % BN254.FP_MODULUS;
        (, uint256 Y) = BN254.findYFromX(1);
        BN254.G1Point memory pt = BN254.G1Point(X, Y + 1);
        vm.expectRevert(KeyBlsBn254.KeyBlsBn254_InvalidKey.selector);
        mock.wrap(pt);
    }

    function test_ZeroKey() public {
        KeyBlsBn254.KEY_BLS_BN254 memory zero = mock.zeroKey();
        assertEq(zero.unwrap().X, 0);
        assertEq(zero.unwrap().Y, 0);
    }

    function test_Equal() public {
        KeyBlsBn254.KEY_BLS_BN254 memory key1 = mock.wrap(BN254.G1Point(1, 2));
        KeyBlsBn254.KEY_BLS_BN254 memory key2 = mock.wrap(BN254.G1Point(1, 2));
        assertEq(mock.equal(key1, key2), true);
    }

    function test_EqualFalse() public {
        (, uint256 y1) = BN254.findYFromX(1);
        (, uint256 y2) = BN254.findYFromX(2);
        KeyBlsBn254.KEY_BLS_BN254 memory key1 = mock.wrap(BN254.G1Point(1, y1));
        KeyBlsBn254.KEY_BLS_BN254 memory key2 = mock.wrap(BN254.G1Point(2, y2));
        assertEq(mock.equal(key1, key2), false);
    }

    function test_OutOfBounds() public {
        vm.expectRevert(KeyBlsBn254.KeyBlsBn254_InvalidKey.selector);
        mock.wrap(BN254.G1Point(BN254.FP_MODULUS - 1, BN254.FP_MODULUS));

        vm.expectRevert(KeyBlsBn254.KeyBlsBn254_InvalidKey.selector);
        mock.wrap(BN254.G1Point(BN254.FP_MODULUS, BN254.FP_MODULUS - 1));

        (, uint256 y) = BN254.findYFromX(BN254.FP_MODULUS - 1);
        mock.wrap(BN254.G1Point(BN254.FP_MODULUS - 1, y));
    }
}
