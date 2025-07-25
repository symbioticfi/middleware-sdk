// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {NetworkManager} from "../base/NetworkManager.sol";
import {OzEIP712} from "../base/OzEIP712.sol";
import {PermissionManager} from "../base/PermissionManager.sol";
import {VotingPowerCalcManager} from "./base/VotingPowerCalcManager.sol";

import {VotingPowerProviderLogic} from "./logic/VotingPowerProviderLogic.sol";

import {IVotingPowerProvider} from "../../interfaces/modules/voting-power/IVotingPowerProvider.sol";

import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import {NoncesUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
 * @title VotingPowerProvider
 * @notice Contract for managing tokens, operators, vaults, and their voting powers.
 */
abstract contract VotingPowerProvider is
    NetworkManager,
    VotingPowerCalcManager,
    OzEIP712,
    PermissionManager,
    NoncesUpgradeable,
    MulticallUpgradeable,
    IVotingPowerProvider
{
    /**
     * @inheritdoc IVotingPowerProvider
     */
    address public immutable OPERATOR_REGISTRY;

    /**
     * @inheritdoc IVotingPowerProvider
     */
    address public immutable VAULT_FACTORY;

    bytes32 private constant REGISTER_OPERATOR_TYPEHASH = keccak256("RegisterOperator(address operator,uint256 nonce)");
    bytes32 private constant UNREGISTER_OPERATOR_TYPEHASH =
        keccak256("UnregisterOperator(address operator,uint256 nonce)");

    constructor(address operatorRegistry, address vaultFactory) {
        OPERATOR_REGISTRY = operatorRegistry;
        VAULT_FACTORY = vaultFactory;
    }

    function __VotingPowerProvider_init(
        VotingPowerProviderInitParams memory votingPowerProviderInitParams
    ) internal virtual onlyInitializing {
        __NetworkManager_init(votingPowerProviderInitParams.networkManagerInitParams);
        VotingPowerProviderLogic.initialize(votingPowerProviderInitParams);
        __OzEIP712_init(votingPowerProviderInitParams.ozEip712InitParams);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getSlashingDataAt(uint48 timestamp, bytes memory hint) public view virtual returns (bool, uint48) {
        return VotingPowerProviderLogic.getSlashingDataAt(timestamp, hint);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getSlashingData() public view virtual returns (bool, uint48) {
        return VotingPowerProviderLogic.getSlashingData();
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function isTokenRegisteredAt(address token, uint48 timestamp) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isTokenRegisteredAt(token, timestamp);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function isTokenRegistered(
        address token
    ) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isTokenRegistered(token);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getTokensAt(
        uint48 timestamp
    ) public view virtual returns (address[] memory) {
        return VotingPowerProviderLogic.getTokensAt(timestamp);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getTokens() public view virtual returns (address[] memory) {
        return VotingPowerProviderLogic.getTokens();
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function isOperatorRegisteredAt(address operator, uint48 timestamp) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isOperatorRegisteredAt(operator, timestamp);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function isOperatorRegistered(
        address operator
    ) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isOperatorRegistered(operator);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperatorsAt(
        uint48 timestamp
    ) public view virtual returns (address[] memory) {
        return VotingPowerProviderLogic.getOperatorsAt(timestamp);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperators() public view virtual returns (address[] memory) {
        return VotingPowerProviderLogic.getOperators();
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function isSharedVaultRegisteredAt(address vault, uint48 timestamp) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isSharedVaultRegisteredAt(vault, timestamp);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function isSharedVaultRegistered(
        address vault
    ) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isSharedVaultRegistered(vault);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getSharedVaultsAt(
        uint48 timestamp
    ) public view virtual returns (address[] memory) {
        return VotingPowerProviderLogic.getSharedVaultsAt(timestamp);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getSharedVaults() public view virtual returns (address[] memory) {
        return VotingPowerProviderLogic.getSharedVaults();
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function isOperatorVaultRegisteredAt(address vault, uint48 timestamp) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isOperatorVaultRegisteredAt(vault, timestamp);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function isOperatorVaultRegistered(
        address vault
    ) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isOperatorVaultRegistered(vault);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function isOperatorVaultRegisteredAt(
        address operator,
        address vault,
        uint48 timestamp
    ) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isOperatorVaultRegisteredAt(operator, vault, timestamp);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function isOperatorVaultRegistered(address operator, address vault) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isOperatorVaultRegistered(operator, vault);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperatorVaultsAt(address operator, uint48 timestamp) public view virtual returns (address[] memory) {
        return VotingPowerProviderLogic.getOperatorVaultsAt(operator, timestamp);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperatorVaults(
        address operator
    ) public view virtual returns (address[] memory) {
        return VotingPowerProviderLogic.getOperatorVaults(operator);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperatorStakesAt(
        address operator,
        uint48 timestamp
    ) public view virtual returns (VaultValue[] memory) {
        return VotingPowerProviderLogic.getOperatorStakesAt(operator, timestamp);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperatorStakes(
        address operator
    ) public view virtual returns (VaultValue[] memory) {
        return VotingPowerProviderLogic.getOperatorStakes(operator);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperatorVotingPowersAt(
        address operator,
        bytes memory extraData,
        uint48 timestamp
    ) public view virtual returns (VaultValue[] memory) {
        return VotingPowerProviderLogic.getOperatorVotingPowersAt(operator, extraData, timestamp);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperatorVotingPowers(
        address operator,
        bytes memory extraData
    ) public view virtual returns (VaultValue[] memory) {
        return VotingPowerProviderLogic.getOperatorVotingPowers(operator, extraData);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getVotingPowersAt(
        bytes[] memory extraData,
        uint48 timestamp
    ) public view virtual returns (OperatorVotingPower[] memory) {
        return VotingPowerProviderLogic.getVotingPowersAt(extraData, timestamp);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getVotingPowers(
        bytes[] memory extraData
    ) public view virtual returns (OperatorVotingPower[] memory) {
        return VotingPowerProviderLogic.getVotingPowers(extraData);
    }

    /**
     * @notice Returns the length of the tokens.
     * @return The length of the tokens.
     */
    function _getTokensLength() internal view virtual returns (uint256) {
        return VotingPowerProviderLogic.getTokensLength();
    }

    /**
     * @notice Returns the length of the operators.
     * @return The length of the operators.
     */
    function _getOperatorsLength() internal view virtual returns (uint256) {
        return VotingPowerProviderLogic.getOperatorsLength();
    }

    /**
     * @notice Returns the length of the shared vaults.
     * @return The length of the shared vaults.
     */
    function _getSharedVaultsLength() internal view virtual returns (uint256) {
        return VotingPowerProviderLogic.getSharedVaultsLength();
    }

    /**
     * @notice Returns the length of the operator vaults.
     * @param operator The operator.
     * @return The length of the operator vaults.
     */
    function _getOperatorVaultsLength(
        address operator
    ) internal view virtual returns (uint256) {
        return VotingPowerProviderLogic.getOperatorVaultsLength(operator);
    }

    /**
     * @notice Returns the stake of the operator at a specific timestamp.
     * @param operator The operator.
     * @param vault The vault.
     * @param timestamp The timestamp.
     * @return The stake of the operator.
     */
    function _getOperatorStakeAt(
        address operator,
        address vault,
        uint48 timestamp
    ) internal view virtual returns (uint256) {
        return VotingPowerProviderLogic.getOperatorStakeAt(operator, vault, timestamp);
    }

    /**
     * @notice Returns the stake of the operator.
     * @param operator The operator.
     * @param vault The vault.
     * @return The stake of the operator.
     */
    function _getOperatorStake(address operator, address vault) internal view virtual returns (uint256) {
        return VotingPowerProviderLogic.getOperatorStake(operator, vault);
    }

    /**
     * @notice Returns the voting power of the operator at a specific timestamp.
     * @param operator The operator.
     * @param vault The vault.
     * @param extraData The extra data.
     * @param timestamp The timestamp.
     * @return The voting power of the operator.
     */
    function _getOperatorVotingPowerAt(
        address operator,
        address vault,
        bytes memory extraData,
        uint48 timestamp
    ) internal view virtual returns (uint256) {
        return VotingPowerProviderLogic.getOperatorVotingPowerAt(operator, vault, extraData, timestamp);
    }

    /**
     * @notice Returns the voting power of the operator.
     * @param operator The operator.
     * @param vault The vault.
     * @param extraData The extra data.
     * @return The voting power of the operator.
     */
    function _getOperatorVotingPower(
        address operator,
        address vault,
        bytes memory extraData
    ) internal view virtual returns (uint256) {
        return VotingPowerProviderLogic.getOperatorVotingPower(operator, vault, extraData);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function registerOperator() public virtual {
        _registerOperatorImpl(msg.sender);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function registerOperatorWithSignature(address operator, bytes memory signature) public virtual {
        _verifyEIP712(
            operator, keccak256(abi.encode(REGISTER_OPERATOR_TYPEHASH, operator, nonces(operator))), signature
        );
        _registerOperatorImpl(operator);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function unregisterOperator() public virtual {
        _unregisterOperatorImpl(msg.sender);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function unregisterOperatorWithSignature(address operator, bytes memory signature) public virtual {
        _verifyEIP712(
            operator, keccak256(abi.encode(UNREGISTER_OPERATOR_TYPEHASH, operator, nonces(operator))), signature
        );
        _unregisterOperatorImpl(operator);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function invalidateOldSignatures() public virtual {
        _useNonce(msg.sender);
    }

    function _setSlashingData(bool requireSlasher, uint48 minVaultEpochDuration) internal virtual {
        VotingPowerProviderLogic.setSlashingData(requireSlasher, minVaultEpochDuration);
    }

    function _registerToken(
        address token
    ) internal virtual {
        VotingPowerProviderLogic.registerToken(token);
    }

    function _unregisterToken(
        address token
    ) internal virtual {
        VotingPowerProviderLogic.unregisterToken(token);
    }

    function _registerOperator(
        address operator
    ) internal virtual {
        VotingPowerProviderLogic.registerOperator(operator);
    }

    function _unregisterOperator(
        address operator
    ) internal virtual {
        VotingPowerProviderLogic.unregisterOperator(operator);
    }

    function _registerSharedVault(
        address vault
    ) internal virtual {
        VotingPowerProviderLogic.registerSharedVault(vault);
    }

    function _registerOperatorVault(address operator, address vault) internal virtual {
        VotingPowerProviderLogic.registerOperatorVault(operator, vault);
    }

    function _unregisterSharedVault(
        address vault
    ) internal virtual {
        VotingPowerProviderLogic.unregisterSharedVault(vault);
    }

    function _unregisterOperatorVault(address operator, address vault) internal virtual {
        VotingPowerProviderLogic.unregisterOperatorVault(operator, vault);
    }

    function _registerOperatorImpl(
        address operator
    ) internal virtual {
        _registerOperator(operator);
        _useNonce(operator);
    }

    function _unregisterOperatorImpl(
        address operator
    ) internal virtual {
        _unregisterOperator(operator);
        _useNonce(operator);
    }

    function _registerOperatorVaultImpl(address operator, address vault) internal virtual {
        _registerOperatorVault(operator, vault);
    }

    function _unregisterOperatorVaultImpl(address operator, address vault) internal virtual {
        _unregisterOperatorVault(operator, vault);
    }

    function _verifyEIP712(address operator, bytes32 structHash, bytes memory signature) internal view {
        if (!SignatureChecker.isValidSignatureNow(operator, hashTypedDataV4(structHash), signature)) {
            revert VotingPowerProvider_InvalidSignature();
        }
    }
}
