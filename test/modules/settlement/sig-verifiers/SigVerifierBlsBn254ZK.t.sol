// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {KeyTags} from "../../../../src/libraries/utils/KeyTags.sol";
import {KeyEcdsaSecp256k1} from "../../../../src/libraries/keys/KeyEcdsaSecp256k1.sol";
import {KeyBlsBn254, BN254} from "../../../../src/libraries/keys/KeyBlsBn254.sol";
import {SigBlsBn254} from "../../../../src/libraries/sigs/SigBlsBn254.sol";
import {
    KEY_TYPE_BLS_BN254,
    KEY_TYPE_ECDSA_SECP256K1
} from "../../../../src/interfaces/modules/key-registry/IKeyRegistry.sol";

import {BN254G2} from "../../../helpers/BN254G2.sol";

import {ISettlement} from "../../../../src/interfaces/modules/settlement/ISettlement.sol";

import "../../../MasterGenesisSetup.sol";

import {console2} from "forge-std/console2.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";

import {SigVerifierBlsBn254ZK} from "../../../../src/modules/settlement/sig-verifiers/SigVerifierBlsBn254ZK.sol";

import {ISigVerifier} from "../../../../src/interfaces/modules/settlement/sig-verifiers/ISigVerifier.sol";
import {IVotingPowerProvider} from "../../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {ISigVerifierBlsBn254ZK} from
    "../../../../src/interfaces/modules/settlement/sig-verifiers/ISigVerifierBlsBn254ZK.sol";

import {ExtraDataStorageHelper} from
    "../../../../src/modules/settlement/sig-verifiers/libraries/ExtraDataStorageHelper.sol";

import {Bytes} from "@openzeppelin/contracts/utils/Bytes.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract SigVerifierBlsBn254ZKTest is MasterGenesisSetupTest {
    using KeyTags for uint8;
    using KeyBlsBn254 for BN254.G1Point;
    using BN254 for BN254.G1Point;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;
    using KeyEcdsaSecp256k1 for KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1;
    using Math for uint256;
    using ExtraDataStorageHelper for uint32;
    using stdStorage for StdStorage;

    struct ZkProof {
        uint256[] input;
        bytes proof;
    }

    function setUp() public override {
        SYMBIOTIC_CORE_NUMBER_OF_OPERATORS = 20;
        VERIFICATION_TYPE = 0;

        SYMBIOTIC_CORE_PROJECT_ROOT = "lib/core/";
        MasterSetupTest.setUp();

        vm.warp(masterSetupParams.valSetDriver.getEpochStart(0) + 1);

        vm.startPrank(vars.deployer.addr);
        (ISettlement.ValSetHeader memory valSetHeader, ISettlement.ExtraData[] memory extraData) = loadGenesis();
        valSetHeader.captureTimestamp = masterSetupParams.valSetDriver.getCurrentEpochStart();
        valSetHeader.epoch = masterSetupParams.valSetDriver.getCurrentEpoch();
        valSetHeader.previousHeaderHash = masterSetupParams.settlement.getValSetHeaderHash();
        valSetHeader.requiredKeyTag = masterSetupParams.valSetDriver.getRequiredHeaderKeyTag();
        valSetHeader.version = masterSetupParams.settlement.VALIDATOR_SET_VERSION();

        SigVerifierBlsBn254ZK sigVerifier = SigVerifierBlsBn254ZK(masterSetupParams.settlement.getSigVerifier());
        extraData = new ISettlement.ExtraData[](2);
        extraData[0].key = uint32(VERIFICATION_TYPE).getKey(sigVerifier.TOTAL_ACTIVE_VALIDATORS_HASH());
        extraData[0].value = bytes32(SYMBIOTIC_CORE_NUMBER_OF_OPERATORS);
        extraData[1].key = uint32(VERIFICATION_TYPE).getKey(15, sigVerifier.VALIDATOR_SET_HASH_MIMC_HASH());
        extraData[1].value = bytes32(0x221e349ac65d42e4884601fd0ddba2b964bb5055bd96f431458652333ede252a);

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }
        uint256 quorumThreshold;
        IValSetDriver.QuorumThreshold[] memory quorumThresholds = masterSetupParams.valSetDriver.getQuorumThresholds();
        for (uint256 i; i < quorumThresholds.length; ++i) {
            if (quorumThresholds[i].keyTag == valSetHeader.requiredKeyTag) {
                quorumThreshold = quorumThresholds[i].quorumThreshold;
                break;
            }
        }
        valSetHeader.quorumThreshold =
            quorumThreshold.mulDiv(totalVotingPower, masterSetupParams.valSetDriver.MAX_QUORUM_THRESHOLD()) + 1;

        masterSetupParams.settlement.setGenesis(valSetHeader, extraData);
        vm.stopPrank();
    }

    function test_Create() public {
        address[] memory verifiers = new address[](3);
        verifiers[0] = address(new Verifier_10());
        verifiers[1] = address(new Verifier_100());
        verifiers[2] = address(new Verifier_1000());
        uint256[] memory maxValidators = new uint256[](verifiers.length);
        maxValidators[0] = 10;
        maxValidators[1] = 100;
        maxValidators[2] = 1000;
        new SigVerifierBlsBn254ZK(verifiers, maxValidators);
    }

    function test_RevertInvalidLength() public {
        address[] memory verifiers;
        uint256[] memory maxValidators;
        vm.expectRevert(ISigVerifierBlsBn254ZK.SigVerifierBlsBn254ZK_InvalidLength.selector);
        new SigVerifierBlsBn254ZK(verifiers, maxValidators);

        verifiers = new address[](3);
        verifiers[0] = address(new Verifier_10());
        verifiers[1] = address(new Verifier_100());
        verifiers[2] = address(new Verifier_1000());
        maxValidators = new uint256[](verifiers.length - 1);
        maxValidators[0] = 10;
        maxValidators[1] = 100;
        vm.expectRevert(ISigVerifierBlsBn254ZK.SigVerifierBlsBn254ZK_InvalidLength.selector);
        new SigVerifierBlsBn254ZK(verifiers, maxValidators);
    }

    function test_Revert_InvalidMaxValidators() public {
        address[] memory verifiers = new address[](3);
        verifiers[0] = address(new Verifier_10());
        verifiers[1] = address(new Verifier_100());
        verifiers[2] = address(new Verifier_1000());
        uint256[] memory maxValidators = new uint256[](verifiers.length);
        maxValidators[0];
        maxValidators[1] = 100;
        maxValidators[2] = 1000;
        vm.expectRevert(ISigVerifierBlsBn254ZK.SigVerifierBlsBn254ZK_InvalidMaxValidators.selector);
        new SigVerifierBlsBn254ZK(verifiers, maxValidators);
    }

    function test_Revert_InvalidVerifier() public {
        address[] memory verifiers = new address[](3);
        verifiers[0] = address(0);
        verifiers[1] = address(new Verifier_100());
        verifiers[2] = address(new Verifier_1000());
        uint256[] memory maxValidators = new uint256[](verifiers.length);
        maxValidators[0] = 10;
        maxValidators[1] = 100;
        maxValidators[2] = 1000;
        vm.expectRevert(ISigVerifierBlsBn254ZK.SigVerifierBlsBn254ZK_InvalidVerifier.selector);
        new SigVerifierBlsBn254ZK(verifiers, maxValidators);
    }

    function test_Revert_InvalidMaxValidatorsOrder() public {
        address[] memory verifiers = new address[](3);
        verifiers[0] = address(new Verifier_10());
        verifiers[1] = address(new Verifier_100());
        verifiers[2] = address(new Verifier_1000());
        uint256[] memory maxValidators = new uint256[](verifiers.length);
        maxValidators[0] = 10;
        maxValidators[1] = 10;
        maxValidators[2] = 1000;
        vm.expectRevert(ISigVerifierBlsBn254ZK.SigVerifierBlsBn254ZK_InvalidMaxValidatorsOrder.selector);
        new SigVerifierBlsBn254ZK(verifiers, maxValidators);
    }

    function test_Revert_UnsupportedKeyTag() public {
        SigVerifierBlsBn254ZK sigVerifier;
        {
            address[] memory verifiers = new address[](3);
            verifiers[0] = address(new Verifier_10());
            verifiers[1] = address(new Verifier_100());
            verifiers[2] = address(new Verifier_1000());
            uint256[] memory maxValidators = new uint256[](verifiers.length);
            maxValidators[0] = 10;
            maxValidators[1] = 100;
            maxValidators[2] = 1000;
            sigVerifier = new SigVerifierBlsBn254ZK(verifiers, maxValidators);
        }
        uint48 epoch = masterSetupParams.settlement.getLastCommittedHeaderEpoch();
        vm.expectRevert(ISigVerifierBlsBn254ZK.SigVerifierBlsBn254ZK_UnsupportedKeyTag.selector);
        sigVerifier.verifyQuorumSig(
            address(masterSetupParams.settlement),
            epoch,
            new bytes(0),
            KEY_TYPE_ECDSA_SECP256K1.getKeyTag(15),
            0,
            new bytes(0)
        );
    }

    function test_Revert_InvalidMessageLength() public {
        SigVerifierBlsBn254ZK sigVerifier;
        {
            address[] memory verifiers = new address[](3);
            verifiers[0] = address(new Verifier_10());
            verifiers[1] = address(new Verifier_100());
            verifiers[2] = address(new Verifier_1000());
            uint256[] memory maxValidators = new uint256[](verifiers.length);
            maxValidators[0] = 10;
            maxValidators[1] = 100;
            maxValidators[2] = 1000;
            sigVerifier = new SigVerifierBlsBn254ZK(verifiers, maxValidators);
        }
        uint48 lastCommittedHeaderEpoch = masterSetupParams.settlement.getLastCommittedHeaderEpoch();
        vm.expectRevert(ISigVerifierBlsBn254ZK.SigVerifierBlsBn254ZK_InvalidMessageLength.selector);
        sigVerifier.verifyQuorumSig(
            address(masterSetupParams.settlement),
            lastCommittedHeaderEpoch,
            abi.encode(bytes32(0), bytes32(0)),
            KEY_TYPE_BLS_BN254.getKeyTag(15),
            0,
            new bytes(0)
        );
    }

    function test_Revert_InvalidProofLength() public {
        SigVerifierBlsBn254ZK sigVerifier;
        {
            address[] memory verifiers = new address[](3);
            verifiers[0] = address(new Verifier_10());
            verifiers[1] = address(new Verifier_100());
            verifiers[2] = address(new Verifier_1000());
            uint256[] memory maxValidators = new uint256[](verifiers.length);
            maxValidators[0] = 10;
            maxValidators[1] = 100;
            maxValidators[2] = 1000;
            sigVerifier = new SigVerifierBlsBn254ZK(verifiers, maxValidators);
        }
        uint48 lastCommittedHeaderEpoch = masterSetupParams.settlement.getLastCommittedHeaderEpoch();

        bytes memory data = abi.encodeCall(
            ISigVerifier.verifyQuorumSig,
            (
                address(masterSetupParams.settlement),
                lastCommittedHeaderEpoch,
                new bytes(32),
                KEY_TYPE_BLS_BN254.getKeyTag(15),
                0,
                new bytes(0)
            )
        );

        console2.logBytes(data);
        vm.expectRevert(ISigVerifierBlsBn254ZK.SigVerifierBlsBn254ZK_InvalidProofLength.selector);
        sigVerifier.verifyQuorumSig(
            address(masterSetupParams.settlement),
            lastCommittedHeaderEpoch,
            new bytes(32),
            KEY_TYPE_BLS_BN254.getKeyTag(15),
            0,
            new bytes(1)
        );
    }

    function test_FalseQuorumThreshold() public {
        bytes32 messageHash = 0xcca0534ef01f2606de9b6c90df9f0a2e1a18fb5ce4d1f9cf1f94d35b398ebce4;
        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }
        uint256 signersVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            if (i % 6 != 0) {
                for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                    signersVotingPower += votingPowers[i].vaults[j].value;
                }
            }
        }

        bytes memory zkProof =
            hex"2ce60b7028d29f8482ca3eb21c39d8269c920676556046e80ccb1f8efc73386319f7fa6ef743de05daf24c0733284a713fedc1136901b4ba882b0955f3447d001119b7e150e3190a3d87170629eb75b3d43dab819a8b0e073e6512a76820d3ad00236488a4ec497168b2d17cbcfde398b50d91b13674df6820af5ed0ce1d14992a8a32ff8cb3841c937e83a6c80e87fec3fe17450e974f71834398da48b6fca109ac7e9eb86007969c9c0fef2bc42dca8cd86be979500effebd4d609220dbfac1bc9339dbb2f5c770a4df722cd0b56d45d5a5f04a67b28366b627883e23c68f72e115e704b729d0de112b5fc5132a629370c2d67bde95bf605bbb08aeada9e0c000000011c0e70276724727ba9c0ca9ea64bd5b26518a80c88d15927a7bf0111c0b841a20e812945aaa2a2a647f01162d4de79c6350094eb5b1d230de77452c181eb881523af7e3f865d504e68b5d37ad3ab7400fe468885f08859eb32bcc4768d839da515f3dc2f45ece1d56f43da62125c0ee9bcbff7909f8540ef79cd3390262befb9";

        bytes memory fullProof;

        {
            bytes memory proof_ = Bytes.slice(zkProof, 0, 256);
            bytes memory commitments = Bytes.slice(zkProof, 260, 324);
            bytes memory commitmentPok = Bytes.slice(zkProof, 324, 388);

            fullProof = abi.encodePacked(proof_, commitments, commitmentPok, signersVotingPower);
        }

        SigVerifierBlsBn254ZK sigVerifier;
        {
            address[] memory verifiers = new address[](3);
            verifiers[0] = address(new Verifier_10());
            verifiers[1] = address(new Verifier_100());
            verifiers[2] = address(new Verifier_1000());
            uint256[] memory maxValidators = new uint256[](verifiers.length);
            maxValidators[0] = 10;
            maxValidators[1] = 100;
            maxValidators[2] = 1000;
            sigVerifier = new SigVerifierBlsBn254ZK(verifiers, maxValidators);
        }

        assertFalse(
            sigVerifier.verifyQuorumSig(
                address(masterSetupParams.settlement),
                masterSetupParams.settlement.getLastCommittedHeaderEpoch(),
                abi.encode(messageHash),
                KEY_TYPE_BLS_BN254.getKeyTag(15),
                totalVotingPower + 1,
                fullProof
            )
        );
    }

    function test_verifyQuorumSig() public {
        bytes32 messageHash = 0x658bc250cfe17f8ad77a5f5d92afb6e9316088b5c89c6df2db63785116b22948;
        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }
        uint256 signersVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            if (i % 6 != 0) {
                for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                    signersVotingPower += votingPowers[i].vaults[j].value;
                }
            }
        }

        bytes memory zkProof =
            hex"2ce60b7028d29f8482ca3eb21c39d8269c920676556046e80ccb1f8efc73386319f7fa6ef743de05daf24c0733284a713fedc1136901b4ba882b0955f3447d001119b7e150e3190a3d87170629eb75b3d43dab819a8b0e073e6512a76820d3ad00236488a4ec497168b2d17cbcfde398b50d91b13674df6820af5ed0ce1d14992a8a32ff8cb3841c937e83a6c80e87fec3fe17450e974f71834398da48b6fca109ac7e9eb86007969c9c0fef2bc42dca8cd86be979500effebd4d609220dbfac1bc9339dbb2f5c770a4df722cd0b56d45d5a5f04a67b28366b627883e23c68f72e115e704b729d0de112b5fc5132a629370c2d67bde95bf605bbb08aeada9e0c000000011c0e70276724727ba9c0ca9ea64bd5b26518a80c88d15927a7bf0111c0b841a20e812945aaa2a2a647f01162d4de79c6350094eb5b1d230de77452c181eb881523af7e3f865d504e68b5d37ad3ab7400fe468885f08859eb32bcc4768d839da515f3dc2f45ece1d56f43da62125c0ee9bcbff7909f8540ef79cd3390262befb9";

        bytes memory fullProof;

        {
            bytes memory proof_ = Bytes.slice(zkProof, 0, 256);
            bytes memory commitments = Bytes.slice(zkProof, 260, 324);
            bytes memory commitmentPok = Bytes.slice(zkProof, 324, 388);

            fullProof = abi.encodePacked(proof_, commitments, commitmentPok, signersVotingPower);
        }

        SigVerifierBlsBn254ZK sigVerifier;
        {
            address[] memory verifiers = new address[](3);
            verifiers[0] = address(new Verifier_10());
            verifiers[1] = address(new Verifier_100());
            verifiers[2] = address(new Verifier_1000());
            uint256[] memory maxValidators = new uint256[](verifiers.length);
            maxValidators[0] = 10;
            maxValidators[1] = 100;
            maxValidators[2] = 1000;
            sigVerifier = new SigVerifierBlsBn254ZK(verifiers, maxValidators);
        }

        bytes memory data = abi.encodeCall(
            ISigVerifier.verifyQuorumSig,
            (
                address(masterSetupParams.settlement),
                masterSetupParams.settlement.getLastCommittedHeaderEpoch(),
                abi.encode(messageHash),
                KEY_TYPE_BLS_BN254.getKeyTag(15),
                Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
                fullProof
            )
        );
        vm.startPrank(vars.deployer.addr);
        (bool success, bytes memory ret) = address(sigVerifier).call(data);

        assertTrue(success);
        assertTrue(abi.decode(ret, (bool)));
        vm.stopPrank();
    }

    function test_verifyQuorumSig_FalseZkProof() public {
        bytes32 messageHash = 0x658bc250cfe17f8ad77a5f5d92afb6e9316088b5c89c6df2db63785116b22948;
        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }
        uint256 signersVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            if (i % 6 != 0) {
                for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                    signersVotingPower += votingPowers[i].vaults[j].value;
                }
            }
        }

        bytes memory zkProof =
            hex"2ce60b7028d29f8482ca3eb21c39d8269c920676566046e80ccb1f8efc73386319f7fa6ef743de05daf24c0733284a713fedc1136901b4ba882b0955f3447d001119b7e150e3190a3d87170629eb75b3d43dab819a8b0e073e6512a76820d3ad00236488a4ec497168b2d17cbcfde398b50d91b13674df6820af5ed0ce1d14992a8a32ff8cb3841c937e83a6c80e87fec3fe17450e974f71834398da48b6fca109ac7e9eb86007969c9c0fef2bc42dca8cd86be979500effebd4d609220dbfac1bc9339dbb2f5c770a4df722cd0b56d45d5a5f04a67b28366b627883e23c68f72e115e704b729d0de112b5fc5132a629370c2d67bde95bf605bbb08aeada9e0c000000011c0e70276724727ba9c0ca9ea64bd5b26518a80c88d15927a7bf0111c0b841a20e812945aaa2a2a647f01162d4de79c6350094eb5b1d230de77452c181eb881523af7e3f865d504e68b5d37ad3ab7400fe468885f08859eb32bcc4768d839da515f3dc2f45ece1d56f43da62125c0ee9bcbff7909f8540ef79cd3390262befb9";

        bytes memory fullProof;

        {
            bytes memory proof_ = Bytes.slice(zkProof, 0, 256);
            bytes memory commitments = Bytes.slice(zkProof, 260, 324);
            bytes memory commitmentPok = Bytes.slice(zkProof, 324, 388);

            fullProof = abi.encodePacked(proof_, commitments, commitmentPok, signersVotingPower);
        }

        SigVerifierBlsBn254ZK sigVerifier;
        {
            address[] memory verifiers = new address[](3);
            verifiers[0] = address(new Verifier_10());
            verifiers[1] = address(new Verifier_100());
            verifiers[2] = address(new Verifier_1000());
            uint256[] memory maxValidators = new uint256[](verifiers.length);
            maxValidators[0] = 10;
            maxValidators[1] = 100;
            maxValidators[2] = 1000;
            sigVerifier = new SigVerifierBlsBn254ZK(verifiers, maxValidators);
        }

        bytes memory data = abi.encodeCall(
            ISigVerifier.verifyQuorumSig,
            (
                address(masterSetupParams.settlement),
                masterSetupParams.settlement.getLastCommittedHeaderEpoch(),
                abi.encode(messageHash),
                KEY_TYPE_BLS_BN254.getKeyTag(15),
                Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
                fullProof
            )
        );
        vm.startPrank(vars.deployer.addr);
        (bool success, bytes memory ret) = address(sigVerifier).call(data);

        assertTrue(success);
        assertFalse(abi.decode(ret, (bool)));
        vm.stopPrank();
    }

    function test_ZeroValidators() public {
        bytes32 messageHash = 0x658bc250cfe17f8ad77a5f5d92afb6e9316088b5c89c6df2db63785116b22948;
        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }
        uint256 signersVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            if (i % 6 != 0) {
                for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                    signersVotingPower += votingPowers[i].vaults[j].value;
                }
            }
        }

        bytes memory zkProof =
            hex"2ce60b7028d29f8482ca3eb21c39d8269c920676556046e80ccb1f8efc73386319f7fa6ef743de05daf24c0733284a713fedc1136901b4ba882b0955f3447d001119b7e150e3190a3d87170629eb75b3d43dab819a8b0e073e6512a76820d3ad00236488a4ec497168b2d17cbcfde398b50d91b13674df6820af5ed0ce1d14992a8a32ff8cb3841c937e83a6c80e87fec3fe17450e974f71834398da48b6fca109ac7e9eb86007969c9c0fef2bc42dca8cd86be979500effebd4d609220dbfac1bc9339dbb2f5c770a4df722cd0b56d45d5a5f04a67b28366b627883e23c68f72e115e704b729d0de112b5fc5132a629370c2d67bde95bf605bbb08aeada9e0c000000011c0e70276724727ba9c0ca9ea64bd5b26518a80c88d15927a7bf0111c0b841a20e812945aaa2a2a647f01162d4de79c6350094eb5b1d230de77452c181eb881523af7e3f865d504e68b5d37ad3ab7400fe468885f08859eb32bcc4768d839da515f3dc2f45ece1d56f43da62125c0ee9bcbff7909f8540ef79cd3390262befb9";

        bytes memory fullProof;

        {
            bytes memory proof_ = Bytes.slice(zkProof, 0, 256);
            bytes memory commitments = Bytes.slice(zkProof, 260, 324);
            bytes memory commitmentPok = Bytes.slice(zkProof, 324, 388);

            fullProof = abi.encodePacked(proof_, commitments, commitmentPok, signersVotingPower);
        }

        SigVerifierBlsBn254ZK sigVerifier;
        {
            address[] memory verifiers = new address[](3);
            verifiers[0] = address(new Verifier_10());
            verifiers[1] = address(new Verifier_100());
            verifiers[2] = address(new Verifier_1000());
            uint256[] memory maxValidators = new uint256[](verifiers.length);
            maxValidators[0] = 10;
            maxValidators[1] = 100;
            maxValidators[2] = 1000;
            sigVerifier = new SigVerifierBlsBn254ZK(verifiers, maxValidators);
        }

        bytes memory data = abi.encodeCall(
            ISigVerifier.verifyQuorumSig,
            (
                address(masterSetupParams.settlement),
                masterSetupParams.settlement.getLastCommittedHeaderEpoch(),
                abi.encode(messageHash),
                KEY_TYPE_BLS_BN254.getKeyTag(15),
                Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
                fullProof
            )
        );

        stdstore.target(address(masterSetupParams.settlement)).sig("getExtraDataAt(uint48,bytes32)").with_key(
            masterSetupParams.settlement.getLastCommittedHeaderEpoch()
        ).with_key(uint32(0).getKey(sigVerifier.TOTAL_ACTIVE_VALIDATORS_HASH())).checked_write(bytes32(uint256(0)));

        vm.startPrank(vars.deployer.addr);
        (bool success, bytes memory ret) = address(sigVerifier).call(data);

        assertTrue(success);
        assertFalse(abi.decode(ret, (bool)));
        vm.stopPrank();
    }

    function test_RevertInvalidTotalActiveValidators() public {
        bytes32 messageHash = 0x658bc250cfe17f8ad77a5f5d92afb6e9316088b5c89c6df2db63785116b22948;
        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }
        uint256 signersVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            if (i % 6 != 0) {
                for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                    signersVotingPower += votingPowers[i].vaults[j].value;
                }
            }
        }

        bytes memory zkProof =
            hex"2ce60b7028d29f8482ca3eb21c39d8269c920676556046e80ccb1f8efc73386319f7fa6ef743de05daf24c0733284a713fedc1136901b4ba882b0955f3447d001119b7e150e3190a3d87170629eb75b3d43dab819a8b0e073e6512a76820d3ad00236488a4ec497168b2d17cbcfde398b50d91b13674df6820af5ed0ce1d14992a8a32ff8cb3841c937e83a6c80e87fec3fe17450e974f71834398da48b6fca109ac7e9eb86007969c9c0fef2bc42dca8cd86be979500effebd4d609220dbfac1bc9339dbb2f5c770a4df722cd0b56d45d5a5f04a67b28366b627883e23c68f72e115e704b729d0de112b5fc5132a629370c2d67bde95bf605bbb08aeada9e0c000000011c0e70276724727ba9c0ca9ea64bd5b26518a80c88d15927a7bf0111c0b841a20e812945aaa2a2a647f01162d4de79c6350094eb5b1d230de77452c181eb881523af7e3f865d504e68b5d37ad3ab7400fe468885f08859eb32bcc4768d839da515f3dc2f45ece1d56f43da62125c0ee9bcbff7909f8540ef79cd3390262befb9";

        bytes memory fullProof;

        {
            bytes memory proof_ = Bytes.slice(zkProof, 0, 256);
            bytes memory commitments = Bytes.slice(zkProof, 260, 324);
            bytes memory commitmentPok = Bytes.slice(zkProof, 324, 388);

            fullProof = abi.encodePacked(proof_, commitments, commitmentPok, signersVotingPower);
        }

        SigVerifierBlsBn254ZK sigVerifier;
        {
            address[] memory verifiers = new address[](3);
            verifiers[0] = address(new Verifier_10());
            verifiers[1] = address(new Verifier_100());
            verifiers[2] = address(new Verifier_1000());
            uint256[] memory maxValidators = new uint256[](verifiers.length);
            maxValidators[0] = 10;
            maxValidators[1] = 100;
            maxValidators[2] = 1000;
            sigVerifier = new SigVerifierBlsBn254ZK(verifiers, maxValidators);
        }

        stdstore.target(address(masterSetupParams.settlement)).sig("getExtraDataAt(uint48,bytes32)").with_key(
            masterSetupParams.settlement.getLastCommittedHeaderEpoch()
        ).with_key(uint32(0).getKey(sigVerifier.TOTAL_ACTIVE_VALIDATORS_HASH())).checked_write(bytes32(uint256(1001)));

        vm.startPrank(vars.deployer.addr);
        uint48 lastCommittedHeaderEpoch = masterSetupParams.settlement.getLastCommittedHeaderEpoch();
        vm.expectRevert(ISigVerifierBlsBn254ZK.SigVerifierBlsBn254ZK_InvalidTotalActiveValidators.selector);
        sigVerifier.verifyQuorumSig(
            address(masterSetupParams.settlement),
            lastCommittedHeaderEpoch,
            abi.encode(messageHash),
            KEY_TYPE_BLS_BN254.getKeyTag(15),
            Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
            fullProof
        );

        vm.stopPrank();
    }
}
