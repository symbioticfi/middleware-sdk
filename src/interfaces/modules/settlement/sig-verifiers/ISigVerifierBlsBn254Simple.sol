// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISigVerifier} from "./ISigVerifier.sol";

interface ISigVerifierBlsBn254Simple is ISigVerifier {
    /**
     * @notice Reverts when the message length is invalid.
     */
    error SigVerifierBlsBn254Simple_InvalidMessageLength();

    /**
     * @notice Reverts when the non-signer index is greater than the number of validators.
     */
    error SigVerifierBlsBn254Simple_InvalidNonSignerIndex();

    /**
     * @notice Reverts when the non-signers' indices are not in the correct order.
     * @dev The indices must be sorted in ascending order.
     */
    error SigVerifierBlsBn254Simple_InvalidNonSignersOrder();

    /**
     * @notice Reverts when the proof length is too short.
     */
    error SigVerifierBlsBn254Simple_InvalidProofLength();

    /**
     * @notice Reverts when the proof offset is invalid.
     */
    error SigVerifierBlsBn254Simple_InvalidProofOffset();

    /**
     * @notice Reverts when the number of validators exceeds the maximum allowed for this verification mechanism.
     */
    error SigVerifierBlsBn254Simple_TooManyValidators();

    /**
     * @notice Reverts when the verification is not supported for the given key tag.
     */
    error SigVerifierBlsBn254Simple_UnsupportedKeyTag();

    /**
     * @notice Returns the marker for extra data fetching of the validator set keccak256 hash.
     * @return The marker for extra data fetching of the validator set keccak256 hash.
     */
    function VALIDATOR_SET_HASH_KECCAK256_HASH() external view returns (bytes32);

    /**
     * @notice Returns the marker for extra data fetching of the aggregated public key G1.
     * @return The marker for extra data fetching of the aggregated public key G1.
     * @dev The public key is compressed to one bytes32 slot.
     */
    function AGGREGATED_PUBLIC_KEY_G1_HASH() external view returns (bytes32);

    /**
     * @notice Returns the maximum allowed number of validators for this verification mechanism.
     * @return The maximum allowed number of validators for this verification mechanism.
     * @dev The maximum exists because each non-signer's index is encoded as a 2 bytes value.
     */
    function MAX_VALIDATORS() external view returns (uint256);
}
