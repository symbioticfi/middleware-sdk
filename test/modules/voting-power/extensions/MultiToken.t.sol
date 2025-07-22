// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {MultiToken} from "../../../../src/contracts/modules/voting-power/extensions/MultiToken.sol";
import {IMultiToken} from "../../../../src/interfaces/modules/voting-power/extensions/IMultiToken.sol";
import {INetworkManager} from "../../../../src/interfaces/modules/base/INetworkManager.sol";
import {NoPermissionManager} from "../../../../test/mocks/NoPermissionManager.sol";
import {EqualStakeVPCalc} from
    "../../../../src/contracts/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {IVotingPowerProvider} from "../../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {IOzEIP712} from "../../../../src/interfaces/modules/base/IOzEIP712.sol";
import {VotingPowerProvider} from "../../../../src/contracts/modules/voting-power/VotingPowerProvider.sol";
import {OperatorVaults} from "../../../../src/contracts/modules/voting-power/extensions/OperatorVaults.sol";

import "../../../InitSetup.sol";

contract TestMultiToken is NoPermissionManager, EqualStakeVPCalc, MultiToken {
    constructor(address operatorRegistry, address vaultFactory) VotingPowerProvider(operatorRegistry, vaultFactory) {}

    function initialize(
        IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit
    ) external initializer {
        __VotingPowerProvider_init(votingPowerProviderInit);

        __MultiToken_init();
    }
}

contract MultiTokenTest is InitSetupTest {
    TestMultiToken private tokens;

    address private owner = address(0x12345);
    address private nonOwner = address(0xABC);

    address dummyOperatorRegistry = address(0xAAA1);
    address dummyVaultFactory = address(0xBBB2);

    function setUp() public override {
        InitSetupTest.setUp();
        tokens = new TestMultiToken(address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory));

        INetworkManager.NetworkManagerInitParams memory netInit =
            INetworkManager.NetworkManagerInitParams({network: vars.network.addr, subnetworkID: IDENTIFIER});

        IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit = IVotingPowerProvider
            .VotingPowerProviderInitParams({
            networkManagerInitParams: netInit,
            ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "MyVotingPowerProvider", version: "1"}),
            requireSlasher: true,
            minVaultEpochDuration: 100,
            token: initSetupParams.masterChain.tokens[0]
        });

        tokens.initialize(votingPowerProviderInit);
    }

    function test_RegisterToken_OnlyOwnerCanCall() public {
        tokens.registerToken(address(1));
    }

    function test_RegisterUnregisterToken_VaultManagerSide() public {
        tokens.registerToken(address(1));

        assertTrue(tokens.isTokenRegistered(address(1)));

        tokens.unregisterToken(address(1));

        assertFalse(tokens.isTokenRegistered(address(1)));
    }
}
