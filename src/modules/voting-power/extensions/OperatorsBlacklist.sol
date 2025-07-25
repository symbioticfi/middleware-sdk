// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerProvider} from "../VotingPowerProvider.sol";

import {IOperatorsBlacklist} from "../../../interfaces/modules/voting-power/extensions/IOperatorsBlacklist.sol";

/**
 * @title OperatorsBlacklist
 * @notice Contract for blacklisting operators.
 */
abstract contract OperatorsBlacklist is VotingPowerProvider, IOperatorsBlacklist {
    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.OperatorsBlacklist")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OperatorsBlacklistStorageLocation =
        0x23ffaefb5f6b29c7a77ac2a8c6e8b7a8cb63a59ee84629217d13308576dcc800;

    function _getOperatorsBlacklistStorage() internal pure returns (OperatorsBlacklistStorage storage $) {
        bytes32 location = OperatorsBlacklistStorageLocation;
        assembly {
            $.slot := location
        }
    }

    function __OperatorsBlacklist_init() internal virtual onlyInitializing {}

    /**
     * @inheritdoc IOperatorsBlacklist
     */
    function isOperatorBlacklisted(
        address operator
    ) public view virtual returns (bool) {
        return _getOperatorsBlacklistStorage()._blacklisted[operator];
    }

    /**
     * @inheritdoc IOperatorsBlacklist
     */
    function blacklistOperator(
        address operator
    ) public virtual checkPermission {
        _getOperatorsBlacklistStorage()._blacklisted[operator] = true;
        if (isOperatorRegistered(operator)) {
            _unregisterOperator(operator);
        }
        emit BlacklistOperator(operator);
    }

    /**
     * @inheritdoc IOperatorsBlacklist
     */
    function unblacklistOperator(
        address operator
    ) public virtual checkPermission {
        _getOperatorsBlacklistStorage()._blacklisted[operator] = false;
        emit UnblacklistOperator(operator);
    }

    function _registerOperatorImpl(
        address operator
    ) internal virtual override {
        if (isOperatorBlacklisted(operator)) {
            revert OperatorsBlacklist_OperatorBlacklisted();
        }
        super._registerOperatorImpl(operator);
    }
}
