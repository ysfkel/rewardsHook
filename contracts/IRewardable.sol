// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

interface IRewardable {
  event ClaimRewards(
    address indexed account,
    address indexed token,
    address indexed receiver,
    uint256 amount,
    address caller
  );

  /**
   * @notice Returns the underlying reward tokens.
   */
  function getRewardTokens() external view returns (address[] memory);

  /**
   * @notice Claim any accrued rewards for the given account.
   *
   * @param account The account to claim the accrued rewards for.
   * @param tokens The tokens to claim.
   * @param amounts The amounts to claim.
   *
   * @return amounts The amounts for the tokens that were claimed.
   */
  function claimRewards(
    address account,
    address[] memory tokens,
    uint256[] memory amounts
  ) external returns (uint256[] memory);

  /**
   * @notice Returns the total claimable rewards for the account.
   *
   * @param account The account to return the claimable rewards for.
   *
   * @return tokens The list of tokens that have rewards.
   * @return amounts The amount of the reward for the tokens.
   */
  function getClaimableRewards(
    address account
  ) external view returns (address[] memory tokens, uint256[] memory amounts);
}
