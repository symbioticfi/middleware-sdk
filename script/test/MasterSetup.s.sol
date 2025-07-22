// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console2} from "forge-std/Script.sol";

import {ISettlement} from "../../src/interfaces/modules/settlement/ISettlement.sol";
import {IOzOwnable} from "../../src/interfaces/modules/common/permissions/IOzOwnable.sol";
import {INetworkManager} from "../../src/interfaces/modules/base/INetworkManager.sol";
import {IEpochManager} from "../../src/interfaces/modules/valset-driver/IEpochManager.sol";
import {IOzEIP712} from "../../src/interfaces/modules/base/IOzEIP712.sol";
import {IValSetDriver} from "../../src/interfaces/modules/valset-driver/IValSetDriver.sol";
import {IOperatorsWhitelist} from "../../src/interfaces/modules/voting-power/extensions/IOperatorsWhitelist.sol";
import {IVotingPowerProvider} from "../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {IBaseSlashing} from "../../src/interfaces/modules/voting-power/extensions/IBaseSlashing.sol";
import {IBaseRewards} from "../../src/interfaces/modules/voting-power/extensions/IBaseRewards.sol";

import {KeyTags} from "../../src/contracts/libraries/utils/KeyTags.sol";

import {SigVerifierMock} from "../../test/mocks/SigVerifierMock.sol";

import {KeyTags} from "../../src/contracts/libraries/utils/KeyTags.sol";
import {KeyEcdsaSecp256k1} from "../../src/contracts/libraries/keys/KeyEcdsaSecp256k1.sol";
import {KeyBlsBn254, BN254} from "../../src/contracts/libraries/keys/KeyBlsBn254.sol";

import {BN254G2} from "../../test/helpers/BN254G2.sol";
import "./InitSetup.s.sol";

import {SigVerifierBlsBn254ZK} from "../../src/contracts/modules/settlement/sig-verifiers/SigVerifierBlsBn254ZK.sol";
import {SigVerifierBlsBn254Simple} from
    "../../src/contracts/modules/settlement/sig-verifiers/SigVerifierBlsBn254Simple.sol";
import {Verifier as Verifier_10} from "./data/zk/Verifier_10.sol";
import {Verifier as Verifier_100} from "./data/zk/Verifier_100.sol";
import {Verifier as Verifier_1000} from "./data/zk/Verifier_1000.sol";

// forge script script/test/MasterSetup.s.sol:MasterSetupScript 25235 --sig "run(uint256)" --rpc-url $ETH_RPC_URL_MASTER

contract MasterSetupScript is InitSetupScript {
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

    function run(
        uint256 seed
    ) public virtual override {
        SYMBIOTIC_CORE_PROJECT_ROOT = "lib/core/";
        SymbioticInit.run(seed);

        NetworkSetupParams memory networkSetupParams;

        networkSetupParams.OPERATORS_TO_REGISTER = vm.envOr("OPERATORS", uint256(4));
        networkSetupParams.EPOCH_DURATION = uint48(vm.envOr("EPOCH_DURATION", uint256(60)));
        networkSetupParams.SLASHING_WINDOW = uint48(vm.envOr("SLASHING_WINDOW", uint256(1200)));
        networkSetupParams.VERIFICATION_TYPE = uint32(vm.envOr("VERIFICATION_TYPE", uint256(1)));
        networkSetupParams.SUBNETWORK_ID = IDENTIFIER;

        if (networkSetupParams.OPERATORS_TO_REGISTER > SYMBIOTIC_CORE_NUMBER_OF_OPERATORS) {
            revert("Too many operators to register");
        }

        string memory obj = "data";
        string memory finalJson;
        (InitSetupParams memory initSetupParams, Vars memory vars) = loadInitSetupParamsAndVars();
        symbioticCore = initSetupParams.masterChain.core;
        MasterSetupParams memory masterSetupParams;

        vm.startBroadcast(vars.deployer.privateKey);
        masterSetupParams.votingPowerProvider = new VotingPowerProviderSemiFull(
            address(symbioticCore.operatorRegistry), address(symbioticCore.vaultFactory)
        );
        masterSetupParams.votingPowerProvider.initialize(
            IVotingPowerProvider.VotingPowerProviderInitParams({
                networkManagerInitParams: INetworkManager.NetworkManagerInitParams({
                    network: vars.network.addr,
                    subnetworkID: networkSetupParams.SUBNETWORK_ID
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
        vm.stopBroadcast();
        vm.serializeAddress(obj, "votingPowerProvider", address(masterSetupParams.votingPowerProvider));

        _networkSetMiddleware_SymbioticCore(vars.network.addr, address(masterSetupParams.votingPowerProvider));

        // token[0] is already registered above
        for (uint256 i = 1; i < initSetupParams.masterChain.tokens.length; ++i) {
            vm.startBroadcast(vars.deployer.privateKey);
            masterSetupParams.votingPowerProvider.registerToken(initSetupParams.masterChain.tokens[i]);
            vm.stopBroadcast();
        }
        for (uint256 i; i < initSetupParams.masterChain.vaults.length; ++i) {
            vm.startBroadcast(vars.network.privateKey);
            masterSetupParams.votingPowerProvider.registerSharedVault(initSetupParams.masterChain.vaults[i]);
            vm.stopBroadcast();
        }

        masterSetupParams.keyRegistry = initSetupParams.keyRegistry;
        vm.serializeAddress(obj, "keyRegistry", initSetupParams.keyRegistry);

        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            vm.startBroadcast(operator.privateKey);
            masterSetupParams.votingPowerProvider.registerOperator();
            vm.stopBroadcast();
        }

        vm.startBroadcast(vars.deployer.privateKey);
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
                        subnetworkID: networkSetupParams.SUBNETWORK_ID
                    }),
                    ozEip712InitParams: IOzEIP712.OzEIP712InitParams({name: "Middleware", version: "1"}),
                    sigVerifier: localVars.sigVerifier
                }),
                vars.deployer.addr
            );
        }
        vm.stopBroadcast();
        vm.serializeAddress(obj, "settlement", address(masterSetupParams.settlement));

        vm.startBroadcast(vars.deployer.privateKey);
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
                        subnetworkID: networkSetupParams.SUBNETWORK_ID
                    }),
                    epochManagerInitParams: IEpochManager.EpochManagerInitParams({
                        epochDuration: networkSetupParams.EPOCH_DURATION,
                        epochDurationTimestamp: uint48(vm.getBlockTimestamp() + vm.envOr("DEPLOYMENT_BUFFER", uint256(600)))
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
        vm.stopBroadcast();
        finalJson = vm.serializeAddress(obj, "valSetDriver", address(masterSetupParams.valSetDriver));

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
        console2.log("Registred operators: ", networkSetupParams.OPERATORS_TO_REGISTER);
        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            uint256 operatorVotingPower;
            IVotingPowerProvider.VaultVotingPower[] memory operatorVotingPowers =
                masterSetupParams.votingPowerProvider.getOperatorVotingPowers(operator.addr, new bytes(0));
            for (uint256 j; j < operatorVotingPowers.length; ++j) {
                operatorVotingPower += operatorVotingPowers[j].votingPower;
            }
            console2.log("  ", operator.addr);
            console2.log("      Voting power: ", operatorVotingPower);
            console2.log("      Private key: ", operator.privateKey);
            totalVotingPower += operatorVotingPower;
        }
        console2.log("Total voting power: ", totalVotingPower);
        console2.log("-----------------------------------------------------------------------------------------------");

        vm.writeJson(finalJson, "script/test/data/master_setup_params.json");
    }

    function loadMasterSetupParams() public returns (MasterSetupParams memory masterSetupParams) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/script/test/data/master_setup_params.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        masterSetupParams = abi.decode(data, (MasterSetupParams));
    }
}
