// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./MasterSetup.sol";

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract MasterGenesisSetupTest is MasterSetupTest {
    using Math for uint256;

    struct Genesis {
        ExtraDataStruct[] extraData;
        ValSetHeaderStruct header;
    }

    struct ExtraDataStruct {
        bytes32 key;
        bytes32 value;
    }

    struct ValSetHeaderStruct {
        uint48 captureTimestamp;
        uint48 epoch;
        bytes32 previousHeaderHash;
        uint256 quorumThreshold;
        uint8 requiredKeyTag;
        uint256 totalVotingPower;
        bytes32 validatorsSszMRoot;
        uint8 version;
    }

    function setUp() public virtual override {
        SYMBIOTIC_CORE_PROJECT_ROOT = "lib/core/";
        MasterSetupTest.setUp();

        vm.warp(masterSetupParams.valSetDriver.getEpochStart(0) + 1);

        vm.startBroadcast(vars.deployer.privateKey);
        (ISettlement.ValSetHeader memory valSetHeader, ISettlement.ExtraData[] memory extraData) = loadGenesis();
        valSetHeader.captureTimestamp = masterSetupParams.valSetDriver.getCurrentEpochStart();
        valSetHeader.epoch = masterSetupParams.valSetDriver.getCurrentEpoch();
        valSetHeader.previousHeaderHash = masterSetupParams.settlement.getValSetHeaderHash();
        valSetHeader.requiredKeyTag = masterSetupParams.valSetDriver.getRequiredHeaderKeyTag();
        valSetHeader.version = masterSetupParams.settlement.VALIDATOR_SET_VERSION();

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
        vm.stopBroadcast();
    }

    function loadGenesis()
        public
        returns (ISettlement.ValSetHeader memory valSetHeader, ISettlement.ExtraData[] memory extraData)
    {
        Genesis memory genesis;
        {
            string memory root = vm.projectRoot();
            string memory path = string.concat(root, "/test/data/genesis_header.json");
            string memory json = vm.readFile(path);
            bytes memory data = vm.parseJson(json);
            genesis = abi.decode(data, (Genesis));
        }

        valSetHeader = ISettlement.ValSetHeader({
            version: genesis.header.version,
            requiredKeyTag: genesis.header.requiredKeyTag,
            epoch: genesis.header.epoch,
            captureTimestamp: genesis.header.captureTimestamp,
            quorumThreshold: genesis.header.quorumThreshold,
            totalVotingPower: genesis.header.totalVotingPower,
            validatorsSszMRoot: genesis.header.validatorsSszMRoot,
            previousHeaderHash: genesis.header.previousHeaderHash
        });

        extraData = new ISettlement.ExtraData[](genesis.extraData.length);
        for (uint256 i; i < genesis.extraData.length; ++i) {
            extraData[i] = ISettlement.ExtraData({key: genesis.extraData[i].key, value: genesis.extraData[i].value});
        }
    }
}
