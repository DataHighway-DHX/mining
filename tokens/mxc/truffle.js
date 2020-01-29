// Allows us to use ES6 in our migrations and tests.
require('@babel/register');

// Default Bulder for Truffle >v3.0
var DefaultBuilder = require("truffle-default-builder");

module.exports = {
  /*
   * Build config of front-end that uses `build` to either
   * invokes Default Builder or Custom Build Pipeline process (i.e. webpack).
   *
   * Notes:
   * - If string specified on right hand side ends in a "/" it is interpreted as a directory
   * - All paths specified on right hand side are relative to the app/ directory
   * - Build target must only be called app.js for the Default Builder to append code to 
   *
   * Reference: 
   * - https://github.com/trufflesuite/truffle-default-builder/tree/master
   * - http://truffleframework.com/docs/advanced/build_processes
   */
  
  // Runs the `webpack` command on each build.
  //
  // The following environment variables are set when running the command:
  // WORKING_DIRECTORY: root location of the project
  // BUILD_DESTINATION_DIRECTORY: expected destination of built assets (important for `truffle serve`)
  // BUILD_CONTRACTS_DIRECTORY: root location of your build contract files (.sol.js)
  //
  build: "webpack",
  // RPC details of how to connect to Ethereum client for each network
  // 
  // Options:
  // - `host` and `port` keys required
  // 
  rpc: {
    host: "localhost",
    port: 8545
  },
  // Networks optionally specified so that when contract abstractions detect that Ethereum client is 
  // connected to specific network it uses specific contract artifacts that were saved and 
  // recorded earlier during compiling and migrations that are associated with that network 
  // to simplify app deplyment.
  // 
  // Notes: 
  // - Networks identified through Ethereums `net_version` RPC call
  // - `networks` object has network name as key, and value is object defining parameters 
  //   of the network.
  //   - Must specify `network_id` with value (i.e. `default` for catch-all, `*`)
  //     - `default` network used during development where contract artifacts not matter long-term
  //     and `network_id` continuously chances if TestRPC is restarted
  networks: {
    // Optional config values:
    // - host - Hostname pointing to networ location of Ethereum client 
    //   (defaults to "localhost" for development)
    // - port - Port number where Ethereum client accepts requests (defaults to 8545)
    // - gas - Gas limit for deploys (default is 3141592)
    // - gasPrice - Gas price used for deploys (default is 100000000000) (100 Shannon)
    // - from - From address used during any transaction Truffle makes during migrations
    //   (defaults to first available account provided by Ethereum client)
    //
    // Ethereum public network
    "live": {
      network_id: 1,
    },
    // Official Ethereum test network with Random IP
    "morden": {
      network_id: 2,
      host: "178.25.19.88",
      port: 80             
    },
    // Custom private network using default rpc settings
    "staging": {
      network_id: 1337
    },
    "development": {
      accounts: 5,
      blockTime: 3,
      defaultEtherBalance: 500,
      host: "localhost",
      port: 8545,
      // `default` - Catch-all
      // `*` - Match any network id
      network_id: "*",
      networkCheckTimeout: "10000"
    }
  },
  // Config options for Mocha testing framework
  mocha: {
    useColors: true
  }
};
