// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

interface IDonatable {
  event Donate(address indexed caller, address indexed token, uint256 amount, uint256 rate, uint40 start, uint40 end);

  /**
   * @notice Donate a reward amount.
   *
   * @param token The token to donate.
   * @param amount The amount of the reward to donate.
   * @param distributionWindow The window (in seconds) to distribute the reward amount.
   */
  function donate(address token, uint256 amount, uint40 distributionWindow) external;
}


// 