//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.28;

interface IMarketHooks {   
  struct BorrowHookParams {
    address account;
    uint256 amount; // the amount that is being borrowed
    uint256 liabilities; // the total liabilities for the account at the time of the hook all
    uint256 totalLiabilities; // the total liabilities for the market as a whole
  }

  struct RepayHookParams {
    address account;
    uint256 amount; // the amount that is being borrowed
    uint256 liabilities; // the total liabilities for the account at the time of the hook all
    uint256 totalLiabilities; // the total liabilities for the market as a whole
  } 

  /**
   * @notice Called before the account borrows from the market.
   *
   * @param params The parameters that the operation is being executed with.
   *
   * @return bytes The data to pass to the afterBorrow hook.
   */
  function beforeBorrow(BorrowHookParams memory params) external returns (bytes memory);

  /**
   * @notice Called after the user has borrowed.
   *
   * @param params The parameters that the operation is being executed with.
   * @param data The context data from the beforeBorrow call.
   */
  function afterBorrow(BorrowHookParams memory params, bytes memory data) external;

  /**
   * @notice Called before the account repays to the market.
   *
   * @param params The parameters that the operation is being executed with.
   *
   * @return bytes The data to pass to the afterRepay hook.
   */
  function beforeRepay(RepayHookParams memory params) external returns (bytes memory);

  /**
   * @notice Called after the user has repaid.
   *
   * @param params The parameters that the operation is being executed with.
   * @param data The context data from the beforeRepay call.
   */
  function afterRepay(RepayHookParams memory params, bytes memory data) external; 
}
