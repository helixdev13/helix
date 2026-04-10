// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";

contract RewardDistributor is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable STAKING_TOKEN;
    IERC20 public immutable REWARD_TOKEN;

    uint256 public rewardsDuration = 7 days;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDurationTotal;
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(
        address stakingToken_,
        address rewardToken_,
        address initialOwner
    ) Ownable(initialOwner) {
        if (stakingToken_ == address(0) || rewardToken_ == address(0)) {
            revert Errors.ZeroAddress();
        }

        STAKING_TOKEN = IERC20(stakingToken_);
        REWARD_TOKEN = IERC20(rewardToken_);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) external view returns (uint256) {
        return _balances[account];
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }

        return rewardPerTokenStored + (
            (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / _totalSupply
        );
    }

    function earned(
        address account
    ) public view returns (uint256) {
        return (
            _balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18
        ) + rewards[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    function stake(
        uint256 amount
    ) external nonReentrant updateReward(msg.sender) {
        if (amount == 0) {
            revert Errors.ZeroAmount();
        }

        _totalSupply += amount;
        _balances[msg.sender] += amount;
        STAKING_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(
        uint256 amount
    ) external nonReentrant updateReward(msg.sender) {
        if (amount == 0) {
            revert Errors.ZeroAmount();
        }

        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        STAKING_TOKEN.safeTransfer(msg.sender, amount);
    }

    function claimRewards() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward != 0) {
            rewards[msg.sender] = 0;
            REWARD_TOKEN.safeTransfer(msg.sender, reward);
            emit Events.RewardDistributed(msg.sender, reward);
        }
    }

    function exit() external nonReentrant updateReward(msg.sender) {
        uint256 amount = _balances[msg.sender];
        if (amount != 0) {
            _totalSupply -= amount;
            _balances[msg.sender] = 0;
            STAKING_TOKEN.safeTransfer(msg.sender, amount);
        }

        uint256 reward = rewards[msg.sender];
        if (reward != 0) {
            rewards[msg.sender] = 0;
            REWARD_TOKEN.safeTransfer(msg.sender, reward);
            emit Events.RewardDistributed(msg.sender, reward);
        }
    }

    function notifyRewardAmount(
        uint256 reward
    ) external onlyOwner updateReward(address(0)) {
        if (reward == 0) {
            revert Errors.ZeroAmount();
        }

        REWARD_TOKEN.safeTransferFrom(msg.sender, address(this), reward);

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        rewardsDurationTotal += reward;
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;

        emit Events.RewardDistributed(address(this), reward);
    }

    function setRewardsDuration(
        uint256 newDuration
    ) external onlyOwner {
        if (block.timestamp < periodFinish) {
            revert Errors.DeadlineExpired(block.timestamp, periodFinish);
        }

        rewardsDuration = newDuration;
    }

    modifier updateReward(
        address account
    ) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
}
