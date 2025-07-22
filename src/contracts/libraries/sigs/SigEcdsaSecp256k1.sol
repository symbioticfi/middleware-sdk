// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {KeyEcdsaSecp256k1} from "../keys/KeyEcdsaSecp256k1.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library SigEcdsaSecp256k1 {
    using ECDSA for bytes32;
    using KeyEcdsaSecp256k1 for KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1;

    /**
     * @notice Reverts when the message length is invalid.
     */
    error SigEcdsaSecp256k1_InvalidMessageLength();

    /**
     * @notice Verify an ECDSA signature.
     * @param keyBytes The encoded signer address.
     * @param message The encoded message hash to verify.
     * @param signature The encoded ECDSA signature.
     * @return If the signature is valid.
     */
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

    /**
     * @notice Verify an ECDSA signature.
     * @param key The signer address.
     * @param message The message hash to verify.
     * @param signature The ECDSA signature.
     * @return If the signature is valid.
     */
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
