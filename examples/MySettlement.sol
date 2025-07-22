// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Settlement} from "../src/contracts/modules/settlement/Settlement.sol";
import {OzAccessControl} from "../src/contracts/modules/common/permissions/OzAccessControl.sol";

import {ISettlement} from "../src/interfaces/modules/settlement/ISettlement.sol";

contract MySettlement is Settlement, OzAccessControl {
    bytes32 public constant SET_SIG_VERIFIER_ROLE = keccak256("SET_SIG_VERIFIER_ROLE");
    bytes32 public constant SET_GENESIS_ROLE = keccak256("SET_GENESIS_ROLE");

    function initialize(
        SettlementInitParams memory settlementInitParams,
        address defaultAdmin
    ) public virtual initializer {
        __Settlement_init(settlementInitParams);
        __OzAccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);

        _setSelectorRole(ISettlement.setSigVerifier.selector, SET_SIG_VERIFIER_ROLE);
        _setSelectorRole(ISettlement.setGenesis.selector, SET_GENESIS_ROLE);
    }
}
