// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INetworkManager {
    /**
     * @notice Reverts when the network is zero address.
     */
    error NetworkManager_InvalidNetwork();

    /**
     * @notice The storage of the NetworkManager contract.
     * @param _network The address of the network.
     * @param _subnetworkID The identifier of the subnetwork.
     * @dev The whole set of contracts supports only a single subnetwork per network.
     * @custom:storage-location erc7201:symbiotic.storage.NetworkManager
     */
    struct NetworkManagerStorage {
        address _network;
        uint96 _subnetworkID;
    }

    /**
     * @notice The parameters for the initialization of the NetworkManager contract.
     * @param network The address of the network.
     * @param subnetworkId The identifier of the subnetwork.
     * @dev `network` is not obligated to be registered in NetworkRegistry contract, it can be any non-zero address.
     */
    struct NetworkManagerInitParams {
        address network;
        uint96 subnetworkId;
    }

    /**
     * @notice Emitted during the NetworkManager initialization.
     * @param network The address of the network.
     * @param subnetworkId The identifier of the subnetwork.
     */
    event InitSubnetwork(address network, uint96 subnetworkId);

    /**
     * @notice Returns the address of the network.
     * @return The address of the network.
     */
    function NETWORK() external view returns (address);

    /**
     * @notice Returns the identifier of the subnetwork.
     * @return The identifier of the subnetwork.
     */
    function SUBNETWORK_IDENTIFIER() external view returns (uint96);

    /**
     * @notice Returns the subnetwork (a concatenation of the network and the subnetwork ID).
     * @return The subnetwork.
     */
    function SUBNETWORK() external view returns (bytes32);
}
