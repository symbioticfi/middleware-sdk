// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BaseMiddleware} from "../../BaseMiddleware.sol";

abstract contract Operators is BaseMiddleware {
    function registerOperator(address operator, bytes memory key, address vault) public checkAccess {
        _beforeRegisterOperator(operator, key, vault);
        _registerOperator(operator);
        _updateKey(operator, key);
        if (vault != address(0)) {
            registerOperatorVault(operator, vault);
        }
    }

    function unregisterOperator(
        address operator
    ) public checkAccess {
        _beforeUnregisterOperator(operator);
        _unregisterOperator(operator);
    }

    function pauseOperator(
        address operator
    ) public checkAccess {
        _beforePauseOperator(operator);
        _pauseOperator(operator);
    }

    function unpauseOperator(
        address operator
    ) public checkAccess {
        _beforeUnpauseOperator(operator);
        _unpauseOperator(operator);
    }

    function updateOperatorKey(address operator, bytes memory key) public checkAccess {
        _beforeUpdateOperatorKey(operator, key);
        _updateKey(operator, key);
    }

    function registerOperatorVault(address operator, address vault) public checkAccess {
        require(isOperatorRegistered(operator), "Operator not registered");
        _beforeRegisterOperatorVault(operator, vault);
        _registerOperatorVault(operator, vault);
    }

    function unregisterOperatorVault(address operator, address vault) public checkAccess {
        _beforeUnregisterOperatorVault(operator, vault);
        _unregisterOperatorVault(operator, vault);
    }

    function pauseOperatorVault(address operator, address vault) public checkAccess {
        _beforePauseOperatorVault(operator, vault);
        _pauseOperatorVault(operator, vault);
    }

    function unpauseOperatorVault(address operator, address vault) public checkAccess {
        _beforeUnpauseOperatorVault(operator, vault);
        _unpauseOperatorVault(operator, vault);
    }

    function _beforeUpdateOperatorKey(address operator, bytes memory key) internal virtual {}

    function _beforeRegisterOperator(address operator, bytes memory key, address vault) internal virtual {}
    function _beforeUnregisterOperator(
        address operator
    ) internal virtual {}
    function _beforePauseOperator(
        address operator
    ) internal virtual {}
    function _beforeUnpauseOperator(
        address operator
    ) internal virtual {}

    function _beforeRegisterOperatorVault(address operator, address vault) internal virtual {}
    function _beforeUnregisterOperatorVault(address operator, address vault) internal virtual {}
    function _beforePauseOperatorVault(address operator, address vault) internal virtual {}
    function _beforeUnpauseOperatorVault(address operator, address vault) internal virtual {}
}