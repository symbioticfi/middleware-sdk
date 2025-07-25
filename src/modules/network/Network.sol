// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {INetwork} from "../../interfaces/modules/network/INetwork.sol";
import {ISetMaxNetworkLimitHook} from "../../interfaces/modules/network/ISetMaxNetworkLimitHook.sol";

import {IBaseDelegator} from "@symbioticfi/core/src/interfaces/delegator/IBaseDelegator.sol";
import {INetworkMiddlewareService} from "@symbioticfi/core/src/interfaces/service/INetworkMiddlewareService.sol";
import {INetworkRegistry} from "@symbioticfi/core/src/interfaces/INetworkRegistry.sol";

import {Bytes} from "@openzeppelin/contracts/utils/Bytes.sol";
import {TimelockControllerUpgradeable} from
    "@openzeppelin/contracts-upgradeable/governance/TimelockControllerUpgradeable.sol";

/**
 * @title Network
 * @notice Contract for network management.
 * @dev It allows any external watcher to verify if the set delay is sufficient for a given operation (call to some contract's function).
 *      It supports delays for native asset transfers.
 *      It supports setting delay for (exact target | exact selector) pairs and for (any target | exact selector) pairs.
 */
contract Network is TimelockControllerUpgradeable, INetwork {
    using Bytes for bytes;

    /**
     * @inheritdoc INetwork
     */
    bytes32 public constant NAME_UPDATE_ROLE = keccak256("NAME_UPDATE_ROLE");

    /**
     * @inheritdoc INetwork
     */
    bytes32 public constant METADATA_URI_UPDATE_ROLE = keccak256("METADATA_URI_UPDATE_ROLE");

    /**
     * @inheritdoc INetwork
     */
    address public immutable NETWORK_REGISTRY;

    /**
     * @inheritdoc INetwork
     */
    address public immutable NETWORK_MIDDLEWARE_SERVICE;

    // keccak256(abi.encode(uint256(keccak256("symbiotic.storage.Network")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant NetworkStorageLocation = 0x2affd7691de6b6d2a998e6b135d73a3c906ea64896dff9dcb273e98dd44a6100;

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.TimelockController")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TimelockControllerStorageLocation =
        0x9a37c2aa9d186a0969ff8a8267bf4e07e864c2f2768f5040949e28a624fb3600;

    constructor(address networkRegistry, address networkMiddlewareService) {
        NETWORK_REGISTRY = networkRegistry;
        NETWORK_MIDDLEWARE_SERVICE = networkMiddlewareService;
    }

    function _getNetworkStorage() internal pure returns (NetworkStorage storage $) {
        bytes32 location = NetworkStorageLocation;
        assembly {
            $.slot := location
        }
    }

    function _getTimelockControllerStorageOverridden() internal pure returns (TimelockControllerStorage storage $) {
        assembly {
            $.slot := TimelockControllerStorageLocation
        }
    }

    function __Network_init(
        NetworkInitParams memory initParams
    ) public virtual onlyInitializing {
        __TimelockController_init(
            initParams.globalMinDelay, initParams.proposers, initParams.executors, initParams.defaultAdminRoleHolder
        );

        INetworkRegistry(NETWORK_REGISTRY).registerNetwork();

        _updateName(initParams.name);
        _updateMetadataURI(initParams.metadataURI);

        for (uint256 i; i < initParams.delayParams.length; ++i) {
            _updateDelay(
                initParams.delayParams[i].target,
                initParams.delayParams[i].selector,
                true,
                initParams.delayParams[i].delay
            );
        }

        if (initParams.defaultAdminRoleHolder != address(0)) {
            _grantRole(DEFAULT_ADMIN_ROLE, initParams.defaultAdminRoleHolder);
        }
        if (initParams.nameUpdateRoleHolder != address(0)) {
            _grantRole(NAME_UPDATE_ROLE, initParams.nameUpdateRoleHolder);
        }
        if (initParams.metadataURIUpdateRoleHolder != address(0)) {
            _grantRole(METADATA_URI_UPDATE_ROLE, initParams.metadataURIUpdateRoleHolder);
        }
    }

    /**
     * @inheritdoc INetwork
     */
    function getMinDelay(address target, bytes memory data) public view virtual returns (uint256) {
        bytes4 selector = _getSelector(data);
        if (target == address(this) && selector == INetwork.updateDelay.selector) {
            (address underlyingTarget, bytes4 underlyingSelector,,) =
                abi.decode(_getPayload(data), (address, bytes4, bool, uint256));
            _validateUpdateDelayTargetAndSelector(underlyingTarget, underlyingSelector);
            return _getMinDelay(underlyingTarget, underlyingSelector);
        }
        _validateTargetAndSelector(target, selector);
        return _getMinDelay(target, selector);
    }

    /**
     * @inheritdoc INetwork
     */
    function name() public view virtual returns (string memory) {
        return _getNetworkStorage()._name;
    }

    /**
     * @inheritdoc INetwork
     */
    function metadataURI() public view virtual returns (string memory) {
        return _getNetworkStorage()._metadataURI;
    }

    /**
     * @inheritdoc INetwork
     */
    function updateDelay(address target, bytes4 selector, bool enabled, uint256 newDelay) public virtual {
        address sender = _msgSender();
        if (sender != address(this)) {
            revert TimelockUnauthorizedCaller(sender);
        }
        _updateDelay(target, selector, enabled, newDelay);
    }

    /**
     * @inheritdoc TimelockControllerUpgradeable
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual override onlyRole(PROPOSER_ROLE) {
        uint256 minDelay = getMinDelay(target, data);
        if (delay < minDelay) {
            revert TimelockInsufficientDelay(delay, minDelay);
        }
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _scheduleOverridden(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
        if (salt != bytes32(0)) {
            emit CallSalt(id, salt);
        }
    }

    /**
     * @inheritdoc TimelockControllerUpgradeable
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual override onlyRole(PROPOSER_ROLE) {
        if (targets.length != values.length || targets.length != payloads.length) {
            revert TimelockInvalidOperationLength(targets.length, payloads.length, values.length);
        }
        for (uint256 i; i < targets.length; ++i) {
            uint256 minDelay = getMinDelay(targets[i], payloads[i]);
            if (delay < minDelay) {
                revert TimelockInsufficientDelay(delay, minDelay);
            }
        }

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);
        _scheduleOverridden(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], payloads[i], predecessor, delay);
        }
        if (salt != bytes32(0)) {
            emit CallSalt(id, salt);
        }
    }

    /**
     * @inheritdoc INetwork
     */
    function updateName(
        string memory name_
    ) public virtual onlyRole(NAME_UPDATE_ROLE) {
        _updateName(name_);
    }

    /**
     * @inheritdoc INetwork
     */
    function updateMetadataURI(
        string memory metadataURI_
    ) public virtual onlyRole(METADATA_URI_UPDATE_ROLE) {
        _updateMetadataURI(metadataURI_);
    }

    /**
     * @inheritdoc ISetMaxNetworkLimitHook
     */
    function setMaxNetworkLimit(address delegator, uint96 subnetworkId, uint256 maxNetworkLimit) public virtual {
        if (msg.sender != INetworkMiddlewareService(NETWORK_MIDDLEWARE_SERVICE).middleware(address(this))) {
            revert NotMiddleware();
        }
        _setMaxNetworkLimit(delegator, subnetworkId, maxNetworkLimit);
    }

    function _updateDelay(address target, bytes4 selector, bool enabled, uint256 newDelay) internal virtual {
        NetworkStorage storage $ = _getNetworkStorage();
        if (!enabled && newDelay != 0) {
            revert InvalidNewDelay();
        }
        bytes32 id = _getId(target, selector);
        emit MinDelayChange(target, selector, $._isMinDelayEnabled[id], $._minDelays[id], enabled, newDelay);
        $._isMinDelayEnabled[id] = enabled;
        $._minDelays[id] = newDelay;
    }

    function _scheduleOverridden(bytes32 id, uint256 delay) internal virtual {
        TimelockControllerStorage storage $ = _getTimelockControllerStorageOverridden();
        if (isOperation(id)) {
            revert TimelockUnexpectedOperationState(id, _encodeStateBitmap(OperationState.Unset));
        }
        $._timestamps[id] = block.timestamp + delay;
    }

    function _updateName(
        string memory name_
    ) internal virtual {
        _getNetworkStorage()._name = name_;
        emit NameSet(name_);
    }

    function _updateMetadataURI(
        string memory metadataURI_
    ) internal virtual {
        _getNetworkStorage()._metadataURI = metadataURI_;
        emit MetadataURISet(metadataURI_);
    }

    function _setMaxNetworkLimit(address delegator, uint96 subnetworkId, uint256 maxNetworkLimit) internal virtual {
        IBaseDelegator(delegator).setMaxNetworkLimit(subnetworkId, maxNetworkLimit);
    }

    function _getId(address target, bytes4 selector) internal pure virtual returns (bytes32 id) {
        return keccak256(abi.encode(target, selector));
    }

    function _getMinDelay(address target, bytes4 selector) internal view virtual returns (uint256) {
        (bool enabled, uint256 minDelay) = _getMinDelay(_getId(target, selector));
        if (enabled) {
            return minDelay;
        }
        (enabled, minDelay) = _getMinDelay(_getId(address(0), selector));
        if (enabled) {
            return minDelay;
        }
        return getMinDelay();
    }

    function _getMinDelay(
        bytes32 id
    ) internal view virtual returns (bool, uint256) {
        NetworkStorage storage $ = _getNetworkStorage();
        return ($._isMinDelayEnabled[id], $._minDelays[id]);
    }

    function _validateTargetAndSelector(address target, bytes4 selector) internal view virtual {
        if (target == address(0)) {
            revert InvalidTargetAndSelector();
        }
        _validateUpdateDelayTargetAndSelector(target, selector);
    }

    function _validateUpdateDelayTargetAndSelector(address target, bytes4 selector) internal view virtual {
        if (target == address(this) && selector == INetwork.updateDelay.selector) {
            revert InvalidTargetAndSelector();
        }
    }

    function _getSelector(
        bytes memory data
    ) internal pure returns (bytes4 selector) {
        if (data.length == 0) {
            return 0xEEEEEEEE;
        }
        if (data.length < 4) {
            revert InvalidDataLength();
        }
        assembly ("memory-safe") {
            selector := mload(add(data, 32))
        }
    }

    function _getPayload(
        bytes memory data
    ) internal pure returns (bytes memory payload) {
        if (data.length < 4) {
            revert InvalidDataLength();
        }
        return data.slice(4);
    }

    /**
     * @inheritdoc TimelockControllerUpgradeable
     */
    function initialize(
        uint256, /* minDelay */
        address[] memory, /* proposers */
        address[] memory, /* executors */
        address /* admin */
    ) public virtual override {
        revert();
    }
}
