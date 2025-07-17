// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IBaseSlashing} from "../../src/interfaces/modules/voting-power/extensions/IBaseSlashing.sol";

contract SlasherMock {
    function slashVault(
        address middleware,
        uint48 timestamp,
        address vault,
        address operator,
        uint256 amount,
        bytes memory hints
    ) external returns (bool success, bytes memory response) {
        return IBaseSlashing(middleware).slashVault(timestamp, vault, operator, amount, hints);
    }

    function executeSlashVault(
        address middleware,
        address vault,
        uint256 slashIndex,
        bytes memory hints
    ) external returns (bool success, uint256 slashedAmount) {
        return IBaseSlashing(middleware).executeSlashVault(vault, slashIndex, hints);
    }
}
