// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {VotingPowerProvider} from "../../../../src/contracts/modules/voting-power/VotingPowerProvider.sol";
import {VotingPowerProviderLogic} from
    "../../../../src/contracts/modules/voting-power/logic/VotingPowerProviderLogic.sol";
import {MultiToken} from "../../../../src/contracts/modules/voting-power/extensions/MultiToken.sol";
import {IVotingPowerProvider} from "../../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {INetworkManager} from "../../../../src/interfaces/modules/base/INetworkManager.sol";
import {IOzEIP712} from "../../../../src/interfaces/modules/base/IOzEIP712.sol";
import {NoPermissionManager} from "../../../../test/mocks/NoPermissionManager.sol";
import {EqualStakeVPCalc} from
    "../../../../src/contracts/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {OperatorVaults} from "../../../../src/contracts/modules/voting-power/extensions/OperatorVaults.sol";

import {BN254} from "../../../../src/contracts/libraries/utils/BN254.sol";
import "../../../MasterSetup.sol";

import {SlasherMock} from "../../../../test/mocks/SlasherMock.sol";

contract BaseSlashingTest is MasterSetupTest {
    function setUp() public override {
        SYMBIOTIC_CORE_PROJECT_ROOT = "lib/core/";
        MasterSetupTest.setUp();
    }

    function test_SlashVault() public {
        vm.warp(vm.getBlockTimestamp() + 1);

        SlasherMock slasher = new SlasherMock();

        assertEq(masterSetupParams.votingPowerProvider.getSlasher(), address(1));

        vm.prank(vars.deployer.addr);
        vm.expectRevert(abi.encodeWithSelector(IBaseSlashing.BaseSlashing_InvalidSlasher.selector));
        masterSetupParams.votingPowerProvider.setSlasher(address(0));

        vm.prank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider.setSlasher(address(slasher));

        assertEq(masterSetupParams.votingPowerProvider.getSlasher(), address(slasher));

        address operator = getOperator(0).addr;
        address[] memory vaults = masterSetupParams.votingPowerProvider.getSharedVaults();

        vm.prank(address(this));
        vm.expectRevert(abi.encodeWithSelector(IBaseSlashing.BaseSlashing_NotSlasher.selector));
        masterSetupParams.votingPowerProvider.slashVault(
            uint48(vm.getBlockTimestamp() - 1), vaults[0], operator, 100, new bytes(0)
        );

        (bool success, bytes memory response) = slasher.slashVault(
            address(masterSetupParams.votingPowerProvider),
            uint48(vm.getBlockTimestamp() - 1),
            vaults[0],
            operator,
            100,
            new bytes(0)
        );

        assertTrue(success, "Slashing should be successful");
        assertEq(response, abi.encode(uint256(100)));
    }

    function test_SlashVault_WithHints() public {
        vm.warp(vm.getBlockTimestamp() + 1);

        SlasherMock slasher = new SlasherMock();

        assertEq(masterSetupParams.votingPowerProvider.getSlasher(), address(1));

        vm.prank(vars.deployer.addr);
        vm.expectRevert(abi.encodeWithSelector(IBaseSlashing.BaseSlashing_InvalidSlasher.selector));
        masterSetupParams.votingPowerProvider.setSlasher(address(0));

        vm.prank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider.setSlasher(address(slasher));

        assertEq(masterSetupParams.votingPowerProvider.getSlasher(), address(slasher));

        address operator = getOperator(0).addr;
        address[] memory vaults = masterSetupParams.votingPowerProvider.getSharedVaults();

        (bool success, bytes memory response) = slasher.slashVault(
            address(masterSetupParams.votingPowerProvider),
            uint48(vm.getBlockTimestamp() - 1),
            vaults[0],
            operator,
            100,
            abi.encode(
                IBaseSlashing.SlashVaultHints({
                    operatorRegisteredHint: new bytes(0),
                    operatorVaultRegisteredHint: new bytes(0),
                    sharedVaultRegisteredHint: new bytes(0),
                    isTokenRegisteredHint: new bytes(0),
                    slashHints: new bytes(0)
                })
            )
        );

        assertTrue(success, "Slashing should be successful");
        assertEq(response, abi.encode(uint256(100)));
    }

    function test_SlashVaultUnsafe() public {
        vm.warp(vm.getBlockTimestamp() + 1);

        SlasherMock slasher = new SlasherMock();

        vm.prank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider.setSlasher(address(slasher));

        address operator = getOperator(0).addr;
        address[] memory vaults = masterSetupParams.votingPowerProvider.getSharedVaults();

        (bool success, bytes memory response) = slasher.slashVaultUnsafe(
            address(masterSetupParams.votingPowerProvider),
            uint48(vm.getBlockTimestamp() - 1),
            vaults[0],
            operator,
            100,
            new bytes(0)
        );

        assertTrue(success, "Slashing should be successful");
        assertEq(response, abi.encode(uint256(100)));

        (bool requireSlasher, uint48 minVaultEpochDuration) = masterSetupParams.votingPowerProvider.getSlashingData();
        address vault = _getVault_SymbioticCore(
            VaultParams({
                owner: operator,
                collateral: initSetupParams.masterChain.tokens[0],
                burner: 0x000000000000000000000000000000000000dEaD,
                epochDuration: minVaultEpochDuration + 1,
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

        vm.expectRevert(abi.encodeWithSelector(IBaseSlashing.BaseSlashing_NoSlasher.selector));
        slasher.slashVaultUnsafe(
            address(masterSetupParams.votingPowerProvider),
            uint48(vm.getBlockTimestamp() - 1),
            vault,
            operator,
            100,
            new bytes(0)
        );
    }

    function test_SlashVault_UnregisteredOperatorSlash() public {
        address operator = getOperator(0).addr;
        vm.startPrank(operator);
        masterSetupParams.votingPowerProvider.unregisterOperator();
        vm.stopPrank();

        vm.warp(vm.getBlockTimestamp() + 1);

        SlasherMock slasher = new SlasherMock();

        vm.prank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider.setSlasher(address(slasher));

        address[] memory vaults = masterSetupParams.votingPowerProvider.getSharedVaults();

        vm.expectRevert(abi.encodeWithSelector(IBaseSlashing.BaseSlashing_UnregisteredOperatorSlash.selector));
        slasher.slashVault(
            address(masterSetupParams.votingPowerProvider),
            uint48(vm.getBlockTimestamp() - 1),
            vaults[0],
            operator,
            100,
            new bytes(0)
        );
    }

    function test_SlashVault_UnregisteredVaultSlash() public {
        address operator = getOperator(0).addr;
        address[] memory vaults = masterSetupParams.votingPowerProvider.getSharedVaults();

        vm.startPrank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider.unregisterSharedVault(vaults[0]);
        vm.stopPrank();

        vm.warp(vm.getBlockTimestamp() + 1);

        SlasherMock slasher = new SlasherMock();

        vm.prank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider.setSlasher(address(slasher));

        vm.expectRevert(abi.encodeWithSelector(IBaseSlashing.BaseSlashing_UnregisteredVaultSlash.selector));
        slasher.slashVault(
            address(masterSetupParams.votingPowerProvider),
            uint48(vm.getBlockTimestamp() - 1),
            vaults[0],
            operator,
            100,
            new bytes(0)
        );
    }

    function test_SlashVault_UnregisteredTokenSlash() public {
        address operator = getOperator(0).addr;
        address[] memory vaults = masterSetupParams.votingPowerProvider.getSharedVaults();

        vm.startPrank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider.unregisterToken(initSetupParams.masterChain.tokens[0]);
        vm.stopPrank();

        vm.warp(vm.getBlockTimestamp() + 1);

        SlasherMock slasher = new SlasherMock();

        vm.prank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider.setSlasher(address(slasher));

        vm.expectRevert(abi.encodeWithSelector(IBaseSlashing.BaseSlashing_UnregisteredTokenSlash.selector));
        slasher.slashVault(
            address(masterSetupParams.votingPowerProvider),
            uint48(vm.getBlockTimestamp() - 1),
            vaults[0],
            operator,
            100,
            new bytes(0)
        );
    }

    function test_SlashVault_VetoSlasher() public {
        address operator = getOperator(0).addr;
        (bool requireSlasher, uint48 minVaultEpochDuration) = masterSetupParams.votingPowerProvider.getSlashingData();
        address vault = _getVault_SymbioticCore(
            VaultParams({
                owner: operator,
                collateral: initSetupParams.masterChain.tokens[0],
                burner: 0x000000000000000000000000000000000000dEaD,
                epochDuration: minVaultEpochDuration + 1,
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
        vm.prank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider.registerSharedVault(vault);

        vm.warp(vm.getBlockTimestamp() + 1);

        SlasherMock slasher = new SlasherMock();

        vm.prank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider.setSlasher(address(slasher));

        (bool success, bytes memory response) = slasher.slashVault(
            address(masterSetupParams.votingPowerProvider),
            uint48(vm.getBlockTimestamp() - 1),
            vault,
            operator,
            100,
            new bytes(0)
        );

        assertFalse(success);
        assertTrue(response.length == 4);

        _networkSetMaxNetworkLimit_SymbioticCore(
            masterSetupParams.votingPowerProvider.NETWORK(), vault, 0, type(uint256).max
        );

        vm.startPrank(operator);
        symbioticCore.operatorVaultOptInService.optIn(vault);
        ISymbioticNetworkRestakeDelegator(ISymbioticVault(vault).delegator()).setNetworkLimit(
            masterSetupParams.votingPowerProvider.SUBNETWORK(), type(uint256).max
        );
        ISymbioticNetworkRestakeDelegator(ISymbioticVault(vault).delegator()).setOperatorNetworkShares(
            masterSetupParams.votingPowerProvider.SUBNETWORK(), operator, 1
        );
        vm.stopPrank();

        _stakerDeposit_SymbioticCore(getStaker(0).addr, vault, 1_000_000);

        vm.warp(vm.getBlockTimestamp() + 1);

        (success, response) = slasher.slashVault(
            address(masterSetupParams.votingPowerProvider),
            uint48(vm.getBlockTimestamp() - 1),
            vault,
            operator,
            100,
            new bytes(0)
        );

        assertTrue(success, "Slashing should be successful");
        assertEq(response, abi.encode(uint256(0)));

        uint256 slashedAmount;
        (success, slashedAmount) = slasher.executeSlashVault(
            address(masterSetupParams.votingPowerProvider), vault, abi.decode(response, (uint256)), new bytes(0)
        );

        assertTrue(success, "Slashing should be successful");
        assertEq(slashedAmount, 100);
    }

    function test_ExecuteSlashVaul_NotVetoSlasher() public {
        vm.warp(vm.getBlockTimestamp() + 1);

        SlasherMock slasher = new SlasherMock();

        vm.prank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider.setSlasher(address(slasher));

        address[] memory vaults = masterSetupParams.votingPowerProvider.getSharedVaults();

        vm.expectRevert(abi.encodeWithSelector(IBaseSlashing.BaseSlashing_NotVetoSlasher.selector));

        slasher.executeSlashVault(address(masterSetupParams.votingPowerProvider), vaults[0], 0, new bytes(0));
    }

    function test_Location() public {
        bytes32 location =
            keccak256(abi.encode(uint256(keccak256("symbiotic.storage.BaseSlashing")) - 1)) & ~bytes32(uint256(0xff));
        assertEq(location, 0xcd08f9337bf45f7ebac10e65ed25c2483d3efb012be3dbf2b4de227af3bf9400);
    }
}
