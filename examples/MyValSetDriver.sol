// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ValSetDriver} from "../src/contracts/modules/valset-driver/ValSetDriver.sol";
import {OzAccessControl} from "../src/contracts/modules/common/permissions/OzAccessControl.sol";

import {IEpochManager} from "../src/interfaces/modules/valset-driver/IEpochManager.sol";
import {IValSetDriver} from "../src/interfaces/modules/valset-driver/IValSetDriver.sol";


contract MyValSetDriver is ValSetDriver, OzAccessControl {
    bytes32 public constant SET_EPOCH_DURATION_ROLE = keccak256("SET_EPOCH_DURATION_ROLE");
    bytes32 public constant MANAGE_VOTING_POWER_PROVIDERS_ROLE = keccak256("MANAGE_VOTING_POWER_PROVIDERS_ROLE");
    bytes32 public constant MANAGE_KEYS_PROVIDER_ROLE = keccak256("MANAGE_KEYS_PROVIDER_ROLE");
    bytes32 public constant MANAGE_REPLICAS_ROLE = keccak256("MANAGE_REPLICAS_ROLE");
    bytes32 public constant SET_VERIFICATION_TYPE_ROLE = keccak256("SET_VERIFICATION_TYPE_ROLE");
    bytes32 public constant SET_MAX_VOTING_POWER_ROLE = keccak256("SET_MAX_VOTING_POWER_ROLE");
    bytes32 public constant SET_MIN_INCLUSION_VOTING_POWER_ROLE = keccak256("SET_MIN_INCLUSION_VOTING_POWER_ROLE");
    bytes32 public constant SET_MAX_VALIDATORS_COUNT_ROLE = keccak256("SET_MAX_VALIDATORS_COUNT_ROLE");
    bytes32 public constant SET_REQUIRED_KEY_TAGS_ROLE = keccak256("SET_REQUIRED_KEY_TAGS_ROLE");
    bytes32 public constant SET_REQUIRED_HEADER_KEY_TAG_ROLE = keccak256("SET_REQUIRED_HEADER_KEY_TAG_ROLE");
    bytes32 public constant MANAGE_QUORUM_THRESHOLDS_ROLE = keccak256("MANAGE_QUORUM_THRESHOLDS_ROLE");

    function initialize(
        ValSetDriverInitParams memory valSetDriverInitParams,
        address defaultAdmin
    ) public virtual initializer {
        __ValSetDriver_init(valSetDriverInitParams);
        __OzAccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);

        _setSelectorRole(IEpochManager.setEpochDuration.selector, SET_EPOCH_DURATION_ROLE);
        _setSelectorRole(IValSetDriver.addVotingPowerProvider.selector, MANAGE_VOTING_POWER_PROVIDERS_ROLE);
        _setSelectorRole(IValSetDriver.removeVotingPowerProvider.selector, MANAGE_VOTING_POWER_PROVIDERS_ROLE);
        _setSelectorRole(IValSetDriver.setKeysProvider.selector, MANAGE_KEYS_PROVIDER_ROLE);
        _setSelectorRole(IValSetDriver.addReplica.selector, MANAGE_REPLICAS_ROLE);
        _setSelectorRole(IValSetDriver.removeReplica.selector, MANAGE_REPLICAS_ROLE);
        _setSelectorRole(IValSetDriver.setVerificationType.selector, SET_VERIFICATION_TYPE_ROLE);
        _setSelectorRole(IValSetDriver.setMaxVotingPower.selector, SET_MAX_VOTING_POWER_ROLE);
        _setSelectorRole(IValSetDriver.setMinInclusionVotingPower.selector, SET_MIN_INCLUSION_VOTING_POWER_ROLE);
        _setSelectorRole(IValSetDriver.setMaxValidatorsCount.selector, SET_MAX_VALIDATORS_COUNT_ROLE);
        _setSelectorRole(IValSetDriver.setRequiredKeyTags.selector, SET_REQUIRED_KEY_TAGS_ROLE);
        _setSelectorRole(IValSetDriver.setRequiredHeaderKeyTag.selector, SET_REQUIRED_HEADER_KEY_TAG_ROLE);
        _setSelectorRole(IValSetDriver.addQuorumThreshold.selector, MANAGE_QUORUM_THRESHOLDS_ROLE);
        _setSelectorRole(IValSetDriver.removeQuorumThreshold.selector, MANAGE_QUORUM_THRESHOLDS_ROLE);
    }
}
