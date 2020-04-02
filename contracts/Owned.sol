pragma solidity ^0.5.16;

contract Owned {
  address public owner;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  constructor() public {
    owner = msg.sender;
  }
}