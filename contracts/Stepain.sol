// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Stepain is ERC20 {

    uint256 private initialSupply;
    uint256 private _maxTransferAmount = 4000000 * 10 ** decimals();

    address private constant _marketingFeeAddress = 0x6eF969580Bb4eA293878a713197B895BfDD82bbe;
    address private constant _charityFeeAddress = 0xc2ACF98406BE652AfB7b1274ab1eFCb3fd15f115;
    address private constant _liquidityFeeAddress = 0x9d48e287D30e509dbd1347C1e0a21e793Fa3c638;
    address private constant _taxFeeAddress = 0xfa1281d974fE922437F03817947246070eE898B1;
    address private constant _unstakeFeeAddress = 0xFb72e8d18a46144ae2D59fb1134F0128D99F153F;

    uint256 private _marketingFee = uint256(1) / uint256(2);
    uint256 private _charityFee = uint256(1) / uint256(2);
    uint256 private _liquidityFee = uint256(1) / uint256(2);
    uint256 private _taxFee = uint256(1) / uint256(2);
    uint256 private _unstakeFee = 15;
    uint256  private constant CLAIM_PERIOD = 15 days;

    // Anti-bot checker
    uint256 private constant MIN_TIME_DELAY = 120;

    // Auto-burn
    uint256 private constant MAX_BURN_PERCENTAGE = 25;
    uint256 private constant AUTOBURN_INTERVAL = 4 * 30 days; // 4 months
    uint256 private lastAutoburnTimestamp;

    mapping(address=>uint256) public stakingBalance;
    mapping(address=>uint256) public depositBalance;
    mapping(address => uint256) lastTransactionTimestamp;
    mapping(address => uint256) public lastClaimedTime;

    event Stake(address indexed user, uint256 amount);
    event Unstake(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event PayMarketingFee(address indexed user, uint256 amount);
    event PayCharityFee(address indexed user, uint256 amount);
    event PayLiquidityFee(address indexed user, uint256 amount);
    event PayTaxFee(address indexed user, uint256 amount);

    constructor() ERC20("STEPAIN", "MRC") {
        initialSupply = 400000000 * 10 ** decimals();
        _mint(msg.sender, initialSupply);
    }
    
    function getTaxFee() public view returns (uint256) {
        return _taxFee;
    }

    function getCharityFee() public view returns (uint256) {
        return _charityFee;
    }

    function getLiquidityFee() public view returns (uint256) {
        return _liquidityFee;
    }

    function getMarketingFee() public view returns (uint256) {
        return _marketingFee;
    }

    // Transfer
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(block.timestamp - lastTransactionTimestamp[msg.sender] >= MIN_TIME_DELAY, "You must wait before making another transaction");
        // Anti-whale
        require(_maxTransferAmount >= amount,"Amount exceeds maximum transfer limit");
        address owner = _msgSender();

        uint256 _finalTransferAmount = _payFees(owner,amount);

        _transfer(owner, to, _finalTransferAmount);
        lastTransactionTimestamp[msg.sender] = block.timestamp;
        return true;
    }

    // Transfer fees
    function _payFees(address _user,uint256 _amount) internal returns(uint256) {
        // Marketing fee
        uint256 marketingfee = (_amount * getMarketingFee()) / 100;
        _transfer(_user,_marketingFeeAddress,marketingfee);
        emit PayMarketingFee(_user,marketingfee);
        // Charity fee
        uint256 charityfee = (_amount * getCharityFee()) / 100;
        _transfer(_user,_charityFeeAddress,charityfee);
        emit PayCharityFee(_user,charityfee);
        // Liquidity fee
        uint256 liquidityfee = (_amount * getLiquidityFee()) / 100;
        _transfer(_user,_liquidityFeeAddress,liquidityfee);
        emit PayLiquidityFee(_user,liquidityfee);
        // Tax Fee
        uint256 taxfee = (_amount * getTaxFee()) / 100;
        _transfer(_user,_taxFeeAddress,taxfee);
        emit PayTaxFee(_user,taxfee);

        uint256 finalTransferAmount = _amount - (marketingfee + charityfee + liquidityfee + taxfee);
        return finalTransferAmount;
    }

    // Claim
    function claim() external {
        require(stakingBalance[msg.sender] > 0, "No staked balance");
        require(block.timestamp >= lastClaimedTime[msg.sender] + CLAIM_PERIOD, "Cannot claim yet");
        uint256 reward = stakingBalance[msg.sender] * 3 / 100;
        _mint(msg.sender,reward);
        lastClaimedTime[msg.sender] = block.timestamp;
    }
    
    // Stake
    function stakeTokens(uint256 _amount) public {
        require(block.timestamp - lastTransactionTimestamp[msg.sender] >= MIN_TIME_DELAY, "You must wait before making another transaction");
        require(_amount > 0,"Staking amount must be more than 0");
        require(balanceOf(msg.sender) >= _amount,"Staking amount is more than balance");
        _burn(msg.sender,_amount);
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;
        emit Stake(msg.sender,_amount);
        lastTransactionTimestamp[msg.sender] = block.timestamp;
    }

    // Unstake
    function unstakeTokens(uint256 _amount) public {
        uint256 balance = stakingBalance[msg.sender];
        require(block.timestamp - lastTransactionTimestamp[msg.sender] >= MIN_TIME_DELAY, "You must wait before making another transaction");
        require(balance > 0,"Your staking balance is 0");
        require(_amount > 0,"Unstaking amount must be more than 0");
        require(balance >= _amount,"Staking balance must be more than unstaking amount");
        uint256 unstakeFee = _amount * _unstakeFee / 100;
        _mint(_unstakeFeeAddress,unstakeFee);
        uint256 _unstakeAmount = _amount - _unstakeFee;
        _mint(msg.sender,_unstakeAmount);
        stakingBalance[msg.sender] = stakingBalance[msg.sender] - _amount;
        emit Unstake(msg.sender,_amount);
        lastTransactionTimestamp[msg.sender] = block.timestamp;
    }

    // Deposit
    function deposit() external payable {
        require(block.timestamp - lastTransactionTimestamp[msg.sender] >= MIN_TIME_DELAY, "You must wait before making another transaction");
        depositBalance[msg.sender] = depositBalance[msg.sender] + msg.value;
        emit Deposit(msg.sender,msg.value);
        lastTransactionTimestamp[msg.sender] = block.timestamp;
    }

    // Withdraw
    function withdraw(uint256 _amount) external {
        require(block.timestamp - lastTransactionTimestamp[msg.sender] >= MIN_TIME_DELAY, "You must wait before making another transaction");
        require(depositBalance[msg.sender] >= _amount, "Insufficient balance");
        depositBalance[msg.sender] = depositBalance[msg.sender] - _amount;
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Withdrawal failed");
        emit Withdraw(msg.sender,_amount);
        lastTransactionTimestamp[msg.sender] = block.timestamp;
    }

    function autoburn() public {
        require(block.timestamp >= lastAutoburnTimestamp + AUTOBURN_INTERVAL, "Autoburn interval not yet reached");
        
        uint256 burnAmount = (totalSupply() * 5) / 1000; // 0.5% of total supply
        
        if (burnAmount > (totalSupply() * MAX_BURN_PERCENTAGE) / 100) {
            burnAmount = (totalSupply() * MAX_BURN_PERCENTAGE) / 100; // limit to maximum autoburn percentage
        }
        
        _burn(msg.sender,burnAmount);
        lastAutoburnTimestamp = block.timestamp;
    }
}

/**
I will create a token smart contract with the following features :

- Transfer
- Anti-Whale
- deposit
- withdraw
- mint
- Staking
- Unstaking
- Anti-Bot
- Marketing Fee
- Charity Fee
- Liquidity Fee
- Tax Fee
- Claim token 3% Every 15days
- autoburn function 0,5% every 4 months maximum autoburn 25%.of total supply.
- add security protocols.
********
Token Name : STEPAIN
Symbol : MRC
decimals 18
Tokens in circulation 400.000.000 MRC
 */