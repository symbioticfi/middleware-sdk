// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {INetworkManager} from "../base/INetworkManager.sol";
import {IOzEIP712} from "../base/IOzEIP712.sol";
import {Checkpoints} from "../../../contracts/libraries/structs/Checkpoints.sol";

import {PersistentSet} from "../../../contracts/libraries/structs/PersistentSet.sol";

interface IVotingPowerProvider {
    /**
     * @notice The error thrown when the signature is invalid.
     */
    error VotingPowerProvider_InvalidSignature();

    /**
     * @notice The error thrown when the shared vault is invalid.
     */
    error VotingPowerProvider_InvalidSharedVault();

    /**
     * @notice The error thrown when the vault is invalid.
     */
    error VotingPowerProvider_InvalidVault();

    /**
     * @notice The error thrown when the operator vault is invalid.
     */
    error VotingPowerProvider_InvalidOperatorVault();

    /**
     * @notice The error thrown when the shared vault is already registered.
     */
    error VotingPowerProvider_SharedVaultAlreadyIsRegistered();

    /**
     * @notice The error thrown when the operator vault is already registered.
     */
    error VotingPowerProvider_OperatorVaultAlreadyIsRegistered();

    /**
     * @notice The error thrown when the token is already registered.
     */
    error VotingPowerProvider_TokenAlreadyIsRegistered();

    /**
     * @notice The error thrown when the token is not registered.
     */
    error VotingPowerProvider_TokenNotRegistered();

    /**
     * @notice The error thrown when the operator is not registered.
     */
    error VotingPowerProvider_OperatorNotRegistered();

    /**
     * @notice The error thrown when the shared vault is not registered.
     */
    error VotingPowerProvider_SharedVaultNotRegistered();

    /**
     * @notice The error thrown when the operator vault is not registered.
     */
    error VotingPowerProvider_OperatorVaultNotRegistered();

    /**
     * @notice The error thrown when the token is zero address.
     */
    error VotingPowerProvider_InvalidToken();

    /**
     * @notice The error thrown when the slashing window is greater than the current one.
     */
    error VotingPowerProvider_SlashingWindowTooLarge();

    /**
     * @notice The error thrown when the operator is not registered in the OperatorRegistry.
     */
    error VotingPowerProvider_InvalidOperator();

    /**
     * @notice The error thrown when the operator is already registered.
     */
    error VotingPowerProvider_OperatorAlreadyRegistered();

    /**
     * @notice The types of the delegator.
     */
    enum DelegatorType {
        NETWORK_RESTAKE,
        FULL_RESTAKE,
        OPERATOR_SPECIFIC,
        OPERATOR_NETWORK_SPECIFIC
    }

    /**
     * @notice The types of the slasher.
     */
    enum SlasherType {
        INSTANT,
        VETO
    }

    /**
     * @notice The storage of the VotingPowerProvider contract.
     * @param _tokens The set of the tokens.
     * @param _operators The set of the operators.
     * @param _sharedVaults The set of the shared vaults.
     * @param _allOperatorVaults The set of the all operator vaults.
     * @param _operatorVaults The mapping from the operator to the set of the operator vaults.
     * @param _slashingWindow The slashing window.
     * @custom:storage-location erc7201:symbiotic.storage.VotingPowerProvider
     */
    struct VotingPowerProviderStorage {
        PersistentSet.AddressSet _tokens;
        PersistentSet.AddressSet _operators;
        PersistentSet.AddressSet _sharedVaults;
        PersistentSet.AddressSet _allOperatorVaults;
        mapping(address operator => PersistentSet.AddressSet set) _operatorVaults;
        Checkpoints.Trace208 _slashingWindow;
    }

    /**
     * @notice The parameters for the initialization of the VotingPowerProvider contract.
     * @param networkManagerInitParams The parameters for the initialization of the NetworkManager contract.
     * @param ozEip712InitParams The parameters for the initialization of the OzEIP712 contract.
     * @param slashingWindow The slashing window.
     * @param token The acceptable token (zero address if not applicable).
     */
    struct VotingPowerProviderInitParams {
        INetworkManager.NetworkManagerInitParams networkManagerInitParams;
        IOzEIP712.OzEIP712InitParams ozEip712InitParams;
        uint48 slashingWindow;
        address token;
    }

    /**
     * @notice The value of the vault.
     * @param vault The address of the vault.
     * @param value The value (voting power or stake).
     */
    struct VaultValue {
        address vault;
        uint256 value;
    }

    /**
     * @notice The voting power of the operator.
     * @param operator The address of the operator.
     * @param vaults The voting power of the operator for each vault.
     */
    struct OperatorVotingPower {
        address operator;
        VaultValue[] vaults;
    }

    /**
     * @notice The extra data for the voting power of the operator.
     * @param sharedVaultsExtraData The extra data for the shared vaults.
     * @param operatorVaultsExtraData The extra data for the operator vaults.
     */
    struct OperatorVotingPowersExtraData {
        bytes[] sharedVaultsExtraData;
        bytes[] operatorVaultsExtraData;
    }

    /**
     * @notice Emitted when the slashing window is set.
     * @param slashingWindow The slashing window.
     */
    event SetSlashingWindow(uint48 slashingWindow);

    /**
     * @notice Emitted when the token is registered.
     */
    event RegisterToken(address indexed token);

    /**
     * @notice Emitted when the token is unregistered.
     * @param token The token.
     */
    event UnregisterToken(address indexed token);

    /**
     * @notice Emitted when the operator is registered.
     * @param operator The operator.
     */
    event RegisterOperator(address indexed operator);

    /**
     * @notice Emitted when the operator is unregistered.
     * @param operator The operator.
     */
    event UnregisterOperator(address indexed operator);

    /**
     * @notice Emitted when the shared vault is registered.
     * @param vault The shared vault.
     */
    event RegisterSharedVault(address indexed vault);

    /**
     * @notice Emitted when the shared vault is unregistered.
     * @param vault The shared vault.
     */
    event UnregisterSharedVault(address indexed vault);

    /**
     * @notice Emitted when the operator vault is registered.
     * @param operator The operator.
     * @param vault The operator vault.
     */
    event RegisterOperatorVault(address indexed operator, address indexed vault);

    /**
     * @notice Emitted when the operator vault is unregistered.
     * @param operator The operator.
     * @param vault The operator vault.
     */
    event UnregisterOperatorVault(address indexed operator, address indexed vault);

    /**
     * @notice Returns the address of the OperatorRegistry contract.
     * @return The address of the OperatorRegistry contract.
     */
    function OPERATOR_REGISTRY() external view returns (address);

    /**
     * @notice Returns the address of the VaultFactory contract.
     * @return The address of the VaultFactory contract.
     */
    function VAULT_FACTORY() external view returns (address);

    /**
     * @notice Returns the slashing window at a specific timestamp.
     * @param timestamp The timestamp.
     * @param hint The hint.
     * @return The slashing window.
     */
    function getSlashingWindowAt(uint48 timestamp, bytes memory hint) external view returns (uint48);

    /**
     * @notice Returns the slashing window.
     * @return The slashing window.
     */
    function getSlashingWindow() external view returns (uint48);

    /**
     * @notice Returns the status of the token registration at a specific timestamp.
     * @param token The token.
     * @param timestamp The timestamp.
     * @return The status of the token registration.
     */
    function isTokenRegisteredAt(address token, uint48 timestamp) external view returns (bool);

    /**
     * @notice Returns the status of the token registration.
     * @param token The token.
     * @return The status of the token registration.
     */
    function isTokenRegistered(
        address token
    ) external view returns (bool);

    /**
     * @notice Returns the tokens at a specific timestamp.
     * @param timestamp The timestamp.
     * @return The tokens.
     */
    function getTokensAt(
        uint48 timestamp
    ) external view returns (address[] memory);

    /**
     * @notice Returns the tokens.
     * @return The tokens.
     */
    function getTokens() external view returns (address[] memory);

    /**
     * @notice Returns the status of the operator registration.
     * @param operator The operator.
     * @return The status of the operator registration.
     */
    function isOperatorRegistered(
        address operator
    ) external view returns (bool);

    /**
     * @notice Returns the status of the operator registration at a specific timestamp.
     * @param operator The operator.
     * @param timestamp The timestamp.
     * @return The status of the operator registration.
     */
    function isOperatorRegisteredAt(address operator, uint48 timestamp) external view returns (bool);

    /**
     * @notice Returns the operators at a specific timestamp.
     * @param timestamp The timestamp.
     * @return The operators.
     */
    function getOperatorsAt(
        uint48 timestamp
    ) external view returns (address[] memory);

    /**
     * @notice Returns the operators.
     * @return The operators.
     */
    function getOperators() external view returns (address[] memory);

    /**
     * @notice Returns the status of the shared vault registration.
     * @param vault The shared vault.
     * @return The status of the shared vault registration.
     */
    function isSharedVaultRegistered(
        address vault
    ) external view returns (bool);

    /**
     * @notice Returns the status of the shared vault registration at a specific timestamp.
     * @param vault The shared vault.
     * @param timestamp The timestamp.
     * @return The status of the shared vault registration.
     */
    function isSharedVaultRegisteredAt(address vault, uint48 timestamp) external view returns (bool);

    /**
     * @notice Returns the shared vaults at a specific timestamp.
     * @param timestamp The timestamp.
     * @return The shared vaults.
     */
    function getSharedVaultsAt(
        uint48 timestamp
    ) external view returns (address[] memory);

    /**
     * @notice Returns the shared vaults.
     * @return The shared vaults.
     */
    function getSharedVaults() external view returns (address[] memory);

    /**
     * @notice Returns the status of the operator vault registration.
     * @param vault The operator vault.
     * @return The status of the operator vault registration.
     */
    function isOperatorVaultRegisteredAt(address vault, uint48 timestamp) external view returns (bool);

    /**
     * @notice Returns the status of the operator vault registration.
     * @param vault The operator vault.
     * @return The status of the operator vault registration.
     */
    function isOperatorVaultRegistered(
        address vault
    ) external view returns (bool);

    /**
     * @notice Returns the status of the operator vault registration at a specific timestamp.
     * @param operator The operator.
     * @param vault The operator vault.
     * @param timestamp The timestamp.
     * @return The status of the operator vault registration.
     */
    function isOperatorVaultRegisteredAt(
        address operator,
        address vault,
        uint48 timestamp
    ) external view returns (bool);

    /**
     * @notice Returns the status of the operator vault registration.
     * @param operator The operator.
     * @param vault The operator vault.
     * @return The status of the operator vault registration.
     */
    function isOperatorVaultRegistered(address operator, address vault) external view returns (bool);

    /**
     * @notice Returns the operator vaults at a specific timestamp.
     * @param operator The operator.
     * @param timestamp The timestamp.
     * @return The operator vaults.
     */
    function getOperatorVaultsAt(address operator, uint48 timestamp) external view returns (address[] memory);

    /**
     * @notice Returns the operator vaults.
     * @param operator The operator.
     * @return The operator vaults.
     */
    function getOperatorVaults(
        address operator
    ) external view returns (address[] memory);

    /**
     * @notice Returns the vaults with stakes of the operator at a specific timestamp.
     * @param operator The operator.
     * @param timestamp The timestamp.
     * @return The vaults with stakes of the operator.
     */
    function getOperatorStakesAt(address operator, uint48 timestamp) external view returns (VaultValue[] memory);

    /**
     * @notice Returns the vaults with stakes of the operator.
     * @param operator The operator.
     * @return The vaults with stakes of the operator.
     */
    function getOperatorStakes(
        address operator
    ) external view returns (VaultValue[] memory);

    /**
     * @notice Returns the vaults with voting powers of the operator at a specific timestamp.
     * @param operator The operator.
     * @param extraData The extra data.
     * @param timestamp The timestamp.
     * @return The vaults with voting powers of the operator.
     */
    function getOperatorVotingPowersAt(
        address operator,
        bytes memory extraData,
        uint48 timestamp
    ) external view returns (VaultValue[] memory);

    /**
     * @notice Returns the vaults with voting powers of the operator.
     * @param operator The operator.
     * @param extraData The extra data.
     * @return The vaults with voting powers of the operator.
     */
    function getOperatorVotingPowers(
        address operator,
        bytes memory extraData
    ) external view returns (VaultValue[] memory);

    /**
     * @notice Returns operators and their vaults with voting powers at a specific timestamp.
     * @param extraData The extra data.
     * @param timestamp The timestamp.
     * @return The operators and their vaults with voting powers.
     */
    function getVotingPowersAt(
        bytes[] memory extraData,
        uint48 timestamp
    ) external view returns (OperatorVotingPower[] memory);

    /**
     * @notice Returns operators and their vaults with voting powers.
     * @param extraData The extra data.
     * @return The operators and their vaults with voting powers.
     */
    function getVotingPowers(
        bytes[] memory extraData
    ) external view returns (OperatorVotingPower[] memory);

    /**
     * @notice Registers the caller as an operator.
     * @dev The caller can be anyone.
     */
    function registerOperator() external;

    /**
     * @notice Registers the operator with a signature.
     * @param operator The operator.
     * @param signature The signature of the operator.
     * @dev The caller can be anyone.
     */
    function registerOperatorWithSignature(address operator, bytes memory signature) external;

    /**
     * @notice Unregisters the operator.
     * @dev The caller can be anyone.
     */
    function unregisterOperator() external;

    /**
     * @notice Unregisters the operator with a signature.
     * @param operator The operator.
     * @param signature The signature of the operator.
     * @dev The caller can be anyone.
     */
    function unregisterOperatorWithSignature(address operator, bytes memory signature) external;

    /**
     * @notice Invalidates the old signatures of the caller.
     * @dev The caller can be anyone.
     *      Increases the signatures' nonce by one.
     */
    function invalidateOldSignatures() external;
}
