// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEpochManager} from "./IEpochManager.sol";
import {INetworkManager} from "../../modules/base/INetworkManager.sol";

import {Checkpoints} from "../../../libraries/structs/Checkpoints.sol";
import {PersistentSet} from "../../../libraries/structs/PersistentSet.sol";

interface IValSetDriver {
    /**
     * @notice Reverts when the cross-chain address with the same chain ID is already added.
     */
    error ValSetDriver_ChainAlreadyAdded();

    /**
     * @notice Reverts when the cross-chain address is either zero or has zero chain ID.
     */
    error ValSetDriver_InvalidCrossChainAddress();

    /**
     * @notice Reverts when the max validators count is zero.
     */
    error ValSetDriver_InvalidMaxValidatorsCount();

    /**
     * @notice Reverts when the quorum threshold is greater than the maximum quorum threshold.
     * @dev The maximum quorum threshold is 1e18 = 100%.
     */
    error ValSetDriver_InvalidQuorumThreshold();

    /**
     * @notice Reverts when the quorum threshold with the same key tag is already added.
     */
    error ValSetDriver_KeyTagAlreadyAdded();

    /**
     * @notice Reverts when the subject is not added but was tried to be removed.
     */
    error ValSetDriver_NotAdded();

    /**
     * @notice The storage of the ValSetDriver contract.
     * @param _isVotingPowerProviderChainAdded The mapping from the chain ID to the voting power provider chain added status.
     * @param _votingPowerProviders The set of the voting power providers.
     * @param _keysProvider The checkpoint of the keys provider.
     * @param _isReplicaChainAdded The mapping from the chain ID to the replica chain added status.
     * @param _replicas The set of the replicas.
     * @param _verificationType The checkpoint of the verification type.
     * @param _maxVotingPower The checkpoint of the max voting power.
     * @param _minInclusionVotingPower The checkpoint of the min inclusion voting power.
     * @param _maxValidatorsCount The checkpoint of the max validators count.
     * @param _requiredKeyTags The checkpoint of the required key tags.
     * @param _requiredHeaderKeyTag The checkpoint of the required header key tag.
     * @param _isQuorumThresholdKeyTagAdded The mapping from the key tag to the quorum threshold key tag added status.
     * @param _quorumThresholds The set of the quorum thresholds.
     * @custom:storage-location erc7201:symbiotic.storage.ValSetDriver
     */
    struct ValSetDriverStorage {
        mapping(uint64 chainId => bool isAdded) _isVotingPowerProviderChainAdded;
        PersistentSet.Bytes32Set _votingPowerProviders;
        Checkpoints.Trace256 _keysProvider;
        mapping(uint64 chainId => bool isAdded) _isReplicaChainAdded;
        PersistentSet.Bytes32Set _replicas;
        Checkpoints.Trace208 _verificationType;
        Checkpoints.Trace256 _maxVotingPower;
        Checkpoints.Trace256 _minInclusionVotingPower;
        Checkpoints.Trace208 _maxValidatorsCount;
        Checkpoints.Trace208 _requiredKeyTags;
        Checkpoints.Trace208 _requiredHeaderKeyTag;
        mapping(uint8 keyTag => bool isAdded) _isQuorumThresholdKeyTagAdded;
        PersistentSet.Bytes32Set _quorumThresholds;
    }

    /**
     * @notice The parameters for the initialization of the ValSetDriver contract.
     * @param networkManagerInitParams The parameters for the initialization of the NetworkManager contract.
     * @param epochManagerInitParams The parameters for the initialization of the EpochManager contract.
     * @param votingPowerProviders The voting power providers.
     * @param keysProvider The keys provider.
     * @param replicas The replicas.
     * @param verificationType The verification type.
     * @param maxVotingPower The max voting power.
     * @param minInclusionVotingPower The min inclusion voting power.
     * @param maxValidatorsCount The max validators count.
     * @param requiredKeyTags The required key tags.
     * @param requiredHeaderKeyTag The required header key tag.
     * @param quorumThresholds The quorum thresholds.
     */
    struct ValSetDriverInitParams {
        INetworkManager.NetworkManagerInitParams networkManagerInitParams;
        IEpochManager.EpochManagerInitParams epochManagerInitParams;
        CrossChainAddress[] votingPowerProviders;
        CrossChainAddress keysProvider;
        CrossChainAddress[] replicas;
        uint32 verificationType;
        uint256 maxVotingPower;
        uint256 minInclusionVotingPower;
        uint208 maxValidatorsCount;
        uint8[] requiredKeyTags;
        uint8 requiredHeaderKeyTag;
        QuorumThreshold[] quorumThresholds;
    }

    /**
     * @notice The cross-chain address.
     * @param chainId The chain ID.
     * @param addr The address.
     */
    struct CrossChainAddress {
        uint64 chainId;
        address addr;
    }

    /**
     * @notice The quorum threshold.
     * @param keyTag The key tag.
     * @param quorumThreshold The quorum threshold (percentage).
     */
    struct QuorumThreshold {
        uint8 keyTag;
        uint248 quorumThreshold;
    }

    /**
     * @notice The configuration.
     * @param votingPowerProviders The voting power providers.
     * @param keysProvider The keys provider.
     * @param replicas The replicas.
     * @param verificationType The verification type.
     * @param maxVotingPower The max voting power.
     * @param minInclusionVotingPower The min inclusion voting power.
     * @param maxValidatorsCount The max validators count.
     * @param requiredKeyTags The required key tags.
     * @param requiredHeaderKeyTag The required header key tag.
     * @param quorumThresholds The quorum thresholds.
     */
    struct Config {
        CrossChainAddress[] votingPowerProviders;
        CrossChainAddress keysProvider;
        CrossChainAddress[] replicas;
        uint32 verificationType;
        uint256 maxVotingPower;
        uint256 minInclusionVotingPower;
        uint208 maxValidatorsCount;
        uint8[] requiredKeyTags;
        uint8 requiredHeaderKeyTag;
        QuorumThreshold[] quorumThresholds;
    }

    /**
     * @notice Emitted when the voting power provider is added.
     * @param votingPowerProvider The voting power provider.
     */
    event AddVotingPowerProvider(CrossChainAddress votingPowerProvider);

    /**
     * @notice Emitted when the voting power provider is removed.
     * @param votingPowerProvider The voting power provider.
     */
    event RemoveVotingPowerProvider(CrossChainAddress votingPowerProvider);

    /**
     * @notice Emitted when the keys provider is set.
     * @param keysProvider The keys provider.
     */
    event SetKeysProvider(CrossChainAddress keysProvider);

    /**
     * @notice Emitted when the replica is added.
     * @param replica The replica.
     */
    event AddReplica(CrossChainAddress replica);

    /**
     * @notice Emitted when the replica is removed.
     * @param replica The replica.
     */
    event RemoveReplica(CrossChainAddress replica);

    /**
     * @notice Emitted when the verification type is set.
     * @param verificationType The verification type.
     */
    event SetVerificationType(uint32 verificationType);

    /**
     * @notice Emitted when the max voting power is set.
     * @param maxVotingPower The max voting power.
     */
    event SetMaxVotingPower(uint256 maxVotingPower);

    /**
     * @notice Emitted when the min inclusion voting power is set.
     * @param minInclusionVotingPower The min inclusion voting power.
     */
    event SetMinInclusionVotingPower(uint256 minInclusionVotingPower);

    /**
     * @notice Emitted when the max validators count is set.
     * @param maxValidatorsCount The max validators count.
     */
    event SetMaxValidatorsCount(uint208 maxValidatorsCount);

    /**
     * @notice Emitted when the required key tags are set.
     * @param requiredKeyTags The required key tags.
     */
    event SetRequiredKeyTags(uint8[] requiredKeyTags);

    /**
     * @notice Emitted when the required header key tag is set.
     * @param requiredHeaderKeyTag The required header key tag.
     */
    event SetRequiredHeaderKeyTag(uint8 requiredHeaderKeyTag);

    /**
     * @notice Emitted when the quorum threshold is added.
     * @param quorumThreshold The quorum threshold.
     */
    event AddQuorumThreshold(QuorumThreshold quorumThreshold);

    /**
     * @notice Emitted when the quorum threshold is removed.
     * @param quorumThreshold The quorum threshold.
     */
    event RemoveQuorumThreshold(QuorumThreshold quorumThreshold);

    /**
     * @notice Returns the maximum quorum threshold.
     * @return The maximum quorum threshold.
     * @dev The maximum quorum threshold is 1e18 = 100%.
     */
    function MAX_QUORUM_THRESHOLD() external view returns (uint248);

    /**
     * @notice Returns if the voting power provider is registered at the given timestamp.
     * @param votingPowerProvider The voting power provider.
     * @param timestamp The timestamp.
     * @return If the voting power provider is registered at the given timestamp.
     */
    function isVotingPowerProviderRegisteredAt(
        CrossChainAddress memory votingPowerProvider,
        uint48 timestamp
    ) external view returns (bool);

    /**
     * @notice Returns if the voting power provider is registered.
     * @param votingPowerProvider The voting power provider.
     * @return If the voting power provider is registered.
     */
    function isVotingPowerProviderRegistered(
        CrossChainAddress memory votingPowerProvider
    ) external view returns (bool);

    /**
     * @notice Returns the voting power providers at the given timestamp.
     * @param timestamp The timestamp.
     * @return The voting power providers at the given timestamp.
     */
    function getVotingPowerProvidersAt(
        uint48 timestamp
    ) external view returns (CrossChainAddress[] memory);

    /**
     * @notice Returns the voting power providers.
     * @return The voting power providers.
     */
    function getVotingPowerProviders() external view returns (CrossChainAddress[] memory);

    /**
     * @notice Returns the keys provider at the given timestamp.
     * @param timestamp The timestamp.
     * @return The keys provider at the given timestamp.
     */
    function getKeysProviderAt(
        uint48 timestamp
    ) external view returns (CrossChainAddress memory);

    /**
     * @notice Returns the keys provider.
     * @return The keys provider.
     */
    function getKeysProvider() external view returns (CrossChainAddress memory);

    /**
     * @notice Returns if the replica is registered at the given timestamp.
     * @param replica The replica.
     * @param timestamp The timestamp.
     * @return If the replica is registered at the given timestamp.
     */
    function isReplicaRegisteredAt(CrossChainAddress memory replica, uint48 timestamp) external view returns (bool);

    /**
     * @notice Returns if the replica is registered.
     * @param replica The replica.
     * @return If the replica is registered.
     */
    function isReplicaRegistered(
        CrossChainAddress memory replica
    ) external view returns (bool);

    /**
     * @notice Returns the replicas at the given timestamp.
     * @param timestamp The timestamp.
     * @return The replicas at the given timestamp.
     */
    function getReplicasAt(
        uint48 timestamp
    ) external view returns (CrossChainAddress[] memory);

    /**
     * @notice Returns the replicas.
     * @return The replicas.
     */
    function getReplicas() external view returns (CrossChainAddress[] memory);

    /**
     * @notice Returns the verification type at the given timestamp.
     * @param timestamp The timestamp.
     * @return The verification type at the given timestamp.
     */
    function getVerificationTypeAt(
        uint48 timestamp
    ) external view returns (uint32);

    /**
     * @notice Returns the verification type.
     * @return The verification type.
     */
    function getVerificationType() external view returns (uint32);

    /**
     * @notice Returns the max voting power at the given timestamp.
     * @param timestamp The timestamp.
     * @return The max voting power at the given timestamp.
     */
    function getMaxVotingPowerAt(
        uint48 timestamp
    ) external view returns (uint256);

    /**
     * @notice Returns the max voting power.
     * @return The max voting power.
     */
    function getMaxVotingPower() external view returns (uint256);

    /**
     * @notice Returns the min inclusion voting power at the given timestamp.
     * @param timestamp The timestamp.
     * @return The min inclusion voting power at the given timestamp.
     */
    function getMinInclusionVotingPowerAt(
        uint48 timestamp
    ) external view returns (uint256);

    /**
     * @notice Returns the min inclusion voting power.
     * @return The min inclusion voting power.
     */
    function getMinInclusionVotingPower() external view returns (uint256);

    /**
     * @notice Returns the max validators count at the given timestamp.
     * @param timestamp The timestamp.
     * @return The max validators count at the given timestamp.
     */
    function getMaxValidatorsCountAt(
        uint48 timestamp
    ) external view returns (uint208);

    /**
     * @notice Returns the max validators count.
     * @return The max validators count.
     */
    function getMaxValidatorsCount() external view returns (uint208);

    /**
     * @notice Returns the required key tags at the given timestamp.
     * @param timestamp The timestamp.
     * @return The required key tags at the given timestamp.
     */
    function getRequiredKeyTagsAt(
        uint48 timestamp
    ) external view returns (uint8[] memory);

    /**
     * @notice Returns the required key tags.
     * @return The required key tags.
     */
    function getRequiredKeyTags() external view returns (uint8[] memory);

    /**
     * @notice Returns the required header key tag at the given timestamp.
     * @param timestamp The timestamp.
     * @return The required header key tag at the given timestamp.
     */
    function getRequiredHeaderKeyTagAt(
        uint48 timestamp
    ) external view returns (uint8);

    /**
     * @notice Returns the required header key tag.
     * @return The required header key tag.
     */
    function getRequiredHeaderKeyTag() external view returns (uint8);

    /**
     * @notice Returns if the quorum threshold is registered at the given timestamp.
     * @param quorumThreshold The quorum threshold.
     * @param timestamp The timestamp.
     * @return If the quorum threshold is registered at the given timestamp.
     */
    function isQuorumThresholdRegisteredAt(
        QuorumThreshold memory quorumThreshold,
        uint48 timestamp
    ) external view returns (bool);

    /**
     * @notice Returns if the quorum threshold is registered.
     * @param quorumThreshold The quorum threshold.
     * @return If the quorum threshold is registered.
     */
    function isQuorumThresholdRegistered(
        QuorumThreshold memory quorumThreshold
    ) external view returns (bool);

    /**
     * @notice Returns the quorum thresholds at the given timestamp.
     * @param timestamp The timestamp.
     * @return The quorum thresholds at the given timestamp.
     */
    function getQuorumThresholdsAt(
        uint48 timestamp
    ) external view returns (QuorumThreshold[] memory);

    /**
     * @notice Returns the quorum thresholds.
     * @return The quorum thresholds.
     */
    function getQuorumThresholds() external view returns (QuorumThreshold[] memory);

    /**
     * @notice Returns the configuration at the given timestamp.
     * @param timestamp The timestamp.
     * @return The configuration at the given timestamp.
     */
    function getConfigAt(
        uint48 timestamp
    ) external view returns (Config memory);

    /**
     * @notice Returns the configuration.
     * @return The configuration.
     */
    function getConfig() external view returns (Config memory);

    /**
     * @notice Adds a voting power provider.
     * @param votingPowerProvider The voting power provider.
     * @dev The caller must have the needed permission.
     */
    function addVotingPowerProvider(
        CrossChainAddress memory votingPowerProvider
    ) external;

    /**
     * @notice Removes a voting power provider.
     * @param votingPowerProvider The voting power provider.
     * @dev The caller must have the needed permission.
     */
    function removeVotingPowerProvider(
        CrossChainAddress memory votingPowerProvider
    ) external;

    /**
     * @notice Sets the keys provider.
     * @param keysProvider The keys provider.
     * @dev The caller must have the needed permission.
     */
    function setKeysProvider(
        CrossChainAddress memory keysProvider
    ) external;

    /**
     * @notice Adds a replica.
     * @param replica The replica.
     * @dev The caller must have the needed permission.
     */
    function addReplica(
        CrossChainAddress memory replica
    ) external;

    /**
     * @notice Removes a replica.
     * @param replica The replica.
     * @dev The caller must have the needed permission.
     */
    function removeReplica(
        CrossChainAddress memory replica
    ) external;

    /**
     * @notice Sets the verification type.
     * @param verificationType The verification type.
     * @dev The caller must have the needed permission.
     */
    function setVerificationType(
        uint32 verificationType
    ) external;

    /**
     * @notice Sets the max voting power.
     * @param maxVotingPower The max voting power.
     * @dev The caller must have the needed permission.
     */
    function setMaxVotingPower(
        uint256 maxVotingPower
    ) external;

    /**
     * @notice Sets the min inclusion voting power.
     * @param minInclusionVotingPower The min inclusion voting power.
     * @dev The caller must have the needed permission.
     */
    function setMinInclusionVotingPower(
        uint256 minInclusionVotingPower
    ) external;

    /**
     * @notice Sets the max validators count.
     * @param maxValidatorsCount The max validators count.
     * @dev The caller must have the needed permission.
     */
    function setMaxValidatorsCount(
        uint208 maxValidatorsCount
    ) external;

    /**
     * @notice Sets the required key tags.
     * @param requiredKeyTags The required key tags.
     * @dev The caller must have the needed permission.
     */
    function setRequiredKeyTags(
        uint8[] memory requiredKeyTags
    ) external;

    /**
     * @notice Sets the required header key tag.
     * @param requiredHeaderKeyTag The required header key tag.
     * @dev The caller must have the needed permission.
     */
    function setRequiredHeaderKeyTag(
        uint8 requiredHeaderKeyTag
    ) external;

    /**
     * @notice Adds a quorum threshold.
     * @param quorumThreshold The quorum threshold.
     * @dev The caller must have the needed permission.
     */
    function addQuorumThreshold(
        QuorumThreshold memory quorumThreshold
    ) external;

    /**
     * @notice Removes a quorum threshold.
     * @param quorumThreshold The quorum threshold.
     * @dev The caller must have the needed permission.
     */
    function removeQuorumThreshold(
        QuorumThreshold memory quorumThreshold
    ) external;
}
