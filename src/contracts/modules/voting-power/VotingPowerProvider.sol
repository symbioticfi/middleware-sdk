// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {PermissionManager} from "../base/PermissionManager.sol";
import {OzEIP712} from "../base/OzEIP712.sol";

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import {IVotingPowerProvider} from "../../../interfaces/modules/voting-power/IVotingPowerProvider.sol";

import {NoncesUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

import {NetworkManager} from "../base/NetworkManager.sol";

import {VotingPowerCalcManager} from "./base/VotingPowerCalcManager.sol";

import {VotingPowerProviderLogic} from "./logic/VotingPowerProviderLogic.sol";

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
    function isTokenRegisteredAt(
        address token,
        uint48 timestamp,
        bytes memory hint
    ) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isTokenRegisteredAt(token, timestamp, hint);
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
    function getTokensLength() public view virtual returns (uint256) {
        return VotingPowerProviderLogic.getTokensLength();
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function isOperatorRegisteredAt(
        address operator,
        uint48 timestamp,
        bytes memory hint
    ) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isOperatorRegisteredAt(operator, timestamp, hint);
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
    function getOperatorsLength() public view virtual returns (uint256) {
        return VotingPowerProviderLogic.getOperatorsLength();
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function isSharedVaultRegisteredAt(
        address vault,
        uint48 timestamp,
        bytes memory hint
    ) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isSharedVaultRegisteredAt(vault, timestamp, hint);
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
    function getSharedVaultsLength() public view virtual returns (uint256) {
        return VotingPowerProviderLogic.getSharedVaultsLength();
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function isOperatorVaultRegisteredAt(
        address vault,
        uint48 timestamp,
        bytes memory hint
    ) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isOperatorVaultRegisteredAt(vault, timestamp, hint);
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
        uint48 timestamp,
        bytes memory hint
    ) public view virtual returns (bool) {
        return VotingPowerProviderLogic.isOperatorVaultRegisteredAt(operator, vault, timestamp, hint);
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
    function getOperatorVaultsLength(
        address operator
    ) public view virtual returns (uint256) {
        return VotingPowerProviderLogic.getOperatorVaultsLength(operator);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperatorStakeAt(
        address vault,
        address operator,
        uint48 timestamp,
        bytes memory hints
    ) public view virtual returns (uint256) {
        return VotingPowerProviderLogic.getOperatorStakeAt(vault, operator, timestamp, hints);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperatorStake(address vault, address operator) public view virtual returns (uint256) {
        return VotingPowerProviderLogic.getOperatorStake(vault, operator);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperatorVotingPowerAt(
        address operator,
        address vault,
        bytes memory extraData,
        uint48 timestamp,
        bytes memory hints
    ) public view virtual returns (uint256) {
        return VotingPowerProviderLogic.getOperatorVotingPowerAt(operator, vault, extraData, timestamp, hints);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperatorVotingPower(
        address operator,
        address vault,
        bytes memory extraData
    ) public view virtual returns (uint256) {
        return VotingPowerProviderLogic.getOperatorVotingPower(operator, vault, extraData);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperatorVotingPowersAt(
        address operator,
        bytes memory extraData,
        uint48 timestamp
    ) public view virtual returns (VaultVotingPower[] memory) {
        return VotingPowerProviderLogic.getOperatorVotingPowersAt(operator, extraData, timestamp);
    }

    /**
     * @inheritdoc IVotingPowerProvider
     */
    function getOperatorVotingPowers(
        address operator,
        bytes memory extraData
    ) public view virtual returns (VaultVotingPower[] memory) {
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
