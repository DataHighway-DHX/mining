pragma solidity ^0.5.16;

/**
* @title ERC20
* @dev ERC Token Standard #20 Interface https://github.com/ethereum/EIPs/issues/20
*/
interface ERC20 {
  // Get the total token supply
  function totalSupply() external view returns (uint256);
  // Get the account balance of another account with address _owner
  function balanceOf(address _owner) external view returns (uint256 balance);
  // Get amount that _spender is still allowed to withdraw from _owner
  function allowance(address _owner, address _spender)
    external view returns (uint256 remaining);
  function transfer(address to, uint256 value) external returns (bool success);
  // Allow _spender to withdraw from the calling account multiple times up to _value amount.
  function approve(address _spender, uint256 _value) external returns (bool success);
  // Send _value amount of tokens from address _from to address _to
  function transferFrom(address _from, address _to, uint256 _value)
    external returns (bool success);
  // Triggered when tokens are transferred.
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  // Triggered whenever approve(address _spender, uint256 _value) is called.
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
