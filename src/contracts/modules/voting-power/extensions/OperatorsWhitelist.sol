// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerProvider} from "../VotingPowerProvider.sol";

import {IOperatorsWhitelist} from "../../../../interfaces/modules/voting-power/extensions/IOperatorsWhitelist.sol";

abstract contract OperatorsWhitelist is VotingPowerProvider, IOperatorsWhitelist {
    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.OperatorsWhitelist")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OperatorsWhitelistStorageLocation =
        0x3fa7d7e58a4c604e915cc85c236f89892f2e36ec13dff506efa6b5ea5fafeb00;

    function _getOperatorsWhitelistStorage() internal pure returns (OperatorsWhitelistStorage storage $) {
        bytes32 location = OperatorsWhitelistStorageLocation;
        assembly {
            $.slot := location
        }
    }

    function __OperatorsWhitelist_init(
        OperatorsWhitelistInitParams memory initParams
    ) internal virtual onlyInitializing {
        _setWhitelistStatus(initParams.isWhitelistEnabled);
    }

    /**
     * @inheritdoc IOperatorsWhitelist
     */
    function isWhitelistEnabled() public view virtual returns (bool) {
        return _getOperatorsWhitelistStorage()._isWhitelistEnabled;
    }

    /**
     * @inheritdoc IOperatorsWhitelist
     */
    function isOperatorWhitelisted(
        address operator
    ) public view virtual returns (bool) {
        return _getOperatorsWhitelistStorage()._whitelisted[operator];
    }

    /**
     * @inheritdoc IOperatorsWhitelist
     */
    function setWhitelistStatus(
        bool status
    ) public virtual checkPermission {
        _setWhitelistStatus(status);
    }

    /**
     * @inheritdoc IOperatorsWhitelist
     */
    function whitelistOperator(
        address operator
    ) public virtual checkPermission {
        _getOperatorsWhitelistStorage()._whitelisted[operator] = true;
        emit WhitelistOperator(operator);
    }

    /**
     * @inheritdoc IOperatorsWhitelist
     */
    function unwhitelistOperator(
        address operator
    ) public virtual checkPermission {
        _getOperatorsWhitelistStorage()._whitelisted[operator] = false;
        if (isWhitelistEnabled() && isOperatorRegistered(operator)) {
            _unregisterOperator(operator);
        }
        emit UnwhitelistOperator(operator);
    }

    function _registerOperatorImpl(
        address operator
    ) internal virtual override {
        if (isWhitelistEnabled() && !isOperatorWhitelisted(operator)) {
            revert OperatorsWhitelist_OperatorNotWhitelisted();
        }
        super._registerOperatorImpl(operator);
    }

    function _setWhitelistStatus(
        bool status
    ) internal virtual {
        _getOperatorsWhitelistStorage()._isWhitelistEnabled = status;
        emit SetWhitelistStatus(status);
    }
}
