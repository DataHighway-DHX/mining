var MXCToken = artifacts.require("./MXCToken.sol");

contract('MXCToken', function(accounts) {
  it("should put 100000000 MXCToken in the first account", function() {
    return MXCToken.deployed().then(function(instance) {
      return instance.balanceOf.call(accounts[0]);
    }).then(function(balance) {
      assert.equal(balance.valueOf(), 100000000, "100000000 wasn't in the first account");
    });
  });
  it("should call a function that depends on a linked library", function() {
    var mxcTokenInstance;
    var mxcTokenInstanceBalance;
    var mxcTokenInstanceEthBalance;

    return MXCToken.deployed().then(function(instance) {
      mxcTokenInstance = instance;
      return mxcTokenInstance.balanceOf.call(accounts[0]);
    }).then(function(outBalance) {
      mxcTokenInstanceBalance = outBalance.toNumber();
      return mxcTokenInstance.getBalanceInEth.call(accounts[0]);
    }).then(function(outBalanceEth) {
      mxcTokenInstanceEthBalance = outBalanceEth.toNumber();
    }).then(function() {
      assert.equal(mxcTokenInstanceEthBalance, 2 * mxcTokenInstanceBalance,
        "Library function returned unexpected function, linkage may be broken");
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

    var amount = 10;

    return MXCToken.deployed().then(function(instance) {
      mxcTokenInstance = instance;
      return mxcTokenInstance.balanceOf.call(account_one);
    }).then(function(balance) {
      account_one_starting_balance = balance.toNumber();
      return mxcTokenInstance.balanceOf.call(account_two);
    }).then(function(balance) {
      account_two_starting_balance = balance.toNumber();
      return mxcTokenInstance.transfer(account_two, amount, {from: account_one});
    }).then(function() {
      return mxcTokenInstance.balanceOf.call(account_one);
    }).then(function(balance) {
      account_one_ending_balance = balance.toNumber();
      return mxcTokenInstance.balanceOf.call(account_two);
    }).then(function(balance) {
      account_two_ending_balance = balance.toNumber();

      assert.equal(account_one_ending_balance, account_one_starting_balance - amount,
        "Amount wasn't correctly taken from the sender");
      assert.equal(account_two_ending_balance, account_two_starting_balance + amount,
        "Amount wasn't correctly sent to the receiver");
    });
  });
});
