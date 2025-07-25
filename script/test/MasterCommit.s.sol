// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./MasterGenesisSetup.s.sol";

import {Bytes} from "@openzeppelin/contracts/utils/Bytes.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ExtraDataStorageHelper} from "../../src/modules/settlement/sig-verifiers/libraries/ExtraDataStorageHelper.sol";

// forge script script/test/MasterCommit.s.sol:MasterCommitScript 25235 --sig "run(uint256)" --rpc-url $ETH_RPC_URL_MASTER

contract MasterCommitScript is MasterGenesisSetupScript {
    using ExtraDataStorageHelper for uint32;
    using KeyTags for uint8;
    using KeyBlsBn254 for BN254.G1Point;
    using BN254 for BN254.G1Point;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;
    using KeyEcdsaSecp256k1 for KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1;

    bytes32 private constant VALSET_HEADER_COMMIT_TYPEHASH =
        keccak256("ValSetHeaderCommit(bytes32 subnetwork,uint48 epoch,bytes32 headerHash,bytes32 extraDataHash)");

    struct ZkProof {
        uint256[] input;
        bytes proof;
    }

    function run(
        uint256 seed
    ) public virtual override {
        SYMBIOTIC_CORE_PROJECT_ROOT = "lib/core/";
        SymbioticInit.run(seed);

        (, Vars memory vars) = loadInitSetupParamsAndVars();
        MasterSetupParams memory masterSetupParams = loadMasterSetupParams();

        (ISettlement.ValSetHeader memory valSetHeader, ISettlement.ExtraData[] memory extraData) = loadGenesis();
        valSetHeader.previousHeaderHash = keccak256(abi.encode(valSetHeader));
        valSetHeader.epoch = masterSetupParams.valSetDriver.getCurrentEpoch();
        valSetHeader.captureTimestamp = masterSetupParams.valSetDriver.getCurrentEpochStart();

        bytes32 messageHash = masterSetupParams.settlement.hashTypedDataV4CrossChain(
            keccak256(
                abi.encode(
                    VALSET_HEADER_COMMIT_TYPEHASH,
                    masterSetupParams.settlement.SUBNETWORK(),
                    masterSetupParams.valSetDriver.getCurrentEpoch(),
                    keccak256(abi.encode(valSetHeader)),
                    keccak256(abi.encode(extraData))
                )
            )
        );

        console2.log("messageHash");
        console2.logBytes32(messageHash);

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 signersVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                signersVotingPower += votingPowers[i].vaults[j].value;
            }
        }

        BN254.G1Point memory aggKeyG1;
        BN254.G2Point memory aggKeyG2;
        BN254.G1Point memory aggSigG1;

        address[] memory operators = masterSetupParams.votingPowerProvider.getOperators();
        for (uint256 i; i < operators.length; ++i) {
            Vm.Wallet memory operator = getOperator(i);
            aggKeyG1 = aggKeyG1.plus(BN254.generatorG1().scalar_mul(operator.privateKey));
            aggSigG1 = aggSigG1.plus(BN254.hashToG1(messageHash).scalar_mul(operator.privateKey));

            BN254.G2Point memory keyG2 = getG2Key(operator.privateKey);

            if (aggKeyG2.X[0] == 0 && aggKeyG2.X[1] == 0 && aggKeyG2.Y[0] == 0 && aggKeyG2.Y[1] == 0) {
                aggKeyG2 = keyG2;
            } else {
                (uint256 x1, uint256 x2, uint256 y1, uint256 y2) = BN254G2.ECTwistAdd(
                    aggKeyG2.X[1],
                    aggKeyG2.X[0],
                    aggKeyG2.Y[1],
                    aggKeyG2.Y[0],
                    keyG2.X[1],
                    keyG2.X[0],
                    keyG2.Y[1],
                    keyG2.Y[0]
                );
                aggKeyG2 = BN254.G2Point([x2, x1], [y2, y1]);
            }
        }

        console2.log("aggSigG1");
        console2.logBytes(abi.encode(aggSigG1));
        console2.log("aggKeyG2");
        console2.logBytes(abi.encode(aggKeyG2));

        bytes memory zkProof =
            hex"1bbfff6bd2dab940e651197642237ce9b2c5d3c4ec761c1498c636c57bb95bc70f49530a1198c69455cd2610373c49520fa928ec515be0fa60fc54ac2bd85de2213a9cc1dbc30d714b201e430181009865153b9890fef27bfaefbeeba0ec1f681bceebfa810aeb7340150fa1add34f4a95e10bfff22738c6a2893f3f868b7e9d10700bc426b575300ec36536e940d317113630f335f48c2fb5e9bec2141b4f4618cd4bc1c884af0573e7bcdab39ff9867f01a1d4514c26caba520186ae70a84017e330c31720ed1d205fef008c4d04e37b00866eac3070740c71d6074f0b0f8f03bb5a30835dc8bf3d4a89200255dc5f6b9c0330dddb54765ba271d8868247ee000000012cfd0371e370f57f6c816e941bb100f74b14e3821976ed3df69235f29df30ead059287c9ab778cbe120f4caafcbb7debaad03b860265043362f45bd22904a3c8076235b408d60d192e44b8f8d7295a0ea94202c3185431ddef1ad6c66325ece40c1742dd5278cddfd2500e3873e800f12250358b96939d11256375e3082030d3";

        bytes memory fullProof;

        {
            bytes memory proof_ = Bytes.slice(zkProof, 0, 256);
            bytes memory commitments = Bytes.slice(zkProof, 260, 324);
            bytes memory commitmentPok = Bytes.slice(zkProof, 324, 388);

            console2.log("proof_");
            console2.logBytes(proof_);
            console2.log("commitments");
            console2.logBytes(commitments);
            console2.log("commitmentPok");
            console2.logBytes(commitmentPok);

            fullProof = abi.encodePacked(proof_, commitments, commitmentPok, signersVotingPower);
        }

        console2.log("fullProof");
        console2.logBytes(fullProof);

        console2.log("commitValSetHeader");

        console2.log("subnetwork");
        console2.logBytes32(masterSetupParams.settlement.SUBNETWORK());

        console2.log("epoch");
        console2.log(masterSetupParams.valSetDriver.getCurrentEpoch());

        console2.log("header");
        console2.log(valSetHeader.captureTimestamp);
        console2.log(valSetHeader.epoch);
        console2.logBytes32(valSetHeader.previousHeaderHash);
        console2.log(valSetHeader.quorumThreshold);
        console2.log(valSetHeader.requiredKeyTag);
        console2.logBytes32(valSetHeader.validatorsSszMRoot);
        console2.log(valSetHeader.version);

        console2.log("extraData");
        console2.logBytes32(extraData[0].key);
        console2.logBytes32(extraData[0].value);
        console2.logBytes32(extraData[1].key);
        console2.logBytes32(extraData[1].value);

        vm.startBroadcast(vars.deployer.privateKey);
        masterSetupParams.settlement.commitValSetHeader(valSetHeader, extraData, fullProof);
        vm.stopBroadcast();
    }

    function loadZkProof() internal returns (ZkProof memory) {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/test/data/zk_proof.json");
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);
        return abi.decode(data, (ZkProof));
    }
}
