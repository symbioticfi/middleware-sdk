// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {NetworkManager} from "../../../src/modules/base/NetworkManager.sol";
import {INetworkManager} from "../../../src/interfaces/modules/base/INetworkManager.sol";

import {Subnetwork} from "@symbioticfi/core/src/contracts/libraries/Subnetwork.sol";

contract TestNetworkManager is NetworkManager {
    function initialize(address net, uint96 subID) external initializer {
        NetworkManagerInitParams memory initParams = NetworkManagerInitParams({network: net, subnetworkId: subID});
        __NetworkManager_init(initParams);
    }
}

contract NetworkManagerTest is Test {
    TestNetworkManager private nm;

    address private testNetwork = address(0xAABBCC);
    uint96 private testSubnetworkID = 42;

    function setUp() public {
        nm = new TestNetworkManager();
    }

    function test_InitializeAndCheckGetters() public {
        nm.initialize(testNetwork, testSubnetworkID);

        assertEq(nm.NETWORK(), testNetwork, "NETWORK mismatch");
        assertEq(nm.SUBNETWORK_IDENTIFIER(), testSubnetworkID, "SUBNETWORK_IDENTIFIER mismatch");

        bytes32 expectedSubnetwork = Subnetwork.subnetwork(testNetwork, testSubnetworkID);
        assertEq(nm.SUBNETWORK(), expectedSubnetwork, "SUBNETWORK mismatch");
    }

    function test_ReinitializeReverts() public {
        nm.initialize(testNetwork, testSubnetworkID);

        vm.expectRevert();
        nm.initialize(address(0xBAD), 9999);
    }

    function test_DefaultsBeforeInit() public {
        assertEq(nm.NETWORK(), address(0), "Expected default zero address");
        assertEq(nm.SUBNETWORK_IDENTIFIER(), 0, "Expected default subnetworkId=0");
        bytes32 subn = nm.SUBNETWORK();
    }

    function test_Location() public {
        bytes32 location =
            keccak256(abi.encode(uint256(keccak256("symbiotic.storage.NetworkManager")) - 1)) & ~bytes32(uint256(0xff));
        assertEq(location, 0x779150488f5e984d1f840ba606e388ada6c73b44f261274c3595c61a30023e00, "Location mismatch");
    }

    function test_RevertNetworkManager_InvalidNetwork() public {
        vm.expectRevert(INetworkManager.NetworkManager_InvalidNetwork.selector);
        nm.initialize(address(0), 9999);

        nm.initialize(address(1), 9999);
    }
}
