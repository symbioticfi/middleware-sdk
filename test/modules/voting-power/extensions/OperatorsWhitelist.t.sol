// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {IOperatorsWhitelist} from "../../../../src/interfaces/modules/voting-power/extensions/IOperatorsWhitelist.sol";
import "../../../InitSetup.sol";

import {OperatorsWhitelist} from "../../../../src/modules/voting-power/extensions/OperatorsWhitelist.sol";
import {NoPermissionManager} from "../../../../test/mocks/NoPermissionManager.sol";
import {EqualStakeVPCalc} from "../../../../src/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {INetworkManager} from "../../../../src/interfaces/modules/base/INetworkManager.sol";
import {IVotingPowerProvider} from "../../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {MultiToken} from "../../../../src/modules/voting-power/extensions/MultiToken.sol";
import {IOzEIP712} from "../../../../src/interfaces/modules/base/IOzEIP712.sol";
import {VotingPowerProvider} from "../../../../src/modules/voting-power/VotingPowerProvider.sol";
import {OperatorVaults} from "../../../../src/modules/voting-power/extensions/OperatorVaults.sol";

contract TestOperatorsWhitelist is
    OperatorsWhitelist,
    NoPermissionManager,
    EqualStakeVPCalc,
    MultiToken,
    OperatorVaults
{
    constructor(address operatorRegistry, address vaultFactory) VotingPowerProvider(operatorRegistry, vaultFactory) {}

    function initialize(
        IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit,
        OperatorsWhitelistInitParams memory wlInit
    ) external initializer {
        __VotingPowerProvider_init(votingPowerProviderInit);

        __OperatorsWhitelist_init(wlInit);
    }

    function _registerOperatorImpl(
        address operator
    ) internal override(OperatorsWhitelist, VotingPowerProvider) {
        super._registerOperatorImpl(operator);
    }
}

contract OperatorsWhitelistTest is Test, InitSetupTest {
    TestOperatorsWhitelist private whitelistOps;

    address operator1;
    address operator2;
    uint256 operator1Pk;

    address vaultA;
    address vaultB;

    function setUp() public override {
        InitSetupTest.setUp();

        whitelistOps =
            new TestOperatorsWhitelist(address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory));

        INetworkManager.NetworkManagerInitParams memory netInit =
            INetworkManager.NetworkManagerInitParams({network: vars.network.addr, subnetworkId: IDENTIFIER});
        IOperatorsWhitelist.OperatorsWhitelistInitParams memory wlInit =
            IOperatorsWhitelist.OperatorsWhitelistInitParams({isWhitelistEnabled: true});

        IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit = IVotingPowerProvider
            .VotingPowerProviderInitParams({
            networkManagerInitParams: netInit,
            ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "MyVotingPowerProvider", version: "1"}),
            requireSlasher: true,
            minVaultEpochDuration: 100,
            token: initSetupParams.masterChain.tokens[0]
        });

        whitelistOps.initialize(votingPowerProviderInit, wlInit);

        operator1 = getOperator(0).addr;
        operator1Pk = getOperator(0).privateKey;

        (bool requireSlasher, uint48 minVaultEpochDuration) = whitelistOps.getSlashingData();

        // whitelistOps.registerToken(initSetupParams.masterChain.tokens[0]);

        vaultA = _getVault_SymbioticCore(
            VaultParams({
                owner: operator1,
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

        vaultB = _getVault_SymbioticCore(
            VaultParams({
                owner: operator1,
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
    }

    function test_WhitelistEnabledByDefault() public {
        assertTrue(whitelistOps.isWhitelistEnabled());
    }

    function test_RegisterOperator_RevertIfNotWhitelisted() public {
        vm.startPrank(operator1);
        vm.expectRevert(IOperatorsWhitelist.OperatorsWhitelist_OperatorNotWhitelisted.selector);
        whitelistOps.registerOperator();
        vm.stopPrank();
    }

    function test_WhitelistOperatorAndRegister() public {
        whitelistOps.whitelistOperator(operator1);

        assertTrue(whitelistOps.isOperatorWhitelisted(operator1));

        vm.startPrank(operator1);
        whitelistOps.registerOperator();
        vm.stopPrank();

        assertTrue(whitelistOps.isOperatorRegistered(operator1));
    }

    function test_UnwhitelistOperator_RegisteredOperatorGetsUnregistered() public {
        whitelistOps.whitelistOperator(operator1);
        vm.prank(operator1);
        whitelistOps.registerOperator();
        assertTrue(whitelistOps.isOperatorRegistered(operator1));

        whitelistOps.unwhitelistOperator(operator1);
        assertFalse(whitelistOps.isOperatorRegistered(operator1));
        assertFalse(whitelistOps.isOperatorWhitelisted(operator1));
    }

    function test_DisableWhitelistAndRegister() public {
        whitelistOps.setWhitelistStatus(false);
        assertFalse(whitelistOps.isWhitelistEnabled());

        vm.prank(operator1);
        whitelistOps.registerOperator();
        assertTrue(whitelistOps.isOperatorRegistered(operator1));
    }

    function test_DisableWhitelistAndRegisterOperatorVault() public {
        whitelistOps.setWhitelistStatus(false);

        vm.startPrank(operator1);
        whitelistOps.registerOperator();
        vm.stopPrank();

        whitelistOps.registerOperatorVault(operator1, vaultA);

        assertTrue(whitelistOps.isOperatorVaultRegistered(operator1, vaultA));
        assertTrue(whitelistOps.isOperatorVaultRegistered(vaultA));
    }

    function test_Location() public {
        bytes32 location = keccak256(abi.encode(uint256(keccak256("symbiotic.storage.OperatorsWhitelist")) - 1))
            & ~bytes32(uint256(0xff));
        assertEq(location, 0x3fa7d7e58a4c604e915cc85c236f89892f2e36ec13dff506efa6b5ea5fafeb00);
    }
}
