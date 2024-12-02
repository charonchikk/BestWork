// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Cliker {

  struct User {
    string name;
    uint256 balance;
    uint256 clicks;
    uint256 clickMultiplier;
    uint256 withdrawableAmount;
    uint256 lastClickTime;
    address referrer; 
    bool registered;
  }

  mapping(address => User) public users;
    address public owner;
    uint256 public totalClicks;
    uint256 public registeredUsers;

    modifier onlyRegistered() {
    require(users[msg.sender].registered, "user ne zaregan");
    _;
    }

    modifier cooldownCheck(){
    require(block.timestamp >= users[msg.sender].lastClickTime + 10, "vrema no");
    _;
    }

    constructor() {
        owner = msg.sender;
    }

    event UserRegistered(address indexed user, string name, address indexed referrer);

    event Click(address indexed user, uint256 amountAdded);

    event Transfer(address indexed sender, address indexed receiver, uint256 amount);

    event UpgradePurchased(address indexed user, uint256 newMultiplier);

    event AdminWithdrawal(address indexed user, uint256 amount);

    function registerUser(string memory _name, address _referrer) public {
        require(!users[msg.sender].registered, "User yve est");

        users[msg.sender] = User(_name, 0, 0, 1, 0, 0, _referrer, true);
        totalClicks = totalClicks + users[msg.sender].clicks;

        registeredUsers++;

        emit UserRegistered(msg.sender, _name, _referrer);

        if (_referrer != address(0) && users[_referrer].registered) {
            users[_referrer].balance += 500;
        }
    }

    function click () public onlyRegistered cooldownCheck {
        User storage user = users[msg.sender];
        uint256 amountAdded;

        if (block.timestamp - user.lastClickTime >= 10) {
        amountAdded = user.clickMultiplier;
      
    } else {user.clickMultiplier *= 2;
      user.lastClickTime = block.timestamp;
       return; 
    }
        user.balance += amountAdded;
        user.clicks++;
        user.lastClickTime = block.timestamp;
        user.clickMultiplier = 1;

        totalClicks++;
        emit Click(msg.sender, amountAdded);
    }

    function transfer(address _recipient, uint256 _amount) public onlyRegistered  {
        require(users[msg.sender].balance >= _amount, "ne hvataet deneg");
        users[msg.sender].balance -= _amount;
        users[_recipient].balance += _amount;
        emit Transfer(msg.sender, _recipient, _amount);
    }

    function purhaseUpgrade () public onlyRegistered{
        uint256 upgradeCost = totalClicks / registeredUsers;
        require(registeredUsers > 0, "net polzovatela");
        require(users[msg.sender].balance >= upgradeCost, "ne hvataet deneg");
        users[msg.sender].balance -= upgradeCost;
        users[msg.sender].clickMultiplier++;
        emit UpgradePurchased(msg.sender, users[msg.sender].clickMultiplier);
    }

    function adminWithdraw (address userAddress, uint _amount) public onlyRegistered {
        require(msg.sender == owner, "Only owner tolka");
        require(users[userAddress].balance >= _amount, "ne hvataet deneg");
        users[userAddress].withdrawableAmount += _amount;
        users[userAddress].balance = 0;
        emit AdminWithdrawal(userAddress, _amount);
    }
}