# RewardsHook Contract


## Features

1. **Donation Handling**:
   - Users can donate reward tokens with a specified duration for distribution.
   - Donations are tracked with details such as token, amount, reward rate, and distribution period.

2. **Reward Accrual**:
   - Rewards are accrued over time and distributed proportionally to borrowers based on their share of the total borrowed amount.

3. **Borrowing and Repayment**:
   - Rewards are calculated and distributed before borrowing or repaying.
   - Borrowed amounts and reward debts are updated accordingly.

4. **Claiming Rewards**:
   - Borrowers can claim their accrued rewards at any time.

5. **Donation Limit**:
   - A maximum number of donations is enforced to ensure gas efficiency.

## Interfaces

- **IMarketHooks**:
  - Called by the Market contract before and after borrowing or repaying.

- **IDonatable**:
  - Allows donations of reward tokens with a specified amount and duration.

- **IRewardable**:
  - Enables borrowers to claim rewards based on their borrowing activity.

## Example Usage

- Donate 1,000 USDC to be distributed over 1 week.
- Borrowers accrue rewards based on their share of the total borrowed amount.
- Borrowers can claim their rewards at any time.

## Events

- `Donate`: Emitted when a donation is made.
- `BeforeBorrow` and `AfterRepay`: Emitted during borrowing and repayment.
- `ClaimRewards`: Emitted when rewards are claimed.

## Installation

1. Clone the repository.
2. Install dependencies:
   ```bash
   npm install

## Test 
npx hardhat test