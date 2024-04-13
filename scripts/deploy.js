const { ethers } = require("ethers");

async function main() {


  const StakeToken = await hre.ethers.deployContract("StakeToken");

  await StakeToken.waitForDeployment();

  console.log(
    `StakeToken deployed to ${StakeToken.target}`
  );



  const RewardToken = await hre.ethers.deployContract("RewardToken");

  await RewardToken.waitForDeployment();

  console.log(
    `RewardToken deployed to ${RewardToken.target}`
  );


  const StakingPool = await hre.ethers.deployContract("StakingPool", [StakeToken, RewardToken]);

  await StakingPool.waitForDeployment();

  console.log(
    `StakingPool deployed to ${StakingPool.target}`
  );

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
