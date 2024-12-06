// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {CaptureTimestampManager} from "../../../managers/extendable/CaptureTimestampManager.sol";

/**
 * @title EpochCapture
 * @notice A middleware extension that captures timestamps based on epochs
 * @dev Implements CaptureTimestampManager with epoch-based timestamp capture
 * @dev Epochs are fixed time periods starting from a base timestamp
 */
abstract contract EpochCapture is CaptureTimestampManager {
    uint64 public constant EpochCapture_VERSION = 1;

    struct EpochCaptureStorage {
        uint48 startTimestamp;
        uint48 epochDuration;
    }

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.EpochCapture")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant EpochCaptureStorageLocation =
        0x4e241e104e7ef4df0fc8eb6aad7b0f201c6126c722652f1bd1305b6b75c86d00;

    function _getEpochCaptureStorage() internal pure returns (EpochCaptureStorage storage $) {
        bytes32 location = EpochCaptureStorageLocation;
        assembly {
            $.slot := location
        }
    }

    /* 
     * @notice initalizer of the Epochs contract.
     * @param epochDuration The duration of each epoch.
     */
    function __EpochCapture_init(
        uint48 epochDuration
    ) internal onlyInitializing {
        EpochCaptureStorage storage $ = _getEpochCaptureStorage();
        $.epochDuration = epochDuration;
        $.startTimestamp = _now();
    }

    /* 
     * @notice Returns the start timestamp for a given epoch.
     * @param epoch The epoch number.
     * @return The start timestamp.
     */
    function getEpochStart(
        uint48 epoch
    ) public view returns (uint48) {
        EpochCaptureStorage storage $ = _getEpochCaptureStorage();
        return $.startTimestamp + epoch * $.epochDuration;
    }

    /* 
     * @notice Returns the current epoch.
     * @return The current epoch.
     */
    function getCurrentEpoch() public view returns (uint48) {
        EpochCaptureStorage storage $ = _getEpochCaptureStorage();
        return (_now() - $.startTimestamp) / $.epochDuration;
    }

    /* 
     * @notice Returns the capture timestamp for the current epoch.
     * @return The capture timestamp.
     */
    function getCaptureTimestamp() public view override returns (uint48 timestamp) {
        return getEpochStart(getCurrentEpoch());
    }
}
