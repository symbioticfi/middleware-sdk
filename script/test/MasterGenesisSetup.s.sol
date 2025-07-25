// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "./MasterSetup.s.sol";

// forge script script/test/MasterGenesisSetup.s.sol:MasterGenesisSetupScript 25235 --sig "run(uint256)" --rpc-url $ETH_RPC_URL_MASTER

contract MasterGenesisSetupScript is MasterSetupScript {
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

    function run(
        uint256 seed
    ) public virtual override {
        SYMBIOTIC_CORE_PROJECT_ROOT = "lib/core/";
        SymbioticInit.run(seed);

        (, Vars memory vars) = loadInitSetupParamsAndVars();
        MasterSetupParams memory masterSetupParams = loadMasterSetupParams();

        vm.startBroadcast(vars.deployer.privateKey);
        (ISettlement.ValSetHeader memory valSetHeader, ISettlement.ExtraData[] memory extraData) = loadGenesis();
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
            string memory path = string.concat(root, "/script/test/data/genesis_header.json");
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
