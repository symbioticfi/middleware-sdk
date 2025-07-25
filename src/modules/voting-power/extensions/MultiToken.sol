// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {VotingPowerProvider} from "../VotingPowerProvider.sol";

import {IMultiToken} from "../../../interfaces/modules/voting-power/extensions/IMultiToken.sol";

/**
 * @title MultiToken
 * @notice Contract for registering and unregistering multiple tokens.
 */
abstract contract MultiToken is VotingPowerProvider, IMultiToken {
    function __MultiToken_init() internal virtual onlyInitializing {}

    /**
     * @inheritdoc IMultiToken
     */
    function registerToken(
        address token
    ) public virtual checkPermission {
        _registerToken(token);
    }

    /**
     * @inheritdoc IMultiToken
     */
    function unregisterToken(
        address token
    ) public virtual checkPermission {
        _unregisterToken(token);
    }
}
