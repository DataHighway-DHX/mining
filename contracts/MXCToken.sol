// Original Source: https://etherscan.io/address/0x5ca381bbfb58f0092df149bd3d243b08b9a8386e#contracts
// Modifications: Update to latest Solidity
pragma solidity ^0.5.16;

import "./lib/StandardToken.sol";

contract MXCToken is StandardToken {

  string public constant name = "MXCToken";
  string public constant symbol = "MXC";
  uint8 public constant decimals = 18;

  uint256 constant MONTH = 3600*24*30;

  struct TimeLock {
    // total amount of tokens that is granted to the user
    uint256 amount;

    // total amount of tokens that have been vested
    uint256 vestedAmount;

    // total amount of vested months (tokens are vested on a monthly basis)
    uint16 vestedMonths;

    // token timestamp start
    uint256 start;

    // token timestamp release start (when user can start receive vested tokens)
    uint256 cliff;

    // token timestamp release end (when all the tokens can be vested)
    uint256 vesting;

    address from;
  }

  mapping(address => TimeLock) timeLocks;

  event NewTokenGrant(address indexed _from, address indexed _to, uint256 _amount, uint256 _start, uint256 _cliff, uint256 _vesting);
  event VestedTokenRedeemed(address indexed _to, uint256 _amount, uint256 _vestedMonths);
  event GrantedTokenReturned(address indexed _from, address indexed _to, uint256 _amount);

  /**
  * @dev Constructor that gives msg.sender all of existing tokens.
  */
  constructor() public {
    totalSupply_ = 2664965800 * (10 ** uint256(decimals));
    balances[msg.sender] = totalSupply_;
    emit Transfer(address(0), msg.sender, totalSupply_);
  }

  function vestBalanceOf(address who)
    public view
    returns (uint256 amount, uint256 vestedAmount, uint256 start, uint256 cliff, uint256 vesting)
  {
    require(who != address(0));
    amount = timeLocks[who].amount;
    vestedAmount = timeLocks[who].vestedAmount;
    start = timeLocks[who].start;
    cliff = timeLocks[who].cliff;
    vesting = timeLocks[who].vesting;
  }

  /**
  * @dev Function to grant the amount of tokens that will be vested later.
  * @param _to The address which will own the tokens.
  * @param _amount The amount of tokens that will be vested later.
  * @param _start Token timestamp start.
  * @param _cliff Token timestamp release start.
  * @param _vesting Token timestamp release end.
  */
  function grantToken(
    address _to,
    uint256 _amount,
    uint256 _start,
    uint256 _cliff,
    uint256 _vesting
  )
    public
    returns (bool success)
  {
    require(_to != address(0));
    require(_amount <= balances[msg.sender], "Not enough balance to grant token.");
    require(_amount > 0, "Nothing to transfer.");
    require((timeLocks[_to].amount.sub(timeLocks[_to].vestedAmount) == 0), "The previous vesting should be completed.");
    require(_cliff >= _start, "_cliff must be >= _start");
    require(_vesting > _start, "_vesting must be bigger than _start");
    require(_vesting > _cliff, "_vesting must be bigger than _cliff");

    balances[msg.sender] = balances[msg.sender].sub(_amount);
    timeLocks[_to] = TimeLock(_amount, 0, 0, _start, _cliff, _vesting, msg.sender);

    emit NewTokenGrant(msg.sender, _to, _amount, _start, _cliff, _vesting);
    return true;
  }

  /**
  * @dev Function to grant the amount of tokens that will be vested later.
  * @param _to The address which will own the tokens.
  * @param _amount The amount of tokens that will be vested later.
  * @param _cliffMonths Token release start in months from now.
  * @param _vestingMonths Token release end in months from now.
  */
  function grantTokenStartNow(
    address _to,
    uint256 _amount,
    uint256 _cliffMonths,
    uint256 _vestingMonths
  )
    public
    returns (bool success)
  {
    return grantToken(
      _to,
      _amount,
      now,
      now.add(_cliffMonths.mul(MONTH)),
      now.add(_vestingMonths.mul(MONTH))
    );
  }

  /**
  * @dev Function to calculate the amount of tokens that can be vested at this moment.
  * @param _to The address which will own the tokens.
  * @return amount - A uint256 specifying the amount of tokens available to be vested at this moment.
  * @return vestedMonths - A uint256 specifying the number of the vested months since the last vesting.
  * @return curTime - A uint256 specifying the current timestamp.
  */
  function calcVestableToken(address _to)
    internal view
    returns (uint256 amount, uint256 vestedMonths, uint256 curTime)
  {
    uint256 vestTotalMonths;
    uint256 vestedAmount;
    uint256 vestPart;
    amount = 0;
    vestedMonths = 0;
    curTime = now;
    
    require(timeLocks[_to].amount > 0, "Nothing was granted to this address.");
    
    if (curTime <= timeLocks[_to].cliff) {
      return (0, 0, curTime);
    }

    vestedMonths = curTime.sub(timeLocks[_to].start) / MONTH;
    vestedMonths = vestedMonths.sub(timeLocks[_to].vestedMonths);

    if (curTime >= timeLocks[_to].vesting) {
      return (timeLocks[_to].amount.sub(timeLocks[_to].vestedAmount), vestedMonths, curTime);
    }

    if (vestedMonths > 0) {
      vestTotalMonths = timeLocks[_to].vesting.sub(timeLocks[_to].start) / MONTH;
      vestPart = timeLocks[_to].amount.div(vestTotalMonths);
      amount = vestedMonths.mul(vestPart);
      vestedAmount = timeLocks[_to].vestedAmount.add(amount);
      if (vestedAmount > timeLocks[_to].amount) {
        amount = timeLocks[_to].amount.sub(timeLocks[_to].vestedAmount);
      }
    }

    return (amount, vestedMonths, curTime);
  }

  /**
  * @dev Function to redeem tokens that can be vested at this moment.
  * @param _to The address which will own the tokens.
  */
  function redeemVestableToken(address _to)
    public
    returns (bool success)
  {
    require(_to != address(0));
    require(timeLocks[_to].amount > 0, "Nothing was granted to this address!");
    require(timeLocks[_to].vestedAmount < timeLocks[_to].amount, "All tokens were vested!");

    (uint256 amount, uint256 vestedMonths, uint256 curTime) = calcVestableToken(_to);
    require(amount > 0, "Nothing to redeem now.");

    TimeLock storage t = timeLocks[_to];
    balances[_to] = balances[_to].add(amount);
    t.vestedAmount = t.vestedAmount.add(amount);
    t.vestedMonths = t.vestedMonths + uint16(vestedMonths);
    t.cliff = curTime;

    emit VestedTokenRedeemed(_to, amount, vestedMonths);
    return true;
  }

  /**
  * @dev Function to return granted token to the initial sender.
  * @param _amount - A uint256 specifying the amount of tokens to be returned.
  */
  function returnGrantedToken(uint256 _amount)
    public
    returns (bool success)
  {
    address to = timeLocks[msg.sender].from;
    require(to != address(0));
    require(_amount > 0, "Nothing to transfer.");
    require(timeLocks[msg.sender].amount > 0, "Nothing to return.");
    require(_amount <= timeLocks[msg.sender].amount.sub(timeLocks[msg.sender].vestedAmount), "Not enough granted token to return.");

    timeLocks[msg.sender].amount = timeLocks[msg.sender].amount.sub(_amount);
    balances[to] = balances[to].add(_amount);

    emit GrantedTokenReturned(msg.sender, to, _amount);
    return true;
  }
}
