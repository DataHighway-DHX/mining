// http://truffleframework.com/docs/getting_started/migrations

// Truffle informed of contracts we wish to interact with. 
// - Variable name should match name of Contract Definition within source file
var Migrations = artifacts.require("./Migrations.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
