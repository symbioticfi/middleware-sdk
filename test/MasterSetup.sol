// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console2} from "forge-std/Test.sol";

import {ISettlement} from "../src/interfaces/modules/settlement/ISettlement.sol";
import {IOzOwnable} from "../src/interfaces/modules/common/permissions/IOzOwnable.sol";
import {INetworkManager} from "../src/interfaces/modules/base/INetworkManager.sol";
import {IEpochManager} from "../src/interfaces/modules/valset-driver/IEpochManager.sol";
import {IOzEIP712} from "../src/interfaces/modules/base/IOzEIP712.sol";
import {IValSetDriver} from "../src/interfaces/modules/valset-driver/IValSetDriver.sol";
import {IOperatorsWhitelist} from "../src/interfaces/modules/voting-power/extensions/IOperatorsWhitelist.sol";
import {IVotingPowerProvider} from "../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {IBaseSlashing} from "../src/interfaces/modules/voting-power/extensions/IBaseSlashing.sol";
import {IBaseRewards} from "../src/interfaces/modules/voting-power/extensions/IBaseRewards.sol";

import {KeyTags} from "../src/libraries/utils/KeyTags.sol";

import {SigVerifierMock} from "./mocks/SigVerifierMock.sol";

import {KeyTags} from "../src/libraries/utils/KeyTags.sol";
import {KeyEcdsaSecp256k1} from "../src/libraries/keys/KeyEcdsaSecp256k1.sol";
import {KeyBlsBn254, BN254} from "../src/libraries/keys/KeyBlsBn254.sol";

import {BN254G2} from "./helpers/BN254G2.sol";
import "./InitSetup.sol";

import {SigVerifierBlsBn254ZK} from "../src/modules/settlement/sig-verifiers/SigVerifierBlsBn254ZK.sol";
import {SigVerifierBlsBn254Simple} from "../src/modules/settlement/sig-verifiers/SigVerifierBlsBn254Simple.sol";
import {Verifier as Verifier_10} from "./data/zk/Verifier_10.sol";
import {Verifier as Verifier_100} from "./data/zk/Verifier_100.sol";
import {Verifier as Verifier_1000} from "./data/zk/Verifier_1000.sol";

contract MasterSetupTest is InitSetupTest {
    using KeyTags for uint8;
    using KeyBlsBn254 for BN254.G1Point;
    using BN254 for BN254.G1Point;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;
    using KeyEcdsaSecp256k1 for KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1;
    using SymbioticSubnetwork for address;
    using Math for uint256;

    struct MasterSetupParams {
        address keyRegistry;
        MySettlement settlement;
        MyValSetDriver valSetDriver;
        VotingPowerProviderSemiFull votingPowerProvider;
    }

    struct NetworkSetupParams {
        uint256 OPERATORS_TO_REGISTER;
        uint48 EPOCH_DURATION;
        uint48 SLASHING_WINDOW;
        uint32 VERIFICATION_TYPE;
        uint96 SUBNETWORK_ID;
    }

    struct LocalVars {
        uint8[] requiredKeyTags;
        IValSetDriver.CrossChainAddress[] votingPowerProviders;
        IValSetDriver.CrossChainAddress[] replicas;
        IValSetDriver.CrossChainAddress keysProvider;
        address sigVerifier;
        IValSetDriver.QuorumThreshold[] quorumThresholds;
    }

    uint256 public EPOCH_DURATION = 300;
    uint256 public SLASHING_WINDOW = 1200;
    uint256 public VERIFICATION_TYPE = 1;
    uint256 public SUBNETWORK_ID = 0;
    uint256 public DEPLOYMENT_BUFFER = 600;

    NetworkSetupParams public networkSetupParams;
    MasterSetupParams public masterSetupParams;

    function setUp() public virtual override {
        SYMBIOTIC_CORE_PROJECT_ROOT = "lib/core/";
        InitSetupTest.setUp();

        networkSetupParams.OPERATORS_TO_REGISTER = SYMBIOTIC_CORE_NUMBER_OF_OPERATORS;
        networkSetupParams.EPOCH_DURATION = uint48(EPOCH_DURATION);
        networkSetupParams.SLASHING_WINDOW = uint48(SLASHING_WINDOW);
        networkSetupParams.VERIFICATION_TYPE = uint32(VERIFICATION_TYPE);
        networkSetupParams.SUBNETWORK_ID = IDENTIFIER;

        symbioticCore = initSetupParams.masterChain.core;

        vm.startPrank(vars.deployer.addr);
        masterSetupParams.votingPowerProvider = new VotingPowerProviderSemiFull(
            address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory)
        );
        masterSetupParams.votingPowerProvider.initialize(
            IVotingPowerProvider.VotingPowerProviderInitParams({
                networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                    network: vars.network.addr,
                    subnetworkId: networkSetupParams.SUBNETWORK_ID
                }),
                ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "VotingPowerProvider", version: "1"}),
                requireSlasher: true,
                minVaultEpochDuration: networkSetupParams.SLASHING_WINDOW,
                token: initSetupParams.masterChain.tokens[0]
            }),
            IOzOwnable.OzOwnableInitParams({owner: vars.network.addr}),
            IOperatorsWhitelist.OperatorsWhitelistInitParams({isWhitelistEnabled: false}),
            IBaseSlashing.BaseSlashingInitParams({slasher: address(1)}),
            IBaseRewards.BaseRewardsInitParams({rewarder: address(1)})
        );
        vm.stopPrank();

        _networkSetMiddleware_SymbioticCore(vars.network.addr, address(masterSetupParams.votingPowerProvider));

        // for (uint256 i; i < initSetupParams.masterChain.tokens.length; ++i) {
        //     vm.startPrank(vars.deployer.addr);
        //     masterSetupParams.votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[i]);
        //     vm.stopPrank();
        // }
        for (uint256 i; i < initSetupParams.masterChain.vaults.length; ++i) {
            vm.startPrank(vars.network.addr);
            masterSetupParams.votingPowerProvider.registerSharedVault(initSetupParams.masterChain.vaults[i]);
            vm.stopPrank();
        }

        masterSetupParams.keyRegistry = initSetupParams.keyRegistry;

        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            vm.startPrank(operator.addr);
            masterSetupParams.votingPowerProvider.registerOperator();
            vm.stopPrank();
        }

        vm.startPrank(vars.deployer.addr);
        masterSetupParams.settlement = new MySettlement();
        {
            LocalVars memory localVars;

            if (networkSetupParams.VERIFICATION_TYPE == 0) {
                address[] memory verifiers = new address[](3);
                verifiers[0] = address(new Verifier_10());
                verifiers[1] = address(new Verifier_100());
                verifiers[2] = address(new Verifier_1000());
                uint256[] memory maxValidators = new uint256[](verifiers.length);
                maxValidators[0] = 10;
                maxValidators[1] = 100;
                maxValidators[2] = 1000;
                localVars.sigVerifier = address(new SigVerifierBlsBn254ZK(verifiers, maxValidators));
            } else if (networkSetupParams.VERIFICATION_TYPE == 1) {
                localVars.sigVerifier = address(new SigVerifierBlsBn254Simple());
            } else {
                revert("Invalid verification type");
            }

            masterSetupParams.settlement.initialize(
                ISettlement.SettlementInitParams({
                    networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                        network: vars.network.addr,
                        subnetworkId: networkSetupParams.SUBNETWORK_ID
                    }),
                    ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "Middleware", version: "1"}),
                    sigVerifier: localVars.sigVerifier
                }),
                vars.deployer.addr
            );
        }

        masterSetupParams.settlement.grantRole(masterSetupParams.settlement.SET_GENESIS_ROLE(), vars.deployer.addr);
        vm.stopPrank();

        vm.startPrank(vars.deployer.addr);
        masterSetupParams.valSetDriver = new MyValSetDriver{salt: bytes32("valSetDriver")}();
        {
            LocalVars memory localVars;

            localVars.requiredKeyTags = new uint8[](1);
            localVars.requiredKeyTags[0] = KEY_TYPE_BLS_BN254.getKeyTag(15);

            localVars.votingPowerProviders = new IValSetDriver.CrossChainAddress[](1);
            localVars.votingPowerProviders[0] = IValSetDriver.CrossChainAddress({
                addr: address(masterSetupParams.votingPowerProvider),
                chainId: uint64(initSetupParams.masterChain.chainId)
            });

            localVars.keysProvider = IValSetDriver.CrossChainAddress({
                addr: address(masterSetupParams.keyRegistry),
                chainId: uint64(initSetupParams.masterChain.chainId)
            });
            localVars.replicas = new IValSetDriver.CrossChainAddress[](1);
            localVars.replicas[0] = IValSetDriver.CrossChainAddress({
                addr: address(masterSetupParams.settlement),
                chainId: uint64(initSetupParams.masterChain.chainId)
            });

            localVars.quorumThresholds = new IValSetDriver.QuorumThreshold[](localVars.requiredKeyTags.length);
            for (uint256 i; i < localVars.requiredKeyTags.length; ++i) {
                localVars.quorumThresholds[i] = IValSetDriver.QuorumThreshold({
                    keyTag: localVars.requiredKeyTags[i],
                    quorumThreshold: uint248(uint256(2).mulDiv(1e18, 3, Math.Rounding.Ceil))
                });
            }

            masterSetupParams.valSetDriver.initialize(
                IValSetDriver.ValSetDriverInitParams({
                    networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                        network: vars.network.addr,
                        subnetworkId: networkSetupParams.SUBNETWORK_ID
                    }),
                    epochManagerInitParams: IEpochManager.EpochManagerInitParams({
                        epochDuration: networkSetupParams.EPOCH_DURATION,
                        epochDurationTimestamp: uint48(vm.getBlockTimestamp() + DEPLOYMENT_BUFFER)
                    }),
                    votingPowerProviders: localVars.votingPowerProviders,
                    keysProvider: localVars.keysProvider,
                    replicas: localVars.replicas,
                    verificationType: networkSetupParams.VERIFICATION_TYPE,
                    maxVotingPower: 1e36,
                    minInclusionVotingPower: 0,
                    maxValidatorsCount: 99_999_999,
                    requiredKeyTags: localVars.requiredKeyTags,
                    requiredHeaderKeyTag: localVars.requiredKeyTags[0],
                    quorumThresholds: localVars.quorumThresholds
                }),
                vars.deployer.addr
            );
        }
        vm.stopPrank();

        console2.log("-----------------------------------------------------------------------------------------------");
        console2.log("Network address: ", vars.network.addr);
        console2.log("VotingPowerProvider address: ", address(masterSetupParams.votingPowerProvider));
        console2.log("KeyRegistry address: ", address(masterSetupParams.keyRegistry));
        console2.log("Settlement address: ", address(masterSetupParams.settlement));
        console2.log(
            "ValSetDriver address: ",
            address(masterSetupParams.valSetDriver),
            "<--- USE THIS ADDRESS IN OFF-CHAIN CONFIG"
        );
        console2.log("-----------------------------------------------------------------------------------------------");

        console2.log("-----------------------------------------------------------------------------------------------");
        console2.log("Network config: ");
        console2.log("  Subnetwork ID: ", networkSetupParams.SUBNETWORK_ID);
        console2.log("  Slashing window: ", networkSetupParams.SLASHING_WINDOW);
        console2.log("  Epoch duration: ", networkSetupParams.EPOCH_DURATION);
        console2.log("  Verification type: ", networkSetupParams.VERIFICATION_TYPE == 0 ? "ZK" : "Simple");
        console2.log("-----------------------------------------------------------------------------------------------");

        console2.log("-----------------------------------------------------------------------------------------------");
        uint256 totalVotingPower;
        console2.log("Registered operators: ", networkSetupParams.OPERATORS_TO_REGISTER);
        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            uint256 operatorVotingPower;
            IVotingPowerProvider.VaultValue[] memory operatorVotingPowers =
                masterSetupParams.votingPowerProvider.getOperatorVotingPowers(operator.addr, new bytes(0));
            for (uint256 j; j < operatorVotingPowers.length; ++j) {
                operatorVotingPower += operatorVotingPowers[j].value;
            }
            console2.log("  ", operator.addr);
            console2.log("      Voting power: ", operatorVotingPower);
            console2.log("      Private key: ", operator.privateKey);
            totalVotingPower += operatorVotingPower;
        }
        console2.log("Total voting power: ", totalVotingPower);
        console2.log("-----------------------------------------------------------------------------------------------");
    }
}
