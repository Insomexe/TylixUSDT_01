// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract TylixUSDT {
	string public name = "Tylix USDT";
	string public symbol = "USDT";
	uint256 public totalSupply;
	uint8 public decimals = 18;
	address public owner; 
	address public liquidityWallet;
	uint256 public taxFee = 3;
}

mapping(address => uint256) private balances;
mapping(address => mapping(address => uint256)) private allowances;
mapping(address => bool) private blacklist;
mapping(address => uint256) private nonces;

struct Log{
	string action;
	address account;
	uint256 amount;
	uint256 timestamp;
}
Log[] private logs;

bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner, address spender, uint256 value, uint256 nonce, uint256 deadline")
event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed owner, address indexed spender, uint256 value);
event Blacklisted(address indexed account, bool value);
event Mint(address indexed minter, address indexed recipient, uint256amount);
event Burn(address indexed burner, uint256 amount);
event LogAction(string action, address indexed account, uint256 timestamp);

modifier onlyOwnner() {
	require(msg.sender == owner, "Ownable: caller is not the owner");
	_;
}

constructor(address _liquidityWallet) {
	owner = msg.sender;
	liquidityWallet = _liquidityWallet;
	totalSupply = 1000000 * 10 ** uint256(decimals);
	balances[owner] = totalSupply;
}

function balanceOf(address account) public view returns (uint256) {
	return balances[account];
}

function transfer(address recipient, uint256 amount) public returns (bool) {
	require(!blacklist[msg.sender], "Sender is blacklisted");
	require(balances[msg.sender] >= amount, "Insufficient balance");
	uint256 feeAmount = (amount * taxFee) / 100;
	uint256 transferAmount = amount - feeAmount;
	balances[msg.sender] -= amount;
	balances[liquidityWalet] += feeAmount;
	balances[recipient] += transferAmount;
	emit Transfer(msg.sender, liquidityWallet, feeAmount);
	emit Transfer(msg.sender, recipient, transferAmount);
	logAction("Transfer", msg.sender, amount);
	return true;
}

function approve(address spender, uint256 amount) public returns (bool) {
	allowances[msg.sender][spender] = amount;
	emit Approval(msg.sender, spender, amount);
}

function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
	require(!blacklist[sender], "Sender is Blacklisted");
	require(balances[sender] >= amount, "Insufficient balance");
	require(allowances[sender][msg.sender] >= amount, "Allowance exceeded");
	uint256 feeAmount = (amount * taxFee) / 100;
	uint256 transferAmount = amount - feeAmount;
	balances[sender] -= amount;
	balances[liquidityWallet] += feeAmount; 
	balances[recipient] += transferAmount;
	allowances[sender][msg.sender] -= amount;
	emit Transfer(sender, liquidtyWallet, feeAmount);
	emit Transfer(sender, recipient, trasnferAmount);
	logAction("TransferFrom", sender, amount);
	return true;
}

function setBlacklist(address account, bool value) external onlyOwner {
	blacklist[account] = value;
	emit Blacklisted(account, value);
	log
}

function permit(adress ownerAddr, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external{
	require(block.timestamp <= deadline, "Permit expired");
	bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, ownerAddr, spender, value, nonces[ownerAddr]++, deadline));
	bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message: \32", structhHash));
	address signer = ecrecover(digest, v, r, s);
	require(signer == ownerAddr, "Invalid signature");
	allowances[ownerAddr][spender] = value;
	emit Approval(ownerAddr, spender, value);
}

function mint(address recipient, uint256 amount) external onlyOwner {
	require(recipient != address(0), "Invalid address");
	totalSupply += amount;
	balances[recipient] += amount;
	emit Mint(msg.sender, recipient, amount);
	emit Transfer(address(0), recipient, amount);
	logAction("Mint", recipient, amount);
}

function burn(uint256 amount) external {
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


 

  