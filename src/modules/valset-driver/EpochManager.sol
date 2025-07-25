// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {PermissionManager} from "../base/PermissionManager.sol";

import {Checkpoints} from "../../libraries/structs/Checkpoints.sol";

import {IEpochManager} from "../../interfaces/modules/valset-driver/IEpochManager.sol";

/**
 * @title EpochManager
 * @notice Contract for managing the epochs state machine.
 */
abstract contract EpochManager is PermissionManager, IEpochManager {
    using Checkpoints for Checkpoints.Trace208;

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.EpochManager")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant EpochManagerStorageLocation =
        0xab930e9b836b4d72502da14061937ab080936446173403910135ea983863d400;

    function _getEpochManagerStorage() internal pure returns (EpochManagerStorage storage $) {
        bytes32 location = EpochManagerStorageLocation;
        assembly {
            $.slot := location
        }
    }

    function __EpochManager_init(
        EpochManagerInitParams memory initParams
    ) internal virtual onlyInitializing {
        if (initParams.epochDurationTimestamp == 0) {
            initParams.epochDurationTimestamp = uint48(block.timestamp);
        } else if (initParams.epochDurationTimestamp < block.timestamp) {
            revert EpochManager_InvalidEpochDurationTimestamp();
        }
        _setEpochDuration(initParams.epochDuration, initParams.epochDurationTimestamp, 0);
        emit InitEpochDuration(initParams.epochDuration, initParams.epochDurationTimestamp);
    }

    /**
     * @inheritdoc IEpochManager
     */
    function getCurrentEpoch() public view virtual returns (uint48) {
        (uint48 epochDuration, uint48 epochDurationTimestamp, uint48 epochDurationIndex) =
            _getCurrentEpochDurationData();
        return epochDurationIndex + (uint48(block.timestamp) - epochDurationTimestamp) / epochDuration;
    }

    /**
     * @inheritdoc IEpochManager
     */
    function getCurrentEpochDuration() public view virtual returns (uint48 epochDuration) {
        (epochDuration,,) = _getCurrentEpochDurationData();
    }

    /**
     * @inheritdoc IEpochManager
     */
    function getCurrentEpochStart() public view virtual returns (uint48) {
        (uint48 epochDuration, uint48 epochDurationTimestamp, uint48 epochDurationIndex) =
            _getCurrentEpochDurationData();
        return epochDurationTimestamp + (getCurrentEpoch() - epochDurationIndex) * epochDuration;
    }

    /**
     * @inheritdoc IEpochManager
     */
    function getNextEpoch() public view virtual returns (uint48) {
        (, uint48 epochDurationTimestamp,) = _getFirstEpochDurationData();
        if (block.timestamp < epochDurationTimestamp) {
            return 0;
        }
        return getCurrentEpoch() + 1;
    }

    /**
     * @inheritdoc IEpochManager
     */
    function getNextEpochDuration() public view virtual returns (uint48) {
        (uint48 epochDuration, uint48 epochDurationTimestamp,) = _getFirstEpochDurationData();
        if (block.timestamp < epochDurationTimestamp) {
            return epochDuration;
        }
        (epochDuration,,) =
            _deserializeEpochDurationData(_getEpochManagerStorage()._epochDurationDataByTimestamp.latest());
        return epochDuration;
    }

    /**
     * @inheritdoc IEpochManager
     */
    function getNextEpochStart() public view virtual returns (uint48) {
        (, uint48 epochDurationTimestamp,) = _getFirstEpochDurationData();
        if (block.timestamp < epochDurationTimestamp) {
            return epochDurationTimestamp;
        }
        return getCurrentEpochStart() + getCurrentEpochDuration();
    }

    /**
     * @inheritdoc IEpochManager
     */
    function getEpochIndex(
        uint48 timestamp
    ) public view virtual returns (uint48) {
        (uint48 epochDuration, uint48 epochDurationTimestamp, uint48 epochDurationIndex) =
            _getEpochDurationDataByTimestamp(timestamp);
        if (epochDuration == 0) {
            revert EpochManager_TooOldTimestamp();
        }
        return epochDurationIndex + (timestamp - epochDurationTimestamp) / epochDuration;
    }

    /**
     * @inheritdoc IEpochManager
     */
    function getEpochDuration(
        uint48 epoch
    ) public view virtual returns (uint48 epochDuration) {
        (epochDuration,,) = _getEpochDurationDataByIndex(epoch);
    }

    /**
     * @inheritdoc IEpochManager
     */
    function getEpochStart(
        uint48 epoch
    ) public view virtual returns (uint48) {
        (uint48 epochDuration, uint48 epochDurationTimestamp, uint48 epochDurationIndex) =
            _getEpochDurationDataByIndex(epoch);
        return epochDurationTimestamp + (epoch - epochDurationIndex) * epochDuration;
    }

    /**
     * @inheritdoc IEpochManager
     */
    function setEpochDuration(
        uint48 epochDuration
    ) public virtual checkPermission {
        _setEpochDuration(epochDuration);
    }

    function _setEpochDuration(
        uint48 epochDuration
    ) internal virtual {
        _setEpochDuration(epochDuration, getNextEpochStart(), getNextEpoch());
        emit SetEpochDuration(epochDuration);
    }

    function _setEpochDuration(
        uint48 epochDuration,
        uint48 epochDurationTimestamp,
        uint48 epochDurationIndex
    ) internal virtual {
        if (epochDuration == 0) {
            revert EpochManager_InvalidEpochDuration();
        }
        _getEpochManagerStorage()._epochDurationDataByTimestamp.push(
            epochDurationTimestamp,
            _serializeEpochDurationData(epochDuration, epochDurationTimestamp, epochDurationIndex)
        );
        _getEpochManagerStorage()._epochDurationDataByIndex.push(
            epochDurationIndex, _serializeEpochDurationData(epochDuration, epochDurationTimestamp, epochDurationIndex)
        );
    }

    function _getEpochDurationDataByTimestamp(
        uint48 timestamp
    ) internal view virtual returns (uint48, uint48, uint48) {
        return _deserializeEpochDurationData(
            _getEpochManagerStorage()._epochDurationDataByTimestamp.upperLookupRecent(timestamp)
        );
    }

    function _getEpochDurationDataByIndex(
        uint48 index
    ) internal view virtual returns (uint48, uint48, uint48) {
        return
            _deserializeEpochDurationData(_getEpochManagerStorage()._epochDurationDataByIndex.upperLookupRecent(index));
    }

    function _getCurrentEpochDurationData() internal view virtual returns (uint48, uint48, uint48) {
        return _deserializeEpochDurationData(
            _getCurrentValue(_getEpochManagerStorage()._epochDurationDataByTimestamp, uint48(block.timestamp))
        );
    }

    function _getFirstEpochDurationData() internal view virtual returns (uint48, uint48, uint48) {
        return _deserializeEpochDurationData(_getEpochManagerStorage()._epochDurationDataByTimestamp.at(0)._value);
    }

    function _serializeEpochDurationData(
        uint48 epochDuration,
        uint48 epochDurationTimestamp,
        uint48 epochDurationIndex
    ) internal pure virtual returns (uint208) {
        return (uint208(epochDurationIndex) << 96) | (uint208(epochDurationTimestamp) << 48) | uint208(epochDuration);
    }

    function _deserializeEpochDurationData(
        uint208 epochDurationData
    ) internal pure virtual returns (uint48, uint48, uint48) {
        return (uint48(epochDurationData), uint48(epochDurationData >> 48), uint48(epochDurationData >> 96));
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
