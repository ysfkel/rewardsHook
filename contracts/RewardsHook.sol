pragma solidity ^0.8.28;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IRewardsHook {
    function beforeBorrow(address user, uint256 amount) external;
    function afterRepay(address user, uint256 amount) external;
    function claimRewards(address user) external;
}

contract RewardsHook {
    error RewardsHook__ZeroAmount();
    error RewardsHook__ZeroAddress();
    error RewardsHook__RepayExceedsBorrowedAmount();
    error RewardsHook__InvalidDistributionWindow();
    error RewardsHook__MaxDonationsReached();

    struct Donation {
        address token;
        uint256 amount;
        uint256 rewardRate;
        uint256 startTime;
        uint256 endTime;
        uint256 accRewardPerBorrowedAmount;
        uint256 lastUpdate;
    }

    event Donate(
        address indexed donor, address indexed token, uint256 amount, uint256 rewardRate, uint256 start, uint256 end
    );

    event BeforeBorrow(address user, uint256 amount);

    event AfterRepay(address user, uint256 amount);

    event ClaimRewards(address indexed user, address indexed token, uint256 indexed donationId, uint256 amount);

    uint256 public constant PRECISION = 1e12;
    uint256 public totalBorrowedAmount;
    uint256 public maxDonations;
    Donation[] public donations;

    mapping(address user => uint256 borrowedAmount) public userBorrowedAmount;
    mapping(address user => mapping(uint256 donationId => uint256 rewardDebt)) public userRewardDebt;

    constructor(uint256 _maxDonations) {
        maxDonations = _maxDonations;
    }
    
    /**
     * @notice Donate a reward amount.
     *
     * @param token The token to donate.
     * @param amount The amount of the reward to donate.
     * @param distributionWindow The window (in seconds) to distribute the reward amount.
     */
    function donate(address token, uint256 amount, uint256 distributionWindow) external {
        require(donations.length <= maxDonations, RewardsHook__MaxDonationsReached());
        require(amount > 0, RewardsHook__ZeroAmount());
        require(distributionWindow > 0, RewardsHook__InvalidDistributionWindow());
        require(address(0) != token, RewardsHook__ZeroAddress());

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        uint256 start = block.timestamp;
        uint256 end = start + distributionWindow;
        uint256 rate = amount / distributionWindow;

        donations.push(
            Donation({
                token: token,
                amount: amount,
                rewardRate: rate,
                startTime: start,
                endTime: end,
                accRewardPerBorrowedAmount: 0,
                lastUpdate: start
            })
        );

        emit Donate(msg.sender, token, amount, rate, start, end);
    }

    /**
     * @notice Accrue rewards per borrowed amount for the given donation.
     *
     * @param donationId The ID of the donation to accrue rewards for.
     */
    function accRewardPerBorrowedAmount(uint256 donationId) internal {
        Donation memory d = donations[donationId];
        // check  we've already updated this donation up to this point in time, so no additional rewards have accrued since last update
        // check Means the donation hasn't started yet. No rewards should accrue before startTime
        if (block.timestamp <= d.lastUpdate || block.timestamp <= d.startTime) return;

        uint256 from = d.lastUpdate < d.startTime ? d.startTime : d.lastUpdate;
        uint256 to = block.timestamp < d.endTime ? block.timestamp : d.endTime;

        if (to <= from) return;

        uint256 elapsed = to - from;
        uint256 reward = d.rewardRate * elapsed;

        if (totalBorrowedAmount > 0) {
            d.accRewardPerBorrowedAmount += (reward * PRECISION) / totalBorrowedAmount;
        }
        d.lastUpdate = block.timestamp;
        donations[donationId] = d;
    }

    /**
     * @notice Increases users borrow balance and accrue rewards and cliams rewards for the current period for the user.
     *
     * @param user User to claim rewards for.
     * @param amount Amount to borrow.
     */
    function beforeBorrow(address user, uint256 amount) external {
        require(amount > 0, RewardsHook__ZeroAmount());
        require(address(0) != user, RewardsHook__ZeroAddress());

        uint256 borrowedAmount = userBorrowedAmount[user];
        mapping(uint256 donationIndex => uint256 rewardDebt) storage rewardDebts = userRewardDebt[user];

        // accrue rewards per borrowed amount for each donation
        // send accrued rewards to user
        // updare user reward debt
        uint256 len = getDonationCount();
        for (uint256 i = 0; i < len; i++) {
            accRewardPerBorrowedAmount(i);
            uint256 rewardDebt = rewardDebts[i];
            Donation memory d = getDonation(i);

            uint256 accumulated = (borrowedAmount * d.accRewardPerBorrowedAmount) / PRECISION;
            uint256 reward = accumulated > rewardDebt ? accumulated - rewardDebt : 0;

            if (reward > 0) {
                IERC20(d.token).transfer(user, reward);
                emit ClaimRewards(user, d.token, i, reward);
            }
            // Update rewardDebt based on the new borrowned amount
            rewardDebts[i] = ((borrowedAmount + amount) * d.accRewardPerBorrowedAmount) / PRECISION;
        }

        userBorrowedAmount[user] += amount;
        totalBorrowedAmount += amount;

        emit BeforeBorrow(user, amount);
    }

    /**
     * @notice Decreases users borrow balance and accrue rewards and cliams rewards for the current period for the user.
     *
     * @param user User to claim rewards for.
     * @param amount Amount to repay.
     */
    function afterRepay(address user, uint256 amount) external {
        require(amount > 0, RewardsHook__ZeroAmount());
        require(address(0) != user, RewardsHook__ZeroAddress());

        uint256 borrowedAmount = userBorrowedAmount[user];
        require(borrowedAmount >= amount, RewardsHook__RepayExceedsBorrowedAmount());

        mapping(uint256 donationIndex => uint256 rewardDebt) storage rewardDebts = userRewardDebt[user];
        // accrue rewards per borrowed amount for each donation
        // send accrued rewards to user
        // updare user reward debt
        uint256 len = getDonationCount();
        for (uint256 i = 0; i < len; i++) {
            accRewardPerBorrowedAmount(i);
            uint256 rewardDebt = rewardDebts[i];
            Donation memory d = getDonation(i);

            uint256 accumulated = (borrowedAmount * d.accRewardPerBorrowedAmount) / PRECISION;
            uint256 reward = accumulated > rewardDebt ? accumulated - rewardDebt : 0;

            if (reward > 0) {
                IERC20(d.token).transfer(user, reward);
                emit ClaimRewards(user, d.token, i, reward);
            }
            // Update rewardDebt based on the new borrowed amount
            rewardDebts[i] = ((borrowedAmount - amount) * d.accRewardPerBorrowedAmount) / PRECISION;
        }

        userBorrowedAmount[user] -= amount;
        totalBorrowedAmount -= amount;
        emit AfterRepay(user, amount);
    }

    /**
     * @notice Claim any accrued rewards for the given account.
     *
     * @param user The account to claim the accrued rewards for.
     */
    function claimRewards(address user) external {
        uint256 borrowedAmount = userBorrowedAmount[user];
        mapping(uint256 donationIndex => uint256 rewardDebt) storage rewardDebts = userRewardDebt[user];

        uint256 len = getDonationCount();
        for (uint256 i = 0; i < len; i++) {
            accRewardPerBorrowedAmount(i);
            uint256 rewardDebt = rewardDebts[i];
            Donation memory d = getDonation(i);

            uint256 accumulated = (borrowedAmount * d.accRewardPerBorrowedAmount) / PRECISION;
            uint256 reward = accumulated > rewardDebt ? accumulated - rewardDebt : 0;

            if (reward > 0) {
                IERC20(d.token).transfer(user, reward);
                emit ClaimRewards(user, d.token, i, reward);
            }
            // Update rewardDebt based on the new borrowed amount
            rewardDebts[i] = accumulated;
        }
    }

    function getDonation(uint256 donationId) public view returns (Donation memory) {
        return donations[donationId];
    }

    function getUserRewardDebt(address user, uint256 donationId) external view returns (uint256) {
        return userRewardDebt[user][donationId];
    }

    function getUserBorrowedAmount(address user) external view returns (uint256) {
        return userBorrowedAmount[user];
    }

    function getDonationCount() public view returns (uint256) {
        return donations.length;
    }
}
