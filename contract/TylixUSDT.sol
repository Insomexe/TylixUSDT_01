// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract TylixUSDT {
    string public name = "Tylix USDT";
    string public symbol = "USDT";
    uint256 public totalSupply;
    uint8 public decimals = 18;
    address public owner;
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) private blacklist;
    mapping(address => uint256) private nonces;
    bool private locked;

    struct Log {
        string action;
        address account;
        uint256 amount;
        uint256 timestamp;
    }
    Log[] private logs;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Blacklisted(address indexed account, bool value);
    event Mint(address indexed minter, address indexed recipient, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event LogAction(string action, address indexed account, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier nonReentrant() {
        require(!locked, "ReentrancyGuard: reentrant call");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        require(owner == address(0), "Contract already initialized");
        owner = msg.sender;
        totalSupply = 1000000 * 10 ** uint256(decimals);
        balances[owner] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(!blacklist[msg.sender], "Sender is blacklisted");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        logAction("Transfer", msg.sender, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public nonReentrant returns (bool) {
        require(!blacklist[sender], "Sender is blacklisted");
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Allowance exceeded");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        logAction("TransferFrom", sender, amount);
        return true;
    }

    function setBlacklist(address account, bool value) external onlyOwner {
        blacklist[account] = value;
        emit Blacklisted(account, value);
        logAction("Blacklist", account, value ? 1 : 0);
    }

    function mint(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Invalid address");

        totalSupply += amount;
        balances[recipient] += amount;

        emit Mint(msg.sender, recipient, amount);
        emit Transfer(address(0), recipient, amount);
        logAction("Mint", recipient, amount);
    }

    function burn(uint256 amount) external nonReentrant {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
        logAction("Burn", msg.sender, amount);
    }

    function getLogs() external view returns (Log[] memory) {
        return logs;
    }

    function logAction(string memory action, address account, uint256 amount) internal {
        logs.push(Log(action, account, amount, block.timestamp));
        emit LogAction(action, account, block.timestamp);
    }
}