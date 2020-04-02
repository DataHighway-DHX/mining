const BN = require("bn.js");
const MXCToken = artifacts.require("./MXCToken.sol");

contract('MXCToken', function(accounts) {
  it("should put 100000000 MXCToken in the first account", function() {
    return MXCToken.deployed().then(function(instance) {
      return instance.balanceOf.call(accounts[0]);
    }).then(function(balance) {
      // Use .toString(10) instead of .toNumber() to avoid error
      // `Error: Number can only safely store up to 53 bits`
      assert.equal(balance.valueOf().toString(10), 2664965800000000000000000000,
        "2664965800000000000000000000 wasn't in the first account");
    });
  });
  it("should send coin correctly", function() {
    var mxcTokenInstance;

    // Get initial balances of first and second account.
    var account_one = accounts[0];
    var account_two = accounts[1];

    var account_one_starting_balance;
    var account_two_starting_balance;
    var account_one_ending_balance;
    var account_two_ending_balance;

    // https://github.com/indutny/bn.js/#usage
    var amount = 10;

    return MXCToken.deployed().then(function(instance) {
      mxcTokenInstance = instance;
      return mxcTokenInstance.balanceOf.call(account_one);
    }).then(function(balance) {
      console.log('balance: ', balance.toString(10));
      account_one_starting_balance = balance;
      return mxcTokenInstance.balanceOf.call(account_two);
    }).then(function(balance) {
      account_two_starting_balance = balance;
      return mxcTokenInstance.transfer(account_two, amount, {from: account_one});
    }).then(function() {
      return mxcTokenInstance.balanceOf.call(account_one);
    }).then(function(balance) {
      account_one_ending_balance = balance;
      return mxcTokenInstance.balanceOf.call(account_two);
    }).then(function(balance) {
      account_two_ending_balance = balance;
      console.log('amount: ', amount);
      console.log('account_one_starting_balance: ', account_two_ending_balance.toString(10));
      console.log('account_two_ending_balance: ', account_two_ending_balance.toString(10));
      console.log('account_two_starting_balance: ', account_two_starting_balance.toString(10));
      console.log('account_one_ending_balance: ', account_one_ending_balance.toString(10));

      assert.equal(account_one_ending_balance, account_one_starting_balance - amount,
        "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance.toNumber(10) + amount,
        "Amount wasn't correctly sent to the receiver");
    });
  });
});
