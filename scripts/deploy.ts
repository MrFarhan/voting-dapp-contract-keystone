import { ethers } from "hardhat";

async function main() {
  console.log("🚀 Starting deployment...\n");

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying contracts with account:", deployer.address);

  // Get account balance
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(balance), "ETH\n");

  // Deploy VotingSystem contract
  console.log("📦 Deploying VotingSystem contract...");
  const VotingSystem = await ethers.getContractFactory("VotingSystem");
  const votingSystem = await VotingSystem.deploy();
  await votingSystem.waitForDeployment();

  const contractAddress = await votingSystem.getAddress();
  console.log("✅ VotingSystem deployed to:", contractAddress);

  // Save deployment info
  const deploymentInfo = {
    network: (await ethers.provider.getNetwork()).name,
    chainId: (await ethers.provider.getNetwork()).chainId.toString(),
    contractAddress: contractAddress,
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
  };

  console.log("\n📄 Deployment Summary:");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("Network:", deploymentInfo.network);
  console.log("Chain ID:", deploymentInfo.chainId);
  console.log("Contract Address:", deploymentInfo.contractAddress);
  console.log("Deployer:", deploymentInfo.deployer);
  console.log("Timestamp:", deploymentInfo.timestamp);
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
  console.log("1. Copy the contract address to your .env file");
  console.log("2. Update VITE_CONTRACT_ADDRESS in .env");
  console.log("3. Start the frontend with: npm run dev\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
