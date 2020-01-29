
// var Owned = artifacts.require("./Owned.sol");
// var ConvertLib = artifacts.require("./lib/ConvertLib.sol");
const MAINNET_LAUNCH_UNIX_TIME =  require("../helpers/constants");
const utility = require("../helpers/util");
const StandardToken = artifacts.require("./lib/StandardToken.sol");
const MXCToken = artifacts.require("./lib/MXCToken.sol");
const Lockdrop = artifacts.require("./Lockdrop.sol");

module.exports = async (deployer, network, accounts) => {
  let time;
  if (network === 'ropsten' || network === 'development') {
    time = await utility.getCurrentTimestamp(web3);
  } else {
    time = MAINNET_LAUNCH_UNIX_TIME;
  }
  await deployer.deploy(Lockdrop, time);
  await deployer.deploy(StandardToken, time);
  await deployer.link(StandardToken, MXCToken);
  await deployer.deploy(MXCToken, time);

  console.log("Deploying Contract on Network: ", network);
  console.log("Deploying Contract on using Accounts: ", accounts);
};
