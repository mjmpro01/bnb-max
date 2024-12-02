// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BNBMAXSimple {
    mapping(address => uint256) public stakes;
    uint256 public totalStaked;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function stake() public payable {
        require(msg.value > 0, "Must stake some BNB");
        stakes[msg.sender] += msg.value;
        totalStaked += msg.value;
        emit Staked(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(stakes[msg.sender] >= amount, "Insufficient stake");
        stakes[msg.sender] -= amount;
        totalStaked -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getStake(address user) public view returns (uint256) {
        return stakes[user];
    }
}