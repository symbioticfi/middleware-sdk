// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {SigBlsBn254} from "../../../libraries/sigs/SigBlsBn254.sol";
import {BN254} from "../../../libraries/utils/BN254.sol";
import {KeyBlsBn254} from "../../../libraries/keys/KeyBlsBn254.sol";
import {ExtraDataStorageHelper} from "./libraries/ExtraDataStorageHelper.sol";
import {KEY_TYPE_BLS_BN254} from "../../../../interfaces/modules/key-registry/IKeyRegistry.sol";
import {KeyTags} from "../../../libraries/utils/KeyTags.sol";

import {ISigVerifier} from "../../../../interfaces/modules/settlement/sig-verifiers/ISigVerifier.sol";
import {ISettlement} from "../../../../interfaces/modules/settlement/ISettlement.sol";
import {ISigVerifierBlsBn254ZK} from
    "../../../../interfaces/modules/settlement/sig-verifiers/ISigVerifierBlsBn254ZK.sol";
import {IVerifier} from "../../../../interfaces/modules/settlement/sig-verifiers/zk/IVerifier.sol";

contract SigVerifierBlsBn254ZK is ISigVerifierBlsBn254ZK {
    using ExtraDataStorageHelper for uint32;
    using KeyTags for uint8;

    /**
     * @inheritdoc ISigVerifier
     */
    uint32 public constant VERIFICATION_TYPE = 0;

    /**
     * @inheritdoc ISigVerifierBlsBn254ZK
     */
    bytes32 public constant TOTAL_ACTIVE_VALIDATORS_HASH = keccak256("totalActiveValidators");

    /**
     * @inheritdoc ISigVerifierBlsBn254ZK
     */
    bytes32 public constant VALIDATOR_SET_HASH_MIMC_HASH = keccak256("validatorSetHashMimc");

    /**
     * @inheritdoc ISigVerifierBlsBn254ZK
     */
    address[] public verifiers;

    /**
     * @inheritdoc ISigVerifierBlsBn254ZK
     */
    uint256[] public maxValidators;

    constructor(address[] memory verifiers_, uint256[] memory maxValidators_) {
        uint256 length = verifiers_.length;
        if (length != maxValidators_.length) {
            revert SigVerifierBlsBn254ZK_InvalidLength();
        }
        if (length == 0) {
            revert SigVerifierBlsBn254ZK_InvalidLength();
        }
        for (uint256 i; i < length; ++i) {
            if (maxValidators_[i] == 0) {
                revert SigVerifierBlsBn254ZK_InvalidMaxValidators();
            }
            if (verifiers_[i] == address(0)) {
                revert SigVerifierBlsBn254ZK_InvalidVerifier();
            }
            if (i > 0 && maxValidators_[i - 1] >= maxValidators_[i]) {
                revert SigVerifierBlsBn254ZK_InvalidMaxValidatorsOrder();
            }
        }

        verifiers = verifiers_;
        maxValidators = maxValidators_;
    }

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
            revert SigVerifierBlsBn254ZK_UnsupportedKeyTag();
        }
        if (message.length != 32) {
            revert SigVerifierBlsBn254ZK_InvalidMessageLength();
        }

        // Proof Structure
        // 0 : 256 - ZK proof (uint256[8])
        // 256 : 320 - commitments (uint256[2])
        // 320 : 384 - commitmentPok (uint256[2])
        // 384 : 416 - voting power of signers (uint256)

        {
            uint256 proofOffset;
            assembly {
                proofOffset := proof.offset
            }
            if (proofOffset >= msg.data.length) {
                revert SigVerifierBlsBn254ZK_InvalidProofOffset();
            }
            if (proof.length != 416) {
                revert SigVerifierBlsBn254ZK_InvalidProofLength();
            }
        }
        uint256 totalActiveValidators = uint256(
            ISettlement(settlement).getExtraDataAt(epoch, VERIFICATION_TYPE.getKey(TOTAL_ACTIVE_VALIDATORS_HASH))
        );
        if (totalActiveValidators == 0) {
            return false;
        }

        uint256 signersVotingPower;
        assembly {
            signersVotingPower := calldataload(add(proof.offset, 384))
        }
        if (signersVotingPower < quorumThreshold) {
            return false;
        }

        uint256[8] calldata zkProof;
        uint256[2] calldata commitments;
        uint256[2] calldata commitmentPok;
        assembly {
            zkProof := add(proof.offset, 0)
            commitments := add(proof.offset, 256)
            commitmentPok := add(proof.offset, 320)
        }

        uint256 inputHash;
        {
            bytes32 validatorSetHash = ISettlement(settlement).getExtraDataAt(
                epoch, VERIFICATION_TYPE.getKey(keyTag, VALIDATOR_SET_HASH_MIMC_HASH)
            );
            BN254.G1Point memory messageG1 = BN254.hashToG1(abi.decode(message, (bytes32)));

            inputHash =
                uint256(keccak256(abi.encodePacked(validatorSetHash, signersVotingPower, messageG1.X, messageG1.Y)));
            inputHash &= 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }

        try IVerifier(_getVerifier(totalActiveValidators)).verifyProof(zkProof, commitments, commitmentPok, [inputHash])
        {
            return true;
        } catch {
            return false;
        }
    }

    function _getVerifier(
        uint256 totalActiveValidators
    ) internal view returns (address) {
        for (uint256 i; i < maxValidators.length; ++i) {
            if (totalActiveValidators <= maxValidators[i]) {
                return verifiers[i];
            }
        }
        revert SigVerifierBlsBn254ZK_InvalidTotalActiveValidators();
    }
}
