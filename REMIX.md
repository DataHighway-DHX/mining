# Remix Deployment and Testing

## Create a DataHighway Account Address

### Option 1: DataHighway App

* Click "Create Account" and follow the prompts

### Option 2: Polkadot.js Apps

* Go to https://polkadot.js.org/apps/#/settings/developer.
  * Copy/Paste the contents of https://github.com/DataHighway-DHX/node/blob/master/custom_types.json
  * Click "Save"
* Go to https://polkadot.js.org/apps/#/settings
  * Click "Custom Endpoint"
  * Paste value of "wss://testnet-harbour.datahighway.com" in the input field "remote node/endpoint to connect to" 
  * Click "Save"
* Go to https://polkadot.js.org/apps/#/accounts
  * Click "Add Account"
  * Enter an account "name"
  * Remember the "mnemonic seed" (keep it confidential and store it offline)
  * Enter a password
  * Click "Save"
* Go to https://polkadot.js.org/apps/#/accounts
  * Click the icon of the account that you created to copy its DataHighway Public Key (Account Address)
    * e.g. `5........................`

### Option 3: Subkey

https://www.substrate.io/kb/integrate/subkey

e.g.
```
subkey --sr25519 --network substrate vanity "mxc" --number 1
```
* Remember the output

## Convert DataHighway Public Key to Bytes

In order provide the DataHighway Public Key as a parameter when interacting with functions of the Lockdrop smart contract in Remix that we will deploy on the Ethereum Ropsten Testnet, we need to convert it from its existing format in UTF8 into a hex value (bytes). In this example we will use the Web3Utils library https://www.npmjs.com/package/web3-utils

* Install Node.js https://nodejs.org/en/download/
* Open Terminal and install the Web3Utils dependency with:
  ```
  npm install web3-utils
  ```
* Start a Node.js REPL
  ```
  node
  ```

* Convert the DataHighway Public Key (Account Address) to Hex (in the Node.js REPL)

  ```
  const Web3Utils = require('web3-utils');
  var dataHighwayPubKey = "<DATAHIGHWAY_PUBLIC_KEY>";
  var hexString = Web3Utils.utf8ToHex("0x46765939697a514462737a7a46556b437a65643435547039785062754b4e516e4d563150676b385959444b43573476");
  console.log('hexString', hexString);
  var restoredPubKey = Web3Utils.toUtf8(hexString);
  console.log('restoredPubKey', restoredPubKey);
  ```
* COPY the `hexString`, as we will use that as the `dataHighwayPublicKey` argument when deploying and interacting with the Lockdrop contract. See https://github.com/DataHighway-DHX/mining/blob/master/contracts/Lockdrop.sol#L34. In the later example this value is `0x467...`.

## Create Ethereum Account & Obtain Ropsten Testnet Ether & Import into Metamask

* Use the team Ethereum Account Address and mnemonic. Or create your own with MyCrypto.
  * e.g. Ethereum Account Address: `0xf0066Db8F8f2c86B2713f09090DDE33C558D03F0`
  * e.g. Mnemonic Passphrase: PLEASE ASK LUKE SCHOEN FOR THIS
* Request Ropsten Testnet Ether from https://faucet.ropsten.be/, since you need to pay gas fees in Testnet Ether to make transactions (e.g. deploying and interacting with smart contracts).
* Import Ethereum Account Address into Metamask and change your connection to the Ropsten Testnet
* COPY the Ethereum Account Address and mnemonic into `ETHEREUM_ADDRESS` and `MNENOMIC` respectively of ./app/.env in the [DataHighway App](https://github.com/DataHighway-DHX/app)

## Deploy "Lockdrop" Contract to Ropsten Testnet

* Go to Remix https://remix.ethereum.org
* Open the ./contracts folder (of https://github.com/DataHighway-DHX/mining) in Remix
* Change imports so they compile in the browser (e.g. change `import "./interface/ERC20.sol";` to `import "./ERC20.sol";`)
* Compile Lockdrop.sol using Remix. Go to "Compile" > "Start Compile"
* COPY its ABI into ./app/assets/data/abi_datahighway_lockdrop_testnet.json of the DataHighway App
* Deploy Lockdrop.sol, providing the current Unix epoch time as 1st argument (obtain from https://www.epochconverter.com). Sign transaction with Metamask. Wait for it to be mined.
  * e.g. `0x0174738a8cbd221f4f4b06011dc282d5b0ea1fbe`

  * Detailed Steps to Deploy (if necessary):
    * Go to "Run"
      * Choose Environment "Injected Web3 Ropsten"
      * Choose Account "<Choose the Ethereum Account Address with Ropsten Testnet ETH>"
      * Choose Gas Limit "3000000"
      * Choose Value "20" Gwei
      * Select: 
        * "Lockdrop"
        * Enter for `startTime`: `...` (get current Epoch time from https://www.epochconverter.com/)
        * Click "Transact" or "Deploy" button
      * Alternatively:
        * Paste the address where the Lockdrop contract was deployed to on Ropsten into "At Address"
          * Click the "At Address" text button
      * In the MetaMask popup, click to "Edit" the "Gas Price", then click "Advanced", and
      enter Gas Price: `40`, and Gas Limit: `4000000`
      * In the "Deployed Contracts" section, obtain the Lockdrop's deployed contract address by clicking the address icon where it says "Lockdrop at 0x....", and clicking the arrow to expand it.

* COPY the Lockdrop deployed address into `CONTRACT_ADDRESS_LOCKDROP_TESTNET` of ./app/.env in the DataHighway App

### Alternative Approach (NOT RECOMMENDED)

Alternatively you may deploy the Lockdrop and MXCToken contracts using Truffle using this repository: https://github.com/DataHighway-DHX/mining

It requires running the following:
```
nvm use v11.6.0
truffle compile --compile-all
truffle migrate --reset --network ropsten
```

Then copying the deployed Lockdrop contract address and MXCToken contract address from the logs. And copying the built contract .json files from the ./build/contracts folder to the  DataHighway App's ./app/assets/data folder.

## Deploy "MXCToken" Contract to Ropsten Testnet

* Go to Remix https://remix.ethereum.org
* Create a file MXCToken.sol in Remix. Paste the contents of https://github.com/mxc-foundation/mxc-wallet/blob/master/contracts/MXCToken.sol (same code as the MXCToken contract that was originally deployed to Ethereum Mainnet)
* Compile MXCToken.sol after switching to the older Solidity compiler version 0.4.24
* COPY its ABI into ./app/assets/data/abi_mxc.json of the DataHighway App https://github.com/DataHighway-DHX/app
* Deploy MXCToken.sol. Sign transaction with Metamask. e.g. `0x7d3037fa9f8f253e4e7fc930f0a299cbd6eac349`
  * Note: The MXCToken contract will send its total supply `2664965800000000000000000000` of MXC to the Ethereum Account Address that deployed it. It has 18 decimals (see https://github.com/mxc-foundation/mxc-wallet/blob/master/contracts/MXCToken.sol#L258).
  * Note:
  ```
  2664965800.000000000000000000 total supply
         100 000000000000000000 = 100 MXC (i.e. 100000000000000000000)
  ```
* COPY the MXCToken deployed address into `CONTRACT_ADDRESS_MXC_TESTNET` of ./app/.env of the DataHighway App

## Interact with Lockdrop Contract on Ropsten Testnet

### Lock ERC20 Tokens

* Click `lock` after entering the following arguments to run that function of the deployed Lockdrop contract to lock 100 MXC (e.g. `100000000000000000000`) for 3 months using fake DataHighway Public Key `0x467..` assuming MXCToken deployed address was `0x7d3...`, and indicate whether you intend to be a validator on the DataHighway (e.g. `true`). Sign transaction with Metamask. Replace the following arguments. Sign transaction with Metamask since it is a transaction that requires payment of gas with Ether (rather than just a call).
  * 1st argument with the Ethereum Account Address
  * 5th argument with the MXCToken address.

  e.g.
  ```
  "0xf0066Db8F8f2c86B2713f09090DDE33C558D03F0","3","100000000000000000000","0x46765939697a514462737a7a46556b437a65643435547039785062754b4e516e4d563150676b385959444b43573476","0x7d3037fa9f8f253e4e7fc930f0a299cbd6eac349",false
  ```
  * Note: This will automatically generate and deploy a "Lock" contract, which is where you will deposit and withdraw the locked MXC tokens. The "Lockdrop" contract is the factory contract that generates the "Lock" contract.
  * Note: The value `0x467...` is an example of the Hex (Bytes) representation of a DataHighway Public Key that we converted.

### View Claim Eligibility to MSB & Obtain Generated Lock Contract Address

* Click `lockWalletStructs` after entering the following arguments to run that function of the deployed Lockdrop contract to find the address of the generated and deployed "Lock" contract and to view information about your signal and claim status.
  * 1st arg: Ethereum Account
  * 2nd arg: MXCToken address

  e.g.
  ```
  "0xf0066Db8F8f2c86B2713f09090DDE33C558D03F0","0x7d3037fa9f8f253e4e7fc930f0a299cbd6eac349"
  ```
  
  * Example Output:

    ```
    0: uint8: claimStatus 0
    1: uint256: approvedTokenERC20Amount 0
    2: uint256: pendingTokenERC20Amount 100000000000000000000
    3: uint256: rejectedTokenERC20Amount 0
    4: uint8: term 3
    5: uint256: tokenERC20Amount 100000000000000000000
    6: bytes: dataHighwayPublicKey 0x46765939697a514462737a7a46556b437a65643435547039785062754b4e516e4d563150676b385959444b43573476
    7: address: lockAddr 0x1e413928cD624B21B00509e9a476552787c0aFD0
    8: bool: isValidator false
    9: uint256: createdAt 1593001631
    ```

  * COPY the `lockAddr` of the output since we'll use that in the next step. It is the Lock contract address that the Lockdrop contract factory deployed.

### Grant Approval for Lock Contract to Deposit ERC20 Tokens

* Click `approve` after entering the following arguments to run that function of the deployed MXCToken contract. Replace the following arguments. Sign transaction with Metamask. 
  * 1st arg: Lock address (`lockAddr` output)
  * 2nd arg: Amount of MXC tokens (e.g. 100 MXC) to allow the Lock contract to deposit from your Ethereum Account Address, which is an Externally Owned Address (EOA) to the Lock contract on your behalf, but this will only happen after you run the Lock contract's `depositTokens` function and sign the transaction with Metamask.

  e.g.
  ```
  "0x.....", 100000000000000000000
  ```

### Deposit ERC20 Tokens from the Ethereum Account Address to the Lock Contract

* Retrieve the "Lock" contract that the Lockdrop contract deployed to address `lockAddrs`
  * In Remix to to Run > Choose "Lock" from the selection box, and for `AtAddress` enter the value of the `lockAddr` (also may be obtained from the logs of the "lock" transaction (i.e. 0x.....).
  * Scroll down and click the `info` function button, it outputs the following (where `0x1e413928cD624B21B00509e9a476552787c0aFD0` is the `lockAddr` is this example)
    ```
    0: address: 0xf0066Db8F8f2c86B2713f09090DDE33C558D03F0
    1: address: 0x1e413928cD624B21B00509e9a476552787c0aFD0
    2: address: 0xf0066Db8F8f2c86B2713f09090DDE33C558D03F0
    3: address: 0x7d3037fa9f8F253e4e7fc930F0A299cBd6Eac349
    4: uint256: 1624537631
    5: uint256: 100000000000000000000
    6: bytes: 0x46765939697a514462737a7a46556b437a65643435547039785062754b4e516e4d563150676b385959444b43573476
    7: bool: false
    8: uint256: 1593001631
    9: uint256: 1593001708
    10: uint256: 0
    ```

* Click `depositTokens` of the deployed Lock.sol contract (after loading it using `AtAddress` and providing its address). Sign transaction with Metamask. The Lock contract will then run a `transferFrom` function, which will transfer 100 MXC (that you indicated that you wanted to lock) from the Ethereum Account Address to the Lock contract (as long as you approved it to be allowed to transfer at least that amount).
* Prior to withdrawing, check that the funds were deposited by running the `lockContractBalance` function the Lock contract until it shows the balance (e.g `100000000000000000000`)
* Also if you run the MXCToken contract's `allowance` function with arg `"0xf0066Db8F8f2c86B2713f09090DDE33C558D03F0","0x....."`, it should return 0 (meaning you can't deposit anymore until you increase the allowance again).

### Withdraw ERC20 Tokens from the Lock Contract to the Ethereum Account Address after the Term

* Click `withdrawTokens` of the deployed Lock.sol contract (after loading it using `AtAddress` and providing its address). Sign transaction with Metamask. The Lock contract will then run a `transfer` function, which will transfer 100 MXC (that you locked) from the Lock contract back to the Ethereum Account Address.

### Set Claim Eligibility to MSB of the Lock

* Click `setClaimStatus` after entering the following arguments to run that function of the deployed Lockdrop contract and to set the claim eligibility. Replace the following arguments. Sign transaction with Metamask. Note: This should be performed after the Lock term. Only the owner of the Ethereum Account Address that deployed the Lockdrop contract may run this.
  * 1st arg: Ethereum Account Address (that Locked)
  * 2nd arg: Claim Type of Lock `0` (whether we're setting the claim eligibility of a Lock for the given Ethereum Account Address)
  * 3rd arg: MXCToken address
  * 4th arg: Claim Status of either Pending `0` or Finalized `1` (setting to finalized indicates to the participant that Locked or Signaled that their claim eligibility has been finalized so they're DataHighway Public Key may obtain the relevant MSB when staking on the DataHighway. WARNING: Once it is set to finalized it is not possible to set it as pending again)
  * 5th arg: Approved Amount of MXC tokens (e.g. 49 MXC)
  * 6th arg: Pending Amount of MXC tokens (e.g. 51 MXC)
  * 7th arg: Rejected Amount of MXC tokens (e.g. 0 MXC)
  * Note: The sum of the 5th, 6th, and 7th args must equal the amount of MXC tokens they indicated they wanted to Lock.

  e.g.
  ```
  "0xf0066Db8F8f2c86B2713f09090DDE33C558D03F0","0","0x7d3037fa9f8f253e4e7fc930f0a299cbd6eac349","1","49000000000000000000","51000000000000000000","0"
  ```

### Signal ERC20 Tokens

* Click `signal` after entering the following arguments to run that function of the deployed Lockdrop contract to signal 2000 MXC for 3 months using fake DataHighway Public Key `0x467..` assuming MXCToken deployed address was `0x7d3...`. Sign transaction with Metamask.
  e.g.
  ```
  "3","2000000000000000000000","0x46765939697a514462737a7a46556b437a65643435547039785062754b4e516e4d563150676b385959444b43573476","0x7d3037fa9f8f253e4e7fc930f0a299cbd6eac349"
  ```
  * Note: Since the MXCToken has 18 decimal places, we use `2000000000000000000000` to represent 2000 MXC.
  * Note: A separate `signalFromContract` option is available, that would be called with the following, where the 1st argument is a contract address that you are signaling from, and the 2nd argument is the nonce of that contract address (see the Lockdrop.sol for further information):
    ```
    "0x....","1","3","2000000000000000000000","0x46765939697a514462737a7a46556b437a65643435547039785062754b4e516e4d563150676b385959444b43573476","0x7d3037fa9f8f253e4e7fc930f0a299cbd6eac349"
    ```

### View Claim Eligibility to MSB & Obtain Generated Lock Contract Address

* Click `signalWalletStructs` after entering the following arguments to run that function of the deployed Lockdrop contract to view information about your signal and claim status. 
  * 1st arg: Ethereum Account
  * 2nd arg: MXCToken address

  e.g.
  ```
  "0xf0066Db8F8f2c86B2713f09090DDE33C558D03F0","0x7d3037fa9f8f253e4e7fc930f0a299cbd6eac349"
  ```

### Set Claim Eligibility to MSB of the Signal

* Click `setClaimStatus` after entering the following arguments to run that function of the deployed Lockdrop contract and to set the claim eligibility. Replace the following arguments. Sign transaction with Metamask. Note: This should be performed after the Signal term. Only the owner of the Ethereum Account Address that deployed the Lockdrop contract may run this.
  * 1st arg: Ethereum Account Address (that Signaled)
  * 2nd arg: Claim Type of Signal `1` (whether we're setting the claim eligibility of a Lock or a Signal for the given Ethereum Account Address)
  * 3rd arg: MXCToken address
  * 4th arg: Claim Status of either Pending `0` or Finalized `1` (setting to finalized indicates to the participant that Locked or Signaled that their claim eligibility has been finalized so they're DataHighway Public Key may obtain the relevant MSB when staking on the DataHighway. WARNING: Once it is set to finalized it is not possible to set it as pending again)
  * 5th arg: Approved Amount of MXC tokens (e.g. 700 MXC)
  * 6th arg: Pending Amount of MXC tokens (e.g. 0 MXC)
  * 7th arg: Rejected Amount of MXC tokens (e.g. 1300 MXC)
  * Note: The sum of the 5th, 6th, and 7th args must equal the amount of MXC tokens they indicated they wanted to Signal.

  e.g.
  ```
  "0xf0066Db8F8f2c86B2713f09090DDE33C558D03F0","0","0x7d3037fa9f8f253e4e7fc930f0a299cbd6eac349","1","700000000000000000000","0","1300000000000000000000"
  ```

### Setup DataHighway App

The DataHighway App codebase is at https://github.com/DataHighway-DHX/app.

#### Update the Environment Variables in the DataHighway App

* Create a .env file in the project root directory (which also contains the pubspec.yaml file)
* Paste the following into the .env file:
  ```
  MNENOMIC = <PLEASE ASK LUKE SCHOEN FOR THIS>
  ETHEREUM_ADDRESS = 0xf0066Db8F8f2c86B2713f09090DDE33C558D03F0
  CONTRACT_ADDRESS_LOCKDROP_TESTNET = 0x712582a25d7b47628a52e372f3add72683bb9962
  CONTRACT_ADDRESS_MXC_TESTNET = 0x7d3037fa9f8f253e4e7fc930f0a299cbd6eac349
  CONTRACT_ADDRESS_IOTA_PEGGED_TESTNET = 0x7d3037fa9f8f253e4e7fc930f0a299cbd6eac349
  CONTRACT_ADDRESS_LOCKDROP_MAINNET = ''
  CONTRACT_ADDRESS_MXC_MAINNET = 0x5Ca381bBfb58f0092df149bD3D243b08B9a8386e
  CONTRACT_ADDRESS_IOTA_PEGGED_MAINNET = ''
  INFURA_API_PROJECT_ID = <PLEASE ASK LUKE SCHOEN FOR THIS OR OBTAIN YOUR OWN>
  ENVIRONMENT = "testnet"
  ```
  * Note: An Infura API Project ID may be obtained for free from https://infura.io.

#### Import DataHighway Account

If you want to import a DataHighway Account, then click the menu icon and choose "Create Account", and then
select "Import Account".

* Select "Source Type" and choose whatever you have available depending on how you created your account.
If you have a "Secret seed" (aka "Raw Seed") then choose that option, otherwise if you have a "Mnemonic" then choose that option.
* Enter the value for the source type chosen
* Click "Advanced Options" and select the "Encrypt Type" that matches that used when the account was created.

Note: In the DataHighway Harbor Testnet the Alice in-built account exists, so if you enter a "Mnemonic Seed" value of "bottom drive obey lake curtain smoke basket hold race lonely fit walk", then enter and repeat a password, and then in "Advanced Creation Options" for "Encryption Type", choose "sr25519", and for "Secret derivation path", enter "//Alice", then click "Next Step" and it will load an account with a balance of DHX.

Note: If the DHX DAO account is imported, then it should display 30% of the total supply as the account balance in DHX. Pending this PR being merged and latest changes deployed https://github.com/DataHighway-DHX/node/pull/94

#### View Claim Eligibility

After logging in, in the "Mining" tab, click the "down arrow" icon in the MXC section to view the Claim Eligibility (MXC) of the account that it will retrieve from the DataHighway Harbor Testnet

#### Runtime Upgrade

To upgrade the DataHighway runtime using the Sudo module and the DHX-DAO account.

* Import a DataHighway account that has Sudo access
  * Go to https://polkadot.js.org/apps/#/accounts
  * Click "Add Account"
  * Enter name "Alice"
  * Select "Mnemonic Seed" option for the input field "Mnemonic Seed"
    * Paste value "bottom drive obey lake curtain smoke basket hold race lonely fit walk"
  * Enter a password and repeat it
  * In "Advanced Creation Options"
    * For "keypair crypto type", choose "sr25519"
    * For "secret derivation path", enter "//Alice" 
  * Click "Save"
  * Check the account has a balance of DHX

* Increment the spec_version in the ./node/runtime/src/lib.rs of repo https://github.com/DataHighway-DHX/node
* Build the latest changes. See instructions here in EXAMPLE.md: https://github.com/DataHighway-DHX/node/pull/94/files#diff-27b714cfcd9ee7241d8db7efa832b94a
  ```
  curl https://getsubstrate.io -sSf | bash -s -- --fast && \
  ./scripts/init.sh && \
  cargo build --release
  ```
* Find the WASM blob file in the compiled directory (i.e. ./node/target/release/wbuild/datahighway_runtime/datahighway_runtime.compact.wasm)
* Go to https://polkadot.js.org/apps/#/extrinsics (OR https://polkadot.js.org/apps/#/sudo)
* Select the "Alice" account (that has a balance of DHX of more than 0)
* Click "system" > "setCode" > Click "document" icon, and select the .wasm file or drag and drop it.
* Click "Submit Transaction"

Reference: https://youtu.be/0eNGZpNkJk4?t=2002
