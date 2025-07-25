// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title ValSetVerifier
 * @notice Library for verifying the validity of validator set elements.
 */
library ValSetVerifier {
    /**
     * @notice The validator's key.
     * @param tag The key tag.
     * @param payloadHash The hash of the key.
     */
    struct Key {
        uint8 tag;
        bytes32 payloadHash;
    }

    /**
     * @notice The validator's vault.
     * @param chainId The chain ID.
     * @param vault The vault address.
     * @param votingPower The voting power.
     */
    struct Vault {
        uint64 chainId;
        address vault;
        uint256 votingPower;
    }

    /**
     * @notice The validator.
     * @param operator The operator address.
     * @param votingPower The voting power.
     * @param isActive If the validator is active.
     * @param keys The validator's keys.
     * @param vaults The validator's vaults.
     * @dev The voting power may not be equal to the sum of the voting powers inside the vaults.
     */
    struct Validator {
        address operator;
        uint256 votingPower;
        bool isActive;
        Key[] keys;
        Vault[] vaults;
    }

    /**
     * @notice The validator set.
     * @param validators The validators in the validator set.
     */
    struct ValidatorSet {
        Validator[] validators;
    }

    /**
     * @notice The Merkle proof.
     * @param leaf The leaf to prove.
     * @param proof The proof.
     */
    struct SszProof {
        bytes32 leaf;
        bytes32[] proof;
    }

    uint256 internal constant VALIDATOR_SET_TREE_HEIGHT = 0; // 1 element (ceil(log2(1)))

    uint256 internal constant VALIDATORS_LIST_TREE_HEIGHT = 20; // 1048576 elements (ceil(log2(1048576)))

    uint256 internal constant VALIDATORS_LIST_MAX_LENGTH = 1_048_576; // 1048576 elements (2 ^ VALIDATORS_LIST_TREE_HEIGHT)

    uint256 internal constant VALIDATOR_TREE_HEIGHT = 3; // 5 elements (ceil(log2(5)))

    uint256 internal constant KEY_LIST_TREE_HEIGHT = 7; // 128 elements (ceil(log2(128)))

    uint256 internal constant KEY_LIST_MAX_LENGTH = 128; // 128 elements (2 ^ KEY_LIST_TREE_HEIGHT)

    uint256 internal constant VAULT_LIST_TREE_HEIGHT = 10; // 1024 elements (ceil(log2(1024)))

    uint256 internal constant VAULT_LIST_MAX_LENGTH = 1024; // 1024 elements (2 ^ VAULT_LIST_TREE_HEIGHT)

    uint256 internal constant KEY_TREE_HEIGHT = 1; // 2 elements (ceil(log2(2)))

    uint256 internal constant VAULT_TREE_HEIGHT = 2; // 3 elements (ceil(log2(3)))

    uint256 internal constant VALIDATOR_SET_VALIDATORS_BASE_INDEX = 0;

    uint256 internal constant VALIDATOR_OPERATOR_BASE_INDEX = 0;

    uint256 internal constant VALIDATOR_VOTING_POWER_BASE_INDEX = 1;

    uint256 internal constant VALIDATOR_IS_ACTIVE_BASE_INDEX = 2;

    uint256 internal constant VALIDATOR_KEYS_BASE_INDEX = 3;

    uint256 internal constant VALIDATOR_VAULTS_BASE_INDEX = 4;

    uint256 internal constant KEY_TAG_BASE_INDEX = 0;

    uint256 internal constant KEY_PAYLOAD_HASH_BASE_INDEX = 1;

    uint256 internal constant VAULT_CHAIN_ID_BASE_INDEX = 0;

    uint256 internal constant VAULT_VAULT_BASE_INDEX = 1;

    uint256 internal constant VAULT_VOTING_POWER_BASE_INDEX = 2;

    /// @dev The precompile address for SHA-256
    uint256 internal constant SHA256_PRECOMPILE = 0x02;

    uint256 internal constant VALIDATORS_LIST_LOCAL_INDEX = VALIDATOR_SET_VALIDATORS_BASE_INDEX; // to element in ValidatorSet

    uint256 internal constant VALIDATOR_ROOT_MIN_LOCAL_INDEX =
        VALIDATORS_LIST_LOCAL_INDEX << (1 + VALIDATORS_LIST_TREE_HEIGHT); // to first element (inclusive), "1" is for the length (for a List)

    uint256 internal constant VALIDATOR_ROOT_MAX_LOCAL_INDEX =
        VALIDATOR_ROOT_MIN_LOCAL_INDEX + VALIDATORS_LIST_MAX_LENGTH; // to last element (exclusive)

    uint256 internal constant VALIDATOR_ROOT_PROOF_EXPECTED_HEIGHT =
        VALIDATOR_SET_TREE_HEIGHT + 1 + VALIDATORS_LIST_TREE_HEIGHT; // (to element in ValidatorSet) + (length) + (to element in validators)

    uint256 internal constant VALIDATOR_OPERATOR_LOCAL_INDEX = VALIDATOR_OPERATOR_BASE_INDEX; // to element in Validator

    uint256 internal constant VALIDATOR_OPERATOR_PROOF_EXPECTED_HEIGHT = VALIDATOR_TREE_HEIGHT; // (to element in Validator)

    uint256 internal constant VALIDATOR_VOTING_POWER_LOCAL_INDEX = VALIDATOR_VOTING_POWER_BASE_INDEX; // to element in Validator

    uint256 internal constant VALIDATOR_VOTING_POWER_PROOF_EXPECTED_HEIGHT = VALIDATOR_TREE_HEIGHT; // (to element in Validator)

    uint256 internal constant VALIDATOR_IS_ACTIVE_LOCAL_INDEX = VALIDATOR_IS_ACTIVE_BASE_INDEX; // to element in Validator

    uint256 internal constant VALIDATOR_IS_ACTIVE_PROOF_EXPECTED_HEIGHT = VALIDATOR_TREE_HEIGHT; // (to element in Validator)

    uint256 internal constant KEYS_LIST_LOCAL_INDEX = VALIDATOR_KEYS_BASE_INDEX; // to element in Validator

    uint256 internal constant KEY_ROOT_MIN_LOCAL_INDEX = KEYS_LIST_LOCAL_INDEX << (1 + KEY_LIST_TREE_HEIGHT); // to first element (inclusive), "1" is for the length (for a List)

    uint256 internal constant KEY_ROOT_MAX_LOCAL_INDEX = KEY_ROOT_MIN_LOCAL_INDEX + KEY_LIST_MAX_LENGTH; // to last element (exclusive)

    uint256 internal constant KEY_ROOT_PROOF_EXPECTED_HEIGHT = VALIDATOR_TREE_HEIGHT + 1 + KEY_LIST_TREE_HEIGHT; // (to element in Validator) + (length) + (to element in keys)

    uint256 internal constant VAULTS_LIST_LOCAL_INDEX = VALIDATOR_VAULTS_BASE_INDEX; // to element in Validator

    uint256 internal constant VAULT_ROOT_MIN_LOCAL_INDEX = VAULTS_LIST_LOCAL_INDEX << (1 + VAULT_LIST_TREE_HEIGHT); // to first element (inclusive), "1" is for the length (for a List)

    uint256 internal constant VAULT_ROOT_MAX_LOCAL_INDEX = VAULT_ROOT_MIN_LOCAL_INDEX + VAULT_LIST_MAX_LENGTH; // to last element (exclusive)

    uint256 internal constant VAULT_ROOT_PROOF_EXPECTED_HEIGHT = VALIDATOR_TREE_HEIGHT + 1 + VAULT_LIST_TREE_HEIGHT; // (to element in Validator) + (length) + (to element in vaults)

    uint256 internal constant KEY_TAG_LOCAL_INDEX = KEY_TAG_BASE_INDEX; // to element in Key

    uint256 internal constant KEY_TAG_PROOF_EXPECTED_HEIGHT = KEY_TREE_HEIGHT; // (to element in Key)

    uint256 internal constant KEY_PAYLOAD_HASH_LOCAL_INDEX = KEY_PAYLOAD_HASH_BASE_INDEX; // to element in Key

    uint256 internal constant KEY_PAYLOAD_HASH_PROOF_EXPECTED_HEIGHT = KEY_TREE_HEIGHT; // (to element in Key)

    uint256 internal constant VAULT_CHAIN_ID_LOCAL_INDEX = VAULT_CHAIN_ID_BASE_INDEX; // to element in Vault

    uint256 internal constant VAULT_CHAIN_ID_PROOF_EXPECTED_HEIGHT = VAULT_TREE_HEIGHT; // (to element in Vault)

    uint256 internal constant VAULT_VAULT_LOCAL_INDEX = VAULT_VAULT_BASE_INDEX; // to element in Vault

    uint256 internal constant VAULT_VAULT_PROOF_EXPECTED_HEIGHT = VAULT_TREE_HEIGHT; // (to element in Vault)

    uint256 internal constant VAULT_VOTING_POWER_LOCAL_INDEX = VAULT_VOTING_POWER_BASE_INDEX; // to element in Vault

    uint256 internal constant VAULT_VOTING_POWER_PROOF_EXPECTED_HEIGHT = VAULT_TREE_HEIGHT; // (to element in Vault)

    /**
     * @notice Verifies that the key is in the validator set.
     * @param validatorRootProof The proof of the validator root.
     * @param validatorRootLocalIndex The local index of the validator root inside the validator set.
     * @param validatorSetRoot The validator set root.
     * @param keyRootProof The proof of the key root.
     * @param keyRootLocalIndex The local index of the key root inside the validator.
     * @param keyTagProof The proof of the key tag.
     * @param keyPayloadHashProof The proof of the key hash.
     * @return isValid If the key is in the validator set.
     */
    function verifyKey(
        SszProof calldata validatorRootProof,
        uint256 validatorRootLocalIndex,
        bytes32 validatorSetRoot,
        SszProof calldata keyRootProof,
        uint256 keyRootLocalIndex,
        SszProof calldata keyTagProof,
        SszProof calldata keyPayloadHashProof
    ) internal view returns (bool isValid) {
        isValid = verifyValidatorRootLocal(validatorRootProof, validatorRootLocalIndex, validatorSetRoot);
        if (!isValid) {
            return false;
        }
        isValid = verifyValidatorKeyRootLocal(keyRootProof, keyRootLocalIndex, validatorRootProof.leaf);
        if (!isValid) {
            return false;
        }
        isValid = verifyKeyTagLocal(keyTagProof, keyRootProof.leaf);
        if (!isValid) {
            return false;
        }
        return verifyKeyPayloadHash(keyPayloadHashProof, keyRootProof.leaf);
    }

    /**
     * @notice Verifies that the vault is in the validator set.
     * @param validatorRootProof The proof of the validator root.
     * @param validatorRootLocalIndex The local index of the validator root inside the validator set.
     * @param validatorSetRoot The validator set root.
     * @param vaultRootProof The proof of the vault root.
     * @param vaultRootLocalIndex The local index of the vault root inside the validator.
     * @param vaultChainIdProof The proof of the vault chain ID.
     * @param vaultVaultProof The proof of the vault address.
     * @param vaultVotingPowerProof The proof of the vault voting power.
     * @return isValid If the vault is in the validator set.
     */
    function verifyVault(
        SszProof calldata validatorRootProof,
        uint256 validatorRootLocalIndex,
        bytes32 validatorSetRoot,
        SszProof calldata vaultRootProof,
        uint256 vaultRootLocalIndex,
        SszProof calldata vaultChainIdProof,
        SszProof calldata vaultVaultProof,
        SszProof calldata vaultVotingPowerProof
    ) internal view returns (bool isValid) {
        isValid = verifyValidatorRootLocal(validatorRootProof, validatorRootLocalIndex, validatorSetRoot);
        if (!isValid) {
            return false;
        }
        isValid = verifyValidatorVaultRootLocal(vaultRootProof, vaultRootLocalIndex, validatorRootProof.leaf);
        if (!isValid) {
            return false;
        }
        isValid = verifyVaultChainIdLocal(vaultChainIdProof, vaultRootProof.leaf);
        if (!isValid) {
            return false;
        }
        isValid = verifyVaultVaultLocal(vaultVaultProof, vaultRootProof.leaf);
        if (!isValid) {
            return false;
        }
        return verifyVaultVotingPowerLocal(vaultVotingPowerProof, vaultRootProof.leaf);
    }

    /**
     * @notice Verifies that the operator address is in the validator set.
     * @param validatorRootProof The proof of the validator root.
     * @param validatorRootLocalIndex The local index of the validator root inside the validator set.
     * @param validatorSetRoot The validator set root.
     * @param operatorProof The proof of the operator address.
     * @return isValid If the operator address is in the validator set.
     */
    function verifyOperator(
        SszProof calldata validatorRootProof,
        uint256 validatorRootLocalIndex,
        bytes32 validatorSetRoot,
        SszProof calldata operatorProof
    ) internal view returns (bool isValid) {
        isValid = verifyValidatorRootLocal(validatorRootProof, validatorRootLocalIndex, validatorSetRoot);
        if (!isValid) {
            return false;
        }
        return verifyValidatorOperatorLocal(operatorProof, validatorRootProof.leaf);
    }

    /**
     * @notice Verifies that the validator's voting power is in the validator set.
     * @param validatorRootProof The proof of the validator root.
     * @param validatorRootLocalIndex The local index of the validator root inside the validator set.
     * @param validatorSetRoot The validator set root.
     * @param votingPowerProof The proof of the voting power.
     * @return isValid If the validator's voting power is in the validator set.
     */
    function verifyVotingPower(
        SszProof calldata validatorRootProof,
        uint256 validatorRootLocalIndex,
        bytes32 validatorSetRoot,
        SszProof calldata votingPowerProof
    ) internal view returns (bool isValid) {
        isValid = verifyValidatorRootLocal(validatorRootProof, validatorRootLocalIndex, validatorSetRoot);
        if (!isValid) {
            return false;
        }
        return verifyValidatorVotingPowerLocal(votingPowerProof, validatorRootProof.leaf);
    }

    /**
     * @notice Verifies that the validator's activity status is in the validator set.
     * @param validatorRootProof The proof of the validator root.
     * @param validatorRootLocalIndex The local index of the validator root inside the validator set.
     * @param validatorSetRoot The validator set root.
     * @param isActiveProof The proof of the validator's is active.
     * @return isValid If the validator is active.
     */
    function verifyIsActive(
        SszProof calldata validatorRootProof,
        uint256 validatorRootLocalIndex,
        bytes32 validatorSetRoot,
        SszProof calldata isActiveProof
    ) internal view returns (bool isValid) {
        isValid = verifyValidatorRootLocal(validatorRootProof, validatorRootLocalIndex, validatorSetRoot);
        if (!isValid) {
            return false;
        }
        return verifyValidatorIsActiveLocal(isActiveProof, validatorRootProof.leaf);
    }

    /**
     * @notice Verifies that the validator root is in the validator set.
     * @param validatorRootProof The proof of the validator root.
     * @param validatorRootLocalIndex The local index of the validator root inside the validator set.
     * @param validatorSetRoot The validator set root.
     * @return isValid If the validator root is in the validator set.
     */
    function verifyValidatorRootLocal(
        SszProof calldata validatorRootProof,
        uint256 validatorRootLocalIndex,
        bytes32 validatorSetRoot
    ) internal view returns (bool) {
        if (
            validatorRootLocalIndex < VALIDATOR_ROOT_MIN_LOCAL_INDEX
                || validatorRootLocalIndex >= VALIDATOR_ROOT_MAX_LOCAL_INDEX
        ) {
            return false;
        }

        return processInclusionProofSha256(
            validatorRootProof.proof,
            validatorRootProof.leaf,
            validatorSetRoot,
            validatorRootLocalIndex,
            VALIDATOR_ROOT_PROOF_EXPECTED_HEIGHT
        );
    }

    /**
     * @notice Verifies that the operator address is in the validator.
     * @param validatorOperatorProof The proof of the operator address.
     * @param validatorRoot The validator root.
     * @return isValid If the operator address is in the validator.
     */
    function verifyValidatorOperatorLocal(
        SszProof calldata validatorOperatorProof,
        bytes32 validatorRoot
    ) internal view returns (bool) {
        return processInclusionProofSha256(
            validatorOperatorProof.proof,
            validatorOperatorProof.leaf,
            validatorRoot,
            VALIDATOR_OPERATOR_LOCAL_INDEX,
            VALIDATOR_OPERATOR_PROOF_EXPECTED_HEIGHT
        );
    }

    /**
     * @notice Verifies that the validator's voting power is in the validator.
     * @param validatorVotingPowerProof The proof of the validator's voting power.
     * @param validatorRoot The validator root.
     * @return isValid If the validator's voting power is in the validator.
     */
    function verifyValidatorVotingPowerLocal(
        SszProof calldata validatorVotingPowerProof,
        bytes32 validatorRoot
    ) internal view returns (bool) {
        return processInclusionProofSha256(
            validatorVotingPowerProof.proof,
            validatorVotingPowerProof.leaf,
            validatorRoot,
            VALIDATOR_VOTING_POWER_LOCAL_INDEX,
            VALIDATOR_VOTING_POWER_PROOF_EXPECTED_HEIGHT
        );
    }

    /**
     * @notice Verifies that the validator's activity status is in the validator.
     * @param validatorIsActiveProof The proof of the validator's activity status.
     * @param validatorRoot The validator root.
     * @return isValid If the validator's activity status is in the validator.
     */
    function verifyValidatorIsActiveLocal(
        SszProof calldata validatorIsActiveProof,
        bytes32 validatorRoot
    ) internal view returns (bool) {
        return processInclusionProofSha256(
            validatorIsActiveProof.proof,
            validatorIsActiveProof.leaf,
            validatorRoot,
            VALIDATOR_IS_ACTIVE_LOCAL_INDEX,
            VALIDATOR_IS_ACTIVE_PROOF_EXPECTED_HEIGHT
        );
    }

    /**
     * @notice Verifies that the key root is in the validator.
     * @param keyRootProof The proof of the key root.
     * @param keyRootLocalIndex The local index of the key root inside the validator.
     * @param validatorRoot The validator root.
     * @return isValid If the key root is in the validator.
     */
    function verifyValidatorKeyRootLocal(
        SszProof calldata keyRootProof,
        uint256 keyRootLocalIndex,
        bytes32 validatorRoot
    ) internal view returns (bool) {
        if (keyRootLocalIndex < KEY_ROOT_MIN_LOCAL_INDEX || keyRootLocalIndex >= KEY_ROOT_MAX_LOCAL_INDEX) {
            return false;
        }

        return processInclusionProofSha256(
            keyRootProof.proof, keyRootProof.leaf, validatorRoot, keyRootLocalIndex, KEY_ROOT_PROOF_EXPECTED_HEIGHT
        );
    }

    /**
     * @notice Verifies that the vault root is in the validator.
     * @param vaultRootProof The proof of the vault root.
     * @param vaultRootLocalIndex The local index of the vault root inside the validator.
     * @param validatorRoot The validator root.
     * @return isValid If the vault root is in the validator.
     */
    function verifyValidatorVaultRootLocal(
        SszProof calldata vaultRootProof,
        uint256 vaultRootLocalIndex,
        bytes32 validatorRoot
    ) internal view returns (bool) {
        if (vaultRootLocalIndex < VAULT_ROOT_MIN_LOCAL_INDEX || vaultRootLocalIndex >= VAULT_ROOT_MAX_LOCAL_INDEX) {
            return false;
        }

        return processInclusionProofSha256(
            vaultRootProof.proof,
            vaultRootProof.leaf,
            validatorRoot,
            vaultRootLocalIndex,
            VAULT_ROOT_PROOF_EXPECTED_HEIGHT
        );
    }

    /**
     * @notice Verifies that the key tag is in the key.
     * @param keyTagProof The proof of the key tag.
     * @param keyRoot The key root.
     * @return isValid If the key tag is in the key.
     */
    function verifyKeyTagLocal(SszProof calldata keyTagProof, bytes32 keyRoot) internal view returns (bool) {
        return processInclusionProofSha256(
            keyTagProof.proof, keyTagProof.leaf, keyRoot, KEY_TAG_LOCAL_INDEX, KEY_TAG_PROOF_EXPECTED_HEIGHT
        );
    }

    /**
     * @notice Verifies that the key hash is in the key.
     * @param keyPayloadHashProof The proof of the key hash.
     * @param keyRoot The key root.
     * @return isValid If the key hash is in the key.
     */
    function verifyKeyPayloadHash(
        SszProof calldata keyPayloadHashProof,
        bytes32 keyRoot
    ) internal view returns (bool) {
        return processInclusionProofSha256(
            keyPayloadHashProof.proof,
            keyPayloadHashProof.leaf,
            keyRoot,
            KEY_PAYLOAD_HASH_LOCAL_INDEX,
            KEY_PAYLOAD_HASH_PROOF_EXPECTED_HEIGHT
        );
    }

    /**
     * @notice Verifies that the vault's chain ID is in the vault.
     * @param vaultChainIdProof The proof of the vault chain ID.
     * @param vaultRoot The vault root.
     * @return isValid If the vault's chain ID is in the vault.
     */
    function verifyVaultChainIdLocal(
        SszProof calldata vaultChainIdProof,
        bytes32 vaultRoot
    ) internal view returns (bool) {
        return processInclusionProofSha256(
            vaultChainIdProof.proof,
            vaultChainIdProof.leaf,
            vaultRoot,
            VAULT_CHAIN_ID_LOCAL_INDEX,
            VAULT_CHAIN_ID_PROOF_EXPECTED_HEIGHT
        );
    }

    /**
     * @notice Verifies that the vault address is in the vault.
     * @param vaultVaultProof The proof of the vault address.
     * @param vaultRoot The vault root.
     * @return isValid If the vault address is in the vault.
     */
    function verifyVaultVaultLocal(SszProof calldata vaultVaultProof, bytes32 vaultRoot) internal view returns (bool) {
        return processInclusionProofSha256(
            vaultVaultProof.proof,
            vaultVaultProof.leaf,
            vaultRoot,
            VAULT_VAULT_LOCAL_INDEX,
            VAULT_VAULT_PROOF_EXPECTED_HEIGHT
        );
    }

    /**
     * @notice Verifies that the vault's voting power is in the vault.
     * @param vaultVotingPowerProof The proof of the vault voting power.
     * @param vaultRoot The vault root.
     * @return isValid If the vault's voting power is in the vault.
     */
    function verifyVaultVotingPowerLocal(
        SszProof calldata vaultVotingPowerProof,
        bytes32 vaultRoot
    ) internal view returns (bool) {
        return processInclusionProofSha256(
            vaultVotingPowerProof.proof,
            vaultVotingPowerProof.leaf,
            vaultRoot,
            VAULT_VOTING_POWER_LOCAL_INDEX,
            VAULT_VOTING_POWER_PROOF_EXPECTED_HEIGHT
        );
    }

    /**
     * @notice Processes an inclusion proof with a SHA256 hash.
     * @param proof The inclusion proof.
     * @param leaf The leaf to be proven.
     * @param root The root to reconcile the proof against.
     * @param localIndex The local index of the leaf.
     * @param expectedHeight The height of the tree that the proof is for.
     * @return valid A boolean indicating whether the derived root from the proof matches the `root` provided.
     * @dev In case of an invalid proof length, we return false which is to be handled by the caller.
     *      In case of a failed SHA-256 call, we revert.
     */
    function processInclusionProofSha256(
        bytes32[] calldata proof,
        bytes32 leaf,
        bytes32 root,
        uint256 localIndex,
        uint256 expectedHeight
    ) internal view returns (bool valid) {
        if (proof.length != expectedHeight) return false;

        /// @solidity memory-safe-assembly
        assembly {
            function callSha256(rdataOffset) {
                if iszero(staticcall(sub(gas(), 2000), SHA256_PRECOMPILE, 0x00, 0x40, rdataOffset, 0x20)) {
                    revert(0x00, 0x00)
                }
            }

            switch mod(localIndex, 2)
            case 0 {
                mstore(0x00, leaf)
                mstore(0x20, calldataload(proof.offset))
            }
            default {
                mstore(0x00, calldataload(proof.offset))
                mstore(0x20, leaf)
            }

            // let startOffset := add(proof.offset, 32)
            // But we'll initialize directly in the loop
            let endOffset := add(shl(5, proof.length), proof.offset)
            for { let i := add(proof.offset, 32) } iszero(eq(i, endOffset)) { i := add(i, 32) } {
                // Div by 2
                localIndex := shr(1, localIndex)

                switch mod(localIndex, 2)
                case 0 {
                    // Store returndata at 0x00
                    callSha256(0x00)
                    mstore(0x20, calldataload(i))
                }
                default {
                    // Store returndata at 0x20
                    callSha256(0x20)
                    mstore(0x00, calldataload(i))
                }
            }

            callSha256(0x00)
            let derivedRoot := mload(0x00)

            valid := eq(derivedRoot, root)
        }
    }
}
