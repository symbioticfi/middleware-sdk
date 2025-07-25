// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {VotingPowerProvider} from "../../../../../src/modules/voting-power/VotingPowerProvider.sol";
import {VotingPowerProviderLogic} from "../../../../../src/modules/voting-power/logic/VotingPowerProviderLogic.sol";
import {MultiToken} from "../../../../../src/modules/voting-power/extensions/MultiToken.sol";
import {IVotingPowerProvider} from "../../../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {INetworkManager} from "../../../../../src/interfaces/modules/base/INetworkManager.sol";
import {IOzEIP712} from "../../../../../src/interfaces/modules/base/IOzEIP712.sol";
import {NoPermissionManager} from "../../../../../test/mocks/NoPermissionManager.sol";
import {EqualStakeVPCalc} from "../../../../../src/modules/voting-power/common/voting-power-calc/EqualStakeVPCalc.sol";
import {NormalizedTokenDecimalsVPCalc} from
    "../../../../../src/modules/voting-power/common/voting-power-calc/NormalizedTokenDecimalsVPCalc.sol";
import {WeightedTokensVPCalc} from
    "../../../../../src/modules/voting-power/common/voting-power-calc/WeightedTokensVPCalc.sol";
import {OperatorVaults} from "../../../../../src/modules/voting-power/extensions/OperatorVaults.sol";

import {BN254} from "../../../../../src/libraries/utils/BN254.sol";
import "../../../../InitSetup.sol";

contract MockToken is ERC20 {
    uint8 private immutable _decimals;

    constructor(string memory name_, string memory symbol_, uint8 dec_) ERC20(name_, symbol_) {
        _decimals = dec_;
        _mint(msg.sender, type(uint128).max); // plenty for tests
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

contract TestVotingPowerProvider is VotingPowerProvider, WeightedTokensVPCalc, NoPermissionManager {
    constructor(address operatorRegistry, address vaultFactory) VotingPowerProvider(operatorRegistry, vaultFactory) {}

    function initialize(
        IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit
    ) external initializer {
        __VotingPowerProvider_init(votingPowerProviderInit);
    }

    function getTokensLength() external view returns (uint256) {
        return _getTokensLength();
    }

    function getOperatorsLength() external view returns (uint256) {
        return _getOperatorsLength();
    }

    function getSharedVaultsLength() external view returns (uint256) {
        return _getSharedVaultsLength();
    }

    function getOperatorVaultsLength(
        address operator
    ) external view returns (uint256) {
        return _getOperatorVaultsLength(operator);
    }

    function getOperatorStakeAt(address operator, address vault, uint48 timestamp) external view returns (uint256) {
        return _getOperatorStakeAt(operator, vault, timestamp);
    }

    function getOperatorStake(address operator, address vault) external view returns (uint256) {
        return _getOperatorStake(operator, vault);
    }

    function getOperatorVotingPowerAt(
        address operator,
        address vault,
        bytes memory extraData,
        uint48 timestamp
    ) external view returns (uint256) {
        return _getOperatorVotingPowerAt(operator, vault, extraData, timestamp);
    }

    function getOperatorVotingPower(
        address operator,
        address vault,
        bytes memory extraData
    ) external view returns (uint256) {
        return _getOperatorVotingPower(operator, vault, extraData);
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

    function validateVaultSlashing(
        address vault
    ) external view returns (bool) {
        return VotingPowerProviderLogic._validateVaultSlashing(vault);
    }
}

contract WeightedTokensVPCalcTest is InitSetupTest {
    TestVotingPowerProvider private votingPowerProvider;

    address operator1 = address(0xAAA1);
    address operator2 = address(0xAAA2);
    address tokenA = address(0xBEE1);
    address tokenB = address(0xBEE2);

    address validOperator = address(0x1111);
    address invalidOperator = address(0x2222);

    function setUp() public override {
        InitSetupTest.setUp();

        votingPowerProvider =
            new TestVotingPowerProvider(address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory));

        INetworkManager.NetworkManagerInitParams memory netInit =
            INetworkManager.NetworkManagerInitParams({network: vars.network.addr, subnetworkId: IDENTIFIER});

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

    function test_CheckStakesTokenWeight() public {
        votingPowerProvider =
            new TestVotingPowerProvider(address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory));

        INetworkManager.NetworkManagerInitParams memory netInit =
            INetworkManager.NetworkManagerInitParams({network: vars.network.addr, subnetworkId: IDENTIFIER});

        MockToken mockToken = new MockToken("MockToken", "MTK", 18);

        IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit = IVotingPowerProvider
            .VotingPowerProviderInitParams({
            networkManagerInitParams: netInit,
            ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "MyVotingPowerProvider", version: "1"}),
            requireSlasher: true,
            minVaultEpochDuration: 100,
            token: address(mockToken)
        });

        votingPowerProvider.initialize(votingPowerProviderInit);

        _networkSetMiddleware_SymbioticCore(vars.network.addr, address(votingPowerProvider));

        for (uint256 i; i < SYMBIOTIC_CORE_NUMBER_OF_OPERATORS; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            vm.startPrank(operator.addr);
            votingPowerProvider.registerOperator(operator.addr);
            vm.stopPrank();
        }

        for (uint256 i; i < SYMBIOTIC_CORE_NUMBER_OF_OPERATORS; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            (bool requireSlasher, uint48 minVaultEpochDuration) = votingPowerProvider.getSlashingData();
            address operatorVault = _getVault_SymbioticCore(
                VaultParams({
                    owner: operator.addr,
                    collateral: address(mockToken),
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
            _deal_Symbiotic(address(mockToken), getStaker(0).addr, type(uint128).max, true);
            _stakerDeposit_SymbioticCore(getStaker(0).addr, operatorVault, 1000 + i);
            vm.startPrank(vars.network.addr);
            votingPowerProvider.registerOperatorVault(operator.addr, operatorVault);
            vm.stopPrank();
        }

        for (uint256 i; i < SYMBIOTIC_CORE_NUMBER_OF_OPERATORS; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            address[] memory operatorVaults = votingPowerProvider.getOperatorVaults(operator.addr);
            assertEq(
                votingPowerProvider.getOperatorVotingPower(operator.addr, operatorVaults[0], ""),
                (1000 + i) * 10 ** (24 - 18) * 10 ** 12
            );
        }

        votingPowerProvider.setTokenWeight(address(mockToken), 10 ** 5);

        for (uint256 i; i < SYMBIOTIC_CORE_NUMBER_OF_OPERATORS; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            address[] memory operatorVaults = votingPowerProvider.getOperatorVaults(operator.addr);
            assertEq(
                votingPowerProvider.getOperatorVotingPower(operator.addr, operatorVaults[0], ""),
                (1000 + i) * 10 ** (24 - 18) * 10 ** 5
            );
        }
    }
}
