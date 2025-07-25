// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {OzEIP712} from "../base/OzEIP712.sol";

import {Checkpoints} from "../../libraries/structs/Checkpoints.sol";
import {KeyBlsBn254} from "../../libraries/keys/KeyBlsBn254.sol";
import {KeyEcdsaSecp256k1} from "../../libraries/keys/KeyEcdsaSecp256k1.sol";
import {KeyTags} from "../../libraries/utils/KeyTags.sol";
import {PersistentSet} from "../../libraries/structs/PersistentSet.sol";
import {SigBlsBn254} from "../../libraries/sigs/SigBlsBn254.sol";
import {SigEcdsaSecp256k1} from "../../libraries/sigs/SigEcdsaSecp256k1.sol";

import {
    IKeyRegistry,
    KEY_TYPE_BLS_BN254,
    KEY_TYPE_ECDSA_SECP256K1
} from "../../interfaces/modules/key-registry/IKeyRegistry.sol";

import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

/**
 * @title KeyRegistry
 * @notice Contract for operators' keys management.
 * @dev It supports:
 *       - BLS public keys on BN254
 *       - ECDSA public keys on secp256k1
 */
contract KeyRegistry is MulticallUpgradeable, OzEIP712, IKeyRegistry {
    using Checkpoints for Checkpoints.Trace208;
    using Checkpoints for Checkpoints.Trace256;
    using Checkpoints for Checkpoints.Trace512;
    using KeyBlsBn254 for KeyBlsBn254.KEY_BLS_BN254;
    using KeyEcdsaSecp256k1 for KeyEcdsaSecp256k1.KEY_ECDSA_SECP256K1;
    using KeyTags for uint8;
    using KeyTags for uint128;
    using PersistentSet for PersistentSet.AddressSet;

    bytes32 internal constant KEY_OWNERSHIP_TYPEHASH = keccak256("KeyOwnership(address operator,bytes key)");

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.KeyRegistry")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant KeyRegistryLocation = 0x79440bf5b0cb104c925971e1cca11d9e1557cbe9fa7533e7b0652d40728ecf00;

    function _getKeyRegistryStorage() internal pure returns (KeyRegistryStorage storage $) {
        assembly {
            $.slot := KeyRegistryLocation
        }
    }

    function __KeyRegistry_init(
        KeyRegistryInitParams memory keyRegistryInitParams
    ) public virtual onlyInitializing {
        __OzEIP712_init(keyRegistryInitParams.ozEip712InitParams);
    }

    /**
     * @inheritdoc IKeyRegistry
     */
    function getKeyAt(address operator, uint8 tag, uint48 timestamp) public view virtual returns (bytes memory) {
        uint8 keyType = tag.getType();
        if (keyType == KEY_TYPE_BLS_BN254) {
            return KeyBlsBn254.deserialize(_getKey32At(operator, tag, timestamp)).toBytes();
        }
        if (keyType == KEY_TYPE_ECDSA_SECP256K1) {
            return KeyEcdsaSecp256k1.deserialize(_getKey32At(operator, tag, timestamp)).toBytes();
        }
        revert IKeyRegistry.KeyRegistry_InvalidKeyType();
    }

    /**
     * @inheritdoc IKeyRegistry
     */
    function getKey(address operator, uint8 tag) public view virtual returns (bytes memory) {
        uint8 keyType = tag.getType();
        if (keyType == KEY_TYPE_BLS_BN254) {
            return KeyBlsBn254.deserialize(_getKey32(operator, tag)).toBytes();
        }
        if (keyType == KEY_TYPE_ECDSA_SECP256K1) {
            return KeyEcdsaSecp256k1.deserialize(_getKey32(operator, tag)).toBytes();
        }
        revert IKeyRegistry.KeyRegistry_InvalidKeyType();
    }

    /**
     * @inheritdoc IKeyRegistry
     */
    function getOperator(
        bytes memory key
    ) public view virtual returns (address) {
        return _getKeyRegistryStorage()._operatorByKeyHash[keccak256(key)];
    }

    /**
     * @inheritdoc IKeyRegistry
     */
    function getKeysAt(address operator, uint48 timestamp) public view virtual returns (Key[] memory keys) {
        uint8[] memory keyTags = _getKeyTagsAt(operator, timestamp);
        keys = new Key[](keyTags.length);
        for (uint256 i; i < keyTags.length; ++i) {
            keys[i] = Key({tag: keyTags[i], payload: getKeyAt(operator, keyTags[i], timestamp)});
        }
    }

    /**
     * @inheritdoc IKeyRegistry
     */
    function getKeys(
        address operator
    ) public view virtual returns (Key[] memory keys) {
        uint8[] memory keyTags = _getKeyTags(operator);
        keys = new Key[](keyTags.length);
        for (uint256 i; i < keyTags.length; ++i) {
            keys[i] = Key({tag: keyTags[i], payload: getKey(operator, keyTags[i])});
        }
    }

    /**
     * @inheritdoc IKeyRegistry
     */
    function getKeysAt(
        uint48 timestamp
    ) public view virtual returns (OperatorWithKeys[] memory operatorsKeys) {
        address[] memory operators = getKeysOperatorsAt(timestamp);
        operatorsKeys = new IKeyRegistry.OperatorWithKeys[](operators.length);
        for (uint256 i; i < operators.length; ++i) {
            operatorsKeys[i].operator = operators[i];
            operatorsKeys[i].keys = getKeysAt(operators[i], timestamp);
        }
    }

    /**
     * @inheritdoc IKeyRegistry
     */
    function getKeys() public view virtual returns (OperatorWithKeys[] memory operatorsKeys) {
        address[] memory operators = getKeysOperators();
        operatorsKeys = new OperatorWithKeys[](operators.length);
        for (uint256 i; i < operators.length; ++i) {
            operatorsKeys[i].operator = operators[i];
            operatorsKeys[i].keys = getKeys(operators[i]);
        }
    }

    /**
     * @inheritdoc IKeyRegistry
     */
    function getKeysOperatorsLength() public view virtual returns (uint256) {
        return _getKeyRegistryStorage()._operators.length();
    }

    /**
     * @inheritdoc IKeyRegistry
     */
    function getKeysOperatorsAt(
        uint48 timestamp
    ) public view virtual returns (address[] memory) {
        return _getKeyRegistryStorage()._operators.valuesAt(timestamp);
    }

    /**
     * @inheritdoc IKeyRegistry
     */
    function getKeysOperators() public view virtual returns (address[] memory) {
        return _getKeyRegistryStorage()._operators.values();
    }

    function _getKeyTagsAt(address operator, uint48 timestamp) internal view virtual returns (uint8[] memory) {
        return uint128(_getKeyRegistryStorage()._operatorKeyTags[operator].upperLookupRecent(timestamp)).deserialize();
    }

    function _getKeyTags(
        address operator
    ) internal view virtual returns (uint8[] memory) {
        return uint128(_getKeyRegistryStorage()._operatorKeyTags[operator].latest()).deserialize();
    }

    /**
     * @inheritdoc IKeyRegistry
     */
    function setKey(uint8 tag, bytes memory key, bytes memory signature, bytes memory extraData) public virtual {
        _setKey(msg.sender, tag, key, signature, extraData);
    }

    function _setKey(
        address operator,
        uint8 tag,
        bytes memory key,
        bytes memory signature,
        bytes memory extraData
    ) internal virtual {
        IKeyRegistry.KeyRegistryStorage storage $ = _getKeyRegistryStorage();

        bytes32 keyHash = keccak256(key);
        if (
            !_verifyKey(
                tag,
                key,
                signature,
                extraData,
                abi.encode(hashTypedDataV4(keccak256(abi.encode(KEY_OWNERSHIP_TYPEHASH, operator, keyHash))))
            )
        ) {
            revert IKeyRegistry.KeyRegistry_InvalidKeySignature();
        }

        // Disallow usage between different operators
        // Disallow usage of the same key on the same type on different tags
        // Allow usage of the old key on the same type and tag
        uint8 type_ = tag.getType();
        address operatorByCompressedKey = $._operatorByKeyHash[keyHash];
        if (operatorByCompressedKey != address(0)) {
            if (operatorByCompressedKey != operator) {
                revert IKeyRegistry.KeyRegistry_AlreadyUsed();
            }
            if (
                $._operatorByTypeAndKeyHash[type_][keyHash] != address(0)
                    && $._operatorByTagAndKeyHash[tag][keyHash] == address(0)
            ) {
                revert IKeyRegistry.KeyRegistry_AlreadyUsed();
            }
        }

        $._operatorByKeyHash[keyHash] = operator;
        $._operatorByTypeAndKeyHash[type_][keyHash] = operator;
        $._operatorByTagAndKeyHash[tag][keyHash] = operator;

        $._operators.add(uint48(block.timestamp), operator);
        $._operatorKeyTags[operator].push(
            uint48(block.timestamp), uint128($._operatorKeyTags[operator].latest()).add(tag)
        );
        _setKey(operator, tag, key);

        emit IKeyRegistry.SetKey(operator, tag, key, extraData);
    }

    function _setKey(address operator, uint8 tag, bytes memory key) internal virtual {
        uint8 type_ = tag.getType();
        if (type_ == KEY_TYPE_BLS_BN254) {
            _setKey32(operator, tag, KeyBlsBn254.fromBytes(key).serialize());
            return;
        }
        if (type_ == KEY_TYPE_ECDSA_SECP256K1) {
            _setKey32(operator, tag, KeyEcdsaSecp256k1.fromBytes(key).serialize());
            return;
        }
        revert IKeyRegistry.KeyRegistry_InvalidKeyType();
    }

    function _setKey32(address operator, uint8 tag, bytes memory key) internal {
        bytes32 compressedKey = abi.decode(key, (bytes32));
        _getKeyRegistryStorage()._keys32[operator][tag].push(uint48(block.timestamp), uint256(compressedKey));
    }

    function _setKey64(address operator, uint8 tag, bytes memory key) internal {
        (bytes32 compressedKey1, bytes32 compressedKey2) = abi.decode(key, (bytes32, bytes32));
        _getKeyRegistryStorage()._keys64[operator][tag].push(
            uint48(block.timestamp), [uint256(compressedKey1), uint256(compressedKey2)]
        );
    }

    function _verifyKey(
        uint8 tag,
        bytes memory key,
        bytes memory signature,
        bytes memory extraData,
        bytes memory message
    ) internal view virtual returns (bool) {
        uint8 type_ = tag.getType();
        if (type_ == KEY_TYPE_BLS_BN254) {
            return SigBlsBn254.verify(key, message, signature, extraData);
        }
        if (type_ == KEY_TYPE_ECDSA_SECP256K1) {
            return SigEcdsaSecp256k1.verify(key, message, signature, extraData);
        }
        revert IKeyRegistry.KeyRegistry_InvalidKeyType();
    }

    function _getKey32At(address operator, uint8 tag, uint48 timestamp) internal view returns (bytes memory) {
        uint256 compressedKey = _getKeyRegistryStorage()._keys32[operator][tag].upperLookupRecent(timestamp);
        return abi.encode(compressedKey);
    }

    function _getKey32(address operator, uint8 tag) internal view returns (bytes memory) {
        uint256 compressedKey = _getKeyRegistryStorage()._keys32[operator][tag].latest();
        return abi.encode(compressedKey);
    }

    function _getKey64At(address operator, uint8 tag, uint48 timestamp) internal view returns (bytes memory) {
        uint256[2] memory compressedKeys = _getKeyRegistryStorage()._keys64[operator][tag].upperLookupRecent(timestamp);
        return abi.encode(compressedKeys[0], compressedKeys[1]);
    }

    function _getKey64(address operator, uint8 tag) internal view returns (bytes memory) {
        uint256[2] memory compressedKeys = _getKeyRegistryStorage()._keys64[operator][tag].latest();
        return abi.encode(compressedKeys[0], compressedKeys[1]);
    }
}
