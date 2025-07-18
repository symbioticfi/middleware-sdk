// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {KeyEcdsaSecp256k1} from "../keys/KeyEcdsaSecp256k1.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library SigEcdsaSecp256k1 {
    using ECDSA for bytes32;
    using KeyEcdsaSecp256k1 for KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1;

    error SigEcdsaSecp256k1_InvalidMessageLength();

    function verify(
        bytes memory keyBytes,
        bytes memory message,
        bytes memory signature,
        bytes memory /* extraData */
    ) internal view returns (bool) {
        if (message.length != 32) {
            revert SigEcdsaSecp256k1_InvalidMessageLength();
        }

        address keyAddress = KeyEcdsaSecp256k1.fromBytes(keyBytes).unwrap();
        bytes32 messageHash = abi.decode(message, (bytes32));

        return verify(keyAddress, messageHash, signature);
    }

    function verify(address key, bytes32 message, bytes memory signature) internal view returns (bool) {
        if (key == address(0)) {
            return false;
        }
        (address recovered, ECDSA.RecoverError error,) = ECDSA.tryRecover(message, signature);
        if (error != ECDSA.RecoverError.NoError) {
            return false;
        }
        return recovered == key;
    }
}
