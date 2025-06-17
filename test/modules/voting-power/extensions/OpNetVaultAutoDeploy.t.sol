// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {OpNetVaultAutoDeploy} from "../../../../src/contracts/modules/voting-power/extensions/OpNetVaultAutoDeploy.sol";
import {VotingPowerProvider} from "../../../../src/contracts/modules/voting-power/VotingPowerProvider.sol";
import {NoPermissionManager} from "../../../../test/mocks/NoPermissionManager.sol";
import {EqualStakeVPCalc} from
    "../../../../src/contracts/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {MultiToken} from "../../../../src/contracts/modules/voting-power/extensions/MultiToken.sol";
import {OperatorVaults} from "../../../../src/contracts/modules/voting-power/extensions/OperatorVaults.sol";
import {INetworkManager} from "../../../../src/interfaces/modules/base/INetworkManager.sol";
import {IOpNetVaultAutoDeploy} from
    "../../../../src/interfaces/modules/voting-power/extensions/IOpNetVaultAutoDeploy.sol";
import {IVotingPowerProvider} from "../../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {IOzEIP712} from "../../../../src/interfaces/modules/base/IOzEIP712.sol";
import {InitSetupTest} from "../../../InitSetup.sol";

contract TestOpNetVaultAutoDeploy is
    OpNetVaultAutoDeploy,
    NoPermissionManager,
    EqualStakeVPCalc,
    MultiToken,
    OperatorVaults
{
    constructor(
        address operatorRegistry,
        address vaultFactory,
        address vaultConfigurator
    ) VotingPowerProvider(operatorRegistry, vaultFactory) OpNetVaultAutoDeploy(vaultConfigurator) {}

    function initialize(
        IVotingPowerProvider.VotingPowerProviderInitParams memory initParams,
        IOpNetVaultAutoDeploy.OpNetVaultAutoDeployInitParams memory autoInit
    ) external initializer {
        __VotingPowerProvider_init(initParams);
        __OpNetVaultAutoDeploy_init(autoInit);
    }

    function _registerOperatorImpl(
        address operator
    ) internal override(OpNetVaultAutoDeploy, VotingPowerProvider) {
        super._registerOperatorImpl(operator);
    }

    function setSlashingWindow(
        uint48 slashingWindow
    ) public {
        _setSlashingWindow(slashingWindow);
    }
}

contract OpNetVaultAutoDeployTest is Test, InitSetupTest {
    TestOpNetVaultAutoDeploy deployer;
    address operator1;
    uint48 slashingWindow = 100;

    IOpNetVaultAutoDeploy.AutoDeployConfig validConfig;

    function setUp() public override {
        super.setUp();
        deployer = new TestOpNetVaultAutoDeploy(
            address(symbioticCore.operatorRegistry),
            address(symbioticCore.vaultFactory),
            address(symbioticCore.vaultConfigurator)
        );

        INetworkManager.NetworkManagerInitParams memory netInit =
            INetworkManager.NetworkManagerInitParams({network: vars.network.addr, subnetworkID: IDENTIFIER});
        IVotingPowerProvider.VotingPowerProviderInitParams memory vpInit = IVotingPowerProvider
            .VotingPowerProviderInitParams({
            networkManagerInitParams: netInit,
            ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "Auto", version: "1"}),
            slashingWindow: slashingWindow,
            token: initSetupParams.masterChain.tokens[0]
        });
        validConfig = IOpNetVaultAutoDeploy.AutoDeployConfig({
            collateral: initSetupParams.masterChain.tokens[0],
            burner: address(0x1),
            epochDuration: slashingWindow,
            withSlasher: true,
            isBurnerHook: false
        });
        IOpNetVaultAutoDeploy.OpNetVaultAutoDeployInitParams memory autoInit = IOpNetVaultAutoDeploy
            .OpNetVaultAutoDeployInitParams({
            isAutoDeployEnabled: false,
            config: validConfig,
            isSetMaxNetworkLimitHookEnabled: false
        });
        deployer.initialize(vpInit, autoInit);
        operator1 = getOperator(0).addr;
    }

    function test_BasicFlags() public {
        assertFalse(deployer.isAutoDeployEnabled());
        assertFalse(deployer.isSetMaxNetworkLimitHookEnabled());
        IOpNetVaultAutoDeploy.AutoDeployConfig memory cfg = deployer.getAutoDeployConfig();
        assertEq(cfg.collateral, validConfig.collateral);
        assertEq(cfg.epochDuration, validConfig.epochDuration);
    }

    function test_SetAutoDeployStatus() public {
        deployer.setAutoDeployStatus(true);
        assertTrue(deployer.isAutoDeployEnabled());
    }

    function test_SetAutoDeployConfig_InvalidCollateral() public {
        IOpNetVaultAutoDeploy.AutoDeployConfig memory cfg = validConfig;
        cfg.collateral = address(0);
        vm.expectRevert(IOpNetVaultAutoDeploy.OpNetVaultAutoDeploy_InvalidCollateral.selector);
        deployer.setAutoDeployConfig(cfg);
    }

    function test_SetAutoDeployConfig_InvalidEpochDurationZero() public {
        IOpNetVaultAutoDeploy.AutoDeployConfig memory cfg = validConfig;
        cfg.epochDuration = 0;
        vm.expectRevert(IOpNetVaultAutoDeploy.OpNetVaultAutoDeploy_InvalidEpochDuration.selector);
        deployer.setAutoDeployConfig(cfg);
    }

    function test_SetAutoDeployConfig_InvalidEpochDurationLessThanWindow() public {
        IOpNetVaultAutoDeploy.AutoDeployConfig memory cfg = validConfig;
        cfg.epochDuration = uint48(slashingWindow - 1);
        vm.expectRevert(IOpNetVaultAutoDeploy.OpNetVaultAutoDeploy_InvalidEpochDuration.selector);
        deployer.setAutoDeployConfig(cfg);
    }

    function test_SetAutoDeployConfig_InvalidWithSlasher() public {
        IOpNetVaultAutoDeploy.AutoDeployConfig memory cfg = validConfig;
        cfg.withSlasher = false;
        vm.expectRevert(IOpNetVaultAutoDeploy.OpNetVaultAutoDeploy_InvalidWithSlasher.selector);
        deployer.setAutoDeployConfig(cfg);
    }

    function test_SetAutoDeployConfig_InvalidBurnerHook() public {
        deployer.setSlashingWindow(0);
        IOpNetVaultAutoDeploy.AutoDeployConfig memory cfg = validConfig;
        cfg.isBurnerHook = true;
        cfg.withSlasher = false;
        vm.expectRevert(IOpNetVaultAutoDeploy.OpNetVaultAutoDeploy_InvalidBurnerHook.selector);
        deployer.setAutoDeployConfig(cfg);
    }

    function test_AutoDeployOnRegister() public {
        deployer.setAutoDeployStatus(true);
        vm.startPrank(operator1);
        deployer.registerOperator();
        vm.stopPrank();
        address v = deployer.getAutoDeployedVault(operator1);
        address[] memory vaults = deployer.getOperatorVaults(operator1);
        assertEq(vaults.length, 1);
        assertEq(v, vaults[0]);
    }

    function test_Location() public {
        bytes32 location = keccak256(abi.encode(uint256(keccak256("symbiotic.storage.OpNetVaultAutoDeploy")) - 1))
            & ~bytes32(uint256(0xff));
        assertEq(location, 0x85a64baaaf23c04aec63d80adaee49297f70e3944d69ec004fa7cee8ee6e8b00);
    }
}
