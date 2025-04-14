# Challenge

Implement the RewardsHook contract which tracks reward tokens that can be issued to borrowers depending on their share of the total liabilities that have been borrowed.

## IMarketHooks

The `IMarketHooks` interface will be called by the Market contract prior to borrowing and repaying and after borrowing and repaying.

## IDonatable

The `IDonatable` interface will be called on the RewardsHook contract in order to donate a reward token. A donation occurs through an amount of tokens and a duration in seconds in which those tokens should be distributed. For example, donate 1,000 USDC over 1 week.

## IRewardable

The `IRewardable` contract is used by accounts to claim the rewards that they are entitled to based on how much they have been borrowing.
