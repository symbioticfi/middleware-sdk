// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {NetworkManager} from "../base/NetworkManager.sol";
import {OzEIP712} from "../base/OzEIP712.sol";
import {PermissionManager} from "../base/PermissionManager.sol";

import {Checkpoints} from "../../libraries/structs/Checkpoints.sol";

import {ISettlement} from "../../interfaces/modules/settlement/ISettlement.sol";
import {ISigVerifier} from "../../interfaces/modules/settlement/sig-verifiers/ISigVerifier.sol";

/**
 * @title Settlement
 * @notice Contract for processing the validator sets through epochs and allowing verifying their attestations on-chain.
 */
abstract contract Settlement is NetworkManager, OzEIP712, PermissionManager, ISettlement {
    using Checkpoints for Checkpoints.Trace208;

    /**
     * @inheritdoc ISettlement
     */
    uint8 public constant VALIDATOR_SET_VERSION = 1;

    bytes32 private constant VALSET_HEADER_COMMIT_TYPEHASH =
        keccak256("ValSetHeaderCommit(bytes32 subnetwork,uint48 epoch,bytes32 headerHash,bytes32 extraDataHash)");

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.Settlement")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SettlementStorageLocation =
        0xad58d27706f0faa4634000571d7d9c19a0123d182a06ad775cbe8a9c22f64400;

    function _getSettlementStorage() internal pure returns (SettlementStorage storage $) {
        bytes32 location = SettlementStorageLocation;
        assembly {
            $.slot := location
        }
    }

    function __Settlement_init(
        SettlementInitParams memory settlementInitParams
    ) internal virtual onlyInitializing {
        __NetworkManager_init(settlementInitParams.networkManagerInitParams);
        __OzEIP712_init(settlementInitParams.ozEip712InitParams);

        SettlementStorage storage $ = _getSettlementStorage();

        if (settlementInitParams.sigVerifier == address(0)) {
            revert Settlement_InvalidSigVerifier();
        }

        $._sigVerifier.push(0, uint160(settlementInitParams.sigVerifier));
        emit InitSigVerifier(settlementInitParams.sigVerifier);
    }

    /**
     * @inheritdoc ISettlement
     */
    function getSigVerifierAt(uint48 epoch, bytes memory hint) public view virtual returns (address) {
        return address(uint160(_getSettlementStorage()._sigVerifier.upperLookupRecent(epoch, hint)));
    }

    /**
     * @inheritdoc ISettlement
     */
    function getSigVerifier() public view virtual returns (address) {
        return address(uint160(_getCurrentValue(_getSettlementStorage()._sigVerifier, getLastCommittedHeaderEpoch())));
    }

    /**
     * @inheritdoc ISettlement
     */
    function getLastCommittedHeaderEpoch() public view virtual returns (uint48) {
        return _getSettlementStorage()._lastCommittedHeaderEpoch;
    }

    /**
     * @inheritdoc ISettlement
     */
    function isValSetHeaderCommittedAt(
        uint48 epoch
    ) public view virtual returns (bool) {
        return _getSettlementStorage()._valSetHeader[epoch].version > 0;
    }

    /**
     * @inheritdoc ISettlement
     */
    function getValSetHeaderHashAt(
        uint48 epoch
    ) public view returns (bytes32) {
        return keccak256(abi.encode(getValSetHeaderAt(epoch)));
    }

    /**
     * @inheritdoc ISettlement
     */
    function getValSetHeaderHash() public view returns (bytes32) {
        return getValSetHeaderHashAt(getLastCommittedHeaderEpoch());
    }

    /**
     * @inheritdoc ISettlement
     */
    function getValSetHeaderAt(
        uint48 epoch
    ) public view virtual returns (ValSetHeader memory) {
        return _getSettlementStorage()._valSetHeader[epoch];
    }

    /**
     * @inheritdoc ISettlement
     */
    function getValSetHeader() public view virtual returns (ValSetHeader memory header) {
        return getValSetHeaderAt(getLastCommittedHeaderEpoch());
    }

    /**
     * @inheritdoc ISettlement
     */
    function getVersionFromValSetHeaderAt(
        uint48 epoch
    ) public view virtual returns (uint8) {
        return _getSettlementStorage()._valSetHeader[epoch].version;
    }

    /**
     * @inheritdoc ISettlement
     */
    function getVersionFromValSetHeader() public view virtual returns (uint8) {
        return getVersionFromValSetHeaderAt(getLastCommittedHeaderEpoch());
    }

    /**
     * @inheritdoc ISettlement
     */
    function getRequiredKeyTagFromValSetHeaderAt(
        uint48 epoch
    ) public view virtual returns (uint8) {
        return _getSettlementStorage()._valSetHeader[epoch].requiredKeyTag;
    }

    /**
     * @inheritdoc ISettlement
     */
    function getRequiredKeyTagFromValSetHeader() public view virtual returns (uint8) {
        return getRequiredKeyTagFromValSetHeaderAt(getLastCommittedHeaderEpoch());
    }

    /**
     * @inheritdoc ISettlement
     */
    function getCaptureTimestampFromValSetHeaderAt(
        uint48 epoch
    ) public view virtual returns (uint48) {
        return _getSettlementStorage()._valSetHeader[epoch].captureTimestamp;
    }

    /**
     * @inheritdoc ISettlement
     */
    function getCaptureTimestampFromValSetHeader() public view virtual returns (uint48) {
        return getCaptureTimestampFromValSetHeaderAt(getLastCommittedHeaderEpoch());
    }

    /**
     * @inheritdoc ISettlement
     */
    function getQuorumThresholdFromValSetHeaderAt(
        uint48 epoch
    ) public view virtual returns (uint256) {
        return _getSettlementStorage()._valSetHeader[epoch].quorumThreshold;
    }

    /**
     * @inheritdoc ISettlement
     */
    function getQuorumThresholdFromValSetHeader() public view virtual returns (uint256) {
        return getQuorumThresholdFromValSetHeaderAt(getLastCommittedHeaderEpoch());
    }

    /**
     * @inheritdoc ISettlement
     */
    function getTotalVotingPowerFromValSetHeaderAt(
        uint48 epoch
    ) public view virtual returns (uint256) {
        return _getSettlementStorage()._valSetHeader[epoch].totalVotingPower;
    }

    /**
     * @inheritdoc ISettlement
     */
    function getTotalVotingPowerFromValSetHeader() public view virtual returns (uint256) {
        return getTotalVotingPowerFromValSetHeaderAt(getLastCommittedHeaderEpoch());
    }

    /**
     * @inheritdoc ISettlement
     */
    function getValidatorsSszMRootFromValSetHeaderAt(
        uint48 epoch
    ) public view virtual returns (bytes32) {
        return _getSettlementStorage()._valSetHeader[epoch].validatorsSszMRoot;
    }

    /**
     * @inheritdoc ISettlement
     */
    function getValidatorsSszMRootFromValSetHeader() public view virtual returns (bytes32) {
        return getValidatorsSszMRootFromValSetHeaderAt(getLastCommittedHeaderEpoch());
    }

    /**
     * @inheritdoc ISettlement
     */
    function getPreviousHeaderHashFromValSetHeaderAt(
        uint48 epoch
    ) public view virtual returns (bytes32) {
        return _getSettlementStorage()._valSetHeader[epoch].previousHeaderHash;
    }

    /**
     * @inheritdoc ISettlement
     */
    function getPreviousHeaderHashFromValSetHeader() public view virtual returns (bytes32) {
        return getPreviousHeaderHashFromValSetHeaderAt(getLastCommittedHeaderEpoch());
    }

    /**
     * @inheritdoc ISettlement
     */
    function getExtraDataAt(uint48 epoch, bytes32 key) public view virtual returns (bytes32) {
        return _getSettlementStorage()._extraData[epoch][key];
    }

    /**
     * @inheritdoc ISettlement
     */
    function getExtraData(
        bytes32 key
    ) public view virtual returns (bytes32) {
        return getExtraDataAt(getLastCommittedHeaderEpoch(), key);
    }

    /**
     * @inheritdoc ISettlement
     */
    function verifyQuorumSigAt(
        bytes memory message,
        uint8 keyTag,
        uint256 quorumThreshold,
        bytes calldata proof,
        uint48 epoch,
        bytes memory hint
    ) public view virtual returns (bool) {
        if (!isValSetHeaderCommittedAt(epoch)) {
            return false;
        }
        return ISigVerifier(getSigVerifierAt(epoch, hint)).verifyQuorumSig(
            address(this), epoch, message, keyTag, quorumThreshold, proof
        );
    }

    /**
     * @inheritdoc ISettlement
     */
    function verifyQuorumSig(
        bytes memory message,
        uint8 keyTag,
        uint256 quorumThreshold,
        bytes calldata proof
    ) public view virtual returns (bool) {
        uint48 lastCommittedHeaderEpoch = getLastCommittedHeaderEpoch();
        if (!isValSetHeaderCommittedAt(lastCommittedHeaderEpoch)) {
            return false;
        }
        return ISigVerifier(getSigVerifier()).verifyQuorumSig(
            address(this), lastCommittedHeaderEpoch, message, keyTag, quorumThreshold, proof
        );
    }

    /**
     * @inheritdoc ISettlement
     */
    function setSigVerifier(
        address sigVerifier
    ) public virtual checkPermission {
        if (sigVerifier == address(0)) {
            revert Settlement_InvalidSigVerifier();
        }
        _getSettlementStorage()._sigVerifier.push(getLastCommittedHeaderEpoch() + 1, uint160(sigVerifier));
        emit SetSigVerifier(sigVerifier);
    }

    /**
     * @inheritdoc ISettlement
     */
    function setGenesis(
        ValSetHeader calldata valSetHeader,
        ExtraData[] calldata extraData
    ) public virtual checkPermission {
        _setValSetHeader(valSetHeader, extraData);

        emit SetGenesis(valSetHeader, extraData);
    }

    /**
     * @inheritdoc ISettlement
     */
    function commitValSetHeader(
        ValSetHeader calldata header,
        ExtraData[] calldata extraData,
        bytes calldata proof
    ) public virtual {
        uint48 valSetEpoch = getLastCommittedHeaderEpoch();
        if (
            !verifyQuorumSig(
                abi.encode(
                    hashTypedDataV4CrossChain(
                        keccak256(
                            abi.encode(
                                VALSET_HEADER_COMMIT_TYPEHASH,
                                SUBNETWORK(),
                                header.epoch,
                                keccak256(abi.encode(header)),
                                keccak256(abi.encode(extraData))
                            )
                        )
                    )
                ),
                getRequiredKeyTagFromValSetHeaderAt(valSetEpoch),
                getQuorumThresholdFromValSetHeaderAt(valSetEpoch),
                proof
            )
        ) {
            revert Settlement_VerificationFailed();
        }

        _setValSetHeader(header, extraData);

        emit CommitValSetHeader(header, extraData);
    }

    function _setValSetHeader(ValSetHeader calldata header, ExtraData[] calldata extraData) internal virtual {
        if (header.version != VALIDATOR_SET_VERSION) {
            revert Settlement_InvalidVersion();
        }

        uint48 lastCommittedHeaderEpoch = getLastCommittedHeaderEpoch();
        if (lastCommittedHeaderEpoch > 0) {
            if (header.epoch <= lastCommittedHeaderEpoch) {
                revert Settlement_InvalidEpoch();
            }
        } else if (header.epoch == 0 && isValSetHeaderCommittedAt(0)) {
            revert Settlement_ValSetHeaderAlreadyCommitted();
        }

        if (
            header.captureTimestamp <= getCaptureTimestampFromValSetHeaderAt(lastCommittedHeaderEpoch)
                || header.captureTimestamp >= block.timestamp
        ) {
            revert Settlement_InvalidCaptureTimestamp();
        }

        if (header.validatorsSszMRoot == bytes32(0)) {
            revert Settlement_InvalidValidatorsSszMRoot();
        }

        if (header.previousHeaderHash != getValSetHeaderHashAt(lastCommittedHeaderEpoch)) {
            revert Settlement_InvalidPreviousHeaderHash();
        }

        SettlementStorage storage $ = _getSettlementStorage();

        ValSetHeader storage headerStorage = $._valSetHeader[header.epoch];
        headerStorage.version = header.version;
        headerStorage.requiredKeyTag = header.requiredKeyTag;
        headerStorage.epoch = header.epoch;
        headerStorage.captureTimestamp = header.captureTimestamp;
        headerStorage.quorumThreshold = header.quorumThreshold;
        headerStorage.totalVotingPower = header.totalVotingPower;
        headerStorage.validatorsSszMRoot = header.validatorsSszMRoot;
        headerStorage.previousHeaderHash = header.previousHeaderHash;

        mapping(bytes32 key => bytes32 value) storage extraDataStorage = $._extraData[header.epoch];
        for (uint256 i; i < extraData.length; ++i) {
            if (extraDataStorage[extraData[i].key] != bytes32(0)) {
                revert Settlement_DuplicateExtraDataKey();
            }
            extraDataStorage[extraData[i].key] = extraData[i].value;
        }

        $._lastCommittedHeaderEpoch = header.epoch;
    }

    function _getCurrentValue(
        Checkpoints.Trace208 storage trace,
        uint48 currentTimepoint
    ) internal view virtual returns (uint208) {
        uint256 length = trace.length();
        Checkpoints.Checkpoint208 memory checkpoint = trace.at(uint32(length - 1));
        if (checkpoint._key <= currentTimepoint) {
            return checkpoint._value;
        }
        return trace.at(uint32(length - 2))._value;
    }
}
