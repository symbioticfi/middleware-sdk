// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {SharedVaults} from "../../../../src/modules/voting-power/extensions/SharedVaults.sol";
import {ISharedVaults} from "../../../../src/interfaces/modules/voting-power/extensions/ISharedVaults.sol";
import {INetworkManager} from "../../../../src/interfaces/modules/base/INetworkManager.sol";
import {NoPermissionManager} from "../../../../test/mocks/NoPermissionManager.sol";
import {EqualStakeVPCalc} from "../../../../src/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {IVotingPowerProvider} from "../../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {IOzEIP712} from "../../../../src/interfaces/modules/base/IOzEIP712.sol";
import {VotingPowerProvider} from "../../../../src/modules/voting-power/VotingPowerProvider.sol";

import "../../../InitSetup.sol";

contract TestSharedVaults is SharedVaults, NoPermissionManager, EqualStakeVPCalc {
    constructor(address operatorRegistry, address vaultFactory) VotingPowerProvider(operatorRegistry, vaultFactory) {}

    function initialize(
        IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit
    ) external initializer {
        __VotingPowerProvider_init(votingPowerProviderInit);
    }

    function registerToken(
        address token
    ) public {
        _registerToken(token);
    }
}

contract SharedVaultsTest is InitSetupTest {
    TestSharedVaults private sharedVaults;

    address private owner = address(0x12345);
    address private nonOwner = address(0xABC);

    address dummyOperatorRegistry = address(0xAAA1);
    address dummyVaultFactory = address(0xBBB2);

    function setUp() public override {
        InitSetupTest.setUp();
        sharedVaults =
            new TestSharedVaults(address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory));

        INetworkManager.NetworkManagerInitParams memory netInit =
            INetworkManager.NetworkManagerInitParams({network: vars.network.addr, subnetworkId: IDENTIFIER});

        IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit = IVotingPowerProvider
            .VotingPowerProviderInitParams({
            networkManagerInitParams: netInit,
            ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "MyVotingPowerProvider", version: "1"}),
            requireSlasher: true,
            minVaultEpochDuration: 100,
            token: initSetupParams.masterChain.tokens[0]
        });

        sharedVaults.initialize(votingPowerProviderInit);
    }

    function test_RegisterSharedVault_OnlyOwnerCanCall() public {
        // sharedVaults.registerToken(initSetupParams.masterChain.tokens[0]);

        sharedVaults.registerSharedVault(initSetupParams.masterChain.vaults[0]);
    }

    function test_RegisterUnregisterSharedVault_VaultManagerSide() public {
        // sharedVaults.registerToken(initSetupParams.masterChain.tokens[0]);

        sharedVaults.registerSharedVault(initSetupParams.masterChain.vaults[0]);

        assertTrue(sharedVaults.isSharedVaultRegistered(initSetupParams.masterChain.vaults[0]));

        sharedVaults.unregisterSharedVault(initSetupParams.masterChain.vaults[0]);

        assertFalse(sharedVaults.isSharedVaultRegistered(initSetupParams.masterChain.vaults[0]));
    }
}
