// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {INetworkManager} from "../../../interfaces/modules/base/INetworkManager.sol";

import {Subnetwork} from "@symbioticfi/core/src/contracts/libraries/Subnetwork.sol";
import {StaticDelegateCallable} from "@symbioticfi/core/src/contracts/common/StaticDelegateCallable.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract NetworkManager is Initializable, StaticDelegateCallable, INetworkManager {
    using Subnetwork for address;

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.NetworkManager")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant NetworkManagerLocation = 0x779150488f5e984d1f840ba606e388ada6c73b44f261274c3595c61a30023e00;

    function _getNetworkManagerStorage() internal pure returns (INetworkManager.NetworkManagerStorage storage $) {
        assembly {
            $.slot := NetworkManagerLocation
        }
    }

    function __NetworkManager_init(
        NetworkManagerInitParams memory initParams
    ) internal virtual onlyInitializing {
        if (initParams.network == address(0)) {
            revert NetworkManager_InvalidNetwork();
        }
        INetworkManager.NetworkManagerStorage storage $ = _getNetworkManagerStorage();
        $._network = initParams.network;
        $._subnetworkID = initParams.subnetworkID;
        emit INetworkManager.InitSubnetwork(initParams.network, initParams.subnetworkID);
    }

    /**
     * @inheritdoc INetworkManager
     */
    function NETWORK() public view virtual returns (address) {
        return _getNetworkManagerStorage()._network;
    }

    /**
     * @inheritdoc INetworkManager
     */
    function SUBNETWORK_IDENTIFIER() public view virtual returns (uint96) {
        return _getNetworkManagerStorage()._subnetworkID;
    }

    /**
     * @inheritdoc INetworkManager
     */
    function SUBNETWORK() public view virtual returns (bytes32) {
        return NETWORK().subnetwork(SUBNETWORK_IDENTIFIER());
    }
}
