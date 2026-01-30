import { ethers } from "hardhat";

async function main() {
  console.log("🚀 Starting BSV deployment...\n");

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying contracts with account:", deployer.address);

  // Get account balance
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(balance), "ETH\n");

  // Deploy MockStakingToken first
  console.log("📦 Deploying MockStakingToken...");
  const MockStakingToken = await ethers.getContractFactory("MockStakingToken");
  const stakingToken = await MockStakingToken.deploy();
  await stakingToken.waitForDeployment();
  const tokenAddress = await stakingToken.getAddress();
  console.log("✅ MockStakingToken deployed to:", tokenAddress);

  // Deploy VotingSystem contract with staking token
  console.log("📦 Deploying VotingSystem (BSV) contract...");
  const VotingSystem = await ethers.getContractFactory("VotingSystem");
  const votingSystem = await VotingSystem.deploy(tokenAddress);
  await votingSystem.waitForDeployment();

  const contractAddress = await votingSystem.getAddress();
  console.log("✅ VotingSystem deployed to:", contractAddress);

  // Add deployer as a member automatically
  console.log("\n👥 Setting up initial membership...");
  const tx = await votingSystem.addMember(deployer.address);
  await tx.wait();
  console.log("✅ Deployer added as verified member");

  // Save deployment info
  const deploymentInfo = {
    network: (await ethers.provider.getNetwork()).name,
    chainId: (await ethers.provider.getNetwork()).chainId.toString(),
    contractAddress: contractAddress,
    stakingTokenAddress: tokenAddress,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    version: "0.1.0",
    features: {
      staking: true,
      weightedVoting: true,
      membershipGated: true,
      baseWeight: "1.0",
      maxWeight: "2.0",
      formula: "weight = 1.0 + sqrt(stake / 100)"
    }
  };

  console.log("\n📄 Deployment Summary:");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("Network:", deploymentInfo.network);
  console.log("Chain ID:", deploymentInfo.chainId);
  console.log("VotingSystem Address:", deploymentInfo.contractAddress);
  console.log("Staking Token Address:", deploymentInfo.stakingTokenAddress);
  console.log("Deployer:", deploymentInfo.deployer);
  console.log("Timestamp:", deploymentInfo.timestamp);
  console.log("Version:", deploymentInfo.version);
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
  console.log("✨ Features:");
  console.log("  • Stake-based vote weighting");
  console.log("  • Base weight: 1.0 for all members");
  console.log("  • Max weight: 2.0 (capped)");
  console.log("  • Diminishing returns formula");
  console.log("  • Membership-gated voting");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

  // Save to file
  const fs = await import("fs/promises");
  const path = await import("path");
  
  const deploymentsDir = path.join(process.cwd(), "deployments");
  try {
    await fs.mkdir(deploymentsDir, { recursive: true });
  } catch (error) {
    // Directory already exists
  }

  const filename = `deployment-${deploymentInfo.network}-${Date.now()}.json`;
  const filepath = path.join(deploymentsDir, filename);
  await fs.writeFile(filepath, JSON.stringify(deploymentInfo, null, 2));

  // Also save latest deployment
  const latestPath = path.join(deploymentsDir, `latest-${deploymentInfo.network}.json`);
  await fs.writeFile(latestPath, JSON.stringify(deploymentInfo, null, 2));

  console.log("💾 Deployment info saved to:", filename);
  console.log("\n🎉 Deployment complete!\n");
  console.log("Next steps:");
  console.log("1. Copy the contract addresses to your .env file");
  console.log("2. Update VITE_CONTRACT_ADDRESS and VITE_TOKEN_ADDRESS");
  console.log("3. Use the staking token to test vote weighting");
  console.log("4. Add members using addMember() function\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
