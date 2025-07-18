// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BN254} from "../utils/BN254.sol";
import {KeyBlsBn254} from "../keys/KeyBlsBn254.sol";

library SigBlsBn254 {
    using BN254 for BN254.G1Point;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;

    error SigBlsBn254_InvalidMessageLength();

    uint256 internal constant PAIRING_CHECK_GAS_LIMIT = 120_000;

    function verify(
        bytes memory keyBytes,
        bytes memory message,
        bytes memory signature,
        bytes memory extraData
    ) internal view returns (bool) {
        if (message.length != 32) {
            revert SigBlsBn254_InvalidMessageLength();
        }

        BN254.G1Point memory keyG1 = KeyBlsBn254.fromBytes(keyBytes).unwrap();
        BN254.G2Point memory keyG2 = abi.decode(extraData, (BN254.G2Point));
        BN254.G1Point memory signatureG1 = abi.decode(signature, (BN254.G1Point));
        bytes32 messageHash = abi.decode(message, (bytes32));

        return verify(keyG1, messageHash, signatureG1, keyG2);
    }

    function verify(
        BN254.G1Point memory keyG1,
        bytes32 messageHash,
        BN254.G1Point memory signatureG1,
        BN254.G2Point memory keyG2
    ) internal view returns (bool) {
        if (keyG1.X == 0 && keyG1.Y == 0) {
            return false;
        }
        BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
        uint256 alpha = uint256(
            keccak256(abi.encodePacked(messageHash, keyG1.X, keyG1.Y, keyG2.X, keyG2.Y, signatureG1.X, signatureG1.Y))
        ) % BN254.FR_MODULUS;
        (bool success, bool result) = BN254.safePairing(
            signatureG1.plus(keyG1.scalar_mul(alpha)),
            BN254.negGeneratorG2(),
            messageG1.plus(BN254.generatorG1().scalar_mul(alpha)),
            keyG2,
            PAIRING_CHECK_GAS_LIMIT
        );
        return success && result;
    }
}
