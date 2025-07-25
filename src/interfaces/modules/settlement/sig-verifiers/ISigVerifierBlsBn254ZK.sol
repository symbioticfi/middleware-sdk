// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISigVerifier} from "./ISigVerifier.sol";

interface ISigVerifierBlsBn254ZK is ISigVerifier {
    /**
     * @notice Reverts when the number of verifiers and max validators is not the same or zero.
     */
    error SigVerifierBlsBn254ZK_InvalidLength();

    /**
     * @notice Reverts when the maximum supported number of validators is zero.
     */
    error SigVerifierBlsBn254ZK_InvalidMaxValidators();

    /**
     * @notice Reverts when the maximum supported numbers of validators is not in the correct order.
     * @dev The maximum supported numbers of validators must be in ascending order.
     */
    error SigVerifierBlsBn254ZK_InvalidMaxValidatorsOrder();

    /**
     * @notice Reverts when the message length is invalid.
     */
    error SigVerifierBlsBn254ZK_InvalidMessageLength();

    /**
     * @notice Reverts when the proof length is invalid.
     */
    error SigVerifierBlsBn254ZK_InvalidProofLength();

    /**
     * @notice Reverts when the proof offset is invalid.
     */
    error SigVerifierBlsBn254ZK_InvalidProofOffset();

    /**
     * @notice Reverts when the total active validators is greater than the maximum supported.
     */
    error SigVerifierBlsBn254ZK_InvalidTotalActiveValidators();

    /**
     * @notice Reverts when the verifier is zero address.
     */
    error SigVerifierBlsBn254ZK_InvalidVerifier();

    /**
     * @notice Reverts when the verification is not supported for the given key tag.
     */
    error SigVerifierBlsBn254ZK_UnsupportedKeyTag();

    /**
     * @notice Returns the marker for extra data fetching of the total active validators.
     * @return The marker for extra data fetching of the total active validators.
     */
    function TOTAL_ACTIVE_VALIDATORS_HASH() external view returns (bytes32);

    /**
     * @notice Returns the marker for extra data fetching of the validator set MiMC hash.
     * @return The marker for extra data fetching of the validator set MiMC hash.
     */
    function VALIDATOR_SET_HASH_MIMC_HASH() external view returns (bytes32);

    /**
     * @notice Returns the verifier at the given index.
     * @param index The index of the verifier.
     * @return The verifier at the given index.
     */
    function verifiers(
        uint256 index
    ) external view returns (address);

    /**
     * @notice Returns the maximum supported number of validators for the verifier at the given index.
     * @param index The index of the verifier.
     * @return The maximum supported number of validators for the verifier at the given index.
     */
    function maxValidators(
        uint256 index
    ) external view returns (uint256);
}
