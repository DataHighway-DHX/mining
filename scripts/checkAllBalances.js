// Reference: https://www.ethereum.org/cli
module.exports = function(callback) {
  function checkAllBalances() {
    web3.eth.getAccounts(function(err, accounts) {
      accounts.forEach(function(id) {
        web3.eth.getBalance(id, function(err, balance) {
          console.log("" + id + ":\tbalance: " + web3.fromWei(balance, "ether") + " ether");
        });
      });
    });
  };
  checkAllBalances();
}