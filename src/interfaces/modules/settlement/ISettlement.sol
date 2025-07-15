// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {INetworkManager} from "../../modules/base/INetworkManager.sol";
import {IOzEIP712} from "../../modules/base/IOzEIP712.sol";

import {Checkpoints} from "../../../contracts/libraries/structs/Checkpoints.sol";

interface ISettlement {
    /**
     * @notice Reverts when the extra data key is duplicated.
     */
    error Settlement_DuplicateExtraDataKey();

    /**
     * @notice Reverts when the version to be committed is not the same as the version inside the contract.
     * @dev Can be triggered during the upgrades.
     */
    error Settlement_InvalidVersion();

    /**
     * @notice Reverts when the quorum signature verification fails.
     */
    error Settlement_VerificationFailed();

    /**
     * @notice Reverts when the validator set header is already committed for the proposed epoch.
     */
    error Settlement_ValSetHeaderAlreadyCommitted();

    /**
     * @notice Reverts when the proposed during the commit epoch is less than or equal to the latest committed one.
     */
    error Settlement_InvalidEpoch();

    /**
     * @notice Reverts when the capture timestamp is less than or equal to the capture timestamp of the latest committed header,
     *         or greater than or equal to the current timestamp.
     */
    error Settlement_InvalidCaptureTimestamp();

    /**
     * @notice Reverts when the new quorum signature verifier is zero.
     */
    error Settlement_InvalidSigVerifier();

    /**
     * @notice Reverts when the proposed previous header hash is not the same as the hash of the latest committed header.
     */
    error Settlement_InvalidPreviousHeaderHash();

    /**
     * @notice Reverts when the checkpoint is not found for the current time point.
     */
    error Settlement_NoCheckpoint();

    /**
     * @notice The storage of the Settlement contract.
     * @param _lastCommittedHeaderEpoch The epoch of the last committed header.
     * @param _sigVerifier The address of the quorum signature verifier.
     * @param _valSetHeader The mapping from the epoch to the validator set header.
     * @param _extraData The mapping from the epoch and the key to the extra data.
     * @custom:storage-location erc7201:symbiotic.storage.Settlement
     */
    struct SettlementStorage {
        uint48 _lastCommittedHeaderEpoch;
        Checkpoints.Trace208 _sigVerifier;
        mapping(uint48 epoch => ValSetHeader) _valSetHeader;
        mapping(uint48 epoch => mapping(bytes32 key => bytes32 value)) _extraData;
    }

    /**
     * @notice The parameters for the initialization of the Settlement contract.
     * @param networkManagerInitParams The parameters for the initialization of the NetworkManager.
     * @param ozEip712InitParams The parameters for the initialization of the OzEIP712.
     * @param sigVerifier The address of the quorum signature verifier.
     */
    struct SettlementInitParams {
        INetworkManager.NetworkManagerInitParams networkManagerInitParams;
        IOzEIP712.OzEIP712InitParams ozEip712InitParams;
        address sigVerifier;
    }

    /**
     * @notice The validator set header.
     * @param version The version of the validator set header.
     * @param requiredKeyTag The required key tag for the validator set header using which the next header will be committed.
     * @param epoch The epoch of the validator set.
     * @param captureTimestamp The capture timestamp of the validator set.
     * @param quorumThreshold The quorum threshold of the validator set header which will need to be reached to commit the next header.
     * @param validatorsSszMRoot The validator set SSZ root.
     * @param previousHeaderHash The previous header hash.
     */
    struct ValSetHeader {
        uint8 version;
        uint8 requiredKeyTag;
        uint48 epoch;
        uint48 captureTimestamp;
        uint256 quorumThreshold;
        bytes32 validatorsSszMRoot;
        bytes32 previousHeaderHash;
    }

    /**
     * @notice The extra data.
     * @param key The key to store the extra data with.
     * @param value The value of the extra data.
     * @dev This key-value storage is fully flexible and can be used to store any data (e.g., verification-specific aggregated data).
     */
    struct ExtraData {
        bytes32 key;
        bytes32 value;
    }

    /**
     * @notice Emitted during the Settlement initialization.
     * @param sigVerifier The address of the quorum signature verifier.
     */
    event InitSigVerifier(address sigVerifier);

    /**
     * @notice Emitted when the quorum signature verifier is set.
     * @param sigVerifier The address of the quorum signature verifier.
     * @dev The new verifier will be "committed" only in the next epoch.
     */
    event SetSigVerifier(address sigVerifier);

    /**
     * @notice Emitted when the genesis is set.
     * @param valSetHeader The validator set header.
     * @param extraData The extra data.
     */
    event SetGenesis(ValSetHeader valSetHeader, ExtraData[] extraData);

    /**
     * @notice Emitted when the validator set header is committed.
     * @param valSetHeader The validator set header.
     * @param extraData The extra data.
     */
    event CommitValSetHeader(ValSetHeader valSetHeader, ExtraData[] extraData);

    /**
     * @notice Returns the version of the validator set.
     * @return The version of the validator set.
     */
    function VALIDATOR_SET_VERSION() external view returns (uint8);

    /**
     * @notice Returns the quorum signature verifier at the given epoch.
     * @param epoch The epoch.
     * @param hint The hint for the quorum signature verifier.
     * @return The quorum signature verifier at the given epoch.
     */
    function getSigVerifierAt(uint48 epoch, bytes memory hint) external view returns (address);

    /**
     * @notice Returns the quorum signature verifier.
     * @return The quorum signature verifier.
     */
    function getSigVerifier() external view returns (address);

    /**
     * @notice Returns the epoch of the last committed validator set header.
     * @return The epoch of the last committed validator set header.
     */
    function getLastCommittedHeaderEpoch() external view returns (uint48);

    /**
     * @notice Returns if the validator set header is committed at the given epoch.
     * @param epoch The epoch.
     * @return True if the validator set header is committed at the given epoch.
     */
    function isValSetHeaderCommittedAt(
        uint48 epoch
    ) external view returns (bool);

    /**
     * @notice Returns the hash of the validator set header at the given epoch.
     * @param epoch The epoch.
     * @return The hash of the validator set header at the given epoch.
     */
    function getValSetHeaderHashAt(
        uint48 epoch
    ) external view returns (bytes32);

    /**
     * @notice Returns the hash of the last committed validator set header.
     * @return The hash of the last committed validator set header.
     */
    function getValSetHeaderHash() external view returns (bytes32);

    /**
     * @notice Returns the validator set header at the given epoch.
     * @param epoch The epoch.
     * @return The validator set header at the given epoch.
     */
    function getValSetHeaderAt(
        uint48 epoch
    ) external view returns (ValSetHeader memory);

    /**
     * @notice Returns the last committed validator set header.
     * @return The last committed validator set header.
     */
    function getValSetHeader() external view returns (ValSetHeader memory);

    /**
     * @notice Returns the version of the validator set header at the given epoch.
     * @param epoch The epoch.
     * @return The version of the validator set header at the given epoch.
     */
    function getVersionFromValSetHeaderAt(
        uint48 epoch
    ) external view returns (uint8);

    /**
     * @notice Returns the version from the last committed validator set header.
     * @return The version from the last committed validator set header.
     */
    function getVersionFromValSetHeader() external view returns (uint8);

    /**
     * @notice Returns the required key tag from the validator set header at the given epoch.
     * @param epoch The epoch.
     * @return The required key tag from the validator set header at the given epoch.
     */
    function getRequiredKeyTagFromValSetHeaderAt(
        uint48 epoch
    ) external view returns (uint8);

    /**
     * @notice Returns the required key tag from the last committed validator set header.
     * @return The required key tag from the last committed validator set header.
     */
    function getRequiredKeyTagFromValSetHeader() external view returns (uint8);

    /**
     * @notice Returns the capture timestamp from the validator set header at the given epoch.
     * @param epoch The epoch.
     * @return The capture timestamp from the validator set header at the given epoch.
     */
    function getCaptureTimestampFromValSetHeaderAt(
        uint48 epoch
    ) external view returns (uint48);

    /**
     * @notice Returns the capture timestamp from the last committed validator set header.
     * @return The capture timestamp from the last committed validator set header.
     */
    function getCaptureTimestampFromValSetHeader() external view returns (uint48);

    /**
     * @notice Returns the quorum threshold from the validator set header at the given epoch.
     * @param epoch The epoch.
     * @return The quorum threshold from the validator set header at the given epoch.
     */
    function getQuorumThresholdFromValSetHeaderAt(
        uint48 epoch
    ) external view returns (uint256);

    /**
     * @notice Returns the quorum threshold from the last committed validator set header.
     * @return The quorum threshold from the last committed validator set header.
     */
    function getQuorumThresholdFromValSetHeader() external view returns (uint256);

    /**
     * @notice Returns the validator set SSZ root from the validator set header at the given epoch.
     * @param epoch The epoch.
     * @return The validator set SSZ root from the validator set header at the given epoch.
     */
    function getValidatorsSszMRootFromValSetHeaderAt(
        uint48 epoch
    ) external view returns (bytes32);

    /**
     * @notice Returns the validator set SSZ root from the last committed validator set header.
     * @return The validator set SSZ root from the last committed validator set header.
     */
    function getValidatorsSszMRootFromValSetHeader() external view returns (bytes32);

    /**
     * @notice Returns the previous header hash from the validator set header at the given epoch.
     * @param epoch The epoch.
     * @return The previous header hash from the validator set header at the given epoch.
     */
    function getPreviousHeaderHashFromValSetHeaderAt(
        uint48 epoch
    ) external view returns (bytes32);

    /**
     * @notice Returns the previous header hash from the last committed validator set header.
     * @return The previous header hash from the last committed validator set header.
     */
    function getPreviousHeaderHashFromValSetHeader() external view returns (bytes32);

    /**
     * @notice Returns the extra data at the given epoch for a certain key.
     * @param epoch The epoch.
     * @param key The key.
     * @return The extra data at the given epoch for a certain key.
     */
    function getExtraDataAt(uint48 epoch, bytes32 key) external view returns (bytes32);

    /**
     * @notice Returns the extra data from the last committed epoch for a certain key.
     * @param key The key.
     * @return The extra data from the last committed epoch for a certain key.
     */
    function getExtraData(
        bytes32 key
    ) external view returns (bytes32);

    /**
     * @notice Returns the result of the quorum signature verification for the given message at the given epoch.
     * @param message The message to verify.
     * @param keyTag The key tag to use for the quorum signature verification.
     * @param quorumThreshold The quorum threshold to require for the quorum signature verification.
     * @param proof The proof to verify the quorum signature.
     * @param epoch The epoch.
     * @param hint The hint to optimize the signature verifier fetching.
     * @return The result of the quorum signature verification for the given message at the given epoch.
     */
    function verifyQuorumSigAt(
        bytes memory message,
        uint8 keyTag,
        uint256 quorumThreshold,
        bytes calldata proof,
        uint48 epoch,
        bytes memory hint
    ) external view returns (bool);

    /**
     * @notice Returns the result of the quorum signature verification for the given message using the last committed validator set header.
     * @param message The message to verify.
     * @param keyTag The key tag to use for the quorum signature verification.
     * @param quorumThreshold The quorum threshold to require for the quorum signature verification.
     * @param proof The proof to verify the quorum signature.
     * @return The result of the quorum signature verification for the given message using the last committed validator set header.
     */
    function verifyQuorumSig(
        bytes memory message,
        uint8 keyTag,
        uint256 quorumThreshold,
        bytes calldata proof
    ) external view returns (bool);

    /**
     * @notice Sets the quorum signature verifier.
     * @param sigVerifier The address of the quorum signature verifier.
     * @dev The new verifier will be "committed" only in the next epoch.
     * @dev The caller must have the needed permission.
     */
    function setSigVerifier(
        address sigVerifier
    ) external;

    /**
     * @notice Sets the genesis validator set header and its extra data.
     * @param valSetHeader The validator set header.
     * @param extraData The extra data.
     * @dev The caller must have the needed permission.
     */
    function setGenesis(ValSetHeader calldata valSetHeader, ExtraData[] calldata extraData) external;

    /**
     * @notice Commits the validator set header and its extra data.
     * @param header The validator set header.
     * @param extraData The extra data.
     * @param proof The proof to verify the quorum signature.
     * @dev The caller can be anyone, the call is validated by verification of the validator set's decision.
     */
    function commitValSetHeader(
        ValSetHeader calldata header,
        ExtraData[] calldata extraData,
        bytes calldata proof
    ) external;
}
