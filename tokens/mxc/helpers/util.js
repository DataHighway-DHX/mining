// Import globally
require("regenerator-runtime/runtime");
const regeneratorRuntime = require("regenerator-runtime");
// const Promise = require('bluebird');

async function getCurrentBlock(web3) {
  return new Promise((resolve, reject) => {
    web3.eth.getBlock('latest', function (err, res) {
      if (err) return reject(err);
      resolve(res);
    });
  });
}

async function getCurrentAccountBalance(web3, address) {
  return new Promise((resolve, reject) => {
    web3.eth.getBalance(address, function (err, res) {
      if (err) return reject(err);
      resolve(res);
    });
  });
}

async function getCurrentTimestamp(web3) {
  const block = await getCurrentBlock(web3);
  return block.timestamp;
}

async function getAccountBalance(web3, address) {
  const balance = await getCurrentAccountBalance(web3, address);
  return balance;
}

module.exports = {
  getAccountBalance,
  getCurrentBlock,
  getCurrentTimestamp,
};
