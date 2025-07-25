// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";

import {VotingPowerProvider} from "../../../../../src/modules/voting-power/VotingPowerProvider.sol";
import {VotingPowerProviderLogic} from "../../../../../src/modules/voting-power/logic/VotingPowerProviderLogic.sol";
import {IVotingPowerProvider} from "../../../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {INetworkManager} from "../../../../../src/interfaces/modules/base/INetworkManager.sol";
import {IOzEIP712} from "../../../../../src/interfaces/modules/base/IOzEIP712.sol";

import {PricedTokensChainlinkVPCalc} from
    "../../../../../src/modules/voting-power/common/voting-power-calc/PricedTokensChainlinkVPCalc.sol";
import {NoPermissionManager} from "../../../../../test/mocks/NoPermissionManager.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import "../../../../InitSetup.sol";

contract TestVotingPowerProvider is VotingPowerProvider, PricedTokensChainlinkVPCalc, NoPermissionManager {
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

contract PricedTokensChainlinkVPCalcTest is InitSetupTest {
    TestVotingPowerProvider private votingPowerProvider;

    address operator1 = address(0xAAA1);
    address operator2 = address(0xAAA2);
    address tokenA = address(0xBEE1);
    address tokenB = address(0xBEE2);

    address validOperator = address(0x1111);
    address invalidOperator = address(0x2222);

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;

    address constant WETH_USD_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address constant WBTC_USD_FEED = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;

    uint256 constant FORK_BLOCK_INITIAL = 21_200_000;
    uint256 constant FORK_BLOCK_LATER = 21_400_000;

    function setUp() public override {}

    function test_ChainlinkCalcTracksRealPrice() public {
        uint256[] memory blockNumbers = new uint256[](2);
        blockNumbers[0] = FORK_BLOCK_INITIAL;
        blockNumbers[1] = FORK_BLOCK_LATER;

        for (uint256 b; b < blockNumbers.length; ++b) {
            vm.createSelectFork("mainnet", blockNumbers[b]);

            SYMBIOTIC_INIT_BLOCK = blockNumbers[b];
            InitSetupTest.setUp();

            votingPowerProvider = new TestVotingPowerProvider(
                address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory)
            );

            _registerOperator_SymbioticCore(symbioticCore, operator1);
            _registerOperator_SymbioticCore(symbioticCore, operator2);

            _registerOperator_SymbioticCore(symbioticCore, validOperator);

            INetworkManager.NetworkManagerInitParams memory netInit =
                INetworkManager.NetworkManagerInitParams({network: vars.network.addr, subnetworkId: IDENTIFIER});

            IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit = IVotingPowerProvider
                .VotingPowerProviderInitParams({
                networkManagerInitParams: netInit,
                ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "MyVotingPowerProvider", version: "1"}),
                requireSlasher: true,
                minVaultEpochDuration: 100,
                token: WETH
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
                        collateral: WETH,
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
                _deal_Symbiotic(WETH, getStaker(0).addr, type(uint128).max, false);
                _stakerDeposit_SymbioticCore(getStaker(0).addr, operatorVault, 1000 + i);
                vm.startPrank(vars.network.addr);
                votingPowerProvider.registerOperatorVault(operator.addr, operatorVault);
                vm.stopPrank();
            }

            votingPowerProvider.setTokenHops(
                WETH, [WETH_USD_FEED, WBTC_USD_FEED], [false, false], [uint48(1_000_000), uint48(1_000_000)]
            );
            votingPowerProvider.setTokenHops(WBTC, [WBTC_USD_FEED, address(0)], [false, false], [uint48(1_000_000), 0]);

            (address[2] memory aggregators, bool[2] memory inverts, uint48[2] memory stalenessDurations) =
                votingPowerProvider.getTokenHops(WETH);
            assertEq(aggregators[0], WETH_USD_FEED);
            assertEq(inverts[0], false);
            assertEq(stalenessDurations[0], uint48(1_000_000));
            assertEq(aggregators[1], WBTC_USD_FEED);
            assertEq(inverts[1], false);
            assertEq(stalenessDurations[1], uint48(1_000_000));

            (aggregators, inverts, stalenessDurations) =
                votingPowerProvider.getTokenHopsAt(WETH, uint48(vm.getBlockTimestamp()));
            assertEq(aggregators[0], WETH_USD_FEED);
            assertEq(inverts[0], false);
            assertEq(stalenessDurations[0], uint48(1_000_000));
            assertEq(aggregators[1], WBTC_USD_FEED);
            assertEq(inverts[1], false);
            assertEq(stalenessDurations[1], uint48(1_000_000));

            AggregatorV3Interface wethFeed = AggregatorV3Interface(WETH_USD_FEED);
            (, int256 wethAnswer,,,) = wethFeed.latestRoundData();
            uint8 wethPriceDecimals = wethFeed.decimals();
            assertEq(wethPriceDecimals, 8);

            AggregatorV3Interface wbtcFeed = AggregatorV3Interface(WBTC_USD_FEED);
            (, int256 wbtcAnswer,,,) = wbtcFeed.latestRoundData();
            uint8 wbtcPriceDecimals = wbtcFeed.decimals();
            assertEq(wbtcPriceDecimals, 8);

            for (uint256 i; i < SYMBIOTIC_CORE_NUMBER_OF_OPERATORS; ++i) {
                Vm.Wallet memory operator = getOperator(i);
                address[] memory operatorVaults = votingPowerProvider.getOperatorVaults(operator.addr);

                uint256 expectedVP = (1000 + i) * 10 ** (24 - 18)
                    * ((uint256(wethAnswer) * 10 ** (18 - 8)) * (uint256(wbtcAnswer) * 10 ** (18 - 8)) / 10 ** 18);
                console2.log("expectedVP", expectedVP);
                assertEq(votingPowerProvider.getOperatorVotingPower(operator.addr, operatorVaults[0], ""), expectedVP);
            }
        }
    }

    function test_ChainlinkCalcTracksRealPriceWithInvert() public {
        uint256[] memory blockNumbers = new uint256[](2);
        blockNumbers[0] = FORK_BLOCK_INITIAL;
        blockNumbers[1] = FORK_BLOCK_LATER;

        for (uint256 b; b < blockNumbers.length; ++b) {
            vm.createSelectFork("mainnet", blockNumbers[b]);

            SYMBIOTIC_INIT_BLOCK = blockNumbers[b];
            InitSetupTest.setUp();

            votingPowerProvider = new TestVotingPowerProvider(
                address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory)
            );

            _registerOperator_SymbioticCore(symbioticCore, operator1);
            _registerOperator_SymbioticCore(symbioticCore, operator2);

            _registerOperator_SymbioticCore(symbioticCore, validOperator);

            INetworkManager.NetworkManagerInitParams memory netInit =
                INetworkManager.NetworkManagerInitParams({network: vars.network.addr, subnetworkId: IDENTIFIER});

            IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit = IVotingPowerProvider
                .VotingPowerProviderInitParams({
                networkManagerInitParams: netInit,
                ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "MyVotingPowerProvider", version: "1"}),
                requireSlasher: true,
                minVaultEpochDuration: 100,
                token: WETH
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
                        collateral: WETH,
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
                _deal_Symbiotic(WETH, getStaker(0).addr, type(uint128).max, false);
                _stakerDeposit_SymbioticCore(getStaker(0).addr, operatorVault, 1000 + i);
                vm.startPrank(vars.network.addr);
                votingPowerProvider.registerOperatorVault(operator.addr, operatorVault);
                vm.stopPrank();
            }

            votingPowerProvider.setTokenHops(
                WETH, [WETH_USD_FEED, WBTC_USD_FEED], [false, true], [uint48(1_000_000), uint48(1_000_000)]
            );
            votingPowerProvider.setTokenHops(WBTC, [WBTC_USD_FEED, address(0)], [false, true], [uint48(1_000_000), 0]);

            (address[2] memory aggregators, bool[2] memory inverts, uint48[2] memory stalenessDurations) =
                votingPowerProvider.getTokenHops(WETH);
            assertEq(aggregators[0], WETH_USD_FEED);
            assertEq(inverts[0], false);
            assertEq(stalenessDurations[0], uint48(1_000_000));
            assertEq(aggregators[1], WBTC_USD_FEED);
            assertEq(inverts[1], true);
            assertEq(stalenessDurations[1], uint48(1_000_000));

            (aggregators, inverts, stalenessDurations) =
                votingPowerProvider.getTokenHopsAt(WETH, uint48(vm.getBlockTimestamp()));
            assertEq(aggregators[0], WETH_USD_FEED);
            assertEq(inverts[0], false);
            assertEq(stalenessDurations[0], uint48(1_000_000));
            assertEq(aggregators[1], WBTC_USD_FEED);
            assertEq(inverts[1], true);
            assertEq(stalenessDurations[1], uint48(1_000_000));

            AggregatorV3Interface wethFeed = AggregatorV3Interface(WETH_USD_FEED);
            (, int256 wethAnswer,,,) = wethFeed.latestRoundData();
            uint8 wethPriceDecimals = wethFeed.decimals();
            assertEq(wethPriceDecimals, 8);

            AggregatorV3Interface wbtcFeed = AggregatorV3Interface(WBTC_USD_FEED);
            (, int256 wbtcAnswer,,,) = wbtcFeed.latestRoundData();
            uint8 wbtcPriceDecimals = wbtcFeed.decimals();
            assertEq(wbtcPriceDecimals, 8);

            for (uint256 i; i < SYMBIOTIC_CORE_NUMBER_OF_OPERATORS; ++i) {
                Vm.Wallet memory operator = getOperator(i);
                address[] memory operatorVaults = votingPowerProvider.getOperatorVaults(operator.addr);

                uint256 expectedVP = (1000 + i) * 10 ** (24 - 18)
                    * (
                        (uint256(wethAnswer) * 10 ** (18 - 8)) * (10 ** 36 / (uint256(wbtcAnswer) * 10 ** (18 - 8)))
                            / 10 ** 18
                    );

                assertEq(votingPowerProvider.getOperatorVotingPower(operator.addr, operatorVaults[0], ""), expectedVP);
            }
        }
    }

    function test_ChainlinkCalcTracksRealPriceStale() public {
        uint256[] memory blockNumbers = new uint256[](2);
        blockNumbers[0] = FORK_BLOCK_INITIAL;
        blockNumbers[1] = FORK_BLOCK_LATER;

        for (uint256 b; b < blockNumbers.length; ++b) {
            vm.createSelectFork("mainnet", blockNumbers[b]);

            SYMBIOTIC_INIT_BLOCK = blockNumbers[b];
            InitSetupTest.setUp();

            votingPowerProvider = new TestVotingPowerProvider(
                address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory)
            );

            _registerOperator_SymbioticCore(symbioticCore, operator1);
            _registerOperator_SymbioticCore(symbioticCore, operator2);

            _registerOperator_SymbioticCore(symbioticCore, validOperator);

            INetworkManager.NetworkManagerInitParams memory netInit =
                INetworkManager.NetworkManagerInitParams({network: vars.network.addr, subnetworkId: IDENTIFIER});

            IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit = IVotingPowerProvider
                .VotingPowerProviderInitParams({
                networkManagerInitParams: netInit,
                ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "MyVotingPowerProvider", version: "1"}),
                requireSlasher: true,
                minVaultEpochDuration: 100,
                token: WETH
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
                        collateral: WETH,
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
                _deal_Symbiotic(WETH, getStaker(0).addr, type(uint128).max, false);
                _stakerDeposit_SymbioticCore(getStaker(0).addr, operatorVault, 1000 + i);
                vm.startPrank(vars.network.addr);
                votingPowerProvider.registerOperatorVault(operator.addr, operatorVault);
                vm.stopPrank();
            }

            votingPowerProvider.setTokenHops(
                WETH, [WETH_USD_FEED, WBTC_USD_FEED], [false, true], [uint48(0), uint48(0)]
            );
            votingPowerProvider.setTokenHops(WBTC, [WBTC_USD_FEED, address(0)], [false, true], [uint48(1_000_000), 0]);

            (address[2] memory aggregators, bool[2] memory inverts, uint48[2] memory stalenessDurations) =
                votingPowerProvider.getTokenHops(WETH);
            assertEq(aggregators[0], WETH_USD_FEED);
            assertEq(inverts[0], false);
            assertEq(stalenessDurations[0], uint48(0));
            assertEq(aggregators[1], WBTC_USD_FEED);
            assertEq(inverts[1], true);
            assertEq(stalenessDurations[1], uint48(0));

            (aggregators, inverts, stalenessDurations) =
                votingPowerProvider.getTokenHopsAt(WETH, uint48(vm.getBlockTimestamp()));
            assertEq(aggregators[0], WETH_USD_FEED);
            assertEq(inverts[0], false);
            assertEq(stalenessDurations[0], uint48(0));
            assertEq(aggregators[1], WBTC_USD_FEED);
            assertEq(inverts[1], true);
            assertEq(stalenessDurations[1], uint48(0));

            AggregatorV3Interface wethFeed = AggregatorV3Interface(WETH_USD_FEED);
            (, int256 wethAnswer,,,) = wethFeed.latestRoundData();
            uint8 wethPriceDecimals = wethFeed.decimals();
            assertEq(wethPriceDecimals, 8);

            AggregatorV3Interface wbtcFeed = AggregatorV3Interface(WBTC_USD_FEED);
            (, int256 wbtcAnswer,,,) = wbtcFeed.latestRoundData();
            uint8 wbtcPriceDecimals = wbtcFeed.decimals();
            assertEq(wbtcPriceDecimals, 8);

            for (uint256 i; i < SYMBIOTIC_CORE_NUMBER_OF_OPERATORS; ++i) {
                Vm.Wallet memory operator = getOperator(i);
                address[] memory operatorVaults = votingPowerProvider.getOperatorVaults(operator.addr);

                uint256 expectedVP = 0;
                assertEq(votingPowerProvider.getOperatorVotingPower(operator.addr, operatorVaults[0], ""), expectedVP);
            }
        }
    }

    function test_ChainlinkCalcTracksRealPriceHistorical() public {
        SYMBIOTIC_CORE_NUMBER_OF_OPERATORS = 20;

        vm.createSelectFork("mainnet", FORK_BLOCK_INITIAL);

        SYMBIOTIC_INIT_BLOCK = FORK_BLOCK_INITIAL;
        InitSetupTest.setUp();

        votingPowerProvider =
            new TestVotingPowerProvider(address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory));

        _registerOperator_SymbioticCore(symbioticCore, operator1);
        _registerOperator_SymbioticCore(symbioticCore, operator2);

        _registerOperator_SymbioticCore(symbioticCore, validOperator);

        INetworkManager.NetworkManagerInitParams memory netInit =
            INetworkManager.NetworkManagerInitParams({network: vars.network.addr, subnetworkId: IDENTIFIER});

        IVotingPowerProvider.VotingPowerProviderInitParams memory votingPowerProviderInit = IVotingPowerProvider
            .VotingPowerProviderInitParams({
            networkManagerInitParams: netInit,
            ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "MyVotingPowerProvider", version: "1"}),
            requireSlasher: true,
            minVaultEpochDuration: 100,
            token: WETH
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
                    collateral: WETH,
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
            _deal_Symbiotic(WETH, getStaker(0).addr, type(uint128).max, false);
            _stakerDeposit_SymbioticCore(getStaker(0).addr, operatorVault, 1000 + i);
            vm.startPrank(vars.network.addr);
            votingPowerProvider.registerOperatorVault(operator.addr, operatorVault);
            vm.stopPrank();
        }

        votingPowerProvider.setTokenHops(
            WETH, [WETH_USD_FEED, WBTC_USD_FEED], [false, false], [uint48(1_000_000), uint48(1_000_000)]
        );
        votingPowerProvider.setTokenHops(WBTC, [WBTC_USD_FEED, address(0)], [false, false], [uint48(1_000_000), 0]);

        (address[2] memory aggregators, bool[2] memory inverts, uint48[2] memory stalenessDurations) =
            votingPowerProvider.getTokenHops(WETH);
        assertEq(aggregators[0], WETH_USD_FEED);
        assertEq(inverts[0], false);
        assertEq(stalenessDurations[0], uint48(1_000_000));
        assertEq(aggregators[1], WBTC_USD_FEED);
        assertEq(inverts[1], false);
        assertEq(stalenessDurations[1], uint48(1_000_000));

        (aggregators, inverts, stalenessDurations) =
            votingPowerProvider.getTokenHopsAt(WETH, uint48(vm.getBlockTimestamp()));
        assertEq(aggregators[0], WETH_USD_FEED);
        assertEq(inverts[0], false);
        assertEq(stalenessDurations[0], uint48(1_000_000));
        assertEq(aggregators[1], WBTC_USD_FEED);
        assertEq(inverts[1], false);
        assertEq(stalenessDurations[1], uint48(1_000_000));

        uint256[] memory expectedVPs = new uint256[](20);
        expectedVPs[0] = 289_285_670_012_285_649_900_000_000_000_000_000;
        expectedVPs[1] = 289_574_955_682_297_935_549_900_000_000_000_000;
        expectedVPs[2] = 289_864_241_352_310_221_199_800_000_000_000_000;
        expectedVPs[3] = 290_153_527_022_322_506_849_700_000_000_000_000;
        expectedVPs[4] = 290_442_812_692_334_792_499_600_000_000_000_000;
        expectedVPs[5] = 290_732_098_362_347_078_149_500_000_000_000_000;
        expectedVPs[6] = 291_021_384_032_359_363_799_400_000_000_000_000;
        expectedVPs[7] = 291_310_669_702_371_649_449_300_000_000_000_000;
        expectedVPs[8] = 291_599_955_372_383_935_099_200_000_000_000_000;
        expectedVPs[9] = 291_889_241_042_396_220_749_100_000_000_000_000;
        expectedVPs[10] = 292_178_526_712_408_506_399_000_000_000_000_000;
        expectedVPs[11] = 292_467_812_382_420_792_048_900_000_000_000_000;
        expectedVPs[12] = 292_757_098_052_433_077_698_800_000_000_000_000;
        expectedVPs[13] = 293_046_383_722_445_363_348_700_000_000_000_000;
        expectedVPs[14] = 293_335_669_392_457_648_998_600_000_000_000_000;
        expectedVPs[15] = 293_624_955_062_469_934_648_500_000_000_000_000;
        expectedVPs[16] = 293_914_240_732_482_220_298_400_000_000_000_000;
        expectedVPs[17] = 294_203_526_402_494_505_948_300_000_000_000_000;
        expectedVPs[18] = 294_492_812_072_506_791_598_200_000_000_000_000;
        expectedVPs[19] = 294_782_097_742_519_077_248_100_000_000_000_000;

        for (uint256 i; i < SYMBIOTIC_CORE_NUMBER_OF_OPERATORS; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            address[] memory operatorVaults = votingPowerProvider.getOperatorVaults(operator.addr);

            assertEq(votingPowerProvider.getOperatorVotingPower(operator.addr, operatorVaults[0], ""), expectedVPs[i]);

            assertEq(
                votingPowerProvider.getOperatorVotingPowerAt(
                    operator.addr, operatorVaults[0], "", uint48(1_731_757_007)
                ),
                expectedVPs[i]
            );
        }
    }
}
