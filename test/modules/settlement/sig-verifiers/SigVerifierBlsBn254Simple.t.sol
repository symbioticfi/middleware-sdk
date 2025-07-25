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
import {ExtraDataStorageHelper} from
    "../../../../src/modules/settlement/sig-verifiers/libraries/ExtraDataStorageHelper.sol";

import {BN254G2} from "../../../helpers/BN254G2.sol";

import {ISettlement} from "../../../../src/interfaces/modules/settlement/ISettlement.sol";
import {IOzOwnable} from "../../../../src/interfaces/modules/common/permissions/IOzOwnable.sol";
import {INetworkManager} from "../../../../src/interfaces/modules/base/INetworkManager.sol";
import {IEpochManager} from "../../../../src/interfaces/modules/valset-driver/IEpochManager.sol";
import {IOperatorsWhitelist} from "../../../../src/interfaces/modules/voting-power/extensions/IOperatorsWhitelist.sol";
import {IOzEIP712} from "../../../../src/interfaces/modules/base/IOzEIP712.sol";
import {ISigVerifierBlsBn254Simple} from
    "../../../../src/interfaces/modules/settlement/sig-verifiers/ISigVerifierBlsBn254Simple.sol";
import {IVotingPowerProvider} from "../../../../src/interfaces/modules/voting-power/IVotingPowerProvider.sol";

import {MasterSetupTest} from "../../../MasterSetup.sol";

import {console2} from "forge-std/console2.sol";

import {SigVerifierBlsBn254Simple} from "../../../../src/modules/settlement/sig-verifiers/SigVerifierBlsBn254Simple.sol";
import "../../../InitSetup.sol";

import {ISigVerifier} from "../../../../src/interfaces/modules/settlement/sig-verifiers/ISigVerifier.sol";

import {Bytes} from "@openzeppelin/contracts/utils/Bytes.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {VotingPowerProviderSemiFull} from "../../../mocks/VotingPowerProviderSemiFull.sol";
import {MyKeyRegistry} from "../../../../examples/MyKeyRegistry.sol";
import {MySettlement} from "../../../../examples/MySettlement.sol";
import {MyValSetDriver} from "../../../../examples/MyValSetDriver.sol";
import {ISettlement} from "../../../../src/interfaces/modules/settlement/ISettlement.sol";
import {IKeyRegistry} from "../../../../src/interfaces/modules/key-registry/IKeyRegistry.sol";
import {IValSetDriver} from "../../../../src/interfaces/modules/valset-driver/IValSetDriver.sol";

contract SigVerifierBlsBn254SimpleTest is MasterSetupTest {
    using KeyTags for uint8;
    using KeyBlsBn254 for BN254.G1Point;
    using BN254 for BN254.G1Point;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;
    using KeyEcdsaSecp256k1 for KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1;
    using Math for uint256;
    using ExtraDataStorageHelper for uint32;

    struct ZkProof {
        uint256[] input;
        bytes proof;
    }

    struct SimpleGenesis {
        ISettlement.ValSetHeader header;
        ISettlement.ExtraData[] extraData;
    }

    function setUp() public override {
        VERIFICATION_TYPE = 1;
        MasterSetupTest.setUp();

        (ISettlement.ValSetHeader memory valSetHeader, ISettlement.ExtraData[] memory extraData) = loadGenesisSimple();

        vm.warp(masterSetupParams.valSetDriver.getEpochStart(0) + 1);

        vm.startPrank(vars.deployer.addr);
        masterSetupParams.settlement.setGenesis(valSetHeader, extraData);
        vm.stopPrank();
    }

    function test_verifyQuorumSig() public {
        bytes32 messageHash = 0x204e0c470c62e2f8426b236c004b581084dd3aaa935ed3afe24dc37e0d040823;

        BN254.G2Point memory aggKeyG2;
        BN254.G1Point memory aggSigG1;

        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            BN254.G2Point memory keyG2 = getG2Key(getOperator(i).privateKey);
            BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
            BN254.G1Point memory sigG1 = messageG1.scalar_mul(getOperator(i).privateKey);

            if (i % 6 != 0) {
                aggSigG1 = aggSigG1.plus(sigG1);

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
        }

        ValidatorData[] memory validatorsData = getValidatorsData();
        bytes memory nonSigners = new bytes((validatorsData.length + 5) / 6 * 2);
        for (uint8 i; i < validatorsData.length; ++i) {
            if (i % 6 == 0) {
                assembly ("memory-safe") {
                    mstore(add(add(nonSigners, 32), mul(div(i, 6), 2)), shl(240, i))
                }
            }
        }
        bytes memory fullProof = abi.encodePacked(
            abi.encode(aggSigG1),
            abi.encode(aggKeyG2),
            Bytes.slice(abi.encode(validatorsData), 32),
            abi.encodePacked(nonSigners)
        );

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }

        bytes memory data = abi.encodeCall(
            ISettlement.verifyQuorumSigAt,
            (
                abi.encode(messageHash),
                KEY_TYPE_BLS_BN254.getKeyTag(15),
                Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
                fullProof,
                masterSetupParams.settlement.getLastCommittedHeaderEpoch(),
                new bytes(0)
            )
        );
        vm.startPrank(vars.deployer.addr);
        (bool success, bytes memory result) = address(masterSetupParams.settlement).call(data);
        assertTrue(success);
        assertTrue(abi.decode(result, (bool)));

        data = abi.encodeCall(
            ISettlement.verifyQuorumSig,
            (
                abi.encode(messageHash),
                KEY_TYPE_BLS_BN254.getKeyTag(15),
                Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
                fullProof
            )
        );
        vm.startPrank(vars.deployer.addr);
        (success, result) = address(masterSetupParams.settlement).call(data);
        assertTrue(success);
        assertTrue(abi.decode(result, (bool)));
        vm.stopPrank();
    }

    function test_RevertUnsupportedKeyTag() public {
        bytes32 messageHash = 0x204e0c470c62e2f8426b236c004b581084dd3aaa935ed3afe24dc37e0d040823;

        BN254.G2Point memory aggKeyG2;
        BN254.G1Point memory aggSigG1;

        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            BN254.G2Point memory keyG2 = getG2Key(getOperator(i).privateKey);
            BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
            BN254.G1Point memory sigG1 = messageG1.scalar_mul(getOperator(i).privateKey);

            if (i % 6 != 0) {
                aggSigG1 = aggSigG1.plus(sigG1);

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
        }

        ValidatorData[] memory validatorsData = getValidatorsData();
        bytes memory nonSigners = new bytes((validatorsData.length + 5) / 6 * 2);
        for (uint8 i; i < validatorsData.length; ++i) {
            if (i % 6 == 0) {
                assembly ("memory-safe") {
                    mstore(add(add(nonSigners, 32), mul(div(i, 6), 2)), shl(240, i))
                }
            }
        }
        bytes memory fullProof = abi.encodePacked(
            abi.encode(aggSigG1),
            abi.encode(aggKeyG2),
            Bytes.slice(abi.encode(validatorsData), 32),
            abi.encodePacked(nonSigners)
        );

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }

        vm.expectRevert(ISigVerifierBlsBn254Simple.SigVerifierBlsBn254Simple_UnsupportedKeyTag.selector);
        ISettlement(masterSetupParams.settlement).verifyQuorumSig(
            abi.encode(messageHash),
            KEY_TYPE_ECDSA_SECP256K1.getKeyTag(15),
            Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
            fullProof
        );
    }

    function test_RevertInvalidMessageLength() public {
        bytes32 messageHash = 0x204e0c470c62e2f8426b236c004b581084dd3aaa935ed3afe24dc37e0d040823;

        BN254.G2Point memory aggKeyG2;
        BN254.G1Point memory aggSigG1;

        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            BN254.G2Point memory keyG2 = getG2Key(getOperator(i).privateKey);
            BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
            BN254.G1Point memory sigG1 = messageG1.scalar_mul(getOperator(i).privateKey);

            if (i % 6 != 0) {
                aggSigG1 = aggSigG1.plus(sigG1);

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
        }

        ValidatorData[] memory validatorsData = getValidatorsData();
        bytes memory nonSigners = new bytes((validatorsData.length + 5) / 6 * 2);
        for (uint8 i; i < validatorsData.length; ++i) {
            if (i % 6 == 0) {
                assembly ("memory-safe") {
                    mstore(add(add(nonSigners, 32), mul(div(i, 6), 2)), shl(240, i))
                }
            }
        }
        bytes memory fullProof = abi.encodePacked(
            abi.encode(aggSigG1),
            abi.encode(aggKeyG2),
            Bytes.slice(abi.encode(validatorsData), 32),
            abi.encodePacked(nonSigners)
        );

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }

        vm.expectRevert(ISigVerifierBlsBn254Simple.SigVerifierBlsBn254Simple_InvalidMessageLength.selector);
        ISettlement(masterSetupParams.settlement).verifyQuorumSig(
            abi.encode(messageHash, messageHash),
            KEY_TYPE_BLS_BN254.getKeyTag(15),
            Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
            fullProof
        );
    }

    function test_RevertInvalidProofOffset() public {
        bytes32 messageHash = 0x204e0c470c62e2f8426b236c004b581084dd3aaa935ed3afe24dc37e0d040823;

        BN254.G2Point memory aggKeyG2;
        BN254.G1Point memory aggSigG1;

        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            BN254.G2Point memory keyG2 = getG2Key(getOperator(i).privateKey);
            BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
            BN254.G1Point memory sigG1 = messageG1.scalar_mul(getOperator(i).privateKey);

            if (i % 6 != 0) {
                aggSigG1 = aggSigG1.plus(sigG1);

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
        }

        ValidatorData[] memory validatorsData = getValidatorsData();
        bytes memory nonSigners = new bytes((validatorsData.length + 5) / 6 * 2);
        for (uint8 i; i < validatorsData.length; ++i) {
            if (i % 6 == 0) {
                assembly ("memory-safe") {
                    mstore(add(add(nonSigners, 32), mul(div(i, 6), 2)), shl(240, i))
                }
            }
        }
        bytes memory fullProof = abi.encodePacked(
            abi.encode(aggSigG1),
            abi.encode(aggKeyG2),
            Bytes.slice(abi.encode(validatorsData), 32),
            abi.encodePacked(nonSigners)
        );

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }

        bytes memory data = abi.encodeCall(
            ISettlement.verifyQuorumSig,
            (
                abi.encode(messageHash),
                KEY_TYPE_BLS_BN254.getKeyTag(15),
                Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
                new bytes(0)
            )
        );

        vm.startPrank(vars.deployer.addr);
        (bool success,) = address(masterSetupParams.settlement).call(data);
        assertFalse(success);
    }

    function test_RevertInvalidProofLength() public {
        bytes32 messageHash = 0x204e0c470c62e2f8426b236c004b581084dd3aaa935ed3afe24dc37e0d040823;

        BN254.G2Point memory aggKeyG2;
        BN254.G1Point memory aggSigG1;

        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            BN254.G2Point memory keyG2 = getG2Key(getOperator(i).privateKey);
            BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
            BN254.G1Point memory sigG1 = messageG1.scalar_mul(getOperator(i).privateKey);

            if (i % 6 != 0) {
                aggSigG1 = aggSigG1.plus(sigG1);

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
        }

        ValidatorData[] memory validatorsData = getValidatorsData();
        bytes memory nonSigners = new bytes((validatorsData.length + 5) / 6 * 2);
        for (uint8 i; i < validatorsData.length; ++i) {
            if (i % 6 == 0) {
                assembly ("memory-safe") {
                    mstore(add(add(nonSigners, 32), mul(div(i, 6), 2)), shl(240, i))
                }
            }
        }
        bytes memory fullProof = abi.encodePacked(
            abi.encode(aggSigG1),
            abi.encode(aggKeyG2),
            Bytes.slice(abi.encode(validatorsData), 32),
            abi.encodePacked(nonSigners)
        );

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }

        assembly ("memory-safe") {
            mstore(fullProof, 223)
        }

        vm.expectRevert(ISigVerifierBlsBn254Simple.SigVerifierBlsBn254Simple_InvalidProofLength.selector);
        ISettlement(masterSetupParams.settlement).verifyQuorumSig(
            abi.encode(messageHash),
            KEY_TYPE_BLS_BN254.getKeyTag(15),
            Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
            fullProof
        );
    }

    function test_ZeroValidators() public {
        (ISettlement.ValSetHeader memory valSetHeader, ISettlement.ExtraData[] memory extraData) = loadGenesisSimple();

        uint48 epoch = 1;
        uint48 epochStart = masterSetupParams.valSetDriver.getEpochStart(epoch);
        vm.warp(epochStart + 1);

        valSetHeader.epoch = epoch;
        valSetHeader.captureTimestamp = epochStart;
        valSetHeader.totalVotingPower = 0;
        valSetHeader.validatorsSszMRoot = 0x0000000000000000000000000000000000000000000000000000000000000001;
        valSetHeader.quorumThreshold = 0;
        valSetHeader.previousHeaderHash = masterSetupParams.settlement.getValSetHeaderHash();

        vm.startPrank(vars.deployer.addr);
        masterSetupParams.settlement.setGenesis(valSetHeader, extraData);
        vm.stopPrank();

        bytes32 messageHash = 0x204e0c470c62e2f8426b236c004b581084dd3aaa935ed3afe24dc37e0d040823;

        BN254.G2Point memory aggKeyG2;
        BN254.G1Point memory aggSigG1;

        ValidatorData[] memory validatorsData;
        bytes memory nonSigners = new bytes((validatorsData.length + 5) / 6 * 2);
        for (uint8 i; i < validatorsData.length; ++i) {
            if (i % 6 == 0) {
                assembly ("memory-safe") {
                    mstore(add(add(nonSigners, 32), mul(div(i, 6), 2)), shl(240, i))
                }
            }
        }
        bytes memory fullProof = abi.encodePacked(
            abi.encode(aggSigG1),
            abi.encode(aggKeyG2),
            Bytes.slice(abi.encode(validatorsData), 32),
            abi.encodePacked(nonSigners)
        );

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }

        assertFalse(
            ISettlement(masterSetupParams.settlement).verifyQuorumSig(
                abi.encode(messageHash),
                KEY_TYPE_BLS_BN254.getKeyTag(15),
                Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
                fullProof
            )
        );
    }

    function test_RevertTooManyValidators() public {
        bytes32 messageHash = 0x204e0c470c62e2f8426b236c004b581084dd3aaa935ed3afe24dc37e0d040823;

        BN254.G2Point memory aggKeyG2;
        BN254.G1Point memory aggSigG1;

        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            BN254.G2Point memory keyG2 = getG2Key(getOperator(i).privateKey);
            BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
            BN254.G1Point memory sigG1 = messageG1.scalar_mul(getOperator(i).privateKey);

            if (i % 6 != 0) {
                aggSigG1 = aggSigG1.plus(sigG1);

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
        }

        ValidatorData[] memory validatorsData = getValidatorsData();
        bytes memory nonSigners = new bytes((validatorsData.length + 5) / 6 * 2);
        for (uint8 i; i < validatorsData.length; ++i) {
            if (i % 6 == 0) {
                assembly ("memory-safe") {
                    mstore(add(add(nonSigners, 32), mul(div(i, 6), 2)), shl(240, i))
                }
            }
        }
        bytes memory fullProof = abi.encodePacked(
            abi.encode(aggSigG1),
            abi.encode(aggKeyG2),
            Bytes.slice(abi.encode(validatorsData), 32),
            abi.encodePacked(nonSigners)
        );

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }

        assembly ("memory-safe") {
            mstore(add(add(fullProof, 32), 192), 65537)
        }

        vm.expectRevert(ISigVerifierBlsBn254Simple.SigVerifierBlsBn254Simple_TooManyValidators.selector);
        ISettlement(masterSetupParams.settlement).verifyQuorumSig(
            abi.encode(messageHash),
            KEY_TYPE_BLS_BN254.getKeyTag(15),
            Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
            fullProof
        );
    }

    function test_RevertInvalidNonSignerIndex() public {
        bytes32 messageHash = 0x204e0c470c62e2f8426b236c004b581084dd3aaa935ed3afe24dc37e0d040823;

        BN254.G2Point memory aggKeyG2;
        BN254.G1Point memory aggSigG1;

        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            BN254.G2Point memory keyG2 = getG2Key(getOperator(i).privateKey);
            BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
            BN254.G1Point memory sigG1 = messageG1.scalar_mul(getOperator(i).privateKey);

            if (i % 6 != 0) {
                aggSigG1 = aggSigG1.plus(sigG1);

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
        }

        ValidatorData[] memory validatorsData = getValidatorsData();
        bytes memory nonSigners = new bytes((validatorsData.length + 5) / 6 * 2);
        for (uint8 i; i < validatorsData.length; ++i) {
            if (i % 6 == 0) {
                assembly ("memory-safe") {
                    mstore(add(add(nonSigners, 32), mul(div(i, 6), 2)), shl(240, i))
                }
            }
        }
        bytes memory fullProof = abi.encodePacked(
            abi.encode(aggSigG1),
            abi.encode(aggKeyG2),
            Bytes.slice(abi.encode(validatorsData), 32),
            abi.encodePacked(nonSigners)
        );

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }

        assembly ("memory-safe") {
            mstore(fullProof, sub(mload(fullProof), 1))
        }

        vm.expectRevert(ISigVerifierBlsBn254Simple.SigVerifierBlsBn254Simple_InvalidProofLength.selector);
        ISettlement(masterSetupParams.settlement).verifyQuorumSig(
            abi.encode(messageHash),
            KEY_TYPE_BLS_BN254.getKeyTag(15),
            Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
            fullProof
        );
    }

    function test_RevertInvalidNonSignersOrder() public {
        bytes32 messageHash = 0x204e0c470c62e2f8426b236c004b581084dd3aaa935ed3afe24dc37e0d040823;

        BN254.G2Point memory aggKeyG2;
        BN254.G1Point memory aggSigG1;

        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            BN254.G2Point memory keyG2 = getG2Key(getOperator(i).privateKey);
            BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
            BN254.G1Point memory sigG1 = messageG1.scalar_mul(getOperator(i).privateKey);

            if (i % 6 != 0) {
                aggSigG1 = aggSigG1.plus(sigG1);

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
        }

        ValidatorData[] memory validatorsData = getValidatorsData();
        bytes memory nonSigners = new bytes((validatorsData.length + 5) / 6 * 2);
        for (uint8 i; i < validatorsData.length; ++i) {
            if (i % 6 == 0) {
                assembly ("memory-safe") {
                    mstore(add(add(nonSigners, 32), mul(div(i, 6), 2)), shl(240, i))
                }
            }
        }
        assembly ("memory-safe") {
            mstore(
                add(add(nonSigners, 32), mul(div(sub(mload(validatorsData), 1), 6), 2)), shl(240, mload(validatorsData))
            )
        }
        bytes memory fullProof = abi.encodePacked(
            abi.encode(aggSigG1),
            abi.encode(aggKeyG2),
            Bytes.slice(abi.encode(validatorsData), 32),
            abi.encodePacked(nonSigners)
        );

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }

        vm.expectRevert(ISigVerifierBlsBn254Simple.SigVerifierBlsBn254Simple_InvalidNonSignerIndex.selector);
        ISettlement(masterSetupParams.settlement).verifyQuorumSig(
            abi.encode(messageHash),
            KEY_TYPE_BLS_BN254.getKeyTag(15),
            Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
            fullProof
        );
    }

    function test_FalseValidatorSet() public {
        bytes32 messageHash = 0x204e0c470c62e2f8426b236c004b581084dd3aaa935ed3afe24dc37e0d040823;

        BN254.G2Point memory aggKeyG2;
        BN254.G1Point memory aggSigG1;

        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            BN254.G2Point memory keyG2 = getG2Key(getOperator(i).privateKey);
            BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
            BN254.G1Point memory sigG1 = messageG1.scalar_mul(getOperator(i).privateKey);

            if (i % 6 != 0) {
                aggSigG1 = aggSigG1.plus(sigG1);

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
        }

        ValidatorData[] memory validatorsData = getValidatorsData();
        bytes memory nonSigners = new bytes((validatorsData.length + 5) / 6 * 2);
        for (uint8 i; i < validatorsData.length; ++i) {
            if (i % 6 == 0) {
                assembly ("memory-safe") {
                    mstore(add(add(nonSigners, 32), mul(div(i, 6), 2)), shl(240, i))
                }
            }
        }

        validatorsData[0].votingPower = type(uint256).max;

        bytes memory fullProof = abi.encodePacked(
            abi.encode(aggSigG1),
            abi.encode(aggKeyG2),
            Bytes.slice(abi.encode(validatorsData), 32),
            abi.encodePacked(nonSigners)
        );

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }

        assertFalse(
            ISigVerifier(masterSetupParams.settlement.getSigVerifier()).verifyQuorumSig(
                address(masterSetupParams.settlement),
                masterSetupParams.settlement.getLastCommittedHeaderEpoch(),
                abi.encode(messageHash),
                KEY_TYPE_BLS_BN254.getKeyTag(15),
                Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
                fullProof
            )
        );
    }

    function test_Revert_InvalidNonSignersOrder() public {
        bytes32 messageHash = 0x204e0c470c62e2f8426b236c004b581084dd3aaa935ed3afe24dc37e0d040823;

        BN254.G2Point memory aggKeyG2;
        BN254.G1Point memory aggSigG1;

        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            BN254.G2Point memory keyG2 = getG2Key(getOperator(i).privateKey);
            BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
            BN254.G1Point memory sigG1 = messageG1.scalar_mul(getOperator(i).privateKey);

            if (i % 6 != 0) {
                aggSigG1 = aggSigG1.plus(sigG1);

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
        }

        ValidatorData[] memory validatorsData = getValidatorsData();
        uint256[] memory nonSigners = new uint256[](validatorsData.length);
        uint256 nonSignersLength;
        for (uint256 i; i < validatorsData.length; ++i) {
            if (i % 6 == 0) {
                nonSigners[nonSignersLength++] = i;
            }
        }
        assembly ("memory-safe") {
            mstore(nonSigners, nonSignersLength)
        }

        (nonSigners[0], nonSigners[1]) = (nonSigners[1], nonSigners[0]);

        bytes memory fullProof = abi.encodePacked(
            abi.encode(aggSigG1),
            abi.encode(aggKeyG2),
            Bytes.slice(abi.encode(validatorsData), 32),
            abi.encodePacked(nonSigners)
        );

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }

        address sigVerifier = masterSetupParams.settlement.getSigVerifier();
        uint48 epoch = masterSetupParams.settlement.getLastCommittedHeaderEpoch();
        vm.expectRevert(ISigVerifierBlsBn254Simple.SigVerifierBlsBn254Simple_InvalidNonSignersOrder.selector);
        ISigVerifier(sigVerifier).verifyQuorumSig(
            address(masterSetupParams.settlement),
            epoch,
            abi.encode(messageHash),
            KEY_TYPE_BLS_BN254.getKeyTag(15),
            Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
            fullProof
        );
    }

    function test_FalseQuorumThreshold() public {
        bytes32 messageHash = 0x204e0c470c62e2f8426b236c004b581084dd3aaa935ed3afe24dc37e0d040823;

        BN254.G2Point memory aggKeyG2;
        BN254.G1Point memory aggSigG1;

        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            BN254.G2Point memory keyG2 = getG2Key(getOperator(i).privateKey);
            BN254.G1Point memory messageG1 = BN254.hashToG1(messageHash);
            BN254.G1Point memory sigG1 = messageG1.scalar_mul(getOperator(i).privateKey);

            if (i % 3 != 0) {
                aggSigG1 = aggSigG1.plus(sigG1);

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
        }

        ValidatorData[] memory validatorsData = getValidatorsData();
        bytes memory nonSigners = new bytes((validatorsData.length + 2) / 3 * 2);
        for (uint8 i; i < validatorsData.length; ++i) {
            if (i % 3 == 0) {
                assembly ("memory-safe") {
                    mstore(add(add(nonSigners, 32), mul(div(i, 3), 2)), shl(240, i))
                }
            }
        }

        bytes memory fullProof = abi.encodePacked(
            abi.encode(aggSigG1),
            abi.encode(aggKeyG2),
            Bytes.slice(abi.encode(validatorsData), 32),
            abi.encodePacked(nonSigners)
        );

        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }
        uint256 nonSignersPower;
        for (uint256 i; i < nonSigners.length; ++i) {
            uint256 currentNonSignerIndex;
            assembly ("memory-safe") {
                currentNonSignerIndex := mload(shr(240, calldataload(add(add(nonSigners, 32), mul(div(i, 6), 2)))))
            }
            for (uint256 j; j < votingPowers[currentNonSignerIndex].vaults.length; ++j) {
                nonSignersPower += votingPowers[currentNonSignerIndex].vaults[j].value;
            }
        }
        assertFalse(
            ISigVerifier(masterSetupParams.settlement.getSigVerifier()).verifyQuorumSig(
                address(masterSetupParams.settlement),
                masterSetupParams.settlement.getLastCommittedHeaderEpoch(),
                abi.encode(messageHash),
                KEY_TYPE_BLS_BN254.getKeyTag(15),
                Math.mulDiv(2, 1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
                fullProof
            )
        );
    }

    function loadGenesisSimple()
        public
        returns (ISettlement.ValSetHeader memory valSetHeader, ISettlement.ExtraData[] memory extraData)
    {
        IVotingPowerProvider.OperatorVotingPower[] memory votingPowers =
            masterSetupParams.votingPowerProvider.getVotingPowers(new bytes[](0));
        uint256 totalVotingPower;
        for (uint256 i; i < votingPowers.length; ++i) {
            for (uint256 j; j < votingPowers[i].vaults.length; ++j) {
                totalVotingPower += votingPowers[i].vaults[j].value;
            }
        }
        valSetHeader = ISettlement.ValSetHeader({
            version: 1,
            requiredKeyTag: 15,
            epoch: 0,
            captureTimestamp: masterSetupParams.valSetDriver.getEpochStart(0),
            quorumThreshold: uint256(2).mulDiv(1e18, 3, Math.Rounding.Ceil).mulDiv(totalVotingPower, 1e18) + 1,
            totalVotingPower: totalVotingPower,
            validatorsSszMRoot: 0x0000000000000000000000000000000000000000000000000000000000000001,
            previousHeaderHash: 0xd397b3b043d87fcd6fad1291ff0bfd16401c274896d8c63a923727f077b8e0b5
        });

        extraData = new ISettlement.ExtraData[](2);
        SigVerifierBlsBn254Simple sigVerifier = SigVerifierBlsBn254Simple(masterSetupParams.settlement.getSigVerifier());

        {
            ValidatorData[] memory validatorsData = getValidatorsData();
            bytes32 validatorSetHash = keccak256(Bytes.slice(abi.encode(validatorsData), 32));
            extraData[0] = ISettlement.ExtraData({
                key: uint32(1).getKey(15, sigVerifier.VALIDATOR_SET_HASH_KECCAK256_HASH()),
                value: validatorSetHash
            });
        }
        {
            BN254.G1Point memory aggPublicKeyG1Raw;
            for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
                BN254.G1Point memory keyG1 = BN254.generatorG1().scalar_mul(getOperator(i).privateKey);
                aggPublicKeyG1Raw = aggPublicKeyG1Raw.plus(keyG1);
            }
            bytes32 aggPublicKeyG1 = abi.decode(aggPublicKeyG1Raw.wrap().serialize(), (bytes32));

            extraData[1] = ISettlement.ExtraData({
                key: uint32(1).getKey(15, sigVerifier.AGGREGATED_PUBLIC_KEY_G1_HASH()),
                value: aggPublicKeyG1
            });
        }
    }

    struct ValidatorData {
        bytes32 keySerialized;
        uint256 votingPower;
    }

    function getValidatorsData() public returns (ValidatorData[] memory validatorsData) {
        validatorsData = new ValidatorData[](networkSetupParams.OPERATORS_TO_REGISTER);
        for (uint256 i; i < networkSetupParams.OPERATORS_TO_REGISTER; ++i) {
            BN254.G1Point memory keyG1 = BN254.generatorG1().scalar_mul(getOperator(i).privateKey);
            IVotingPowerProvider.VaultValue[] memory votingPowers =
                masterSetupParams.votingPowerProvider.getOperatorVotingPowers(getOperator(i).addr, new bytes(0));
            uint256 operatorVotingPower;
            for (uint256 j; j < votingPowers.length; ++j) {
                operatorVotingPower += votingPowers[j].value;
            }
            validatorsData[i] = ValidatorData({
                keySerialized: abi.decode(keyG1.wrap().serialize(), (bytes32)),
                votingPower: operatorVotingPower
            });
        }
    }
}
