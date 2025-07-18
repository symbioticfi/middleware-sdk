// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IOzEIP712} from "../../modules/base/IOzEIP712.sol";

import {Checkpoints} from "../../../libraries/structs/Checkpoints.sol";
import {PersistentSet} from "../../../libraries/structs/PersistentSet.sol";

uint8 constant KEY_TYPE_BLS_BN254 = 0;
uint8 constant KEY_TYPE_ECDSA_SECP256K1 = 1;

interface IKeyRegistry {
    /**
     * @notice Reverts when the key is already used by another operator or with another tag.
     */
    error KeyRegistry_AlreadyUsed();

    /**
     * @notice Reverts when the key ownership signature is invalid.
     */
    error KeyRegistry_InvalidKeySignature();

    /**
     * @notice Reverts when the key type is not supported.
     */
    error KeyRegistry_InvalidKeyType();

    /**
     * @notice The storage of the KeyRegistry contract.
     * @param _keys32 The mapping from the operator and the key tag to the 32 bytes key.
     * @param _keys64 The mapping from the operator and the key tag to the 64 bytes key.
     * @param _operatorByKeyHash The mapping from the key hash to the operator.
     * @param _operatorByTypeAndKeyHash The mapping from the key type and the key hash to the operator.
     * @param _operatorByTagAndKeyHash The mapping from the key type and the key hash to the operator.
     * @param _operators The set of operators with registered keys.
     * @param _operatorKeyTags The mapping from the operator to the registered key tags.
     * @custom:storage-location erc7201:symbiotic.storage.KeyRegistry
     */
    struct KeyRegistryStorage {
        mapping(address operator => mapping(uint8 keyTag => Checkpoints.Trace256 trace)) _keys32;
        mapping(address operator => mapping(uint8 keyTag => Checkpoints.Trace512 trace)) _keys64;
        mapping(bytes32 keyHash => address operator) _operatorByKeyHash;
        mapping(uint8 keyType => mapping(bytes32 keyHash => address operator)) _operatorByTypeAndKeyHash;
        mapping(uint8 keyTag => mapping(bytes32 keyHash => address operator)) _operatorByTagAndKeyHash;
        PersistentSet.AddressSet _operators;
        mapping(address operator => Checkpoints.Trace208 trace) _operatorKeyTags;
    }

    /**
     * @notice The parameters for the initialization of the KeyRegistry contract.
     * @param ozEip712InitParams The parameters for the initialization of the OzEIP712 contract.
     */
    struct KeyRegistryInitParams {
        IOzEIP712.OzEIP712InitParams ozEip712InitParams;
    }

    /**
     * @notice The key with the tag and the payload.
     * @param tag The tag of the key.
     * @param payload The payload of the key.
     */
    struct Key {
        uint8 tag;
        bytes payload;
    }

    /**
     * @notice The operator with the keys.
     * @param operator The address of the operator.
     * @param keys The operator's keys.
     */
    struct OperatorWithKeys {
        address operator;
        Key[] keys;
    }

    /**
     * @notice Emitted when the key is set.
     * @param operator The address of the operator.
     * @param tag The tag of the key.
     * @param key The payload of the key.
     * @param extraData The extra data of the key (e.g., the G2 key for BLS keys).
     */
    event SetKey(address indexed operator, uint8 indexed tag, bytes indexed key, bytes extraData);

    /**
     * @notice Returns the operator's keys at a specific timestamp.
     * @param operator The address of the operator.
     * @param timestamp The timestamp.
     * @return The operator's keys.
     */
    function getKeysAt(address operator, uint48 timestamp) external view returns (Key[] memory);

    /**
     * @notice Returns the current operator's keys.
     * @param operator The address of the operator.
     * @return The operator's keys.
     */
    function getKeys(
        address operator
    ) external view returns (Key[] memory);

    /**
     * @notice Returns the key at a specific timestamp.
     * @param operator The address of the operator.
     * @param tag The tag of the key.
     * @param timestamp The timestamp.
     * @return The key.
     * @dev Will return a zero key if the key is not found (e.g., abi.encode(address(0)) for ECDSA keys).
     */
    function getKeyAt(address operator, uint8 tag, uint48 timestamp) external view returns (bytes memory);

    /**
     * @notice Returns the current key.
     * @param operator The address of the operator.
     * @param tag The tag of the key.
     * @return The key.
     * @dev Will return a zero key if the key is not found (e.g., abi.encode(address(0)) for ECDSA keys).
     */
    function getKey(address operator, uint8 tag) external view returns (bytes memory);

    /**
     * @notice Returns the operator by the key.
     * @param key The key.
     * @return The operator.
     */
    function getOperator(
        bytes memory key
    ) external view returns (address);

    /**
     * @notice Returns the operators with their keys at a specific timestamp.
     * @param timestamp The timestamp.
     * @return The operators with their keys.
     * @dev Different operators may have different numbers of keys and their tags.
     */
    function getKeysAt(
        uint48 timestamp
    ) external view returns (OperatorWithKeys[] memory);

    /**
     * @notice Returns the current operators with their keys.
     * @return The operators with their keys.
     * @dev Different operators may have different numbers of keys and their tags.
     */
    function getKeys() external view returns (OperatorWithKeys[] memory);

    /**
     * @notice Returns the number of the operators who registered any keys.
     * @return The number of the operators who registered any keys.
     */
    function getKeysOperatorsLength() external view returns (uint256);

    /**
     * @notice Returns the operators who registered any keys until a specific timestamp.
     * @param timestamp The timestamp.
     * @return The operators who registered any keys until a specific timestamp.
     */
    function getKeysOperatorsAt(
        uint48 timestamp
    ) external view returns (address[] memory);

    /**
     * @notice Returns the operators who registered any keys.
     * @return The operators who registered any keys.
     */
    function getKeysOperators() external view returns (address[] memory);

    /**
     * @notice Sets a key for a caller.
     * @param tag The tag of the key.
     * @param key The payload of the key.
     * @param signature The signature to verify the key ownership.
     * @param extraData The extra data of the key (e.g., the G2 key for BLS keys).
     */
    function setKey(uint8 tag, bytes memory key, bytes memory signature, bytes memory extraData) external;
}
