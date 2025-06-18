// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {KeyRegistry} from "../../src/contracts/modules/key-registry/KeyRegistry.sol";

import {IKeyRegistry} from "../../src/interfaces/modules/key-registry/IKeyRegistry.sol";

import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";
import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

import {OzEIP712} from "../../src/contracts/modules/base/OzEIP712.sol";

import {Checkpoints} from "../../src/contracts/libraries/structs/Checkpoints.sol";
import {InputNormalizer} from "../../src/contracts/libraries/utils/InputNormalizer.sol";
import {PersistentSet} from "../../src/contracts/libraries/structs/PersistentSet.sol";

import {KeyTags} from "../../src/contracts/libraries/utils/KeyTags.sol";
import {KeyBlsBn254} from "../../src/contracts/libraries/keys/KeyBlsBn254.sol";
import {KeyEcdsaSecp256k1} from "../../src/contracts/libraries/keys/KeyEcdsaSecp256k1.sol";

import {SigBlsBn254} from "../../src/contracts/libraries/sigs/SigBlsBn254.sol";
import {SigEcdsaSecp256k1} from "../../src/contracts/libraries/sigs/SigEcdsaSecp256k1.sol";

uint8 constant KEY_TYPE_KEY64 = 2;

contract KeyRegistryWithKey64 is KeyRegistry {
    using KeyTags for uint8;
    using KeyTags for uint128;
    using Checkpoints for Checkpoints.Trace208;
    using Checkpoints for Checkpoints.Trace256;
    using Checkpoints for Checkpoints.Trace512;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;
    using KeyEcdsaSecp256k1 for KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1;
    using InputNormalizer for bytes[];
    using InputNormalizer for bytes[][];
    using PersistentSet for PersistentSet.AddressSet;

    function getKeyAt(
        address operator,
        uint8 tag,
        uint48 timestamp,
        bytes memory hint
    ) public view override returns (bytes memory) {
        if (tag.getType() == KEY_TYPE_KEY64) {
            bytes memory key = _getKey64At(operator, tag, timestamp, hint);
            (bytes32 key1, bytes32 key2) = abi.decode(key, (bytes32, bytes32));
            return abi.encode(~key1, ~key2);
        }
        return super.getKeyAt(operator, tag, timestamp, hint);
    }

    function getKey(address operator, uint8 tag) public view override returns (bytes memory) {
        if (tag.getType() == KEY_TYPE_KEY64) {
            bytes memory key = _getKey64(operator, tag);
            (bytes32 key1, bytes32 key2) = abi.decode(key, (bytes32, bytes32));
            return abi.encode(~key1, ~key2);
        }
        return super.getKey(operator, tag);
    }

    function _setKey(address operator, uint8 tag, bytes memory key) internal override {
        if (tag.getType() == KEY_TYPE_KEY64) {
            (bytes32 key1, bytes32 key2) = abi.decode(key, (bytes32, bytes32));
            _setKey64(operator, tag, abi.encode(~key1, ~key2));
            return;
        }
        super._setKey(operator, tag, key);
    }

    function _verifyKey(
        uint8 tag,
        bytes memory key,
        bytes memory signature,
        bytes memory extraData,
        bytes memory message
    ) internal view override returns (bool) {
        if (tag.getType() == KEY_TYPE_KEY64) {
            return true;
        }
        return super._verifyKey(tag, key, signature, extraData, message);
    }
}
