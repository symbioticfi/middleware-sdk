// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {VotingPowerProvider} from "../../../src/contracts/modules/voting-power/VotingPowerProvider.sol";
import {VotingPowerProviderLogic} from "../../../src/contracts/modules/voting-power/logic/VotingPowerProviderLogic.sol";
import {MultiToken} from "../../../src/contracts/modules/voting-power/extensions/MultiToken.sol";
import {IVotingPowerProvider} from "../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {INetworkManager} from "../../../src/interfaces/modules/base/INetworkManager.sol";
import {IOzEIP712} from "../../../src/interfaces/modules/base/IOzEIP712.sol";
import {NoPermissionManager} from "../../../test/mocks/NoPermissionManager.sol";
import {EqualStakeVPCalc} from
    "../../../src/contracts/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {OperatorVaults} from "../../../src/contracts/modules/voting-power/extensions/OperatorVaults.sol";

import {BN254} from "../../../src/contracts/libraries/utils/BN254.sol";
import "../../InitSetup.sol";

contract TestVotingPowerProvider is VotingPowerProvider, EqualStakeVPCalc, NoPermissionManager {
    constructor(address operatorRegistry, address vaultFactory) VotingPowerProvider(operatorRegistry, vaultFactory) {}

    function initialize(
        IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit
    ) external initializer {
        __VotingPowerProvider_init(votingPowerProviderInit);
    }

    function registerOperator(
        address operator
    ) external {
        _registerOperator(operator);
    }

    function unregisterOperator(
        address operator
    ) external {
        _unregisterOperator(operator);
    }

    function setSlashingData(bool requireSlasher, uint48 minVaultEpochDuration) external {
        _setSlashingData(requireSlasher, minVaultEpochDuration);
    }

    function registerToken(
        address token
    ) external {
        _registerToken(token);
    }

    function unregisterToken(
        address token
    ) external {
        _unregisterToken(token);
    }

    function registerSharedVault(
        address vault
    ) external {
        _registerSharedVault(vault);
    }

    function unregisterSharedVault(
        address vault
    ) external {
        _unregisterSharedVault(vault);
    }

    function registerOperatorVault(address operator, address vault) external {
        _registerOperatorVault(operator, vault);
    }

    function unregisterOperatorVault(address operator, address vault) external {
        _unregisterOperatorVault(operator, vault);
    }

    function validateVault(
        address vault
    ) external view returns (bool) {
        return VotingPowerProviderLogic._validateVault(vault);
    }

    function validateSharedVault(
        address vault
    ) external view returns (bool) {
        return VotingPowerProviderLogic._validateSharedVault(vault);
    }

    function validateOperatorVault(address operator, address vault) external view returns (bool) {
        return VotingPowerProviderLogic._validateOperatorVault(operator, vault);
    }

    function validateVaultEpochDuration(
        address vault
    ) external view returns (bool) {
        return VotingPowerProviderLogic._validateVaultSlashing(vault);
    }
}

contract VotingPowerProviderTest is InitSetupTest {
    TestVotingPowerProvider private votingPowerProvider;

    address operator1 = address(0xAAA1);
    address operator2 = address(0xAAA2);
    address tokenA = address(0xBEE1);
    address tokenB = address(0xBEE2);

    address validOperator = address(0x1111);
    address invalidOperator = address(0x2222);

    bytes4 private ERR_INVALID_OPERATOR = IVotingPowerProvider.VotingPowerProvider_InvalidOperator.selector;
    bytes4 private ERR_ALREADY_REGISTERED = IVotingPowerProvider.VotingPowerProvider_OperatorAlreadyRegistered.selector;
    bytes4 private ERR_NOT_REGISTERED = IVotingPowerProvider.VotingPowerProvider_OperatorNotRegistered.selector;

    bytes4 private ERR_TOKEN_ALREADY_registered =
        IVotingPowerProvider.VotingPowerProvider_TokenAlreadyIsRegistered.selector;
    bytes4 private ERR_TOKEN_NOT_registered = IVotingPowerProvider.VotingPowerProvider_TokenNotRegistered.selector;
    bytes4 private ERR_INVALID_TOKEN = IVotingPowerProvider.VotingPowerProvider_InvalidToken.selector;

    bytes4 private ERR_SHARED_VAULT_ALREADY_registered =
        IVotingPowerProvider.VotingPowerProvider_SharedVaultAlreadyIsRegistered.selector;
    bytes4 private ERR_OPERATOR_VAULT_ALREADY_registered =
        IVotingPowerProvider.VotingPowerProvider_OperatorVaultAlreadyIsRegistered.selector;
    bytes4 private ERR_INVALID_VAULT = IVotingPowerProvider.VotingPowerProvider_InvalidVault.selector;

    bytes4 private ERR_INVALID_SHARED_VAULT = IVotingPowerProvider.VotingPowerProvider_InvalidSharedVault.selector;
    bytes4 private ERR_INVALID_OPERATOR_VAULT = IVotingPowerProvider.VotingPowerProvider_InvalidOperatorVault.selector;
    bytes4 private ERR_OPERATOR_NOT_REGISTERED = IVotingPowerProvider.VotingPowerProvider_OperatorNotRegistered.selector;

    function setUp() public override {
        InitSetupTest.setUp();

        votingPowerProvider =
            new TestVotingPowerProvider(address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory));

        INetworkManager.NetworkManagerInitParams memory netInit =
            INetworkManager.NetworkManagerInitParams({network: vars.network.addr, subnetworkID: IDENTIFIER});

        IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit = IVotingPowerProvider
            .VotingPowerProviderInitParams({
            networkManagerInitParams: netInit,
            ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "MyVotingPowerProvider", version: "1"}),
            requireSlasher: true,
            minVaultEpochDuration: 100,
            token: address(0)
        });

        votingPowerProvider.initialize(votingPowerProviderInit);

        _registerOperator_SymbioticCore(symbioticCore, operator1);
        _registerOperator_SymbioticCore(symbioticCore, operator2);

        _registerOperator_SymbioticCore(symbioticCore, validOperator);

        // votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[0]);
    }

    function test_RegisterOperatorValid() public {
        votingPowerProvider.registerOperator(validOperator);

        bool isRegistered = votingPowerProvider.isOperatorRegistered(validOperator);
        assertTrue(isRegistered, "Should be registered now");
    }

    function test_RegisterOperator_RevertIfNotEntity() public {
        vm.expectRevert(ERR_INVALID_OPERATOR);
        votingPowerProvider.registerOperator(invalidOperator);
    }

    function test_RegisterOperator_RevertIfAlreadyRegistered() public {
        votingPowerProvider.registerOperator(validOperator);
        vm.expectRevert(ERR_ALREADY_REGISTERED);
        votingPowerProvider.registerOperator(validOperator);
    }

    function test_UnregisterOperator() public {
        votingPowerProvider.registerOperator(validOperator);

        address[] memory actOps = votingPowerProvider.getOperators();
        assertEq(actOps.length, 1, "Should have exactly 1 registered operator");
        assertEq(actOps[0], validOperator, "Operator mismatch in actOps");

        votingPowerProvider.unregisterOperator(validOperator);

        bool isRegistered = votingPowerProvider.isOperatorRegistered(validOperator);
        assertFalse(isRegistered, "Should not be registered after unregister");

        actOps = votingPowerProvider.getOperators();
        assertEq(actOps.length, 0, "Should have no registered operators");

        uint256 actOpsLength = votingPowerProvider.getOperatorsLength();
        assertEq(actOpsLength, 0, "Should have no registered operators");
    }

    function test_UnregisterOperator_RevertIfNotRegistered() public {
        vm.expectRevert(ERR_NOT_REGISTERED);
        votingPowerProvider.unregisterOperator(validOperator);
    }

    function test_IsOperatorRegisteredAt_withTime() public {
        uint48 t0 = uint48(vm.getBlockTimestamp());
        votingPowerProvider.registerOperator(validOperator);

        vm.warp(vm.getBlockTimestamp() + 100);
        uint48 t1 = uint48(vm.getBlockTimestamp());

        bool wasRegisteredBefore = votingPowerProvider.isOperatorRegisteredAt(validOperator, t0 - 1, "");
        assertFalse(wasRegisteredBefore, "Should be inregistered before we registered");
        bool isRegisteredT0 = votingPowerProvider.isOperatorRegisteredAt(validOperator, t0, "");
        assertTrue(isRegisteredT0, "Should be registered at T0");
        bool isRegisteredT1 = votingPowerProvider.isOperatorRegisteredAt(validOperator, t1, "");
        assertTrue(isRegisteredT1, "Should be registered at T1");
    }

    function testGetOperatorsAt_withTime() public {
        address validOp2 = address(0x3333);
        _registerOperator_SymbioticCore(symbioticCore, validOp2);

        uint48 t0 = uint48(vm.getBlockTimestamp());

        votingPowerProvider.registerOperator(validOperator);

        {
            address[] memory actOps = votingPowerProvider.getOperators();
            assertEq(actOps.length, 1, "At T0, 1 registered operator");
            assertEq(actOps[0], validOperator);

            uint256 actOpsT0Length = votingPowerProvider.getOperatorsLength();
            assertEq(actOpsT0Length, 1, "At T0, 1 registered operator");
        }

        vm.warp(t0 + 50);
        uint48 t1 = uint48(vm.getBlockTimestamp());
        votingPowerProvider.registerOperator(validOp2);

        {
            address[] memory actOpsT0 = votingPowerProvider.getOperatorsAt(t0);
            assertEq(actOpsT0.length, 1, "At T0, only 1 registered operator");
            assertEq(actOpsT0[0], validOperator);
        }
        {
            address[] memory actOpsT1 = votingPowerProvider.getOperatorsAt(t1);
            assertEq(actOpsT1.length, 2, "At T1, 2 registered operators");
            assertEq(actOpsT1[0], validOperator);
            assertEq(actOpsT1[1], validOp2);
        }
        {
            address[] memory actOps = votingPowerProvider.getOperators();
            assertEq(actOps.length, 2, "At T1, 2 registered operators");
            assertEq(actOps[0], validOperator);
            assertEq(actOps[1], validOp2);

            uint256 actOpsT1Length = votingPowerProvider.getOperatorsLength();
            assertEq(actOpsT1Length, 2, "At T1, 2 registered operators");
        }
    }

    function test_SlashingData() public {
        (bool requireSlasher, uint48 minVaultEpochDuration) = votingPowerProvider.getSlashingData();
        assertTrue(requireSlasher);
        assertEq(minVaultEpochDuration, 100);
        vm.warp(vm.getBlockTimestamp() + 100);
        votingPowerProvider.setSlashingData(false, 50);
        (requireSlasher, minVaultEpochDuration) = votingPowerProvider.getSlashingData();
        assertFalse(requireSlasher);
        assertEq(minVaultEpochDuration, 50);
    }

    function test_RegisterToken() public {
        votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[0]);
        vm.expectRevert(ERR_TOKEN_ALREADY_registered);
        votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[0]);

        assertEq(votingPowerProvider.getTokensLength(), 1);

        address[] memory registeredTokens = votingPowerProvider.getTokensAt(uint48(vm.getBlockTimestamp()) - 100);
        assertEq(registeredTokens.length, 0);
        registeredTokens = votingPowerProvider.getTokensAt(uint48(vm.getBlockTimestamp()));

        votingPowerProvider.registerToken(tokenB);

        assertEq(votingPowerProvider.getTokensLength(), 2);

        registeredTokens = votingPowerProvider.getTokensAt(uint48(vm.getBlockTimestamp()));
        assertEq(registeredTokens.length, 2);
        assertEq(registeredTokens[0], initSetupParams.masterChain.tokens[0]);
        assertEq(registeredTokens[1], tokenB);

        votingPowerProvider.unregisterToken(tokenB);

        assertEq(votingPowerProvider.getTokensLength(), 1);

        registeredTokens = votingPowerProvider.getTokensAt(uint48(vm.getBlockTimestamp()));
        assertEq(registeredTokens.length, 1);
        assertEq(registeredTokens[0], initSetupParams.masterChain.tokens[0]);

        assertTrue(votingPowerProvider.isTokenRegistered(initSetupParams.masterChain.tokens[0]));
        assertFalse(votingPowerProvider.isTokenRegisteredAt(tokenB, uint48(vm.getBlockTimestamp()), ""));

        registeredTokens = votingPowerProvider.getTokens();
        assertEq(registeredTokens.length, 1);
        assertEq(registeredTokens[0], initSetupParams.masterChain.tokens[0]);
    }

    function test_RegisterToken_RevertOnZeroAddress() public {
        vm.expectRevert(ERR_INVALID_TOKEN);
        votingPowerProvider.registerToken(address(0));
    }

    function test_UnregisterToken() public {
        votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[0]);
        votingPowerProvider.unregisterToken(initSetupParams.masterChain.tokens[0]);
        vm.expectRevert(ERR_TOKEN_NOT_registered);
        votingPowerProvider.unregisterToken(initSetupParams.masterChain.tokens[0]);
    }

    function test_RegisterSharedVault() public {
        votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[0]);

        votingPowerProvider.registerSharedVault(initSetupParams.masterChain.vaults[0]);

        vm.expectRevert(ERR_SHARED_VAULT_ALREADY_registered);
        votingPowerProvider.registerSharedVault(initSetupParams.masterChain.vaults[0]);

        address[] memory registeredSharedVaults = votingPowerProvider.getSharedVaults();
        assertEq(registeredSharedVaults.length, 1);
        assertEq(registeredSharedVaults[0], initSetupParams.masterChain.vaults[0]);

        registeredSharedVaults = votingPowerProvider.getSharedVaultsAt(uint48(vm.getBlockTimestamp()));
        assertEq(registeredSharedVaults.length, 1);

        assertEq(votingPowerProvider.isSharedVaultRegistered(initSetupParams.masterChain.vaults[0]), true);
        assertEq(
            votingPowerProvider.isSharedVaultRegisteredAt(
                initSetupParams.masterChain.vaults[0], uint48(vm.getBlockTimestamp()), ""
            ),
            true
        );

        votingPowerProvider.unregisterSharedVault(initSetupParams.masterChain.vaults[0]);

        assertEq(votingPowerProvider.getSharedVaultsLength(), 0);

        registeredSharedVaults = votingPowerProvider.getSharedVaults();
        assertEq(registeredSharedVaults.length, 0);

        vm.expectRevert(IVotingPowerProvider.VotingPowerProvider_SharedVaultNotRegistered.selector);
        votingPowerProvider.unregisterSharedVault(initSetupParams.masterChain.vaults[0]);
    }

    function test_RegisterSharedVault_RevertIfInvalidVault() public {
        vm.expectRevert(ERR_INVALID_VAULT);
        votingPowerProvider.registerSharedVault(address(0));
    }

    function test_RegisterSharedVault_RevertIfTokenNotRegistered() public {
        votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[0]);

        vm.expectRevert(ERR_INVALID_VAULT);
        votingPowerProvider.registerSharedVault(address(1));

        (bool requireSlasher, uint48 minVaultEpochDuration) = votingPowerProvider.getSlashingData();
        address newVault = _getVault_SymbioticCore(
            VaultParams({
                owner: vars.deployer.addr,
                collateral: address(2),
                burner: 0x000000000000000000000000000000000000dEaD,
                epochDuration: minVaultEpochDuration * 2,
                whitelistedDepositors: new address[](0),
                depositLimit: 0,
                delegatorIndex: 0,
                hook: address(0),
                network: address(0),
                withSlasher: true,
                slasherIndex: 0,
                vetoDuration: 1
            })
        );

        vm.expectRevert(ERR_INVALID_VAULT);
        votingPowerProvider.registerSharedVault(newVault);

        newVault = _getVault_SymbioticCore(
            VaultParams({
                owner: vars.deployer.addr,
                collateral: initSetupParams.masterChain.tokens[0],
                burner: 0x000000000000000000000000000000000000dEaD,
                epochDuration: minVaultEpochDuration - 1,
                whitelistedDepositors: new address[](0),
                depositLimit: 0,
                delegatorIndex: 0,
                hook: address(0),
                network: address(0),
                withSlasher: true,
                slasherIndex: 0,
                vetoDuration: 1
            })
        );

        vm.expectRevert(ERR_INVALID_VAULT);
        votingPowerProvider.registerSharedVault(newVault);

        newVault = _getVault_SymbioticCore(
            VaultParams({
                owner: vars.deployer.addr,
                collateral: initSetupParams.masterChain.tokens[0],
                burner: 0x000000000000000000000000000000000000dEaD,
                epochDuration: minVaultEpochDuration * 2,
                whitelistedDepositors: new address[](0),
                depositLimit: 0,
                delegatorIndex: 0,
                hook: address(0),
                network: address(0),
                withSlasher: false,
                slasherIndex: 0,
                vetoDuration: 0
            })
        );

        vm.expectRevert(ERR_INVALID_VAULT);
        votingPowerProvider.registerSharedVault(newVault);

        newVault = _getVault_SymbioticCore(
            VaultParams({
                owner: vars.deployer.addr,
                collateral: initSetupParams.masterChain.tokens[0],
                burner: 0x000000000000000000000000000000000000dEaD,
                epochDuration: minVaultEpochDuration,
                whitelistedDepositors: new address[](0),
                depositLimit: 0,
                delegatorIndex: 0,
                hook: address(0),
                network: address(0),
                withSlasher: true,
                slasherIndex: 1,
                vetoDuration: 1
            })
        );

        vm.expectRevert(ERR_INVALID_VAULT);
        votingPowerProvider.registerSharedVault(newVault);

        vm.startPrank(getOperator(0).addr);
        votingPowerProvider.registerOperator();
        vm.stopPrank();

        newVault = _getVault_SymbioticCore(
            VaultParams({
                owner: getOperator(0).addr,
                collateral: initSetupParams.masterChain.tokens[0],
                burner: 0x000000000000000000000000000000000000dEaD,
                epochDuration: minVaultEpochDuration,
                whitelistedDepositors: new address[](0),
                depositLimit: 0,
                delegatorIndex: 2,
                hook: address(0),
                network: address(0),
                withSlasher: true,
                slasherIndex: 0,
                vetoDuration: 0
            })
        );

        vm.expectRevert(ERR_INVALID_SHARED_VAULT);
        votingPowerProvider.registerSharedVault(newVault);

        newVault = _getVault_SymbioticCore(
            VaultParams({
                owner: getOperator(0).addr,
                collateral: initSetupParams.masterChain.tokens[0],
                burner: 0x000000000000000000000000000000000000dEaD,
                epochDuration: minVaultEpochDuration,
                whitelistedDepositors: new address[](0),
                depositLimit: 0,
                delegatorIndex: 0,
                hook: address(0),
                network: address(0),
                withSlasher: true,
                slasherIndex: 0,
                vetoDuration: 0
            })
        );

        vm.expectRevert(ERR_INVALID_OPERATOR_VAULT);
        votingPowerProvider.registerOperatorVault(getOperator(0).addr, newVault);

        newVault = _getVault_SymbioticCore(
            VaultParams({
                owner: getOperator(0).addr,
                collateral: initSetupParams.masterChain.tokens[0],
                burner: 0x000000000000000000000000000000000000dEaD,
                epochDuration: minVaultEpochDuration - 1,
                whitelistedDepositors: new address[](0),
                depositLimit: 0,
                delegatorIndex: 2,
                hook: address(0),
                network: address(0),
                withSlasher: true,
                slasherIndex: 0,
                vetoDuration: 0
            })
        );

        vm.expectRevert(ERR_INVALID_VAULT);
        votingPowerProvider.registerOperatorVault(getOperator(0).addr, newVault);

        address newNetwork = address(3535);
        _networkRegister_SymbioticCore(newNetwork);

        newVault = _getVault_SymbioticCore(
            VaultParams({
                owner: getOperator(0).addr,
                collateral: initSetupParams.masterChain.tokens[0],
                burner: 0x000000000000000000000000000000000000dEaD,
                epochDuration: minVaultEpochDuration,
                whitelistedDepositors: new address[](0),
                depositLimit: 0,
                delegatorIndex: 3,
                hook: address(0),
                network: newNetwork,
                withSlasher: true,
                slasherIndex: 0,
                vetoDuration: 0
            })
        );

        vm.expectRevert(ERR_INVALID_OPERATOR_VAULT);
        votingPowerProvider.registerOperatorVault(getOperator(0).addr, newVault);

        newVault = _getVault_SymbioticCore(
            VaultParams({
                owner: getOperator(0).addr,
                collateral: initSetupParams.masterChain.tokens[0],
                burner: 0x000000000000000000000000000000000000dEaD,
                epochDuration: minVaultEpochDuration,
                whitelistedDepositors: new address[](0),
                depositLimit: 0,
                delegatorIndex: 2,
                hook: address(0),
                network: address(0),
                withSlasher: true,
                slasherIndex: 0,
                vetoDuration: 0
            })
        );

        votingPowerProvider.registerOperatorVault(getOperator(0).addr, newVault);

        vm.expectRevert(ERR_OPERATOR_VAULT_ALREADY_registered);
        votingPowerProvider.registerOperatorVault(getOperator(0).addr, newVault);

        newVault = ISymbioticVaultFactory(symbioticCore.vaultFactory).create(
            1,
            address(0),
            abi.encode(
                ISymbioticVault.InitParams({
                    collateral: initSetupParams.masterChain.tokens[0],
                    burner: 0x000000000000000000000000000000000000dEaD,
                    epochDuration: minVaultEpochDuration,
                    depositWhitelist: false,
                    isDepositLimit: false,
                    depositLimit: 0,
                    defaultAdminRoleHolder: address(0),
                    depositWhitelistSetRoleHolder: address(0),
                    depositorWhitelistRoleHolder: address(0),
                    isDepositLimitSetRoleHolder: address(0),
                    depositLimitSetRoleHolder: address(0)
                })
            )
        );

        vm.expectRevert(ERR_INVALID_VAULT);
        votingPowerProvider.registerOperatorVault(getOperator(0).addr, newVault);
    }

    function test_RegisterOperatorVault() public {
        address[] memory networkLimitSetRoleHolders = new address[](1);
        networkLimitSetRoleHolders[0] = address(this);
        address[] memory operatorNetworkSharesSetRoleHolders = new address[](1);
        operatorNetworkSharesSetRoleHolders[0] = address(this);

        (bool requireSlasher, uint48 minVaultEpochDuration) = votingPowerProvider.getSlashingData();
        address opVault = _getVault_SymbioticCore(
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

        votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[0]);

        votingPowerProvider.registerOperator(operator1);

        votingPowerProvider.registerOperatorVault(operator1, opVault);

        vm.expectRevert(ERR_OPERATOR_VAULT_ALREADY_registered);
        votingPowerProvider.registerOperatorVault(operator1, opVault);

        address[] memory registeredOperatorVaults = votingPowerProvider.getOperatorVaults(operator1);
        assertEq(registeredOperatorVaults.length, 1);
        assertEq(registeredOperatorVaults[0], opVault);

        registeredOperatorVaults = votingPowerProvider.getOperatorVaultsAt(operator1, uint48(vm.getBlockTimestamp()));
        assertEq(registeredOperatorVaults.length, 1);

        assertEq(votingPowerProvider.isOperatorVaultRegistered(operator1, opVault), true);
        assertEq(
            votingPowerProvider.isOperatorVaultRegisteredAt(operator1, opVault, uint48(vm.getBlockTimestamp()), ""),
            true
        );
        assertEq(votingPowerProvider.isOperatorVaultRegisteredAt(opVault, uint48(vm.getBlockTimestamp()), ""), true);

        votingPowerProvider.unregisterOperatorVault(operator1, opVault);

        assertEq(votingPowerProvider.getOperatorVaultsLength(operator1), 0);

        registeredOperatorVaults = votingPowerProvider.getOperatorVaults(operator1);
        assertEq(registeredOperatorVaults.length, 0);
    }

    function test_RegisterOperatorVault_RevertIfOperatorNotRegistered() public {
        address operator3 = address(0x777);
        _registerOperator_SymbioticCore(symbioticCore, operator3);
        (bool requireSlasher, uint48 minVaultEpochDuration) = votingPowerProvider.getSlashingData();
        address opVault = _getVault_SymbioticCore(
            VaultParams({
                owner: operator3,
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
        votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[0]);

        vm.expectRevert(ERR_OPERATOR_NOT_REGISTERED);
        votingPowerProvider.registerOperatorVault(operator3, opVault);
    }

    function test_SlashVault_InstantSlasher() public {}

    function test_SlashVault_VetoSlasherFlow() public {}

    function test_SlashVault_RevertIfNoSlasher() public {}

    function test_DistributeRewards() public {}

    function test_ValidateVault() public {
        (bool requireSlasher, uint48 minVaultEpochDuration) = votingPowerProvider.getSlashingData();
        address someVault = _getVault_SymbioticCore(
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
        votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[0]);

        bool ok = votingPowerProvider.validateVault(someVault);
        assertTrue(ok, "should pass validation");
    }

    function test_ValidateVaultSlashingFailsIfLessThanMinVaultEpochDuration() public {
        (bool requireSlasher, uint48 minVaultEpochDuration) = votingPowerProvider.getSlashingData();
        address shortVault = _getVault_SymbioticCore(
            VaultParams({
                owner: operator1,
                collateral: initSetupParams.masterChain.tokens[0],
                burner: 0x000000000000000000000000000000000000dEaD,
                epochDuration: 50,
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
        votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[0]);

        bool ok = votingPowerProvider.validateVault(shortVault);
        assertFalse(ok, "should fail since 50 < minVaultEpochDuration=100");
    }

    function test_Location() public {
        bytes32 location = keccak256(abi.encode(uint256(keccak256("symbiotic.storage.VotingPowerProvider")) - 1))
            & ~bytes32(uint256(0xff));
        assertEq(location, 0x3671387af6738df83002b4d17260f89ef208ae15fe22fab69d817f0195c74800, "Location mismatch");
    }

    function test_CheckStakes() public {
        (bool requireSlasher, uint48 minVaultEpochDuration) = votingPowerProvider.getSlashingData();
        votingPowerProvider =
            new TestVotingPowerProvider(address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory));

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

        votingPowerProvider.initialize(votingPowerProviderInit);

        _networkSetMiddleware_SymbioticCore(vars.network.addr, address(votingPowerProvider));

        // for (uint256 i; i < initSetupParams.masterChain.tokens.length; ++i) {
        //     vm.startPrank(vars.deployer.addr);
        //     votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[i]);
        //     vm.stopPrank();
        // }
        for (uint256 i; i < initSetupParams.masterChain.vaults.length; ++i) {
            vm.startPrank(vars.network.addr);
            votingPowerProvider.registerSharedVault(initSetupParams.masterChain.vaults[i]);
            vm.stopPrank();
        }

        for (uint256 i; i < SYMBIOTIC_CORE_NUMBER_OF_OPERATORS; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            vm.startPrank(operator.addr);
            votingPowerProvider.registerOperator(operator.addr);
            vm.stopPrank();
        }

        for (uint256 i; i < SYMBIOTIC_CORE_NUMBER_OF_OPERATORS; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            address operatorVault = _getVault_SymbioticCore(
                VaultParams({
                    owner: operator.addr,
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

            _operatorOptIn_SymbioticCore(operator.addr, operatorVault);
            _networkSetMaxNetworkLimit_SymbioticCore(
                votingPowerProvider.NETWORK(),
                operatorVault,
                votingPowerProvider.SUBNETWORK_IDENTIFIER(),
                type(uint256).max
            );
            _curatorSetNetworkLimit_SymbioticCore(
                operator.addr, operatorVault, votingPowerProvider.SUBNETWORK(), type(uint256).max
            );
            _stakerDeposit_SymbioticCore(getStaker(0).addr, operatorVault, 1000 + i);
            vm.startPrank(vars.network.addr);
            votingPowerProvider.registerOperatorVault(operator.addr, operatorVault);
            vm.stopPrank();
        }

        IVotingPowerProvider.OperatorVotingPower[] memory operatorVotingPowers1 =
            votingPowerProvider.getVotingPowers(new bytes[](0));
        assertEq(
            abi.encode(operatorVotingPowers1),
            abi.encode(votingPowerProvider.getVotingPowersAt(new bytes[](0), uint48(vm.getBlockTimestamp())))
        );

        uint256 totalStake;
        for (uint256 i; i < SYMBIOTIC_CORE_NUMBER_OF_OPERATORS; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            IVotingPowerProvider.VaultVotingPower[] memory vaultVotingPowers1 =
                votingPowerProvider.getOperatorVotingPowers(operator.addr, "");
            assertEq(
                abi.encode(vaultVotingPowers1),
                abi.encode(
                    votingPowerProvider.getOperatorVotingPowersAt(operator.addr, "", uint48(vm.getBlockTimestamp()))
                )
            );
            assertEq(
                abi.encode(vaultVotingPowers1),
                abi.encode(
                    votingPowerProvider.getOperatorVotingPowersAt(
                        operator.addr,
                        abi.encode(
                            IVotingPowerProvider.OperatorVotingPowersExtraData({
                                sharedVaultsExtraData: new bytes[](0),
                                operatorVaultsExtraData: new bytes[](0)
                            })
                        ),
                        uint48(vm.getBlockTimestamp())
                    )
                )
            );
            assertEq(
                abi.encode(vaultVotingPowers1),
                abi.encode(
                    votingPowerProvider.getOperatorVotingPowers(
                        operator.addr,
                        abi.encode(
                            IVotingPowerProvider.OperatorVotingPowersExtraData({
                                sharedVaultsExtraData: new bytes[](0),
                                operatorVaultsExtraData: new bytes[](0)
                            })
                        )
                    )
                )
            );

            uint256 operatorStake;
            for (uint256 j; j < initSetupParams.masterChain.vaults.length; ++j) {
                uint256 operatorVaultStake = (
                    _normalizeForToken_Symbiotic(
                        SYMBIOTIC_CORE_MIN_TOKENS_TO_DEPOSIT_TIMES_1e18 * SYMBIOTIC_CORE_NUMBER_OF_OPERATORS,
                        initSetupParams.masterChain.tokens[0]
                    ) + j
                ) / SYMBIOTIC_CORE_NUMBER_OF_OPERATORS;
                assertEq(
                    votingPowerProvider.getOperatorStake(initSetupParams.masterChain.vaults[j], operator.addr),
                    operatorVaultStake
                );
                assertEq(
                    votingPowerProvider.getOperatorStakeAt(
                        initSetupParams.masterChain.vaults[j], operator.addr, uint48(vm.getBlockTimestamp()), ""
                    ),
                    operatorVaultStake
                );

                address vault = _getVault_SymbioticCore(
                    VaultParams({
                        owner: getOperator(0).addr,
                        collateral: address(1),
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
                assertEq(
                    votingPowerProvider.getOperatorVotingPower(operator.addr, initSetupParams.masterChain.vaults[j], ""),
                    operatorVaultStake
                );
                assertEq(votingPowerProvider.getOperatorVotingPower(operator.addr, vault, ""), 0);

                assertEq(
                    votingPowerProvider.getOperatorVotingPowerAt(
                        operator.addr, initSetupParams.masterChain.vaults[j], "", uint48(vm.getBlockTimestamp()), ""
                    ),
                    operatorVaultStake
                );

                assertEq(
                    votingPowerProvider.getOperatorVotingPowerAt(
                        operator.addr,
                        initSetupParams.masterChain.vaults[j],
                        "",
                        uint48(vm.getBlockTimestamp()),
                        abi.encode(
                            IVotingPowerProvider.OperatorVaultVotingPowerHints({
                                isTokenRegisteredHint: new bytes(0),
                                stakeHints: new bytes(0)
                            })
                        )
                    ),
                    operatorVaultStake
                );
                assertEq(
                    votingPowerProvider.getOperatorVotingPowerAt(
                        operator.addr, vault, "", uint48(vm.getBlockTimestamp()), new bytes(0)
                    ),
                    0
                );
                assertEq(vaultVotingPowers1[j].vault, initSetupParams.masterChain.vaults[j]);
                assertEq(vaultVotingPowers1[j].votingPower, operatorVaultStake);
                assertEq(operatorVotingPowers1[i].operator, operator.addr);
                assertEq(operatorVotingPowers1[i].vaults[j].vault, initSetupParams.masterChain.vaults[j]);
                assertEq(operatorVotingPowers1[i].vaults[j].votingPower, operatorVaultStake);
                operatorStake += operatorVaultStake;
            }

            totalStake += operatorStake;
        }
        assertGt(totalStake, 0);
    }

    function test_RegisterOperator() public {
        votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[0]);

        (bool requireSlasher, uint48 minVaultEpochDuration) = votingPowerProvider.getSlashingData();
        address vault = _getVault_SymbioticCore(
            VaultParams({
                owner: getOperator(0).addr,
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

        vm.startPrank(getOperator(0).addr);
        votingPowerProvider.registerOperator();
        vm.stopPrank();

        votingPowerProvider.registerOperatorVault(getOperator(0).addr, vault);

        assertTrue(votingPowerProvider.isOperatorRegistered(getOperator(0).addr), "Operator should be registered");
        assertTrue(
            votingPowerProvider.isOperatorVaultRegistered(getOperator(0).addr, vault), "Vault should be registered"
        );
        assertTrue(votingPowerProvider.isOperatorVaultRegistered(vault), "Vault should be registered");

        vm.startPrank(getOperator(0).addr);
        votingPowerProvider.unregisterOperator();
        vm.stopPrank();

        assertFalse(votingPowerProvider.isOperatorRegistered(getOperator(0).addr), "Operator should be unregistered");
        assertTrue(
            votingPowerProvider.isOperatorVaultRegistered(getOperator(0).addr, vault), "Vault should be unregistered"
        );
        assertTrue(votingPowerProvider.isOperatorVaultRegistered(vault), "Vault should be unregistered");
    }

    function test_RegisterOperatorVaultExternal() public {
        votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[0]);
        (bool requireSlasher, uint48 minVaultEpochDuration) = votingPowerProvider.getSlashingData();
        address vault = _getVault_SymbioticCore(
            VaultParams({
                owner: getOperator(0).addr,
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

        vm.startPrank(getOperator(0).addr);
        votingPowerProvider.registerOperator();
        vm.stopPrank();

        votingPowerProvider.registerOperatorVault(getOperator(0).addr, vault);

        assertTrue(votingPowerProvider.isOperatorRegistered(getOperator(0).addr), "Operator should be registered");
        assertTrue(
            votingPowerProvider.isOperatorVaultRegistered(getOperator(0).addr, vault), "Vault should be registered"
        );
        assertTrue(votingPowerProvider.isOperatorVaultRegistered(vault), "Vault should be registered");

        vm.startPrank(getOperator(0).addr);
        votingPowerProvider.unregisterOperatorVault(getOperator(0).addr, vault);
        vm.stopPrank();

        assertTrue(votingPowerProvider.isOperatorRegistered(getOperator(0).addr), "Operator should be registered");
        assertFalse(
            votingPowerProvider.isOperatorVaultRegistered(getOperator(0).addr, vault), "Vault should be unregistered"
        );
        assertFalse(votingPowerProvider.isOperatorVaultRegistered(vault), "Vault should be unregistered");
    }

    function test_registerOperatorWithSignature() public {
        votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[0]);
        (bool requireSlasher, uint48 minVaultEpochDuration) = votingPowerProvider.getSlashingData();
        address operatorAddr = getOperator(0).addr;
        uint256 operatorPk = getOperator(0).privateKey;

        uint256 currentNonce = votingPowerProvider.nonces(operatorAddr);

        address someVault = _getVault_SymbioticCore(
            VaultParams({
                owner: operatorAddr,
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

        bytes32 registerOperatorTypehash = keccak256("RegisterOperator(address operator,uint256 nonce)");

        bytes32 structHash = keccak256(abi.encode(registerOperatorTypehash, operatorAddr, currentNonce));

        bytes32 digest = votingPowerProvider.hashTypedDataV4(structHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(operatorPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        votingPowerProvider.registerOperatorWithSignature(operatorAddr, signature);

        assertTrue(votingPowerProvider.isOperatorRegistered(operatorAddr), "Operator should be registered");

        votingPowerProvider.registerOperatorVault(operatorAddr, someVault);
        assertTrue(votingPowerProvider.isOperatorVaultRegistered(operatorAddr, someVault), "Vault should be registered");
        assertTrue(votingPowerProvider.isOperatorVaultRegistered(someVault), "Vault should be registered");
    }

    function test_registerOperatorWithSignature_RevertIfInvalidSig() public {
        address operatorAddr = getOperator(0).addr;
        uint256 operatorPk = getOperator(0).privateKey;
        (bool requireSlasher, uint48 minVaultEpochDuration) = votingPowerProvider.getSlashingData();
        uint256 wrongPk = 0x999999999;
        address someVault = _getVault_SymbioticCore(
            VaultParams({
                owner: operatorAddr,
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

        uint256 currentNonce = votingPowerProvider.nonces(operatorAddr);
        bytes32 registerOperatorTypehash = keccak256("RegisterOperator(address operator,address vault,uint256 nonce)");

        bytes32 structHash = keccak256(abi.encode(registerOperatorTypehash, operatorAddr, currentNonce));
        bytes32 digest = votingPowerProvider.hashTypedDataV4(structHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongPk, digest);
        bytes memory badSignature = abi.encodePacked(r, s, v);

        vm.expectRevert(IVotingPowerProvider.VotingPowerProvider_InvalidSignature.selector);
        votingPowerProvider.registerOperatorWithSignature(operatorAddr, badSignature);
    }

    function test_IncreaseNonce() public {
        address operatorAddr = getOperator(0).addr;
        uint256 oldNonce = votingPowerProvider.nonces(operatorAddr);
        assertEq(oldNonce, 0, "Initial nonce is 0");

        vm.prank(operatorAddr);
        votingPowerProvider.invalidateOldSignatures();

        uint256 newNonce = votingPowerProvider.nonces(operatorAddr);
        assertEq(newNonce, 1, "Nonce incremented by 1");
    }

    function test_unregisterOperatorWithSignature() public {
        address operatorAddr = getOperator(0).addr;
        uint256 operatorPk = getOperator(0).privateKey;

        vm.prank(operatorAddr);
        votingPowerProvider.registerOperator();
        assertTrue(votingPowerProvider.isOperatorRegistered(operatorAddr));

        uint256 currentNonce = votingPowerProvider.nonces(operatorAddr);
        bytes32 typehash = keccak256("UnregisterOperator(address operator,uint256 nonce)");
        bytes32 structHash = keccak256(abi.encode(typehash, operatorAddr, currentNonce));
        bytes32 digest = votingPowerProvider.hashTypedDataV4(structHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(operatorPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        votingPowerProvider.unregisterOperatorWithSignature(operatorAddr, signature);

        assertFalse(votingPowerProvider.isOperatorRegistered(operatorAddr), "Should be unregistered now");
    }
}
