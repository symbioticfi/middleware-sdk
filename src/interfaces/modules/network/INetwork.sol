// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISetMaxNetworkLimitHook} from "./ISetMaxNetworkLimitHook.sol";

interface INetwork is ISetMaxNetworkLimitHook {
    /**
     * @notice Reverts when the calldata length is invalid.
     */
    error InvalidDataLength();

    /**
     * @notice Reverts when the new delay is non-zero but disabled.
     */
    error InvalidNewDelay();

    /**
     * @notice Reverts when the "recursive" delay update is attempted.
     */
    error InvalidTargetAndSelector();

    /**
     * @notice Reverts when the caller is not the network's middleware.
     */
    error NotMiddleware();

    /**
     * @notice The storage of the Network contract.
     * @param _minDelays The mapping from the id (derived from the target and the selector) to the minimum delay.
     * @param _isMinDelayEnabled The mapping from the id (derived from the target and the selector) to the minimum delay enabled status.
     * @param _name The name of the network.
     * @param _metadataURI The metadata URI of the network.
     * @custom:storage-location erc7201:symbiotic.storage.Network
     */
    struct NetworkStorage {
        mapping(bytes32 id => uint256 minDelay) _minDelays;
        mapping(bytes32 => bool) _isMinDelayEnabled;
        string _name;
        string _metadataURI;
    }

    /**
     * @notice The parameters for the initialization of the Network contract.
     * @param globalMinDelay The global minimum delay.
     * @param delayParams The delays.
     * @param proposers The proposers.
     * @param executors The executors.
     * @param name The name of the network.
     * @param metadataURI The metadata URI of the network.
     * @param defaultAdminRoleHolder The address of the default admin role holder.
     * @param nameUpdateRoleHolder The address of the name update role holder.
     * @param metadataURIUpdateRoleHolder The address of the metadata URI update role holder.
     */
    struct NetworkInitParams {
        uint256 globalMinDelay;
        DelayParams[] delayParams;
        address[] proposers;
        address[] executors;
        string name;
        string metadataURI;
        address defaultAdminRoleHolder;
        address nameUpdateRoleHolder;
        address metadataURIUpdateRoleHolder;
    }

    /**
     * @notice The delay parameters.
     * @param target The target address the delay is for.
     * @param selector The function selector the delay is for.
     * @param delay The delay value.
     */
    struct DelayParams {
        address target;
        bytes4 selector;
        uint256 delay;
    }

    /**
     * @notice Emitted when the minimum delay is changed.
     * @param target The target address the delay is for.
     * @param selector The function selector the delay is for.
     * @param oldEnabledStatus The old enabled status.
     * @param oldDelay The old delay value.
     * @param newEnabledStatus The new enabled status.
     * @param newDelay The new delay value.
     */
    event MinDelayChange(
        address indexed target,
        bytes4 indexed selector,
        bool oldEnabledStatus,
        uint256 oldDelay,
        bool newEnabledStatus,
        uint256 newDelay
    );

    /**
     * @notice Emitted when the name is set.
     * @param name The name of the network.
     */
    event NameSet(string name);

    /**
     * @notice Emitted when the metadata URI is set.
     * @param metadataURI The metadata URI of the network.
     */
    event MetadataURISet(string metadataURI);

    /**
     * @notice Returns the role for updating the name.
     * @return The role for updating the name.
     */
    function NAME_UPDATE_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the role for updating the metadata URI.
     * @return The role for updating the metadata URI.
     */
    function METADATA_URI_UPDATE_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the address of the network registry.
     * @return The address of the network registry.
     */
    function NETWORK_REGISTRY() external view returns (address);

    /**
     * @notice Returns the address of the network middleware service.
     * @return The address of the network middleware service.
     */
    function NETWORK_MIDDLEWARE_SERVICE() external view returns (address);

    /**
     * @notice Returns the minimum delay for a given target and calldata.
     * @param target The target address the delay is for.
     * @param data The calldata of the function call.
     * @return The minimum delay for a given target and calldata.
     */
    function getMinDelay(address target, bytes memory data) external view returns (uint256);

    /**
     * @notice Returns the name of the network.
     * @return The name of the network.
     */
    function name() external view returns (string memory);

    /**
     * @notice Returns the metadata URI of the network.
     * @return The metadata URI of the network.
     */
    function metadataURI() external view returns (string memory);

    /**
     * @notice Updates the delay for a given target and selector.
     * @param target The target address the delay is for.
     * @param selector The function selector the delay is for.
     * @param enabled If to enable the delay.
     * @param newDelay The new delay value.
     * @dev Can be reached only via scheduled calls.
     */
    function updateDelay(address target, bytes4 selector, bool enabled, uint256 newDelay) external;

    /**
     * @notice Updates the name of the network.
     * @param name The new name.
     * @dev The caller must have the name update role.
     */
    function updateName(
        string memory name
    ) external;

    /**
     * @notice Updates the metadata URI of the network.
     * @param metadataURI The new metadata URI.
     * @dev The caller must have the metadata URI update role.
     */
    function updateMetadataURI(
        string memory metadataURI
    ) external;
}
