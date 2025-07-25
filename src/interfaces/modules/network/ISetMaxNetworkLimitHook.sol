// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISetMaxNetworkLimitHook {
    /**
     * @notice Sets the maximum network limit for a delegator.
     * @param delegator The address of the delegator.
     * @param subnetworkId The identifier of the subnetwork.
     * @param maxNetworkLimit The maximum network limit.
     * @dev The caller must be the network's middleware.
     */
    function setMaxNetworkLimit(address delegator, uint96 subnetworkId, uint256 maxNetworkLimit) external;
}
