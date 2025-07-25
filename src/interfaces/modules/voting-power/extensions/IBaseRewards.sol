// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseRewards {
    /**
     * @notice Reverts when the new rewarder is zero address.
     */
    error BaseRewards_InvalidRewarder();

    /**
     * @notice Reverts when the caller is not the rewarder.
     */
    error BaseRewards_NotRewarder();

    /**
     * @notice The storage of the BaseRewards contract.
     * @param _rewarder The address of the rewarder.
     * @custom:storage-location erc7201:symbiotic.storage.BaseRewards
     */
    struct BaseRewardsStorage {
        address _rewarder;
    }

    /**
     * @notice The parameters for the initialization of the BaseRewards contract.
     * @param rewarder The address of the rewarder.
     */
    struct BaseRewardsInitParams {
        address rewarder;
    }

    /**
     * @notice Emitted when the rewarder is set.
     * @param rewarder The address of the rewarder.
     */
    event SetRewarder(address rewarder);

    /**
     * @notice Emitted when the staker rewards are distributed.
     * @param stakerRewards The address of the staker rewards.
     * @param token The address of the token.
     * @param amount The amount of the token.
     * @param data The data (depends on the staker rewards implementation).
     */
    event DistributeStakerRewards(address indexed stakerRewards, address indexed token, uint256 amount, bytes data);

    /**
     * @notice Emitted when the operator rewards are distributed.
     * @param operatorRewards The address of the operator rewards.
     * @param token The address of the token.
     * @param amount The amount of the token.
     * @param root The Merkle root of the distribution.
     */
    event DistributeOperatorRewards(
        address indexed operatorRewards, address indexed token, uint256 amount, bytes32 root
    );

    /**
     * @notice Returns the address of the rewarder.
     * @return The address of the rewarder.
     */
    function getRewarder() external view returns (address);

    /**
     * @notice Sets the rewarder.
     * @param rewarder The address of the rewarder.
     * @dev The caller must have the needed permission.
     */
    function setRewarder(
        address rewarder
    ) external;

    /**
     * @notice Distributes the staker rewards.
     * @param stakerRewards The address of the staker rewards.
     * @param token The address of the token.
     * @param amount The amount of the token.
     * @param data The data (depends on the staker rewards implementation).
     * @dev Only the rewarder can call this function.
     *      The funds should be transferred to this contract separately before the call.
     */
    function distributeStakerRewards(
        address stakerRewards,
        address token,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @notice Distributes the operator rewards.
     * @param operatorRewards The address of the operator rewards.
     * @param token The address of the token.
     * @param amount The amount of the token.
     * @param root The Merkle root of the distribution.
     * @dev Only the rewarder can call this function.
     *      The funds should be transferred to this contract separately before the call.
     */
    function distributeOperatorRewards(address operatorRewards, address token, uint256 amount, bytes32 root) external;
}
