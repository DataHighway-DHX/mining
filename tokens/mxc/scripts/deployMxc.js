// https://www.trufflesuite.com/docs/truffle/getting-started/writing-external-scripts#file-structure
module.exports = function(callback) {
  const Web3 = require('web3');
  const contract = require("truffle-contract");
  const utility = require('../helpers/util');
  const artifacts = require('../build/contracts/MXCToken.json');

  const HTTP_PROVIDER_ENDPOINT = "http://127.0.0.1:8545";
  const WS_PROVIDER_ENDPOINT = "ws://127.0.0.1:8545";
  // 0xd3806d52cfc265Ea6a8Ae264dC3FeDa92cF1Be84
  const MXC_TOKEN_CONTRACT_ADDRESS = '0xd3806d52cfc265Ea6a8Ae264dC3FeDa92cF1Be84';
  const MXCToken = contract(artifacts);
  // var web3 = new Web3(Web3.givenProvider || "ws://localhost:8545");
  // const provider = new Web3.providers.HttpProvider(HTTP_PROVIDER_ENDPOINT);
  const provider = Web3.givenProvider || new Web3.providers.WebsocketProvider(WS_PROVIDER_ENDPOINT);
  const web3 = new Web3(provider);

  // TODO - move into utility
  async function isListening() { 
    return await new Promise(resolve => {
      web3.eth.net.isListening()
        .then((res) => {
          console.log('Node is listening for peers: ', res);
          resolve(res);
        });
    });
  }

  // TODO - move into utility
  async function getAccounts() { 
    return await new Promise(resolve => {
      web3.eth.getAccounts()
        .then((res) => {
          console.log('Accounts: ', res);
          resolve(res);
        });
    });
  }

  // TODO - move into utility
  async function networkId() { 
    return await new Promise(resolve => {
      web3.eth.net.getId()
        .then((res) => {
          console.log('Network ID: ', res);
          resolve(res);
        });
    });
  }

  // TODO - move into utility
  async function contractTransfer(accounts, MXCTokenContractInstance) {
    console.log('contractTransfer');
    return await new Promise((resolve, reject) => {
      MXCTokenContractInstance.methods.transfer(accounts[2], 10).call({from: accounts[0]}).then(function(result) {
        console.log('result', result);
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
        resolve(result);
      }).catch(function(e) {
        console.log("Error running MXCToken.sol function transfer: ", e);
        reject(e);
      })
    });
  }

  async function createContractInstance(accounts) {
    return await new Promise((resolve, reject) => {
      if (err) return reject(err);
      const res = web3.eth.Contract(MXCToken.abi, MXC_TOKEN_CONTRACT_ADDRESS, {gasPrice: '12345678', from: accounts[0]});
      console.log('MXCTokenContractInstance: ', res);
      resolve(res);
    });
  }

  isListening();
  getAccounts().then((accounts) => {
    // // Note: Obtained private keys from output shown when running `truffle develop`
    // const ALICE_PRIVATE_KEY = '7d7277b0e05f6db32f979fd75cbdc901f99eb5f25bdb79be1ef1e41424e90b43';
    // const BOB_PRIVATE_KEY = '46060b676767b729c3c017497aa7764ac22bdc9e75eda8df5bd3e0b5116cc6d2';
    // web3.eth.accounts.wallet.add(ALICE_PRIVATE_KEY);
    // web3.eth.accounts.wallet.add(BOB_PRIVATE_KEY);

    // // // Execute Custom Contract (MXCToken) Functions on Ethereum Network (i.e. we * previously created
    // // // the following functions in MXCToken.sol: sendCoin, getBalanceInEth, getBalance)

    // // Get reference to the 2x Ethereum Account Addresses we created on the Ethereum.js TestRPC network:
    // var account_one = web3.eth.accounts.wallet[0].address;
    // web3.eth.defaultAccount = account_one
    // var account_two = web3.eth.accounts.wallet[1].address;

    // Show Account Balances
    const aliceBalance = utility.getAccountBalance(web3, accounts[0]);
    aliceBalance.then(function(result) {
      console.log('Alice balance:', result);
    })

    const bobBalance = utility.getAccountBalance(web3, accounts[1]);
    bobBalance.then(function(result) {
      console.log('Bob balance:', result);
    })

    const currentBlockTimestamp = utility.getCurrentTimestamp(web3);
    currentBlockTimestamp.then(function(result) {
      console.log('Timestamp of current block:', result);
    })

    // Call the Contract Abstractions `transfer` function directly
    // (passing a special object as the last parameter that allows Editing of
    // specific transaction details) that results 
    // in a `transaction` (WRITE DATA instead of a `call`) and callback function * only fires when transaction successful
    // Refer to alternative better approach using `MXCToken.at(...)`: https://github.com/trufflesuite/truffle-contract

    var mxcTokenInstance;

    MXCToken.setProvider(provider);
    // MXCToken.setProvider(web3.eth.currentProvider);
    // console.log('MXCToken: ', MXCToken);
    // console.log('MXCToken.deployed()', MXCToken.at('0x2ac4A7eeF0521C2088202c4307F6744238296854'))
    // MXCToken.deployed().then(function(instance) {

    networkId();

    // console.log('web3.eth.Contract', web3.eth.Contract)
    // console.log('MXC_TOKEN_CONTRACT_ADDRESS', MXC_TOKEN_CONTRACT_ADDRESS)
    // console.log('MXCToken.address', MXCToken.address)

    // Load the contract schema from the abi
    // const MXCTokenContract = new web3.eth.Contract(MXCToken.abi, MXCToken.address, {gasPrice: '12345678', from: account_one});
    // FIXME - this is not responding
    const MXCTokenContractInstance = createContractInstance(accounts);
    // console.log('MXCTokenContract', MXCTokenContract)
    MXCTokenContractInstance.setProvider(provider);

    // console.log('web3.eth', web3.eth)
    // web3.eth.defaultCommon.customChain.networkId = 5777;

    contractTransfer(accounts, MXCTokenContractInstance);
  });

  // // Call the Contract Abstractions `getBalance` function using 
  // // a `call` (READ DATA instead of a `transaction`) so Ethereum network 
  // // knows we do not intend to persist any changes, and callback function 
  // // only fires when call is successful. Instead returns a value (instead
  // // of just a Transaction ID like with `transaction`) of MXCToken balance 
  // // as BigNumber object at address that is passed to it.

  // var mxcTokenInstance;
  // MXCToken.deployed().then(function(instance) {
  // 	mxcTokenInstance = instance;
  // 	return mxcTokenInstance.getBalance.call(account_one, {from: account_one});
  // }).then(function(balance) {
  // 	// Callback is called when 'call' was successfully executed
  // 	// Callback returns immediately without any waiting
  // 	console.log("Balance is: ", balance.toNumber());
  // }).catch(function(e) {
  // 	console.log("Error running MXCToken.sol function getBalance");
  // })

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
}
