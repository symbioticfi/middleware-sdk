// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {SigEcdsaSecp256k1} from "../../../src/libraries/sigs/SigEcdsaSecp256k1.sol";
import {KeyEcdsaSecp256k1} from "../../../src/libraries/keys/KeyEcdsaSecp256k1.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SigEcdsaSecp256k1Test is Test {
    using KeyEcdsaSecp256k1 for KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1;

    function test_CorrectSignature() public {
        uint256 privKey = 1;
        address signer = vm.addr(privKey);

        bytes memory keyBytes = KeyEcdsaSecp256k1.wrap(signer).toBytes();

        bytes memory message = bytes("Hello, ECDSA!");

        bytes32 hashed = keccak256(message);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, hashed);
        bytes memory signature = abi.encodePacked(r, s, v);

        bool verified = SigEcdsaSecp256k1.verify(keyBytes, abi.encode(hashed), signature, "");
        assertTrue(verified);

        verified = SigEcdsaSecp256k1.verify(signer, hashed, signature);
        assertTrue(verified);
    }

    function test_IncorrectSignature() public {
        uint256 privKey = 1;
        address signer = vm.addr(privKey);
        bytes memory keyBytes = KeyEcdsaSecp256k1.wrap(signer).toBytes();
        bytes memory message = bytes("Hello, ECDSA!");
        bytes32 hashed = keccak256(message);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, hashed);
        bytes memory signature = abi.encodePacked(r, s, v);

        address wrongSigner = vm.addr(12_345);
        bytes memory wrongKeyBytes = KeyEcdsaSecp256k1.wrap(wrongSigner).toBytes();

        bool result = SigEcdsaSecp256k1.verify(wrongKeyBytes, abi.encode(hashed), signature, "");
        assertFalse(result);

        result = SigEcdsaSecp256k1.verify(wrongSigner, hashed, signature);
        assertFalse(result);

        bytes memory badSig = abi.encodePacked(r, bytes32(uint256(s) + 1), v);
        result = SigEcdsaSecp256k1.verify(keyBytes, abi.encode(hashed), badSig, "");
        assertFalse(result);

        result = SigEcdsaSecp256k1.verify(signer, hashed, badSig);
        assertFalse(result);
    }

    function test_FuzzVerification(uint256 privKey, bytes memory msgData) public {
        privKey = bound(
            privKey,
            1,
            115_792_089_237_316_195_423_570_985_008_687_907_852_837_564_279_074_904_382_605_163_141_518_161_494_337 - 1
        );

        address signer = vm.addr(privKey);
        bytes memory keyBytes = KeyEcdsaSecp256k1.wrap(signer).toBytes();

        bytes32 hashed = keccak256(msgData);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, hashed);
        bytes memory signature = abi.encodePacked(r, s, v);

        bool result = SigEcdsaSecp256k1.verify(keyBytes, abi.encode(hashed), signature, "");
        assertTrue(result);

        result = SigEcdsaSecp256k1.verify(signer, hashed, signature);
        assertTrue(result);
    }

    function test_ZeroKey() public {
        bytes memory keyBytes = KeyEcdsaSecp256k1.wrap(address(0)).toBytes();
        bytes memory message = bytes("Hello, ECDSA!");
        bytes32 hashed = keccak256(message);
        bytes memory signature = new bytes(65);
        bool result = SigEcdsaSecp256k1.verify(keyBytes, abi.encode(hashed), signature, "");
        assertFalse(result);

        result = SigEcdsaSecp256k1.verify(address(0), hashed, signature);
        assertFalse(result);
    }

    function verify(
        bytes memory keyBytes,
        bytes memory message,
        bytes memory signature,
        bytes memory extraData
    ) public view returns (bool) {
        return SigEcdsaSecp256k1.verify(keyBytes, message, signature, extraData);
    }

    function test_InvalidMessageLength() public {
        bytes memory keyBytes = KeyEcdsaSecp256k1.wrap(address(0)).toBytes();
        bytes memory message = bytes("Hello, ECDSA!");
        bytes32 hashed = keccak256(message);
        bytes memory signature = new bytes(65);
        vm.expectRevert(SigEcdsaSecp256k1.SigEcdsaSecp256k1_InvalidMessageLength.selector);
        this.verify(keyBytes, abi.encode(hashed, hashed), signature, "");
    }
}
