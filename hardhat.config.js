import('hardhat/config.js').HardhatUserConfig

require('@nomicfoundation/hardhat-ethers');
require("@bonadocs/docgen");
require("dotenv").config();

const { ALCHEMY_SEPOLIA_API_KEY_URL, ACCOUNT_PRIVATE_KEY, ETHERSCAN_API_KEY } = process.env;
module.exports = {
  solidity: "0.8.20",
  networks: {
    sepolia: {
      url: ALCHEMY_SEPOLIA_API_KEY_URL,
      accounts: [`0x${ACCOUNT_PRIVATE_KEY}`],
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
  docgen: {
    projectName: "Staking pool",
    projectDescription:
      "An Platform that allows users to create staking pools, stake, claim rewards and unstake.",
    outputDir: "./site",
    deploymentAddresses: {
      StakingPool: [
        {
          chainId: 11155111, // sepolia testnet
          address: "0xE3A6B5176e2E9132Ea2C19E0348e80746f681d5A",
        },
      ],
      StakeToken: [
        {
          chainId: 11155111, // sepolia testnet
          address: "0x48E12d7251CbCCAa64Bfb127a917555d88fccA93",
        },
      ],
      RewardToken: [
        {
          chainId: 11155111, // sepolia testnet
          address: "0x18204e829898696579122482899Db3fE20733197",
        },
      ],
    },
  },
};
