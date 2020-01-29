# Data Highway Inter-Chain Bridged Token Asset Mining

## Table of Contents

* [Setup](#setup)
  * [Clone the repo](#clone-the-repo)
  * [Install Dependencies](#install-dependencies)
    * [Switch to relevant Node.js version using NVM and install dependencies](#switch-to-relevant-nodejs-version-using-nvm-and-install-dependencies)
    * [Install Truffle and Test Framework with Ganache CLI (previously Ethereum TestRPC)](#install-truffle-and-test-framework-with-ganache-cli-previously-ethereum-testrpc)
    * [Configure Blockchain](#configure-blockchain)
    * [Compile and Migrate Contracts onto Network of choice (i.e. "development") defined in truffle.js](#compile-and-migrate-contracts-onto-network-of-choice-ie-development-defined-in-trufflejs)
      * [Compile](#compile)
      * [Migrate](#migrate)
  * [Build DApp Front-end](#build-dapp-front-end)
  * [Run DApp Node.js Server](#run-dapp-nodejs-server)
    * [Example:](#example)
  * [Watch](#watch)
  * [Test](#test)
  * [Linter](#linter)
* [Truffle Interactive Console (REPL)](#truffle-interactive-console-repl)
* [References](#references)

<!-- Note: Update the TOC by installing [markdown-toc](https://github.com/jonschlinkert/markdown-toc), and then running `cd mining && npm install -g markdown-toc && markdown-toc --bullets "*"  --no-firsth1 ./README.md` and replacing the current TOC with the output. -->

## Setup

### Clone the repo

```bash
git clone https://github.com/DataHighway-com/mining
cd ./mining/tokens/mxc
```

### Install Dependencies

#### Switch to relevant Node.js version using NVM and install dependencies

```bash
nvm use v11.6.0
```

Note: Otherwise may get error like `no matching constructor for initialization of 'v8::String::Utf8Value'`
    
```bash
npm install
```

#### Install Truffle and Test Framework with Ganache CLI (previously Ethereum TestRPC)

```bash
npm install -g truffle ganache-cli
```

#### Configure Blockchain

Run Ethereum Client (in separate Terminal tab)

Delete DB folder if starting fresh

```bash
rm -rf ./db
```

Create DB folder

```bash
mkdir db && mkdir db/chain_database
```

Start Ethereum Blockchain Protocol Node Simulation that will be served on http://localhost:8545

```bash
ganache-cli \
	--account="0x0000000000000000000000000000000000000000000000000000000000000001, 2471238800000000000" \
	--account="0x0000000000000000000000000000000000000000000000000000000000000002, 4471238800000000000" \
	--unlock "0x0000000000000000000000000000000000000000000000000000000000000001" \
	--unlock "0x0000000000000000000000000000000000000000000000000000000000000002" \
	--blockTime 0 \
	--port 8545 \
	--hostname localhost \
	--seed 'blah' \
	--debug true \
	--mem true \
	--mnemonic 'something' \
	--db './db/chain_database' \
	--verbose \
	--networkId=3 \
	--gasLimit=7984452 \
	--gasPrice=20000000000;
```

#### Compile and Migrate Contracts onto Network of choice (i.e. "development") defined in truffle.js

##### Compile

* Compile Contract Latest - `truffle compile` (only changes since last compile)
* Compile Contract Full - `truffle compile --compile-all` (full compile)

##### Migrate

* Run Migrations Latest - `truffle migrate`
* Run Migrations Full - `truffle migrate --reset --network development`
* Run Contracts from specific Migration - `truffle migrate -f <number>`
* Run Migration on specific network called 'live' defined in truffle.js - `truffle migrate --network live`

Note: If the above results in a time-out, then instead run the following to try and uncover any other errors:

```bash
truffle develop
truffle(develop)> migrate --reset --network development
```

References:
* http://truffleframework.com/docs/getting_started/compile

### Build DApp Front-end

Build Artifacts (requires Default or Custom Builder such as Webpack to be configured)

```bash
npm run build
``` 
(same as `truffle build`)

### Run DApp Node.js Server

Build App and Run Dev Server:

```bash
npm run dev
```

Open `open http://localhost:8080` in browser

#### Example:

* Within the DApp transfer say 10 wei to Account No.  0x0000000000000000000000000000000000000000000000000000000000000001 that we created on Ethereum TestRPC

* Check Account Balances from Terminal by loading External JavaScript file:

```bash
truffle exec './scripts/checkAllBalances.js’
```
		
### Watch
Watch for changes to contracts, app and config files. Rebuild app upon changes.

```bash
truffle watch
```

Reference
* http://truffleframework.com/docs/advanced/commands
		
### Test

```bash
truffle test
truffle test ./path/to/test/file.js
```

### Linter

Run Linter:

```bash
npm run lint
```

## Truffle Interactive Console (REPL) 
Run REPL on specified network and log communication between Truffle and the RPC

```bash
truffle console --network development --verbose-rpc
```

Try the following commands

```bash
web3

// Show existing MXCToken accounts
web3.eth.accounts

i.e. 
	[ '0x7e5f4552091a69125d5dfcb7b8c2659029395bdf',
		'0x2b5ad5c4795c026514f8317c7a215e218dccd6cf' ]

web3.eth.blockNumber
var Web3 = require('web3');
var web3 = new Web3.providers.HttpProvider("http://localhost:8545");
web3.isConnected();
var contract = require("truffle-contract");

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

// IMPORTANT NOTE: COPY/PASTE BELOW INTO TRUFFLE CONSOLE (SINCE CANNOT COPY/PASTE MULTI-LINE CODE)
var mxcTokenInstance; MXCToken.deployed().then(function(instance) { mxcTokenInstance = instance; return mxcTokenInstance.sendCoin(account_two, 10, {from: account_one}); }).then(function(result) { for (var i = 0; i < result.logs.length; i++) { var log = result.logs[i]; if (log.event == "Transfer") { console.log("Transaction triggered Transfer event in logs"); break; } }; console.log("Transaction successful with response: ", JSON.stringify(result, null, 2)); }).catch(function(e) { console.log("Error running MXCToken.sol function sendCoin"); })

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

// New Contract Abstraction deployed to Address on network
MXCToken.new().then(function(instance) {
	// Print the new address
	console.log("New Contract Abstraction deployed to network at address: ", instance.address);
}).catch(function(err) {
	console.log("Error creating new contract abstraction: ", err);
});

// Existing Contract Abstraction Address - Create New Contract Abstraction using Existing Contract Address (that has already been deployed)
var mxcTokenInstance = MXCToken.at("0x7e5f4552091a69125d5dfcb7b8c2659029395bdf");

// Send Ether directly to a Contract or trigger a Contracts [Fallback function](http://solidity.readthedocs.io/en/develop/contracts.html#fallback-function)

// Send Ether / Trigger Fallback function 
// Reference: https://github.com/ethereum/wiki/wiki/JavaScript-API#web3ethsendtransaction
mxcTokenInstance.sendTransaction({...}).then(function(result) {
	// Same transaction result object as above.
});

// Send Ether directly to Contract using shorthand
mxcTokenInstance.send(web3.toWei(1, "ether")).then(function(result) {
	// Same result object as above.
});
```

## References

* http://truffleframework.com/docs/getting_started/console
* https://github.com/trufflesuite/truffle-contract
* http://truffleframework.com/docs/getting_started/contracts
* https://github.com/ethereum/wiki/wiki/JavaScript-API
* https://www.ethereum.org/cli
* https://github.com/ltfschoen/benzcoin
