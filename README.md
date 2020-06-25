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
    * [Example](#example)
  * [Watch](#watch)
  * [Test](#test)
  * [Linter](#linter)
* [Truffle Interactive Console (REPL)](#truffle-interactive-console-repl)
* [Remix](#remix)
* [References](#references)

<!-- Note: Update the TOC by installing [markdown-toc](https://github.com/jonschlinkert/markdown-toc), and then running `cd mining && npm install -g markdown-toc && markdown-toc --bullets "*"  --no-firsth1 ./README.md` and replacing the current TOC with the output. -->

## Credits

* Original Source: https://github.com/hicommonwealth/edgeware-lockdrop
* Key references: https://github.com/radek1st/time-locked-wallets/tree/master/contracts

## Setup

### Clone the repo

```bash
git clone https://github.com/DataHighway-com/mining
cd ./mining
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

Latest beta (see https://github.com/trufflesuite/ganache-cli/releases)
```bash
npm uninstall ganache-cli -g
npm install ganache-cli@beta -g
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

Note:
* `0xce31EeD26ff009f1F5e38408571ea174c5d54f20` is Ethereum address of seed `0x209c205f333b5a65cc428589a51bd9f2621e2fc01de1b02dbf8c0f0b68e4974e`
* `0xe66628e37eFE36098c148d2a3B970074999E95C6` is Ethereum address of seed `0x0edb559026c8f779be17b4c9d8e4dfc14bead6592241de4d6612f77769327f7f`
* These keys are defined in ./helpers/constants.js
```bash
ganache-cli \
	--account="0x209c205f333b5a65cc428589a51bd9f2621e2fc01de1b02dbf8c0f0b68e4974e, 50471238800000000000" \
	--account="0x0edb559026c8f779be17b4c9d8e4dfc14bead6592241de4d6612f77769327f7f, 100471238800000000000" \
	--unlock "0x209c205f333b5a65cc428589a51bd9f2621e2fc01de1b02dbf8c0f0b68e4974e" \
	--unlock "0x0edb559026c8f779be17b4c9d8e4dfc14bead6592241de4d6612f77769327f7f" \
	--port 8545 \
	--hostname localhost \
	--seed '0x209c205f333b5a65cc428589a51bd9f2621e2fc01de1b02dbf8c0f0b68e4974e' \
	--debug true \
	--mem true \
	--mnemonic 'end sleep vote expire arctic magic crack wrap toddler lizard acoustic owner' \
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
* Run Migrations Full (Ropsten) - `truffle migrate --reset --network ropsten`
* Run Migrations Full (Development) - `truffle migrate --reset --network development`
* Run Contracts from specific Migration - `truffle migrate -f <number>`
* Run Migration on specific network called 'live' defined in truffle.js - `truffle migrate --network live`

Note: If you get error `Could not find suitable configuration file.` then you're running the command in the wrong directory.
Note: If the above results in a time-out, then instead run the following to try and uncover any other errors:

```bash
truffle develop
truffle(develop)> migrate --reset
```

References:
* http://truffleframework.com/docs/getting_started/compile

### Build DApp Front-end

Build Artifacts (requires Default or Custom Builder such as Webpack to be configured)

```bash
npm run build
``` 
(same as `truffle build`)

### Run DApp Node.js Server & Interact

#### Terminal 3 - Install & Run MongoDB

##### macOS

https://docs.mongodb.com/manual/tutorial/install-mongodb-on-os-x/

```
brew tap mongodb/brew
brew install mongodb-community@4.2
brew services start mongodb-community@4.2
```

#### Terminal 1 - Run Server

Drop DB. Build App and Run Dev Server:

```bash
npm run drop; npm run dev
```

Open `open http://localhost:8080` in browser

#### Terminal 2 - Interact using cURL

* Send request to server and receive response for authentication and authorisation to access specific API endpoints.
	* Register. JWT provided in response (i.e. `{"token":"xyz"}`)
		```
		curl -v POST http://localhost:7000/users/auth/register -d "network=ethereum-testnet-local&publicAddress=0x123&email=ltfschoen@gmail.com&password=123456&name=Luke" -H "Content-Type: application/x-www-form-urlencoded"
		curl -v POST http://localhost:7000/users/auth/register -d '{"network": "ethereum-testnet-local", "publicAddress": "0x123", "email":"ltfschoen@gmail.com", "password":"123456", "name":"Luke"}' -H "Content-Type: application/json"
		```
	* Fetch the Nonce if it exists for given Public Address. Nonce provided in response (i.e. `{"nonce":"123"}`)
		```
		curl -v GET http://localhost:7000/users/show?network='ethereum-testnet-local&publicAddress=0x123'
		```
	* Sign in using signature verification. JWT provided in response (i.e. `{"token":"xyz"}`)
		```
		curl -v POST http://localhost:7000/users/auth/login -d "network='ethereum-testnet-local'&publicAddress=0x123&signature=0x456&email=ltfschoen@gmail.com&password=123456" -H "Content-Type: application/x-www-form-urlencoded"
		curl -v POST http://localhost:7000/users/auth/login -d '{"network": "ethereum-testnet-local", "publicAddress": "0x123", "signature": "0x456", "email":"ltfschoen@gmail.com", "password":"123456"}' -H "Content-Type: application/json"
		```
	* Access a restricted endpoint by providing JWT
		```
		curl -v GET http://localhost:7000/users/list -H "Content-Type: application/json" -H "Authorization: Bearer <INSERT_TOKEN>"
		```
	* Create user by providing JWT
		```
		curl -v POST http://localhost:7000/users/create --data '[{"network": "ethereum-testnet-local", "publicAddress": "0x123", "signature": "0x456", "email":"test@fake.com", "name":"Test"}]' -H "Content-Type: application/json" -H "Authorization: JWT <INSERT_TOKEN>"
		curl -v POST http://localhost:7000/users/create -d "network='ethereum-testnet-local'&publicAddress=0x123&signature=0x456&email=test2@fake.com&name=Test2" -H "Content-Type: application/x-www-form-urlencoded" -H "Authorization: JWT <INSERT_TOKEN>"
		```

#### Example 2:

* Within the DApp transfer say 10 wei to Account No.  0x0000000000000000000000000000000000000000000000000000000000000001 that we created on Ethereum TestRPC

* Check Account Balances from Terminal by loading External JavaScript file:

```bash
truffle exec './scripts/checkAllBalances.js’
```

#### Example 2:

```
$ truffle develop
truffle(develop)> compile
truffle(develop)> migrate
truffle(develop)> exec ./scripts/deployMxc.js
```

OR `truffle exec ./scripts/deployMxc.js --network development`
		
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

OR 

```
$ truffle develop
truffle(develop)> test
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
	[ '0xce31EeD26ff009f1F5e38408571ea174c5d54f20',
		'0xe66628e37eFE36098c148d2a3B970074999E95C6' ]

web3.eth.blockNumber
```

## Remix

Refer to [Remix](./REMIX.md)

## References

* http://truffleframework.com/docs/getting_started/console
* https://github.com/trufflesuite/truffle-contract
* http://truffleframework.com/docs/getting_started/contracts
* https://github.com/ethereum/wiki/wiki/JavaScript-API
* https://www.ethereum.org/cli
* https://github.com/ltfschoen/benzcoin
* https://www.toptal.com/ethereum/one-click-login-flows-a-metamask-tutorial
* https://mongoosejs.com/docs/populate.html
* https://github.com/vanbexlabs/web3-auth

### FAQ

* Question: Why do I get the following error when running `truffle test`: `Transaction was not mined within 50 blocks, please make sure your transaction was properly sent. Be aware that it might still be mined!`?
	* Answer: Running Ganache CLI with `--blockTime 3` mines 1 block every 3 seconds,
	whereas if the blockTime option is omitted then blocks are mined instantly.
* Question: Why do I get the following error when running `truffle test`: `sender doesn't have enough funds to send tx. The upfront cost is: 1134439500000000000 and the sender's account only has: 320739879999999999`?
	* Answer: When running Ganache CLI, provide more ETH to the default accounts (i.e. `--account="0x0000000000000000000000000000000000000000000000000000000000000001, 50471238800000000000" \` provides 50 ETH to that account.) or restart the Ganache CLI