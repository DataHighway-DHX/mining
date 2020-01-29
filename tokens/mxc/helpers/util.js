// Import globally
require("regenerator-runtime/runtime");
const regeneratorRuntime = require("regenerator-runtime");
// const Promise = require('bluebird');

function getCurrentBlock(web3) {
  return new Promise((resolve, reject) => {
    web3.eth.getBlock('latest', function (err, res) {
      if (err) return reject(err);
      resolve(res);
    });
  });
}

async function getCurrentTimestamp(web3) {
  const block = await getCurrentBlock(web3);
  return block.timestamp;
}

module.exports = {
  getCurrentBlock,
  getCurrentTimestamp,
};
