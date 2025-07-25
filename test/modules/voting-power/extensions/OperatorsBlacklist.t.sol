// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {OperatorsBlacklist} from "../../../../src/modules/voting-power/extensions/OperatorsBlacklist.sol";
import {VotingPowerProvider} from "../../../../src/modules/voting-power/VotingPowerProvider.sol";
import {NoPermissionManager} from "../../../../test/mocks/NoPermissionManager.sol";
import {EqualStakeVPCalc} from "../../../../src/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";

import {INetworkManager} from "../../../../src/interfaces/modules/base/INetworkManager.sol";
import {IOperatorsBlacklist} from "../../../../src/interfaces/modules/voting-power/extensions/IOperatorsBlacklist.sol";
import {InitSetupTest} from "../../../InitSetup.sol";
import {MultiToken} from "../../../../src/modules/voting-power/extensions/MultiToken.sol";
import {IVotingPowerProvider} from "../../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {IOzEIP712} from "../../../../src/interfaces/modules/base/IOzEIP712.sol";
import {OperatorVaults} from "../../../../src/modules/voting-power/extensions/OperatorVaults.sol";

contract TestOperatorsBlacklist is
    OperatorsBlacklist,
    NoPermissionManager,
    EqualStakeVPCalc,
    MultiToken,
    OperatorVaults
{
    constructor(address operatorRegistry, address vaultFactory) VotingPowerProvider(operatorRegistry, vaultFactory) {}

    function initialize(
        IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit
    ) external initializer {
        __VotingPowerProvider_init(votingPowerProviderInit);
    }

    function _registerOperatorImpl(
        address operator
    ) internal override(OperatorsBlacklist, VotingPowerProvider) {
        super._registerOperatorImpl(operator);
    }
}

contract OperatorsBlacklistTest is InitSetupTest {
    TestOperatorsBlacklist private blacklistOps;

    address operator1;
    uint256 operator1Pk;

    address vault1;

    function setUp() public override {
        InitSetupTest.setUp();

        blacklistOps =
            new TestOperatorsBlacklist(address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory));

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

        blacklistOps.initialize(votingPowerProviderInit);

        operator1 = getOperator(0).addr;
        operator1Pk = getOperator(0).privateKey;

        (bool requireSlasher, uint48 minVaultEpochDuration) = blacklistOps.getSlashingData();

        // blacklistOps.registerToken(initSetupParams.masterChain.tokens[0]);

        vault1 = _getVault_SymbioticCore(
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

    function test_BasicEnvironment() public {
        assertFalse(blacklistOps.isOperatorBlacklisted(operator1));
    }

    function test_BlacklistOperator() public {
        vm.startPrank(operator1);
        blacklistOps.registerOperator();
        vm.stopPrank();

        assertTrue(blacklistOps.isOperatorRegistered(operator1));

        blacklistOps.blacklistOperator(operator1);

        assertTrue(blacklistOps.isOperatorBlacklisted(operator1));
        assertFalse(blacklistOps.isOperatorRegistered(operator1));

        vm.startPrank(operator1);
        vm.expectRevert(IOperatorsBlacklist.OperatorsBlacklist_OperatorBlacklisted.selector);
        blacklistOps.registerOperator();
        vm.stopPrank();
    }

    function test_UnblacklistOperator() public {
        blacklistOps.blacklistOperator(operator1);
        assertTrue(blacklistOps.isOperatorBlacklisted(operator1));

        blacklistOps.unblacklistOperator(operator1);
        assertFalse(blacklistOps.isOperatorBlacklisted(operator1));

        vm.startPrank(operator1);
        blacklistOps.registerOperator();
        vm.stopPrank();

        assertTrue(blacklistOps.isOperatorRegistered(operator1));
    }

    function test_Location() public {
        bytes32 location = keccak256(abi.encode(uint256(keccak256("symbiotic.storage.OperatorsBlacklist")) - 1))
            & ~bytes32(uint256(0xff));
        assertEq(location, 0x23ffaefb5f6b29c7a77ac2a8c6e8b7a8cb63a59ee84629217d13308576dcc800);
    }
}
