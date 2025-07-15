// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Checkpoints} from "../../../contracts/libraries/structs/Checkpoints.sol";

interface IEpochManager {
    /**
     * @notice Reverts when the epoch duration is zero.
     */
    error EpochManager_InvalidEpochDuration();

    /**
     * @notice Reverts when the initial epoch duration timestamp is less than the current timestamp.
     */
    error EpochManager_InvalidEpochDurationTimestamp();

    /**
     * @notice Reverts when the timestamp is too old.
     */
    error EpochManager_TooOldTimestamp();

    /**
     * @notice Reverts when the checkpoint is not found for the current time point.
     */
    error EpochManager_NoCheckpoint();

    /**
     * @notice The storage of the EpochManager contract.
     * @param _epochDurationDataByTimestamp The epoch duration data checkpointed by timestamps.
     * @param _epochDurationDataByIndex The epoch duration data checkpointed by epoch indexes.
     * @custom:storage-location erc7201:symbiotic.storage.EpochManager
     */
    struct EpochManagerStorage {
        Checkpoints.Trace208 _epochDurationDataByTimestamp;
        Checkpoints.Trace208 _epochDurationDataByIndex;
    }

    /**
     * @notice The parameters for the initialization of the EpochManager contract.
     * @param epochDuration The epoch duration.
     * @param epochDurationTimestamp The initial epoch duration timestamp.
     */
    struct EpochManagerInitParams {
        uint48 epochDuration;
        uint48 epochDurationTimestamp;
    }

    /**
     * @notice Emitted during the initialization of the EpochManager contract.
     * @param epochDuration The epoch duration.
     * @param epochDurationTimestamp The initial epoch duration timestamp.
     */
    event InitEpochDuration(uint48 epochDuration, uint48 epochDurationTimestamp);

    /**
     * @notice Emitted when the epoch duration is set.
     * @param epochDuration The epoch duration.
     * @dev The new duration will be "committed" only in the next epoch.
     */
    event SetEpochDuration(uint48 epochDuration);

    /**
     * @notice Returns the current epoch.
     * @return The current epoch.
     */
    function getCurrentEpoch() external view returns (uint48);

    /**
     * @notice Returns the current epoch duration.
     * @return The current epoch duration.
     */
    function getCurrentEpochDuration() external view returns (uint48);

    /**
     * @notice Returns the current epoch start.
     * @return The current epoch start.
     */
    function getCurrentEpochStart() external view returns (uint48);

    /**
     * @notice Returns the next epoch.
     * @return The next epoch.
     */
    function getNextEpoch() external view returns (uint48);

    /**
     * @notice Returns the next epoch duration.
     * @return The next epoch duration.
     */
    function getNextEpochDuration() external view returns (uint48);

    /**
     * @notice Returns the next epoch start.
     * @return The next epoch start.
     */
    function getNextEpochStart() external view returns (uint48);

    /**
     * @notice Returns the epoch index at the given timestamp.
     * @param timestamp The timestamp.
     * @param hint The hint to optimize the epoch index fetching.
     * @return The epoch index at the given timestamp.
     */
    function getEpochIndex(uint48 timestamp, bytes memory hint) external view returns (uint48);

    /**
     * @notice Returns the epoch duration of the given epoch.
     * @param epoch The epoch.
     * @param hint The hint to optimize the epoch duration fetching.
     * @return The epoch duration of the given epoch.
     */
    function getEpochDuration(uint48 epoch, bytes memory hint) external view returns (uint48);

    /**
     * @notice Returns the epoch start of the given epoch.
     * @param epoch The epoch.
     * @param hint The hint to optimize the epoch start fetching.
     * @return The epoch start of the given epoch.
     */
    function getEpochStart(uint48 epoch, bytes memory hint) external view returns (uint48);

    /**
     * @notice Sets the epoch duration.
     * @param epochDuration The epoch duration.
     * @dev The new duration will be "committed" only in the next epoch.
     *      The caller must have the needed permission.
     */
    function setEpochDuration(
        uint48 epochDuration
    ) external;
}
