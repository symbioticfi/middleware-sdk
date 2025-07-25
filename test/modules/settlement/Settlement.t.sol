// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";

import {KeyTags} from "../../../src/libraries/utils/KeyTags.sol";
import {KeyEcdsaSecp256k1} from "../../../src/libraries/keys/KeyEcdsaSecp256k1.sol";
import {KeyBlsBn254, BN254} from "../../../src/libraries/keys/KeyBlsBn254.sol";
import {SigBlsBn254} from "../../../src/libraries/sigs/SigBlsBn254.sol";

import {BN254G2} from "../../helpers/BN254G2.sol";

import {ISettlement} from "../../../src/interfaces/modules/settlement/ISettlement.sol";

import {MasterGenesisSetupTest} from "../../MasterGenesisSetup.sol";

import {console2} from "forge-std/console2.sol";

import {SigVerifierBlsBn254ZK} from "../../../src/modules/settlement/sig-verifiers/SigVerifierBlsBn254ZK.sol";

import {Bytes} from "@openzeppelin/contracts/utils/Bytes.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Settlement} from "../../../src/modules/settlement/Settlement.sol";

import {IOzEIP712} from "../../../src/interfaces/modules/base/IOzEIP712.sol";
import {INetworkManager} from "../../../src/interfaces/modules/base/INetworkManager.sol";
import {SigVerifierMock} from "../../mocks/SigVerifierMock.sol";
import {SigVerifierBlsBn254Simple} from "../../../src/modules/settlement/sig-verifiers/SigVerifierBlsBn254Simple.sol";
import {SigVerifierFalseMock} from "../../mocks/SigVerifierFalseMock.sol";

contract SettlementTest is MasterGenesisSetupTest {
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

    function setUp() public override {
        super.setUp();
    }

    // function test_commitValSetHeader() public {
    //     (ISettlement.ValSetHeader memory valSetHeader, ISettlement.ExtraData[] memory extraData) = loadGenesis();

    //     valSetHeader.epoch = 1;
    //     valSetHeader.captureTimestamp = uint48(vm.getBlockTimestamp()) - 1;
    //     // valSetHeader.previousHeaderHash = keccak256(abi.encode(masterSetupParams.master.getValSetHeaderAt(0)));
    //     valSetHeader.previousHeaderHash = 0x9ff403105928d3f1b175251c01c8c0fb0bba20e781cdd12c845e7715c84549f2;

    //     bytes32 messageHash = masterSetupParams.master.hashTypedDataV4CrossChain(
    //         keccak256(
    //             abi.encode(
    //                 VALSET_HEADER_COMMIT_TYPEHASH,
    //                 masterSetupParams.master.SUBNETWORK(),
    //                 0,
    //                 keccak256(abi.encode(valSetHeader)),
    //                 keccak256(abi.encode(extraData))
    //             )
    //         )
    //     );

    //     console2.log("messageHash");
    //     console2.logBytes32(messageHash);
    //     console2.logBytes32(valSetHeader.previousHeaderHash);

    //     BN254.G1Point memory aggKeyG1;
    //     BN254.G2Point memory aggKeyG2;
    //     BN254.G1Point memory aggSigG1;

    //     for (uint256 i; i < vars.operators.length; ++i) {
    //         BN254.G1Point memory keyG1 = BN254.generatorG1().scalar_mul(vars.operators[i].privateKey);

    //         BN254.G2Point memory keyG2 = getG2Key(vars.operators[i].privateKey);
    //         BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
    //         BN254.G1Point memory sigG1 = messageG1.scalar_mul(vars.operators[i].privateKey);
    //         aggSigG1 = aggSigG1.plus(sigG1);
    //         aggKeyG1 = aggKeyG1.plus(keyG1);

    //         if (aggKeyG2.X[0] == 0 && aggKeyG2.X[1] == 0 && aggKeyG2.Y[0] == 0 && aggKeyG2.Y[1] == 0) {
    //             aggKeyG2 = keyG2;
    //         } else {
    //             (uint256 x1, uint256 x2, uint256 y1, uint256 y2) = BN254G2.ECTwistAdd(
    //                 aggKeyG2.X[1],
    //                 aggKeyG2.X[0],
    //                 aggKeyG2.Y[1],
    //                 aggKeyG2.Y[0],
    //                 keyG2.X[1],
    //                 keyG2.X[0],
    //                 keyG2.Y[1],
    //                 keyG2.Y[0]
    //             );
    //             aggKeyG2 = BN254.G2Point([x2, x1], [y2, y1]);
    //         }
    //     }

    //     bytes memory zkProof =
    //         hex"0c9d92bd8aac8588329e85aade26354a7b9206e170f0df0ee891c3927e5a58522adf6d35c9649dbf628cfe567bc31647d52cf5ae023c88984cecbf01fb477d492761b1f57ca217b83d1851f3e9276e3a758fe92b0f7022d9610ed51e1d7da1521458461ac568a806eb566e1f177baba0bee7c49bbb225347da8d236def25eb3829f4a51eecc66d28b5c973a943d752aa383cbab591b59406da361cbeac1dfcc22afdfa764b84685fabc31a3e5367ca30c2eaa3480ec44a9f847f952da34df4ca0ec698607fb631abd2939ea85d57c69e097b8cdba0734b21154479dc7c39d2a11d2dec162d71b5fad118e59a9dd6917335f251384a3cb16ed48af9f3dbed8266000000011199b925c505c27fe05e9f75e2a0965aea4b6cdb945a4a481c6bc06bd080da701cd2629a69c1946bcd2695c369de10999ce9ec4f0c51d1f8d265460b4f2646d923e00d2fa0a29d4760394d8da2af4f7545377705157c75b86a20044f792a50b30068fdfeaa3eb3be8444c454fdf3629d902034c84714a652394c35da7fa2fb6f";

    //     bytes memory proof_ = Bytes.slice(zkProof, 0, 256);
    //     bytes memory commitments = Bytes.slice(zkProof, 260, 324);
    //     bytes memory commitmentPok = Bytes.slice(zkProof, 324, 388);

    //     IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
    //         masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
    //     uint256 signersVotingPower = 0;
    //     for (uint256 i; i < votingPowers.length; ++i) {
    //         for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
    //             signersVotingPower += votingPowers[i].vaults[j].value;
    //         }
    //     }

    //     bytes memory fullProof = abi.encodePacked(proof_, commitments, commitmentPok, signersVotingPower);

    //     console2.log("messageHash");
    //     console2.logBytes32(messageHash);

    //     masterSetupParams.master.commitValSetHeader(valSetHeader, extraData, fullProof, new bytes(0));
    // }
}

contract TestSettlement is Settlement {
    address public owner;

    function initialize(SettlementInitParams memory settlementInitParams, address _owner) external initializer {
        __Settlement_init(settlementInitParams);
        owner = _owner;
    }

    // PermissionManager requirement:
    function _checkPermission() internal view override {
        require(msg.sender == owner, "Not authorized");
    }
}

contract SettlementRawTest is Test {
    TestSettlement private testSettle;

    address private owner = address(0xABC);
    address private nonOwner = address(0x999);

    ISettlement.ValSetHeader private sampleHeader;
    ISettlement.ExtraData[] private someExtra;

    ISettlement.SettlementInitParams private initParams;

    function setUp() public {
        vm.warp(1_731_325_032);

        testSettle = new TestSettlement();

        vm.expectRevert();
        testSettle.getSigVerifier();

        {
            IOzEIP712.OzEIP712InitParams memory eip712;
            eip712.name = "Settlement";
            eip712.version = "1";

            INetworkManager.NetworkManagerInitParams memory netInit;
            netInit.network = address(0xDEF);
            netInit.subnetworkId = 999;

            initParams.ozEip712InitParams = eip712;
            initParams.networkManagerInitParams = netInit;
        }

        vm.expectRevert(ISettlement.Settlement_InvalidSigVerifier.selector);
        testSettle.initialize(initParams, owner);

        initParams.sigVerifier = address(new SigVerifierMock());
        testSettle.initialize(initParams, owner);

        sampleHeader = ISettlement.ValSetHeader({
            version: testSettle.VALIDATOR_SET_VERSION(),
            requiredKeyTag: 7,
            epoch: 0,
            captureTimestamp: uint48(vm.getBlockTimestamp()) - 1,
            quorumThreshold: 1000,
            totalVotingPower: 1501,
            validatorsSszMRoot: bytes32(uint256(0xAAA)),
            previousHeaderHash: 0xd397b3b043d87fcd6fad1291ff0bfd16401c274896d8c63a923727f077b8e0b5
        });
        someExtra.push(ISettlement.ExtraData({key: bytes32(uint256(0xCCC)), value: bytes32(uint256(0xBBB))}));
    }

    function testVersion() public {
        assertEq(testSettle.VALIDATOR_SET_VERSION(), 1, "VALIDATOR_SET_VERSION mismatch");
    }

    function testInitParams() public {
        assertEq(testSettle.getSigVerifier(), initParams.sigVerifier, "Sig verifier mismatch");
        assertEq(
            testSettle.getSigVerifierAt(uint48(vm.getBlockTimestamp()), new bytes(0)),
            initParams.sigVerifier,
            "Sig verifier mismatch"
        );
    }

    function testSetGenesis_Permission() public {
        vm.prank(nonOwner);
        vm.expectRevert("Not authorized");
        testSettle.setGenesis(sampleHeader, someExtra);

        vm.prank(owner);
        testSettle.setGenesis(sampleHeader, someExtra);

        vm.assertEq(
            testSettle.getPreviousHeaderHashFromValSetHeader(),
            sampleHeader.previousHeaderHash,
            "ValSet previousHeaderHash mismatch after setGenesis"
        );
        assertEq(
            testSettle.getPreviousHeaderHashFromValSetHeaderAt(sampleHeader.epoch),
            sampleHeader.previousHeaderHash,
            "ValSet previousHeaderHash mismatch after setGenesis"
        );
        assertEq(
            testSettle.getValidatorsSszMRootFromValSetHeader(),
            sampleHeader.validatorsSszMRoot,
            "ValSet validatorsSszMRoot mismatch after setGenesis"
        );
        assertEq(
            testSettle.getValidatorsSszMRootFromValSetHeaderAt(sampleHeader.epoch),
            sampleHeader.validatorsSszMRoot,
            "ValSet validatorsSszMRoot mismatch after setGenesis"
        );
        assertEq(
            testSettle.getQuorumThresholdFromValSetHeader(),
            sampleHeader.quorumThreshold,
            "ValSet quorumThreshold mismatch after setGenesis"
        );
        assertEq(
            testSettle.getQuorumThresholdFromValSetHeaderAt(sampleHeader.epoch),
            sampleHeader.quorumThreshold,
            "ValSet quorumThreshold mismatch after setGenesis"
        );
        assertEq(
            testSettle.getTotalVotingPowerFromValSetHeader(),
            sampleHeader.totalVotingPower,
            "ValSet totalVotingPower mismatch after setGenesis"
        );
        assertEq(
            testSettle.getTotalVotingPowerFromValSetHeaderAt(sampleHeader.epoch),
            sampleHeader.totalVotingPower,
            "ValSet totalVotingPower mismatch after setGenesis"
        );
        assertEq(
            testSettle.getRequiredKeyTagFromValSetHeader(),
            sampleHeader.requiredKeyTag,
            "ValSet requiredKeyTag mismatch after setGenesis"
        );
        assertEq(
            testSettle.getRequiredKeyTagFromValSetHeaderAt(sampleHeader.epoch),
            sampleHeader.requiredKeyTag,
            "ValSet requiredKeyTag mismatch after setGenesis"
        );
        assertEq(
            testSettle.getCaptureTimestampFromValSetHeader(),
            sampleHeader.captureTimestamp,
            "ValSet captureTimestamp mismatch after setGenesis"
        );
        assertEq(
            testSettle.getCaptureTimestampFromValSetHeaderAt(sampleHeader.epoch),
            sampleHeader.captureTimestamp,
            "ValSet captureTimestamp mismatch after setGenesis"
        );
        assertEq(
            testSettle.getVersionFromValSetHeader(), sampleHeader.version, "ValSet version mismatch after setGenesis"
        );
        assertEq(
            testSettle.getVersionFromValSetHeaderAt(sampleHeader.epoch),
            sampleHeader.version,
            "ValSet version mismatch after setGenesis"
        );
        assertEq(testSettle.getExtraData(someExtra[0].key), someExtra[0].value, "Extra data mismatch after setGenesis");
        assertEq(
            testSettle.getExtraDataAt(sampleHeader.epoch, someExtra[0].key),
            someExtra[0].value,
            "Extra data mismatch after setGenesis"
        );
        assertEq(testSettle.getValSetHeaderHash(), keccak256(abi.encode(sampleHeader)), "ValSet header hash mismatch");
        assertEq(
            testSettle.getValSetHeaderHashAt(sampleHeader.epoch),
            keccak256(abi.encode(sampleHeader)),
            "ValSet header hash mismatch"
        );
    }

    function testSetGenesis_Revert_ValSetHeaderAlreadySubmitted() public {
        vm.prank(owner);
        testSettle.setGenesis(sampleHeader, someExtra);

        vm.expectRevert(ISettlement.Settlement_ValSetHeaderAlreadyCommitted.selector);
        vm.prank(owner);
        testSettle.setGenesis(sampleHeader, someExtra);

        ISettlement.ValSetHeader memory stored = testSettle.getValSetHeaderAt(0);

        assertEq(stored.version, sampleHeader.version, "ValSet version mismatch after setGenesis");
        assertEq(stored.epoch, 0, "ValSet epoch mismatch after setGenesis");
        assertEq(
            stored.captureTimestamp,
            uint48(vm.getBlockTimestamp()) - 1,
            "ValSet captureTimestamp mismatch after setGenesis"
        );
        assertEq(stored.quorumThreshold, 1000, "ValSet quorumThreshold mismatch after setGenesis");
        assertEq(
            stored.validatorsSszMRoot, bytes32(uint256(0xAAA)), "ValSet validatorsSszMRoot mismatch after setGenesis"
        );
        assertEq(
            stored.previousHeaderHash,
            0xd397b3b043d87fcd6fad1291ff0bfd16401c274896d8c63a923727f077b8e0b5,
            "ValSet previousHeaderHash mismatch after setGenesis"
        );

        stored = testSettle.getValSetHeader();
        assertEq(stored.version, sampleHeader.version, "ValSet version mismatch after setGenesis");
        assertEq(stored.epoch, 0, "ValSet epoch mismatch after setGenesis");
        assertEq(
            stored.captureTimestamp,
            uint48(vm.getBlockTimestamp()) - 1,
            "ValSet captureTimestamp mismatch after setGenesis"
        );
        assertEq(stored.quorumThreshold, 1000, "ValSet quorumThreshold mismatch after setGenesis");
        assertEq(
            stored.validatorsSszMRoot, bytes32(uint256(0xAAA)), "ValSet validatorsSszMRoot mismatch after setGenesis"
        );
        assertEq(
            stored.previousHeaderHash,
            0xd397b3b043d87fcd6fad1291ff0bfd16401c274896d8c63a923727f077b8e0b5,
            "ValSet previousHeaderHash mismatch after setGenesis"
        );
    }

    function testCommitValSetHeader_Basic() public {
        vm.prank(owner);
        testSettle.setGenesis(sampleHeader, someExtra);

        // address sigVerifier = address(new SigVerifierBlsBn254Simple());
        // vm.prank(owner);
        // testSettle.setSigVerifier(sigVerifier);

        vm.warp(vm.getBlockTimestamp() + 130);

        ISettlement.ValSetHeader memory header = sampleHeader;
        header.version = 2;
        header.epoch = 1;
        header.captureTimestamp = uint48(vm.getBlockTimestamp() - 1);
        header.previousHeaderHash = testSettle.getValSetHeaderHash();

        vm.expectRevert(ISettlement.Settlement_InvalidVersion.selector);
        testSettle.commitValSetHeader(header, someExtra, bytes(""));

        header.version = 1;
        testSettle.commitValSetHeader(header, someExtra, bytes(""));

        assertTrue(testSettle.isValSetHeaderCommittedAt(header.epoch - 1));
        assertTrue(testSettle.isValSetHeaderCommittedAt(header.epoch));
        assertFalse(testSettle.isValSetHeaderCommittedAt(header.epoch + 1));

        vm.warp(vm.getBlockTimestamp() + 1);

        header.epoch = 2;
        header.captureTimestamp = uint48(vm.getBlockTimestamp() - 1);
        header.previousHeaderHash = testSettle.getValSetHeaderHash();

        testSettle.commitValSetHeader(header, someExtra, bytes(""));

        vm.expectRevert(ISettlement.Settlement_InvalidEpoch.selector);
        testSettle.commitValSetHeader(header, someExtra, bytes(""));

        header.epoch = 3;
        vm.expectRevert(ISettlement.Settlement_InvalidCaptureTimestamp.selector);
        testSettle.commitValSetHeader(header, someExtra, bytes(""));

        vm.warp(vm.getBlockTimestamp() + 1);

        header.captureTimestamp = uint48(vm.getBlockTimestamp() - 1);

        vm.expectRevert(ISettlement.Settlement_InvalidPreviousHeaderHash.selector);
        testSettle.commitValSetHeader(header, someExtra, bytes(""));

        header.previousHeaderHash = testSettle.getValSetHeaderHash();

        header.validatorsSszMRoot = bytes32(0);
        vm.expectRevert(ISettlement.Settlement_InvalidValidatorsSszMRoot.selector);
        testSettle.commitValSetHeader(header, someExtra, bytes(""));
        header.validatorsSszMRoot = sampleHeader.validatorsSszMRoot;

        testSettle.commitValSetHeader(header, someExtra, bytes(""));
    }

    function test_setSigVerifier() public {
        address newSigVerifier = address(new SigVerifierMock());
        vm.prank(owner);
        testSettle.setSigVerifier(newSigVerifier);

        assertEq(testSettle.getSigVerifier(), initParams.sigVerifier, "Sig verifier mismatch");
        assertEq(
            testSettle.getSigVerifierAt(testSettle.getLastCommittedHeaderEpoch(), new bytes(0)),
            initParams.sigVerifier,
            "Sig verifier mismatch"
        );
        assertEq(
            testSettle.getSigVerifierAt(testSettle.getLastCommittedHeaderEpoch() + 1, new bytes(0)),
            newSigVerifier,
            "Sig verifier mismatch"
        );
    }

    function test_setSigVerifier_Revert_InvalidSigVerifier() public {
        vm.prank(owner);
        vm.expectRevert(ISettlement.Settlement_InvalidSigVerifier.selector);
        testSettle.setSigVerifier(address(0));
    }

    function test_commitValSetHeader_VerificationFailed() public {
        ISettlement.ValSetHeader memory header = sampleHeader;

        vm.expectRevert(ISettlement.Settlement_VerificationFailed.selector);
        testSettle.commitValSetHeader(header, someExtra, bytes(""));

        vm.prank(owner);
        testSettle.setGenesis(sampleHeader, someExtra);

        vm.startPrank(owner);
        testSettle.setSigVerifier(address(new SigVerifierFalseMock()));
        vm.stopPrank();

        vm.warp(vm.getBlockTimestamp() + 1);

        assertFalse(testSettle.verifyQuorumSigAt(new bytes(0), 0, 0, new bytes(0), 1, new bytes(0)));

        header.epoch = 1;
        header.captureTimestamp = uint48(vm.getBlockTimestamp() - 1);
        header.previousHeaderHash = testSettle.getValSetHeaderHash();

        someExtra.push(ISettlement.ExtraData({key: someExtra[0].key, value: someExtra[0].value}));
        vm.expectRevert(ISettlement.Settlement_DuplicateExtraDataKey.selector);
        testSettle.commitValSetHeader(header, someExtra, bytes(""));

        someExtra.pop();

        testSettle.commitValSetHeader(header, someExtra, bytes(""));

        vm.warp(vm.getBlockTimestamp() + 1);

        header.epoch = 2;
        header.captureTimestamp = uint48(vm.getBlockTimestamp() - 1);
        header.previousHeaderHash = testSettle.getValSetHeaderHash();
        vm.expectRevert(ISettlement.Settlement_VerificationFailed.selector);
        testSettle.commitValSetHeader(header, someExtra, bytes(""));
    }
}
