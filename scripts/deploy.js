const { ethers } = require("hardhat");

const SUBSCRIPTION_PRICE    = ethers.parseEther("0.01");  // 0.01 ETH
const SUBSCRIPTION_DURATION = 30n * 24n * 60n * 60n;      // 30 days in seconds

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying with account:", deployer.address);
  console.log(
    "Account balance:",
    ethers.formatEther(await ethers.provider.getBalance(deployer.address)),
    "ETH"
  );

  const Factory = await ethers.getContractFactory("OnChainSubscription");

  console.log("\nDeploying OnChainSubscription...");
  const contract = await Factory.deploy(SUBSCRIPTION_PRICE, SUBSCRIPTION_DURATION);
  await contract.waitForDeployment();

  const address = await contract.getAddress();

  console.log("\n✅ OnChainSubscription deployed!");
  console.log("   Address  :", address);
  console.log("   Price    :", ethers.formatEther(SUBSCRIPTION_PRICE), "ETH / period");
  console.log("   Duration :", Number(SUBSCRIPTION_DURATION) / 86400, "days");
  console.log("   Owner    :", deployer.address);
  console.log("\nVerify on Etherscan:");
  console.log(
    `   npx hardhat verify --network <network> ${address} ${SUBSCRIPTION_PRICE} ${SUBSCRIPTION_DURATION}`
  );
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
