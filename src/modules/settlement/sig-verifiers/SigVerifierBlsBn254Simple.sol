// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BN254} from "../../../libraries/utils/BN254.sol";
import {ExtraDataStorageHelper} from "./libraries/ExtraDataStorageHelper.sol";
import {KeyBlsBn254} from "../../../libraries/keys/KeyBlsBn254.sol";
import {KeyTags} from "../../../libraries/utils/KeyTags.sol";
import {SigBlsBn254} from "../../../libraries/sigs/SigBlsBn254.sol";

import {ISettlement} from "../../../interfaces/modules/settlement/ISettlement.sol";
import {ISigVerifierBlsBn254Simple} from
    "../../../interfaces/modules/settlement/sig-verifiers/ISigVerifierBlsBn254Simple.sol";
import {ISigVerifier} from "../../../interfaces/modules/settlement/sig-verifiers/ISigVerifier.sol";
import {KEY_TYPE_BLS_BN254} from "../../../interfaces/modules/key-registry/IKeyRegistry.sol";

/**
 * @title SigVerifierBlsBn254Simple
 * @notice Contract for verifying validator's set attestations based on BLS signatures on the BN254 curve
 *         by decompressing the whole validator set on-chain.
 */
contract SigVerifierBlsBn254Simple is ISigVerifierBlsBn254Simple {
    using BN254 for BN254.G1Point;
    using ExtraDataStorageHelper for uint32;
    using KeyBlsBn254 for bytes;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;
    using KeyTags for uint8;

    /**
     * @inheritdoc ISigVerifier
     */
    uint32 public constant VERIFICATION_TYPE = 1;

    /**
     * @inheritdoc ISigVerifierBlsBn254Simple
     */
    bytes32 public constant VALIDATOR_SET_HASH_KECCAK256_HASH = keccak256("validatorSetHashKeccak256");

    /**
     * @inheritdoc ISigVerifierBlsBn254Simple
     */
    bytes32 public constant AGGREGATED_PUBLIC_KEY_G1_HASH = keccak256("aggPublicKeyG1");

    /**
     * @inheritdoc ISigVerifierBlsBn254Simple
     */
    uint256 public constant MAX_VALIDATORS = 65_536;

    /**
     * @inheritdoc ISigVerifier
     */
    function verifyQuorumSig(
        address settlement,
        uint48 epoch,
        bytes memory message,
        uint8 keyTag,
        uint256 quorumThreshold,
        bytes calldata proof
    ) public view returns (bool) {
        if (keyTag.getType() != KEY_TYPE_BLS_BN254) {
            revert SigVerifierBlsBn254Simple_UnsupportedKeyTag();
        }
        if (message.length != 32) {
            revert SigVerifierBlsBn254Simple_InvalidMessageLength();
        }

        // Proof Structure
        // 0 : 64 - G1 aggregated signature
        // 64 : 192 - G2 aggregated public key
        // 192 : 224+validatorsData.length*64 - encoded data of all active validators for a given `keyTag`
        //     192 : 224 - number of validators
        //     224 : 224+validatorsData.length*64 - (bytes32 keySerialized,uint256 votingPower)[]
        // 224+validatorsData.length*64 (nonSignersOffset) : nonSignersOffset+nonSigners.length*2 - encoded array of 2 bytes non-signer indices (from validatorsData)
        //     nonSignersOffset : nonSignersOffset+nonSigners.length*2 - uint16[]

        unchecked {
            {
                uint256 proofOffset;
                assembly {
                    proofOffset := proof.offset
                }
                if (proofOffset >= msg.data.length) {
                    revert SigVerifierBlsBn254Simple_InvalidProofOffset();
                }
                if (proof.length < 224) {
                    revert SigVerifierBlsBn254Simple_InvalidProofLength();
                }
            }
            uint256 nonSignersVotingPower;
            BN254.G1Point memory nonSignersPublicKeyG1;
            {
                uint256 validatorsDataLength;
                assembly ("memory-safe") {
                    validatorsDataLength := calldataload(add(proof.offset, 192))
                }
                if (validatorsDataLength == 0) {
                    return false;
                }
                if (validatorsDataLength > MAX_VALIDATORS) {
                    revert SigVerifierBlsBn254Simple_TooManyValidators();
                }
                uint256 nonSignersOffset = 224 + validatorsDataLength * 64;
                if (
                    keccak256(proof[192:nonSignersOffset])
                        != ISettlement(settlement).getExtraDataAt(
                            epoch, VERIFICATION_TYPE.getKey(keyTag, VALIDATOR_SET_HASH_KECCAK256_HASH)
                        )
                ) {
                    return false;
                }

                uint256 nonSignersLength = (proof.length - nonSignersOffset) >> 1;

                if (proof.length != nonSignersOffset + nonSignersLength * 2) {
                    revert SigVerifierBlsBn254Simple_InvalidProofLength();
                }

                uint256 prevNonSignerIndex;
                for (uint256 i; i < nonSignersLength; ++i) {
                    uint256 currentNonSignerIndex;
                    assembly ("memory-safe") {
                        currentNonSignerIndex := shr(240, calldataload(add(proof.offset, nonSignersOffset)))
                    }
                    if (currentNonSignerIndex >= validatorsDataLength) {
                        revert SigVerifierBlsBn254Simple_InvalidNonSignerIndex();
                    }
                    if (i > 0 && prevNonSignerIndex >= currentNonSignerIndex) {
                        revert SigVerifierBlsBn254Simple_InvalidNonSignersOrder();
                    }
                    uint256 indexOffset;
                    assembly {
                        indexOffset := add(add(proof.offset, 224), mul(currentNonSignerIndex, 64))
                    }
                    {
                        bytes32 keySerialized;
                        assembly {
                            keySerialized := calldataload(indexOffset)
                        }
                        nonSignersPublicKeyG1 =
                            nonSignersPublicKeyG1.plus(abi.encode(keySerialized).deserialize().unwrap());
                    }
                    {
                        uint256 votingPower;
                        assembly {
                            votingPower := calldataload(add(indexOffset, 32))
                        }
                        // assuming that the validator set, and, hence, total voting power, were properly committed,
                        // so that the sum of the non-signers' voting powers cannot be greater than the total voting power,
                        // and, hence, cannot overflow
                        nonSignersVotingPower += votingPower;
                    }
                    prevNonSignerIndex = currentNonSignerIndex;
                    nonSignersOffset += 2;
                }
            }

            if (
                quorumThreshold
                    > uint256(ISettlement(settlement).getTotalVotingPowerFromValSetHeaderAt(epoch)) - nonSignersVotingPower
            ) {
                return false;
            }

            {
                bytes memory aggPublicKeyG1Serialized = abi.encode(
                    ISettlement(settlement).getExtraDataAt(
                        epoch, VERIFICATION_TYPE.getKey(keyTag, AGGREGATED_PUBLIC_KEY_G1_HASH)
                    )
                );
                bytes32 messageHash;
                BN254.G1Point calldata signatureG1;
                BN254.G2Point calldata aggKeyG2;
                assembly ("memory-safe") {
                    messageHash := mload(add(message, 32))
                    signatureG1 := proof.offset
                    aggKeyG2 := add(proof.offset, 64)
                }
                return SigBlsBn254.verify(
                    aggPublicKeyG1Serialized.deserialize().unwrap().plus(nonSignersPublicKeyG1.negate()),
                    messageHash,
                    signatureG1,
                    aggKeyG2
                );
            }
        }
    }
}
