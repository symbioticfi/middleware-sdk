// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {SigBlsBn254} from "../../../src/contracts/libraries/sigs/SigBlsBn254.sol";
import {KeyBlsBn254} from "../../../src/contracts/libraries/keys/KeyBlsBn254.sol";
import {BN254} from "../../../src/contracts/libraries/utils/BN254.sol";
import {BN254G2} from "../../helpers/BN254G2.sol";

contract SigBlsBn254Test is Test {
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;
    using BN254 for BN254.G1Point;

    function getG2Key(
        uint256 privateKey
    ) public view returns (BN254.G2Point memory) {
        BN254.G2Point memory G2 = BN254.generatorG2();
        (uint256 x1, uint256 x2, uint256 y1, uint256 y2) =
            BN254G2.ECTwistMul(privateKey, G2.X[1], G2.X[0], G2.Y[1], G2.Y[0]);
        return BN254.G2Point([x2, x1], [y2, y1]);
    }

    function test_BLSRegisterOperator() public {
        (uint256 privateKey, bytes32 messageHash) = (uint256(0x1234567890abcdef), keccak256("test message"));
        BN254.G1Point memory keyG1 = BN254.generatorG1().scalar_mul(privateKey);
        BN254.G2Point memory keyG2 = getG2Key(privateKey);

        BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);

        BN254.G1Point memory sigG1 = messageG1.scalar_mul(privateKey);

        assertTrue(
            SigBlsBn254.verify(
                KeyBlsBn254.wrap(keyG1).toBytes(), abi.encode(messageHash), abi.encode(sigG1), abi.encode(keyG2)
            )
        );

        assertTrue(SigBlsBn254.verify(keyG1, messageHash, sigG1, keyG2));
    }

    function test_BLSRegisterOperatorInvalid() public {
        (uint256 privateKey, bytes32 messageHash) = (uint256(0x1234567890abcdef), keccak256("test message"));
        BN254.G1Point memory keyG1 = BN254.generatorG1().scalar_mul(privateKey);
        BN254.G2Point memory keyG2 = getG2Key(privateKey);

        BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);

        BN254.G1Point memory invalidSigG1 =
            messageG1.scalar_mul(privateKey == type(uint256).max ? type(uint256).max - 1 : privateKey + 1);

        assertFalse(
            SigBlsBn254.verify(
                KeyBlsBn254.wrap(keyG1).toBytes(), abi.encode(messageHash), abi.encode(invalidSigG1), abi.encode(keyG2)
            )
        );

        assertFalse(SigBlsBn254.verify(keyG1, messageHash, invalidSigG1, keyG2));
    }

    function test_ZeroKey() public {
        bytes memory keyBytes = KeyBlsBn254.wrap(BN254.G1Point(0, 0)).toBytes();
        bytes memory message = bytes("Hello, BLS!");
        bytes32 hashed = keccak256(message);
        bytes memory signature = abi.encode(BN254.G1Point(0, 0));
        bool result = SigBlsBn254.verify(
            keyBytes,
            abi.encode(hashed),
            signature,
            abi.encode(BN254.G2Point([uint256(0), uint256(0)], [uint256(0), uint256(0)]))
        );
        assertFalse(result);

        result = SigBlsBn254.verify(
            BN254.G1Point(0, 0),
            hashed,
            BN254.G1Point(0, 0),
            BN254.G2Point([uint256(0), uint256(0)], [uint256(0), uint256(0)])
        );
        assertFalse(result);
    }
}
