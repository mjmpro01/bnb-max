// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EnhancedStaking is ReentrancyGuard, Ownable, Pausable {
    using SafeMath for uint256;

    address public stakingWallet;
    mapping(address => uint256) public stakes;
    uint256 public totalStaked;
    uint256 public minStakeAmount;
    uint256 public maxStakeAmount;
    uint256 public cooldownPeriod;
    mapping(address => uint256) public lastWithdrawalTime;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event StakingWalletChanged(address indexed oldWallet, address indexed newWallet);
    event MinStakeAmountChanged(uint256 oldAmount, uint256 newAmount);
    event MaxStakeAmountChanged(uint256 oldAmount, uint256 newAmount);
    event CooldownPeriodChanged(uint256 oldPeriod, uint256 newPeriod);

    constructor(address _stakingWallet) Ownable(_stakingWallet) {
        require(_stakingWallet != address(0), "Invalid staking wallet address");
        stakingWallet = _stakingWallet;
        minStakeAmount = 0.05 ether;
        maxStakeAmount = 100 ether;
        cooldownPeriod = 1 days;
    }

    function stake() public payable nonReentrant whenNotPaused {
        require(msg.value >= minStakeAmount, "Stake amount too low");
        require(msg.value <= maxStakeAmount, "Stake amount too high");
        require(stakes[msg.sender].add(msg.value) <= maxStakeAmount, "Total stake exceeds maximum");

        stakes[msg.sender] = stakes[msg.sender].add(msg.value);
        totalStaked = totalStaked.add(msg.value);
        
        (bool success, ) = payable(stakingWallet).call{value: msg.value}("");
        require(success, "Failed to transfer stake to staking wallet");

        emit Staked(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public nonReentrant whenNotPaused {
        require(stakes[msg.sender] >= amount, "Insufficient stake");
        require(block.timestamp >= lastWithdrawalTime[msg.sender].add(cooldownPeriod), "Cooldown period not met");

        stakes[msg.sender] = stakes[msg.sender].sub(amount);
        totalStaked = totalStaked.sub(amount);
        lastWithdrawalTime[msg.sender] = block.timestamp;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send BNB");

        emit Withdrawn(msg.sender, amount);
    }

    function getStake(address user) public view returns (uint256) {
        return stakes[user];
    }

    function changeStakingWallet(address newWallet) public onlyOwner {
        require(newWallet != address(0), "Invalid new staking wallet address");
        address oldWallet = stakingWallet;
        stakingWallet = newWallet;
        emit StakingWalletChanged(oldWallet, newWallet);
    }

    function setMinStakeAmount(uint256 newAmount) public onlyOwner {
        require(newAmount < maxStakeAmount, "Min amount must be less than max amount");
        uint256 oldAmount = minStakeAmount;
        minStakeAmount = newAmount;
        emit MinStakeAmountChanged(oldAmount, newAmount);
    }

    function setMaxStakeAmount(uint256 newAmount) public onlyOwner {
        require(newAmount > minStakeAmount, "Max amount must be greater than min amount");
        uint256 oldAmount = maxStakeAmount;
        maxStakeAmount = newAmount;
        emit MaxStakeAmountChanged(oldAmount, newAmount);
    }

    function setCooldownPeriod(uint256 newPeriod) public onlyOwner {
        uint256 oldPeriod = cooldownPeriod;
        cooldownPeriod = newPeriod;
        emit CooldownPeriodChanged(oldPeriod, newPeriod);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    receive() external payable {
        stake();
    }
}

