const HTTPProviderRateLimitRetry = require('./lib/http-provider-rate-limit-retry')
var Web3 = require('web3');

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
      provider: () => {
        
        return new Web3.providers.HttpProvider("https://e0y5m5su8t:XaVqiiHpPwn082p-i5uIberKPxxcMDOThWXf46gBPPo@e0f89v2ex3-e0b2kv5nv4-rpc.de0-aws.kaleido.io")
      },
      network_id: "*", // Match any network id
      gasPrice: 0,
      gas: 4500000,
      disableConfirmationListener: true, // generates thousands of eth_getBlockByNumber calls
      timeoutBlocks: 3,
      deploymentPollingInterval: 5000,
      /* type: 'quorum' // Use this property for Quorum environments */
    },
  },
  mocha: {
    enableTimeouts: false,
    before_timeout: 600000
  },
  compilers: {
    solc: {
      version: "0.5.0",
      settings: {
        evmVersion: "constantinople"
      }
    },
  }
};
