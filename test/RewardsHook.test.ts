import  { expect } from "chai";
import { ethers } from "hardhat";

describe("RewardsHook", function () {
  let  rewardToken, rewardsHook;
  let owner, alice;
  // const donationAmount = ethers.parseEther("1000000");
  const donationAmount = BigInt(ethers.parseUnits("1000000", "ether").toString()); // Convert to BigInt
  const duration = BigInt(3600); // 1 hour

  beforeEach(async () => {
    [owner, alice] = await ethers.getSigners();

    console.log("Owner address:", owner.address);

    const RewardToken = await ethers.getContractFactory("RewardToken");
    const RewardsHook = await ethers.getContractFactory("RewardsHook");

    rewardToken = await RewardToken.deploy();
    rewardsHook = await RewardsHook.deploy(10);

    await rewardToken.mint(owner.address, donationAmount);
    await rewardToken.connect(owner).approve(rewardsHook.target, donationAmount);
  });

  it("should donate successfully", async () => {
    await rewardsHook.connect(owner).donate(rewardToken.target, donationAmount, duration);

    const donation = await rewardsHook.getDonation(0);
    const expectedRate = donationAmount / duration; // Use BigNumber division
    expect(await rewardsHook.getDonationCount()).to.equal(1);
    expect(donation.rewardRate).to.equal(expectedRate);
  });

  it("should accrue reward correctly after borrowing", async () => {
    await rewardsHook.connect(owner).donate(rewardToken.target, donationAmount, duration);
    await rewardsHook.connect(alice).beforeBorrow(alice.address, ethers.parseEther("100"));
    await ethers.provider.send("evm_increaseTime", [1800]); // 30 mins
    await ethers.provider.send("evm_mine");
    await rewardsHook.connect(alice).beforeBorrow(alice.address, ethers.parseEther("100"));
    const rewardDebt = await rewardsHook.getUserRewardDebt(alice.address, 0);
    const rewardBal = await rewardToken.balanceOf(alice.address);

    expect(rewardDebt.toString()).to.equal("1000555555555555400000000");
    expect(rewardBal.toString()).to.equal('500277777777777700000000');
  });

  it("should claim full reward after 2 hours", async () => {
    await rewardsHook.connect(owner).donate(rewardToken.target, donationAmount, duration);
    await rewardsHook.connect(alice).beforeBorrow(alice.address, ethers.parseEther("100"));
    await ethers.provider.send("evm_increaseTime", [7200]); // 2 hours
    await ethers.provider.send("evm_mine");
    await rewardsHook.connect(alice).claimRewards(alice.address);

    const rewardBal = await rewardToken.balanceOf(alice.address); 
  });
});
