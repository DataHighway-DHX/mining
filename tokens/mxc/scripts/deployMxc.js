const artifacts = require('./build/contracts/MXCToken.json');

var Web3 = require('web3');
var web3 = new Web3.providers.HttpProvider("http://localhost:8545");
web3.isConnected();
var contract = require("truffle-contract");
const MXCToken = contract(artifacts);

// Execute Custom Contract (MXCToken) Functions on Ethereum Network (i.e. we * previously created
// the following functions in MXCToken.sol: sendCoin, getBalanceInEth, getBalance)

// Call sendCoin function to send Benz coins from one account to another. Execute as `transaction` that persists changes to the network

// Get reference to the 2x Ethereum Account Addresses we created on the Ethereum.js TestRPC network:
var account_one = web3.eth.accounts[0]; // an address
var account_two = web3.eth.accounts[1]; // another address

// Show Account Balances 
web3.eth.getBalance(account_one)
web3.eth.getBalance(account_two)

// Call the Contract Abstractions `sendCoin` function directly
// (passing a special object as the last parameter that allows Editing of
// specific transaction details) that results 
// in a `transaction` (WRITE DATA instead of a `call`) and callback function * only fires when transaction successful
// Refer to alternative better approach using `MXCToken.at(...)`: https://github.com/trufflesuite/truffle-contract

var mxcTokenInstance;

MXCToken.deployed().then(function(instance) {
	mxcTokenInstance = instance;
	return mxcTokenInstance.sendCoin(account_two, 10, {from: account_one});
}).then(function(result) {
	// callback that when called means transaction was successfully processed
	// Validate that triggered the Transfer event by checking logs
	for (var i = 0; i < result.logs.length; i++) {
		var log = result.logs[i];

		if (log.event == "Transfer") {
			console.log("Transaction triggered Transfer event in logs");
			break;
		}
	}
	console.log("Transaction successful with response: ", JSON.stringify(result, null, 2));
}).catch(function(e) {
	console.log("Error running MXCToken.sol function sendCoin");
})

// Call the Contract Abstractions `getBalance` function using 
// a `call` (READ DATA instead of a `transaction`) so Ethereum network 
// knows we do not intend to persist any changes, and callback function 
// only fires when call is successful. Instead returns a value (instead
// of just a Transaction ID like with `transaction`) of MXCToken balance 
// as BigNumber object at address that is passed to it.

var mxcTokenInstance;
MXCToken.deployed().then(function(instance) {
	mxcTokenInstance = instance;
	return mxcTokenInstance.getBalance.call(account_one, {from: account_one});
}).then(function(balance) {
	// Callback is called when 'call' was successfully executed
	// Callback returns immediately without any waiting
	console.log("Balance is: ", balance.toNumber());
}).catch(function(e) {
	console.log("Error running MXCToken.sol function getBalance");
})

// // New Contract Abstraction deployed to Address on network
// MXCToken.new().then(function(instance) {
// 	// Print the new address
// 	console.log("New Contract Abstraction deployed to network at address: ", instance.address);
// }).catch(function(err) {
// 	console.log("Error creating new contract abstraction: ", err);
// });

// // Existing Contract Abstraction Address - Create New Contract Abstraction using Existing Contract Address (that has already been deployed)
// var mxcTokenInstance = MXCToken.at("0x7e5f4552091a69125d5dfcb7b8c2659029395bdf");

// // Send Ether directly to a Contract or trigger a Contracts [Fallback function](http://solidity.readthedocs.io/en/develop/contracts.html#fallback-function)

// // Send Ether / Trigger Fallback function 
// // Reference: https://github.com/ethereum/wiki/wiki/JavaScript-API#web3ethsendtransaction
// mxcTokenInstance.sendTransaction({
// }).then(function(result) {
// 	// Same transaction result object as above.
// });

// // Send Ether directly to Contract using shorthand
// mxcTokenInstance.send(web3.toWei(1, "ether")).then(function(result) {
// 	// Same result object as above.
// });
