// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {VotingPowerProvider} from "../../../../src/modules/voting-power/VotingPowerProvider.sol";
import {VotingPowerProviderLogic} from "../../../../src/modules/voting-power/logic/VotingPowerProviderLogic.sol";
import {MultiToken} from "../../../../src/modules/voting-power/extensions/MultiToken.sol";
import {IVotingPowerProvider} from "../../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {INetworkManager} from "../../../../src/interfaces/modules/base/INetworkManager.sol";
import {IOzEIP712} from "../../../../src/interfaces/modules/base/IOzEIP712.sol";
import {NoPermissionManager} from "../../../../test/mocks/NoPermissionManager.sol";
import {EqualStakeVPCalc} from "../../../../src/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {OperatorVaults} from "../../../../src/modules/voting-power/extensions/OperatorVaults.sol";

import {BN254} from "../../../../src/libraries/utils/BN254.sol";
import "../../../MasterSetup.sol";

import {RewarderMock} from "../../../../test/mocks/RewarderMock.sol";

import {SymbioticRewardsBindings} from "@symbioticfi/rewards/test/integration/SymbioticRewardsBindings.sol";
import "@symbioticfi/rewards/test/integration/SymbioticRewardsImports.sol";

contract BaseRewardsTest is MasterSetupTest, SymbioticRewardsBindings {
    string public SYMBIOTIC_REWARDS_PROJECT_ROOT = "";

    ISymbioticDefaultStakerRewardsFactory public symbioticDefaultStakerRewardsFactory;
    ISymbioticDefaultOperatorRewardsFactory public symbioticDefaultOperatorRewardsFactory;

    function setUp() public override {
        SYMBIOTIC_CORE_PROJECT_ROOT = "lib/core/";
        SYMBIOTIC_REWARDS_PROJECT_ROOT = "lib/rewards/";
        MasterSetupTest.setUp();
        _initRewards_SymbioticRewards();
    }

    function test_StakerRewards() public {
        vm.warp(vm.getBlockTimestamp() + 1);

        RewarderMock rewarder = new RewarderMock();

        assertEq(masterSetupParams.votingPowerProvider.getRewarder(), address(1));

        vm.prank(vars.deployer.addr);
        vm.expectRevert(abi.encodeWithSelector(IBaseRewards.BaseRewards_InvalidRewarder.selector));
        masterSetupParams.votingPowerProvider.setRewarder(address(0));

        vm.prank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider.setRewarder(address(rewarder));

        assertEq(masterSetupParams.votingPowerProvider.getRewarder(), address(rewarder));

        address[] memory vaults = masterSetupParams.votingPowerProvider.getSharedVaults();

        address stakerRewards = _getDefaultStakerRewards_SymbioticRewards(vaults[0], 0, address(this));

        _deal_Symbiotic(initSetupParams.masterChain.tokens[0], address(this), 100_000, true);
        IERC20(initSetupParams.masterChain.tokens[0]).transfer(address(masterSetupParams.votingPowerProvider), 100);

        vm.prank(address(this));
        vm.expectRevert(abi.encodeWithSelector(IBaseRewards.BaseRewards_NotRewarder.selector));
        masterSetupParams.votingPowerProvider.distributeStakerRewards(
            stakerRewards,
            initSetupParams.masterChain.tokens[0],
            100,
            abi.encode(uint48(vm.getBlockTimestamp() - 1), type(uint256).max, new bytes(0), new bytes(0))
        );

        rewarder.distributeStakerRewards(
            address(masterSetupParams.votingPowerProvider),
            stakerRewards,
            initSetupParams.masterChain.tokens[0],
            100,
            abi.encode(uint48(vm.getBlockTimestamp() - 1), type(uint256).max, new bytes(0), new bytes(0))
        );

        assertEq(
            ISymbioticDefaultStakerRewards(stakerRewards).rewardsLength(
                initSetupParams.masterChain.tokens[0], masterSetupParams.votingPowerProvider.NETWORK()
            ),
            1
        );
        (uint256 amount, uint48 timestamp) = ISymbioticDefaultStakerRewards(stakerRewards).rewards(
            initSetupParams.masterChain.tokens[0], masterSetupParams.votingPowerProvider.NETWORK(), 0
        );
        assertEq(amount, 100);
        assertEq(timestamp, uint48(vm.getBlockTimestamp() - 1));
    }

    function test_OperatorRewards() public {
        vm.warp(vm.getBlockTimestamp() + 1);

        RewarderMock rewarder = new RewarderMock();

        assertEq(masterSetupParams.votingPowerProvider.getRewarder(), address(1));

        vm.prank(vars.deployer.addr);
        vm.expectRevert(abi.encodeWithSelector(IBaseRewards.BaseRewards_InvalidRewarder.selector));
        masterSetupParams.votingPowerProvider.setRewarder(address(0));

        vm.prank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider.setRewarder(address(rewarder));

        assertEq(masterSetupParams.votingPowerProvider.getRewarder(), address(rewarder));

        address operatorRewards = _getDefaultOperatorRewards_SymbioticRewards();

        _deal_Symbiotic(initSetupParams.masterChain.tokens[0], address(this), 100_000, true);
        IERC20(initSetupParams.masterChain.tokens[0]).transfer(address(masterSetupParams.votingPowerProvider), 100);

        vm.prank(address(this));
        vm.expectRevert(abi.encodeWithSelector(IBaseRewards.BaseRewards_NotRewarder.selector));
        masterSetupParams.votingPowerProvider.distributeOperatorRewards(
            operatorRewards, initSetupParams.masterChain.tokens[0], 100, bytes32(uint256(1))
        );

        rewarder.distributeOperatorRewards(
            address(masterSetupParams.votingPowerProvider),
            operatorRewards,
            initSetupParams.masterChain.tokens[0],
            100,
            bytes32(uint256(1))
        );

        assertEq(
            ISymbioticDefaultOperatorRewards(operatorRewards).root(
                masterSetupParams.votingPowerProvider.NETWORK(), initSetupParams.masterChain.tokens[0]
            ),
            bytes32(uint256(1))
        );
    }

    function _initRewards_SymbioticRewards() internal virtual {
        address defaultStakerRewardsImplementation = deployCode(
            string.concat(SYMBIOTIC_REWARDS_PROJECT_ROOT, "out/DefaultStakerRewards.sol/DefaultStakerRewards.json"),
            abi.encode(address(symbioticCore.vaultFactory), address(symbioticCore.networkMiddlewareService))
        );
        symbioticDefaultStakerRewardsFactory = ISymbioticDefaultStakerRewardsFactory(
            deployCode(
                string.concat(
                    SYMBIOTIC_REWARDS_PROJECT_ROOT,
                    "out/DefaultStakerRewardsFactory.sol/DefaultStakerRewardsFactory.json"
                ),
                abi.encode(defaultStakerRewardsImplementation)
            )
        );
        address defaultOperatorRewardsImplementation = deployCode(
            string.concat(SYMBIOTIC_REWARDS_PROJECT_ROOT, "out/DefaultOperatorRewards.sol/DefaultOperatorRewards.json"),
            abi.encode(address(symbioticCore.networkMiddlewareService))
        );
        symbioticDefaultOperatorRewardsFactory = ISymbioticDefaultOperatorRewardsFactory(
            deployCode(
                string.concat(
                    SYMBIOTIC_REWARDS_PROJECT_ROOT,
                    "out/DefaultOperatorRewardsFactory.sol/DefaultOperatorRewardsFactory.json"
                ),
                abi.encode(defaultOperatorRewardsImplementation)
            )
        );
    }

    function test_Location() public {
        bytes32 location =
            keccak256(abi.encode(uint256(keccak256("symbiotic.storage.BaseRewards")) - 1)) & ~bytes32(uint256(0xff));
        assertEq(location, 0xbda599e6417b60ef01d2592ea6468e27d9dc233383dcd1f33c49128d08d88b00);
    }

    function _getDefaultStakerRewards_SymbioticRewards(
        address vault,
        uint256 adminFee,
        address admin
    ) internal virtual returns (address) {
        return _createDefaultStakerRewards_SymbioticRewards({
            symbioticDefaultStakerRewardsFactory: symbioticDefaultStakerRewardsFactory,
            who: address(this),
            vault: vault,
            adminFee: adminFee,
            defaultAdminRoleHolder: admin,
            adminFeeClaimRoleHolder: admin,
            adminFeeSetRoleHolder: admin
        });
    }

    function _getDefaultOperatorRewards_SymbioticRewards() internal virtual returns (address) {
        return _createDefaultOperatorRewards_SymbioticRewards({
            symbioticDefaultOperatorRewardsFactory: symbioticDefaultOperatorRewardsFactory,
            who: address(this)
        });
    }
}
