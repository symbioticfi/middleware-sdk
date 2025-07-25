// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {OperatorVaults} from "../../../../src/modules/voting-power/extensions/OperatorVaults.sol";
import {IOperatorVaults} from "../../../../src/interfaces/modules/voting-power/extensions/IOperatorVaults.sol";
import {INetworkManager} from "../../../../src/interfaces/modules/base/INetworkManager.sol";
import {OzOwnable} from "../../../../src/modules/common/permissions/OzOwnable.sol";
import {EqualStakeVPCalc} from "../../../../src/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {IVotingPowerProvider} from "../../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {IOzEIP712} from "../../../../src/interfaces/modules/base/IOzEIP712.sol";
import {VotingPowerProvider} from "../../../../src/modules/voting-power/VotingPowerProvider.sol";

import "../../../InitSetup.sol";

contract TestOperatorVaults is OperatorVaults, OzOwnable, EqualStakeVPCalc {
    constructor(address operatorRegistry, address vaultFactory) VotingPowerProvider(operatorRegistry, vaultFactory) {
        _transferOwnership(msg.sender);
    }

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

contract OperatorVaultsTest is InitSetupTest {
    TestOperatorVaults private operatorVaults;

    address private owner = address(0x12345);
    address private nonOwner = address(0xABC);

    address dummyOperatorRegistry = address(0xAAA1);
    address dummyVaultFactory = address(0xBBB2);

    function setUp() public override {
        InitSetupTest.setUp();
        operatorVaults =
            new TestOperatorVaults(address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory));

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

        operatorVaults.initialize(votingPowerProviderInit);
    }

    function test_RegisterOperatorVault_OnlyOwnerCanCall() public {
        address operator = getOperator(1).addr;

        (bool requireSlasher, uint48 minVaultEpochDuration) = operatorVaults.getSlashingData();
        address opVault = _getVault_SymbioticCore(
            VaultParams({
                owner: operator,
                collateral: initSetupParams.masterChain.tokens[0],
                burner: 0x000000000000000000000000000000000000dEaD,
                epochDuration: minVaultEpochDuration * 2,
                whitelistedDepositors: new address[](0),
                depositLimit: 0,
                delegatorIndex: 2,
                hook: address(0),
                network: address(0),
                withSlasher: true,
                slasherIndex: 0,
                vetoDuration: 1
            })
        );

        vm.startPrank(operator);
        operatorVaults.registerOperator();
        vm.expectRevert();
        operatorVaults.registerOperatorVault(operator, opVault);
        vm.stopPrank();

        operatorVaults.registerOperatorVault(operator, opVault);

        assertTrue(operatorVaults.isOperatorVaultRegistered(opVault));

        operatorVaults.unregisterOperatorVault(operator, opVault);

        assertFalse(operatorVaults.isOperatorVaultRegistered(opVault));

        operatorVaults.registerOperatorVault(operator, opVault);

        vm.startPrank(operator);
        vm.expectRevert();
        operatorVaults.unregisterOperatorVault(operator, opVault);
        vm.stopPrank();

        assertTrue(operatorVaults.isOperatorVaultRegistered(opVault));

        vm.startPrank(operator);
        operatorVaults.unregisterOperatorVault(opVault);
        vm.stopPrank();

        assertFalse(operatorVaults.isOperatorVaultRegistered(opVault));
    }
}
