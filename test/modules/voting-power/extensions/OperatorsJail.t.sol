// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {OperatorsJail} from "../../../../src/contracts/modules/voting-power/extensions/OperatorsJail.sol";
import {VotingPowerProvider} from "../../../../src/contracts/modules/voting-power/VotingPowerProvider.sol";
import {NoPermissionManager} from "../../../../test/mocks/NoPermissionManager.sol";
import {EqualStakeVPCalc} from
    "../../../../src/contracts/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";

import {MultiToken} from "../../../../src/contracts/modules/voting-power/extensions/MultiToken.sol";
import {OperatorVaults} from "../../../../src/contracts/modules/voting-power/extensions/OperatorVaults.sol";
import {INetworkManager} from "../../../../src/interfaces/modules/base/INetworkManager.sol";
import {IOperatorsJail} from "../../../../src/interfaces/modules/voting-power/extensions/IOperatorsJail.sol";
import {IVotingPowerProvider} from "../../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {IOzEIP712} from "../../../../src/interfaces/modules/base/IOzEIP712.sol";

import {InitSetupTest} from "../../../InitSetup.sol";

contract TestOperatorsJail is OperatorsJail, NoPermissionManager, EqualStakeVPCalc, MultiToken, OperatorVaults {
    constructor(address operatorRegistry, address vaultFactory) VotingPowerProvider(operatorRegistry, vaultFactory) {}

    function initialize(
        IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit
    ) external initializer {
        __VotingPowerProvider_init(votingPowerProviderInit);
        __OperatorVaults_init();
        __OperatorsJail_init();
    }

    function _registerOperatorImpl(
        address operator
    ) internal override(OperatorsJail, VotingPowerProvider) {
        super._registerOperatorImpl(operator);
    }
}

contract OperatorsJailTest is InitSetupTest {
    TestOperatorsJail private jailOps;
    address operator1;
    uint256 operator1Pk;
    uint48 jailDuration = 100;

    function setUp() public override {
        super.setUp();
        jailOps = new TestOperatorsJail(address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory));

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

        jailOps.initialize(votingPowerProviderInit);

        operator1 = getOperator(0).addr;
        operator1Pk = getOperator(0).privateKey;
    }

    function test_BasicEnvironment() public {
        assertFalse(jailOps.isOperatorJailed(operator1));
    }

    function test_JailOperator() public {
        vm.startPrank(operator1);
        jailOps.registerOperator();
        vm.stopPrank();

        assertTrue(jailOps.isOperatorRegistered(operator1));

        jailOps.jailOperator(operator1, jailDuration);

        assertTrue(jailOps.isOperatorJailed(operator1));
        assertFalse(jailOps.isOperatorRegistered(operator1));
        assertEq(jailOps.getOperatorJailedUntil(operator1), vm.getBlockTimestamp() + jailDuration);

        vm.startPrank(operator1);
        vm.expectRevert(IOperatorsJail.OperatorsJail_OperatorJailed.selector);
        jailOps.registerOperator();
        vm.stopPrank();

        vm.warp(vm.getBlockTimestamp() + jailDuration - 1);

        assertTrue(jailOps.isOperatorJailed(operator1));
        assertEq(jailOps.getOperatorJailedUntil(operator1), vm.getBlockTimestamp() + 1);

        vm.startPrank(operator1);
        vm.expectRevert(IOperatorsJail.OperatorsJail_OperatorJailed.selector);
        jailOps.registerOperator();
        vm.stopPrank();

        vm.warp(vm.getBlockTimestamp() + 1);

        assertFalse(jailOps.isOperatorJailed(operator1));
        assertEq(jailOps.getOperatorJailedUntil(operator1), vm.getBlockTimestamp());

        vm.startPrank(operator1);
        jailOps.registerOperator();
        vm.stopPrank();
    }

    function test_UnjailOperator() public {
        jailOps.jailOperator(operator1, jailDuration);
        assertTrue(jailOps.isOperatorJailed(operator1));
        assertEq(jailOps.getOperatorJailedUntil(operator1), vm.getBlockTimestamp() + jailDuration);

        jailOps.unjailOperator(operator1);
        assertFalse(jailOps.isOperatorJailed(operator1));
        assertEq(jailOps.getOperatorJailedUntil(operator1), 0);

        vm.startPrank(operator1);
        jailOps.registerOperator();
        vm.stopPrank();

        assertTrue(jailOps.isOperatorRegistered(operator1));
    }

    function test_Location() public {
        bytes32 location =
            keccak256(abi.encode(uint256(keccak256("symbiotic.storage.OperatorsJail")) - 1)) & ~bytes32(uint256(0xff));
        assertEq(location, 0xcf19420dad377ef849f2ba5fafa7311a71756e09aee8adb231516efd3d2b7b00);
    }
}
