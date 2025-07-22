// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IVault} from "@symbioticfi/core/src/interfaces/vault/IVault.sol";
import {IBaseDelegator} from "@symbioticfi/core/src/interfaces/delegator/IBaseDelegator.sol";
import {IRegistry} from "@symbioticfi/core/src/interfaces/common/IRegistry.sol";
import {IEntity} from "@symbioticfi/core/src/interfaces/common/IEntity.sol";
import {IVetoSlasher} from "@symbioticfi/core/src/interfaces/slasher/IVetoSlasher.sol";
import {Subnetwork} from "@symbioticfi/core/src/contracts/libraries/Subnetwork.sol";
import {ISlasher} from "@symbioticfi/core/src/interfaces/slasher/ISlasher.sol";
import {IOperatorSpecificDelegator} from "@symbioticfi/core/src/interfaces/delegator/IOperatorSpecificDelegator.sol";
import {IOperatorNetworkSpecificDelegator} from
    "@symbioticfi/core/src/interfaces/delegator/IOperatorNetworkSpecificDelegator.sol";

import {IStakerRewards} from "@symbioticfi/rewards/src/interfaces/stakerRewards/IStakerRewards.sol";
import {IDefaultOperatorRewards} from
    "@symbioticfi/rewards/src/interfaces/defaultOperatorRewards/IDefaultOperatorRewards.sol";

import {EnumerableMap} from "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Time} from "@openzeppelin/contracts/utils/types/Time.sol";

import {Checkpoints} from "../../../libraries/structs/Checkpoints.sol";
import {PersistentSet} from "../../../libraries/structs/PersistentSet.sol";
import {InputNormalizer} from "../../../libraries/utils/InputNormalizer.sol";

import {IVotingPowerProvider} from "../../../../interfaces/modules/voting-power/IVotingPowerProvider.sol";
import {IVotingPowerCalcManager} from "../../../../interfaces/modules/voting-power/base/IVotingPowerCalcManager.sol";
import {INetworkManager} from "../../../../interfaces/modules/base/INetworkManager.sol";

library VotingPowerProviderLogic {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    using EnumerableMap for EnumerableMap.AddressToAddressMap;
    using EnumerableSet for EnumerableSet.AddressSet;
    using Subnetwork for address;
    using Subnetwork for bytes32;
    using Checkpoints for Checkpoints.Trace208;
    using PersistentSet for PersistentSet.AddressSet;
    using InputNormalizer for bytes[];

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.VotingPowerProvider")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant VotingPowerProviderStorageLocation =
        0x3671387af6738df83002b4d17260f89ef208ae15fe22fab69d817f0195c74800;

    function _getVotingPowerProviderStorage()
        internal
        pure
        returns (IVotingPowerProvider.VotingPowerProviderStorage storage $)
    {
        assembly {
            $.slot := VotingPowerProviderStorageLocation
        }
    }

    function initialize(
        IVotingPowerProvider.VotingPowerProviderInitParams memory initParams
    ) public {
        setSlashingData(initParams.requireSlasher, initParams.minVaultEpochDuration);
        if (initParams.token != address(0)) {
            registerToken(initParams.token);
        }
    }

    function getSlashingDataAt(uint48 timestamp, bytes memory hint) public view returns (bool, uint48) {
        return
            deserializeSlashingData(_getVotingPowerProviderStorage()._slashingData.upperLookupRecent(timestamp, hint));
    }

    function getSlashingData() public view returns (bool, uint48) {
        return deserializeSlashingData(_getVotingPowerProviderStorage()._slashingData.latest());
    }

    function isTokenRegisteredAt(address token, uint48 timestamp, bytes memory hint) public view returns (bool) {
        return _getVotingPowerProviderStorage()._tokens.containsAt(timestamp, token, hint);
    }

    function isTokenRegistered(
        address token
    ) public view returns (bool) {
        return _getVotingPowerProviderStorage()._tokens.contains(token);
    }

    function getTokensAt(
        uint48 timestamp
    ) public view returns (address[] memory) {
        return _getVotingPowerProviderStorage()._tokens.valuesAt(timestamp);
    }

    function getTokens() public view returns (address[] memory) {
        return _getVotingPowerProviderStorage()._tokens.values();
    }

    function getTokensLength() public view returns (uint256) {
        return _getVotingPowerProviderStorage()._tokens.length();
    }

    function isOperatorRegisteredAt(address operator, uint48 timestamp, bytes memory hint) public view returns (bool) {
        return _getVotingPowerProviderStorage()._operators.containsAt(timestamp, operator, hint);
    }

    function isOperatorRegistered(
        address operator
    ) public view returns (bool) {
        return _getVotingPowerProviderStorage()._operators.contains(operator);
    }

    function getOperatorsAt(
        uint48 timestamp
    ) public view returns (address[] memory) {
        return _getVotingPowerProviderStorage()._operators.valuesAt(timestamp);
    }

    function getOperators() public view returns (address[] memory) {
        return _getVotingPowerProviderStorage()._operators.values();
    }

    function getOperatorsLength() public view returns (uint256) {
        return _getVotingPowerProviderStorage()._operators.length();
    }

    function isSharedVaultRegisteredAt(address vault, uint48 timestamp, bytes memory hint) public view returns (bool) {
        return _getVotingPowerProviderStorage()._sharedVaults.containsAt(timestamp, vault, hint);
    }

    function isSharedVaultRegistered(
        address vault
    ) public view returns (bool) {
        return _getVotingPowerProviderStorage()._sharedVaults.contains(vault);
    }

    function getSharedVaultsAt(
        uint48 timestamp
    ) public view returns (address[] memory) {
        return _getVotingPowerProviderStorage()._sharedVaults.valuesAt(timestamp);
    }

    function getSharedVaults() public view returns (address[] memory) {
        return _getVotingPowerProviderStorage()._sharedVaults.values();
    }

    function getSharedVaultsLength() public view returns (uint256) {
        return _getVotingPowerProviderStorage()._sharedVaults.length();
    }

    function isOperatorVaultRegisteredAt(
        address vault,
        uint48 timestamp,
        bytes memory hint
    ) public view returns (bool) {
        return _getVotingPowerProviderStorage()._allOperatorVaults.containsAt(timestamp, vault, hint);
    }

    function isOperatorVaultRegistered(
        address vault
    ) public view returns (bool) {
        return _getVotingPowerProviderStorage()._allOperatorVaults.contains(vault);
    }

    function isOperatorVaultRegisteredAt(
        address operator,
        address vault,
        uint48 timestamp,
        bytes memory hint
    ) public view returns (bool) {
        return _getVotingPowerProviderStorage()._operatorVaults[operator].containsAt(timestamp, vault, hint);
    }

    function isOperatorVaultRegistered(address operator, address vault) public view returns (bool) {
        return _getVotingPowerProviderStorage()._operatorVaults[operator].contains(vault);
    }

    function getOperatorVaultsAt(address operator, uint48 timestamp) public view returns (address[] memory) {
        return _getVotingPowerProviderStorage()._operatorVaults[operator].valuesAt(timestamp);
    }

    function getOperatorVaults(
        address operator
    ) public view returns (address[] memory) {
        return _getVotingPowerProviderStorage()._operatorVaults[operator].values();
    }

    function getOperatorVaultsLength(
        address operator
    ) public view returns (uint256) {
        return _getVotingPowerProviderStorage()._operatorVaults[operator].length();
    }

    function getOperatorStakeAt(
        address vault,
        address operator,
        uint48 timestamp,
        bytes memory hints
    ) public view returns (uint256) {
        return IBaseDelegator(IVault(vault).delegator()).stakeAt(
            INetworkManager(address(this)).SUBNETWORK(), operator, timestamp, hints
        );
    }

    function getOperatorStake(address vault, address operator) public view returns (uint256) {
        return IBaseDelegator(IVault(vault).delegator()).stake(INetworkManager(address(this)).SUBNETWORK(), operator);
    }

    function getOperatorVotingPowerAt(
        address operator,
        address vault,
        bytes memory extraData,
        uint48 timestamp,
        bytes memory hints
    ) public view returns (uint256) {
        IVotingPowerProvider.OperatorVaultVotingPowerHints memory operatorVaultVotingPowerHints;
        if (hints.length > 0) {
            operatorVaultVotingPowerHints = abi.decode(hints, (IVotingPowerProvider.OperatorVaultVotingPowerHints));
        }

        if (
            !isTokenRegisteredAt(
                IVault(vault).collateral(), timestamp, operatorVaultVotingPowerHints.isTokenRegisteredHint
            )
        ) {
            return 0;
        }
        return IVotingPowerCalcManager(address(this)).stakeToVotingPowerAt(
            vault,
            getOperatorStakeAt(vault, operator, timestamp, operatorVaultVotingPowerHints.stakeHints),
            extraData,
            timestamp
        );
    }

    function getOperatorVotingPower(
        address operator,
        address vault,
        bytes memory extraData
    ) public view returns (uint256) {
        if (!isTokenRegistered(IVault(vault).collateral())) {
            return 0;
        }
        return IVotingPowerCalcManager(address(this)).stakeToVotingPower(
            vault, getOperatorStake(vault, operator), extraData
        );
    }

    function getOperatorVotingPowersAt(
        address operator,
        bytes memory extraData,
        uint48 timestamp
    ) public view returns (IVotingPowerProvider.VaultVotingPower[] memory vaultVotingPowers) {
        IVotingPowerProvider.OperatorVotingPowersExtraData memory operatorVotingPowersExtraData;
        if (extraData.length > 0) {
            operatorVotingPowersExtraData = abi.decode(extraData, (IVotingPowerProvider.OperatorVotingPowersExtraData));
        }

        uint256 length;
        address[] memory sharedVaults = getSharedVaultsAt(timestamp);
        address[] memory operatorVaults = getOperatorVaultsAt(operator, timestamp);
        vaultVotingPowers = new IVotingPowerProvider.VaultVotingPower[](sharedVaults.length + operatorVaults.length);
        operatorVotingPowersExtraData.sharedVaultsExtraData =
            operatorVotingPowersExtraData.sharedVaultsExtraData.normalize(sharedVaults.length);
        for (uint256 i; i < sharedVaults.length; ++i) {
            uint256 votingPower_ = getOperatorVotingPowerAt(
                operator,
                sharedVaults[i],
                operatorVotingPowersExtraData.sharedVaultsExtraData[i],
                timestamp,
                new bytes(0)
            );
            if (votingPower_ > 0) {
                vaultVotingPowers[length++] =
                    IVotingPowerProvider.VaultVotingPower({vault: sharedVaults[i], votingPower: votingPower_});
            }
        }
        operatorVotingPowersExtraData.operatorVaultsExtraData =
            operatorVotingPowersExtraData.operatorVaultsExtraData.normalize(operatorVaults.length);
        for (uint256 i; i < operatorVaults.length; ++i) {
            uint256 votingPower_ = getOperatorVotingPowerAt(
                operator,
                operatorVaults[i],
                operatorVotingPowersExtraData.operatorVaultsExtraData[i],
                timestamp,
                new bytes(0)
            );
            if (votingPower_ > 0) {
                vaultVotingPowers[length++] =
                    IVotingPowerProvider.VaultVotingPower({vault: operatorVaults[i], votingPower: votingPower_});
            }
        }

        assembly ("memory-safe") {
            mstore(vaultVotingPowers, length)
        }
    }

    function getOperatorVotingPowers(
        address operator,
        bytes memory extraData
    ) public view returns (IVotingPowerProvider.VaultVotingPower[] memory vaultVotingPowers) {
        IVotingPowerProvider.OperatorVotingPowersExtraData memory operatorVotingPowersExtraData;
        if (extraData.length > 0) {
            operatorVotingPowersExtraData = abi.decode(extraData, (IVotingPowerProvider.OperatorVotingPowersExtraData));
        }

        uint256 length;
        address[] memory sharedVaults = getSharedVaults();
        address[] memory operatorVaults = getOperatorVaults(operator);
        vaultVotingPowers = new IVotingPowerProvider.VaultVotingPower[](sharedVaults.length + operatorVaults.length);
        operatorVotingPowersExtraData.sharedVaultsExtraData =
            operatorVotingPowersExtraData.sharedVaultsExtraData.normalize(sharedVaults.length);
        for (uint256 i; i < sharedVaults.length; ++i) {
            uint256 votingPower_ = getOperatorVotingPower(
                operator, sharedVaults[i], operatorVotingPowersExtraData.sharedVaultsExtraData[i]
            );
            if (votingPower_ > 0) {
                vaultVotingPowers[length++] =
                    IVotingPowerProvider.VaultVotingPower({vault: sharedVaults[i], votingPower: votingPower_});
            }
        }
        operatorVotingPowersExtraData.operatorVaultsExtraData =
            operatorVotingPowersExtraData.operatorVaultsExtraData.normalize(operatorVaults.length);
        for (uint256 i; i < operatorVaults.length; ++i) {
            uint256 votingPower_ = getOperatorVotingPower(
                operator, operatorVaults[i], operatorVotingPowersExtraData.operatorVaultsExtraData[i]
            );
            if (votingPower_ > 0) {
                vaultVotingPowers[length++] =
                    IVotingPowerProvider.VaultVotingPower({vault: operatorVaults[i], votingPower: votingPower_});
            }
        }

        assembly ("memory-safe") {
            mstore(vaultVotingPowers, length)
        }
    }

    function getVotingPowersAt(
        bytes[] memory extraData,
        uint48 timestamp
    ) public view returns (IVotingPowerProvider.OperatorVotingPower[] memory operatorVotingPowers) {
        uint256 length;
        address[] memory operators = getOperatorsAt(timestamp);
        operatorVotingPowers = new IVotingPowerProvider.OperatorVotingPower[](operators.length);
        extraData = extraData.normalize(operators.length);
        for (uint256 i; i < operators.length; ++i) {
            IVotingPowerProvider.VaultVotingPower[] memory votingPowers =
                getOperatorVotingPowersAt(operators[i], extraData[i], timestamp);
            if (votingPowers.length > 0) {
                operatorVotingPowers[length++] =
                    IVotingPowerProvider.OperatorVotingPower({operator: operators[i], vaults: votingPowers});
            }
        }
        assembly ("memory-safe") {
            mstore(operatorVotingPowers, length)
        }
    }

    function getVotingPowers(
        bytes[] memory extraData
    ) public view returns (IVotingPowerProvider.OperatorVotingPower[] memory operatorVotingPowers) {
        uint256 length;
        address[] memory operators = getOperators();
        operatorVotingPowers = new IVotingPowerProvider.OperatorVotingPower[](operators.length);
        extraData = extraData.normalize(operators.length);
        for (uint256 i; i < operators.length; ++i) {
            IVotingPowerProvider.VaultVotingPower[] memory votingPowers =
                getOperatorVotingPowers(operators[i], extraData[i]);
            if (votingPowers.length > 0) {
                operatorVotingPowers[length++] =
                    IVotingPowerProvider.OperatorVotingPower({operator: operators[i], vaults: votingPowers});
            }
        }
        assembly ("memory-safe") {
            mstore(operatorVotingPowers, length)
        }
    }

    function setSlashingData(bool requireSlasher, uint48 minVaultEpochDuration) public {
        _getVotingPowerProviderStorage()._slashingData.push(
            Time.timestamp(), serializeSlashingData(requireSlasher, minVaultEpochDuration)
        );

        emit IVotingPowerProvider.SetSlashingData(requireSlasher, minVaultEpochDuration);
    }

    function registerToken(
        address token
    ) public {
        if (token == address(0)) {
            revert IVotingPowerProvider.VotingPowerProvider_InvalidToken();
        }
        if (!_getVotingPowerProviderStorage()._tokens.add(Time.timestamp(), token)) {
            revert IVotingPowerProvider.VotingPowerProvider_TokenAlreadyIsRegistered();
        }

        emit IVotingPowerProvider.RegisterToken(token);
    }

    function unregisterToken(
        address token
    ) public {
        if (!_getVotingPowerProviderStorage()._tokens.remove(Time.timestamp(), token)) {
            revert IVotingPowerProvider.VotingPowerProvider_TokenNotRegistered();
        }

        emit IVotingPowerProvider.UnregisterToken(token);
    }

    function registerOperator(
        address operator
    ) public {
        if (!_validateOperator(operator)) {
            revert IVotingPowerProvider.VotingPowerProvider_InvalidOperator();
        }

        if (!_getVotingPowerProviderStorage()._operators.add(Time.timestamp(), operator)) {
            revert IVotingPowerProvider.VotingPowerProvider_OperatorAlreadyRegistered();
        }

        emit IVotingPowerProvider.RegisterOperator(operator);
    }

    function unregisterOperator(
        address operator
    ) public {
        if (!_getVotingPowerProviderStorage()._operators.remove(Time.timestamp(), operator)) {
            revert IVotingPowerProvider.VotingPowerProvider_OperatorNotRegistered();
        }

        emit IVotingPowerProvider.UnregisterOperator(operator);
    }

    function registerSharedVault(
        address vault
    ) public {
        IVotingPowerProvider.VotingPowerProviderStorage storage $ = _getVotingPowerProviderStorage();
        if (!_validateVault(vault)) {
            revert IVotingPowerProvider.VotingPowerProvider_InvalidVault();
        }
        if (!_validateSharedVault(vault)) {
            revert IVotingPowerProvider.VotingPowerProvider_InvalidSharedVault();
        }
        if ($._allOperatorVaults.contains(vault)) {
            revert IVotingPowerProvider.VotingPowerProvider_OperatorVaultAlreadyIsRegistered();
        }
        if (!$._sharedVaults.add(Time.timestamp(), vault)) {
            revert IVotingPowerProvider.VotingPowerProvider_SharedVaultAlreadyIsRegistered();
        }

        emit IVotingPowerProvider.RegisterSharedVault(vault);
    }

    function registerOperatorVault(address operator, address vault) public {
        IVotingPowerProvider.VotingPowerProviderStorage storage $ = _getVotingPowerProviderStorage();
        if (!_validateVault(vault)) {
            revert IVotingPowerProvider.VotingPowerProvider_InvalidVault();
        }
        if (!_validateOperatorVault(operator, vault)) {
            revert IVotingPowerProvider.VotingPowerProvider_InvalidOperatorVault();
        }
        if (!isOperatorRegistered(operator)) {
            revert IVotingPowerProvider.VotingPowerProvider_OperatorNotRegistered();
        }
        if ($._sharedVaults.contains(vault)) {
            revert IVotingPowerProvider.VotingPowerProvider_SharedVaultAlreadyIsRegistered();
        }
        if (!$._allOperatorVaults.add(Time.timestamp(), vault)) {
            revert IVotingPowerProvider.VotingPowerProvider_OperatorVaultAlreadyIsRegistered();
        }
        $._operatorVaults[operator].add(Time.timestamp(), vault);

        emit IVotingPowerProvider.RegisterOperatorVault(operator, vault);
    }

    function unregisterSharedVault(
        address vault
    ) public {
        if (!_getVotingPowerProviderStorage()._sharedVaults.remove(Time.timestamp(), vault)) {
            revert IVotingPowerProvider.VotingPowerProvider_SharedVaultNotRegistered();
        }

        emit IVotingPowerProvider.UnregisterSharedVault(vault);
    }

    function unregisterOperatorVault(address operator, address vault) public {
        IVotingPowerProvider.VotingPowerProviderStorage storage $ = _getVotingPowerProviderStorage();
        if (!$._operatorVaults[operator].remove(Time.timestamp(), vault)) {
            revert IVotingPowerProvider.VotingPowerProvider_OperatorVaultNotRegistered();
        }
        $._allOperatorVaults.remove(Time.timestamp(), vault);

        emit IVotingPowerProvider.UnregisterOperatorVault(operator, vault);
    }

    function serializeSlashingData(bool requireSlasher, uint48 minVaultEpochDuration) public pure returns (uint208) {
        return uint208(minVaultEpochDuration) << 1 | (requireSlasher ? 1 : 0);
    }

    function deserializeSlashingData(
        uint208 slashingData
    ) public pure returns (bool, uint48) {
        return (slashingData & 1 > 0, uint48(slashingData >> 1));
    }

    function _validateOperator(
        address operator
    ) public view returns (bool) {
        if (!IRegistry(IVotingPowerProvider(address(this)).OPERATOR_REGISTRY()).isEntity(operator)) {
            return false;
        }
        return true;
    }

    function _validateVault(
        address vault
    ) public view returns (bool) {
        if (!IRegistry(IVotingPowerProvider(address(this)).VAULT_FACTORY()).isEntity(vault)) {
            return false;
        }

        if (!IVault(vault).isInitialized()) {
            return false;
        }

        if (!_validateVaultSlashing(vault)) {
            return false;
        }

        if (!isTokenRegistered(IVault(vault).collateral())) {
            return false;
        }

        return true;
    }

    function _validateSharedVault(
        address vault
    ) public view returns (bool) {
        address delegator = IVault(vault).delegator();
        uint64 delegatorType = IEntity(delegator).TYPE();
        if (
            (
                delegatorType != uint64(IVotingPowerProvider.DelegatorType.FULL_RESTAKE)
                    && delegatorType != uint64(IVotingPowerProvider.DelegatorType.NETWORK_RESTAKE)
            )
        ) {
            return false;
        }

        return true;
    }

    function _validateOperatorVault(address operator, address vault) public view returns (bool) {
        address delegator = IVault(vault).delegator();
        uint64 delegatorType = IEntity(delegator).TYPE();
        if (
            (
                delegatorType != uint64(IVotingPowerProvider.DelegatorType.OPERATOR_SPECIFIC)
                    && delegatorType != uint64(IVotingPowerProvider.DelegatorType.OPERATOR_NETWORK_SPECIFIC)
            ) || IOperatorSpecificDelegator(delegator).operator() != operator
        ) {
            return false;
        }

        if (
            delegatorType == uint64(IVotingPowerProvider.DelegatorType.OPERATOR_NETWORK_SPECIFIC)
                && IOperatorNetworkSpecificDelegator(delegator).network() != INetworkManager(address(this)).NETWORK()
        ) {
            return false;
        }

        return true;
    }

    function _validateVaultSlashing(
        address vault
    ) public view returns (bool) {
        address slasher = IVault(vault).slasher();
        (bool requireSlasher, uint48 minVaultEpochDuration) = getSlashingData();
        if (requireSlasher && slasher == address(0)) {
            return false;
        }

        uint48 vaultEpochDuration = IVault(vault).epochDuration();
        if (slasher != address(0)) {
            uint64 slasherType = IEntity(slasher).TYPE();
            if (slasherType == uint64(IVotingPowerProvider.SlasherType.VETO)) {
                vaultEpochDuration -= IVetoSlasher(slasher).vetoDuration();
            } else if (slasherType > uint64(type(IVotingPowerProvider.SlasherType).max)) {
                return false;
            }
        }
        return minVaultEpochDuration <= vaultEpochDuration;
    }
}
