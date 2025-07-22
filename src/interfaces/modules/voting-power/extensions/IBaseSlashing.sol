// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseSlashing {
    /**
     * @notice The error thrown when the slashed operator is not registered.
     */
    error BaseSlashing_UnregisteredOperatorSlash();

    /**
     * @notice The error thrown when the slashed vault is not registered.
     */
    error BaseSlashing_UnregisteredVaultSlash();

    /**
     * @notice The error thrown when the slasher type is unsupported.
     */
    error BaseSlashing_UnknownSlasherType();

    /**
     * @notice The error thrown when the slasher is not a veto slasher.
     */
    error BaseSlashing_NotVetoSlasher();

    /**
     * @notice The error thrown when the vault doesn't have a slasher.
     */
    error BaseSlashing_NoSlasher();

    /**
     * @notice The error thrown when the caller is not the slasher.
     */
    error BaseSlashing_NotSlasher();

    /**
     * @notice The error thrown when the new slasher is zero address.
     */
    error BaseSlashing_InvalidSlasher();

    /**
     * @notice The error thrown when the unregistered token is slashed.
     */
    error BaseSlashing_UnregisteredTokenSlash();

    /**
     * @notice The storage of the BaseSlashing contract.
     * @param _slasher The address of the slasher.
     * @custom:storage-location erc7201:symbiotic.storage.BaseSlashing
     */
    struct BaseSlashingStorage {
        address _slasher;
    }

    /**
     * @notice The parameters for the initialization of the BaseSlashing contract.
     * @param slasher The address of the slasher.
     */
    struct BaseSlashingInitParams {
        address slasher;
    }

    /**
     * @notice The hints to optimize the vault slashing.
     * @param operatorRegisteredHint The hint to optimize the operator registration status fetching.
     * @param operatorVaultRegisteredHint The hint to optimize the operator vault registration status fetching.
     * @param sharedVaultRegisteredHint The hint to optimize the shared vault registration status fetching.
     * @param isTokenRegisteredHint The hint to optimize the token registration status fetching.
     * @param slashHints The hints to optimize the slash.
     */
    struct SlashVaultHints {
        bytes operatorRegisteredHint;
        bytes operatorVaultRegisteredHint;
        bytes sharedVaultRegisteredHint;
        bytes isTokenRegisteredHint;
        bytes slashHints;
    }

    /**
     * @notice The hints to optimize the base slashing.
     * @param slashingDataHint The hint to optimize the slashing data fetching.
     * @param slashCoreHints The hints to optimize the slash core.
     */
    struct SlashHints {
        bytes slashingDataHint;
        bytes slashCoreHints;
    }

    /**
     * @notice The hints to optimize the execute slash.
     * @param slashingDataHint The hint to optimize the slashing data fetching.
     * @param executeSlashCoreHints The hints to optimize the execute slash core.
     */
    struct ExecuteSlashHints {
        bytes slashingDataHint;
        bytes executeSlashCoreHints;
    }

    /**
     * @notice Emitted when the slasher is set.
     * @param slasher The address of the slasher.
     */
    event SetSlasher(address slasher);

    /**
     * @notice Emitted when the instant slash is executed.
     * @param slasher The address of the slasher.
     * @param operator The address of the operator.
     * @param success The success of the slash.
     * @param slashedAmount The amount of the slashed tokens.
     */
    event InstantSlash(address indexed slasher, address indexed operator, bool indexed success, uint256 slashedAmount);

    /**
     * @notice Emitted when the veto slash is executed.
     * @param slasher The address of the slasher.
     * @param operator The address of the operator.
     * @param success The success of the slash.
     * @param slashIndex The index of the slash.
     */
    event VetoSlash(address indexed slasher, address indexed operator, bool indexed success, uint256 slashIndex);

    /**
     * @notice Emitted when the slash is executed.
     * @param slasher The address of the slasher.
     * @param slashIndex The index of the slash.
     * @param success The success of the slash.
     * @param slashedAmount The amount of the slashed tokens.
     */
    event ExecuteSlash(
        address indexed slasher, uint256 indexed slashIndex, bool indexed success, uint256 slashedAmount
    );

    /**
     * @notice Returns the address of the slasher.
     * @return The address of the slasher.
     */
    function getSlasher() external view returns (address);

    /**
     * @notice Sets the slasher.
     * @param slasher The address of the slasher.
     * @dev The caller must have the needed permission.
     */
    function setSlasher(
        address slasher
    ) external;

    /**
     * @notice Slashes the vault.
     * @param timestamp The capture timestamp for the slash.
     * @param vault The address of the vault.
     * @param operator The address of the operator.
     * @param amount The amount of the tokens to be slashed.
     * @param hints The hints to optimize the vault slashing.
     * @return success The success of the slash.
     * @return response The response of the slash.
     * @dev The function checks the registration statuses of the operator, the vault, and the vault's collateral.
     */
    function slashVault(
        uint48 timestamp,
        address vault,
        address operator,
        uint256 amount,
        bytes memory hints
    ) external returns (bool success, bytes memory response);

    /**
     * @notice Slashes the vault.
     * @param timestamp The capture timestamp for the slash.
     * @param vault The address of the vault.
     * @param operator The address of the operator.
     * @param amount The amount of the tokens to be slashed.
     * @param hints The hints to optimize the vault slashing.
     * @return success The success of the slash.
     * @return response The response of the slash.
     * @dev The function doesn't check the registration statuses.
     */
    function slashVaultUnsafe(
        uint48 timestamp,
        address vault,
        address operator,
        uint256 amount,
        bytes memory hints
    ) external returns (bool success, bytes memory response);

    /**
     * @notice Executes the slash of the vault.
     * @param vault The address of the vault.
     * @param slashIndex The index of the slash.
     * @param hints The hints to optimize the vault slashing.
     * @return success The success of the slash.
     * @return slashedAmount The amount of the slashed tokens.
     */
    function executeSlashVault(
        address vault,
        uint256 slashIndex,
        bytes memory hints
    ) external returns (bool success, uint256 slashedAmount);
}
