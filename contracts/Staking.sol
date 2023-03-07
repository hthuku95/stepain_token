// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Staking is ReentrancyGuard { 
    uint256 private constant UNLOCK_PERIOD = 1 days;
    uint256 private constant MIN_STAKE_AMOUNT = 1000 ether;

    uint256 public constant STAKING_DURATION_60DAYS = 60 days;
    uint256 public constant STAKING_DURATION_120DAYS = 120 days;
    uint256 public constant STAKING_DURATION_150DAYS = 150 days;
    uint256 public constant STAKING_DURATION_180DAYS = 180 days;

    uint256[] stakingDurations = [
        STAKING_DURATION_60DAYS,
        STAKING_DURATION_120DAYS,
        STAKING_DURATION_150DAYS,
        STAKING_DURATION_180DAYS
    ];

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _lastClaimTime;
    mapping(address => uint256) private _lockTime;

    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    event RewardClaimed(address indexed account, uint256 amount);

    // Stake
    function stake(uint256 amount, uint256 stakingPeriod) public payable nonReentrant{
        require(msg.value >= MIN_STAKE_AMOUNT, "Minimum stake amount not met");
        require(msg.value == amount, "Amount sent does not match the expected amount.");

        bool validStakingPeriod = false;
        for (uint stakingDurationIndex = 0; stakingDurationIndex < stakingDurations.length; stakingDurationIndex++) {
            if (stakingDurations[stakingDurationIndex] == stakingPeriod) {
                validStakingPeriod = true;
                break;
            }
        }
        require(validStakingPeriod, "Invalid staking period");

        address account = msg.sender;

        _balances[account] += amount;
        _lockTime[account] = block.timestamp + stakingPeriod;

        emit Staked(account, amount);
    }

    // Unstake
    function unstake() public nonReentrant{
        address account = msg.sender;

        require(balanceOf(account) > 0, "No stake to withdraw");
        require(block.timestamp >= lockTime(account), "Stake is still locked");

        uint256 amount = _balances[account];
        uint256 finalUnstakeAmount = _calculateUnstakeFee(amount);
        _balances[account] = 0;

        payable(account).transfer(finalUnstakeAmount);

        emit Unstaked(account, amount);
    }

    // Calculating the Unstake Fee
    function _calculateUnstakeFee(uint256 amount) internal pure returns(uint256) {
       uint256 unstakeFee = (amount * 15) / 100;
       uint256 finalUnstakeAmount = amount - unstakeFee;
       return finalUnstakeAmount;
    }

    // Claim Reward
    function claimReward() public nonReentrant{
        address account = msg.sender;

        require(balanceOf(account) > 0, "No stake to claim rewards");
        require(block.timestamp >= lastClaimTime(account) + UNLOCK_PERIOD, "Cannot claim rewards yet");

        uint256 reward = (balanceOf(account) * 3) / 100;
        _lastClaimTime[account] = block.timestamp;

        payable(account).transfer(reward);

        emit RewardClaimed(account, reward);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function lastClaimTime(address account) public view returns (uint256) {
        return _lastClaimTime[account];
    }

    function lockTime(address account) public view returns (uint256) {
        return _lockTime[account];
    }
}