import { ethers } from "hardhat";
import * as fs from "fs/promises";
import * as path from "path";

/**
 * Deploy VotingSystemOptimized (Gas-Optimized Version) to Testnet
 * 
 * This script deploys the gas-optimized version of the BSV contract
 * which saves up to 20% on gas costs.
 * 
 * Usage:
 * npx hardhat run scripts/deploy-optimized-testnet.ts --network sepolia
 */

async function main() {
  console.log("\n⚡ Deploying Gas-Optimized BSV to Testnet...\n");

  // Get network info
  const network = await ethers.provider.getNetwork();
  const networkName = network.name === "unknown" ? "sepolia" : network.name;
  const chainId = network.chainId.toString();

  console.log("🌐 Network:", networkName);
  console.log("🔗 Chain ID:", chainId);

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("📝 Deploying with account:", deployer.address);

  // Get account balance
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("💰 Account balance:", ethers.formatEther(balance), "ETH");

  // Check if balance is sufficient
  if (balance < ethers.parseEther("0.01")) {
    console.warn("\n⚠️  WARNING: Low balance. You may need more ETH for deployment.");
    console.log("   Recommended: At least 0.01 ETH for testnet deployment\n");
  }

  console.log("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("  DEPLOYING CONTRACTS");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

  // Step 1: Deploy MockStakingToken
  console.log("1️⃣  Deploying MockStakingToken...");
  const MockStakingToken = await ethers.getContractFactory("MockStakingToken");
  const stakingToken = await MockStakingToken.deploy();
  await stakingToken.waitForDeployment();
  const tokenAddress = await stakingToken.getAddress();
  console.log("   ✅ MockStakingToken deployed to:", tokenAddress);

  // Wait for a few blocks for better reliability
  console.log("   ⏳ Waiting for 2 block confirmations...");
  await stakingToken.deploymentTransaction()?.wait(2);
  console.log("   ✅ Confirmed!\n");

  // Step 2: Deploy VotingSystemOptimized
  console.log("2️⃣  Deploying VotingSystemOptimized (Gas-Optimized BSV)...");
  const VotingSystemOptimized = await ethers.getContractFactory("VotingSystemOptimized");
  const votingSystem = await VotingSystemOptimized.deploy(tokenAddress);
  await votingSystem.waitForDeployment();
  const contractAddress = await votingSystem.getAddress();
  console.log("   ✅ VotingSystemOptimized deployed to:", contractAddress);

  // Wait for confirmations
  console.log("   ⏳ Waiting for 2 block confirmations...");
  await votingSystem.deploymentTransaction()?.wait(2);
  console.log("   ✅ Confirmed!\n");

  // Step 3: Setup initial membership
  console.log("3️⃣  Setting up initial membership...");
  const tx = await votingSystem.addMember(deployer.address);
  console.log("   ⏳ Waiting for transaction confirmation...");
  await tx.wait(1);
  console.log("   ✅ Deployer added as verified member\n");

  // Step 4: Verify deployment
  console.log("4️⃣  Verifying deployment...");
  const isMember = await votingSystem.isMember(deployer.address);
  const tokenAddr = await votingSystem.stakingToken();
  
  if (isMember && tokenAddr === tokenAddress) {
    console.log("   ✅ Deployment verification passed!\n");
  } else {
    console.error("   ❌ Deployment verification failed!");
    process.exit(1);
  }

  // Create deployment info
  const deploymentInfo = {
    network: networkName,
    chainId: chainId,
    contractAddress: contractAddress,
    stakingTokenAddress: tokenAddress,
    deployer: deployer.address,
    deployerBalance: ethers.formatEther(balance),
    timestamp: new Date().toISOString(),
    version: "0.2.0",
    contractType: "VotingSystemOptimized",
    gasOptimizations: {
      customErrors: true,
      immutableVariables: true,
      cachedStorageReads: true,
      uncheckedArithmetic: true,
      calldataParameters: true,
      estimatedSavings: "Up to 20% on expensive operations"
    },
    features: {
      staking: true,
      weightedVoting: true,
      membershipGated: true,
      baseWeight: "1.0",
      maxWeight: "2.0",
      formula: "weight = 1.0 + sqrt(stake / 100)"
    },
    blockNumber: await ethers.provider.getBlockNumber(),
    transactionHashes: {
      token: stakingToken.deploymentTransaction()?.hash,
      votingSystem: votingSystem.deploymentTransaction()?.hash,
      membership: tx.hash
    }
  };

  // Display summary
  console.log("\n╔════════════════════════════════════════════════════════╗");
  console.log("║           DEPLOYMENT SUCCESSFUL! ⚡                    ║");
  console.log("╚════════════════════════════════════════════════════════╝\n");
  console.log("📄 DEPLOYMENT SUMMARY");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("Network:              ", networkName);
  console.log("Chain ID:             ", chainId);
  console.log("Contract Version:     ", deploymentInfo.version);
  console.log("Contract Type:        ", deploymentInfo.contractType);
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("VotingSystem:         ", contractAddress);
  console.log("Staking Token:        ", tokenAddress);
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("Deployer:             ", deployer.address);
  console.log("Balance:              ", deploymentInfo.deployerBalance, "ETH");
  console.log("Block Number:         ", deploymentInfo.blockNumber);
  console.log("Timestamp:            ", deploymentInfo.timestamp);
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

  console.log("✨ GAS OPTIMIZATIONS");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("✓ Custom errors instead of require strings");
  console.log("✓ Immutable stakingToken variable");
  console.log("✓ Cached storage reads");
  console.log("✓ Unchecked arithmetic where safe");
  console.log("✓ Calldata parameters for external functions");
  console.log("✓ Estimated savings: Up to 20%");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

  console.log("✨ BSV FEATURES");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("✓ Stake-based vote weighting");
  console.log("✓ Base weight: 1.0 for all members");
  console.log("✓ Max weight: 2.0 (capped)");
  console.log("✓ Diminishing returns: sqrt(stake / 100)");
  console.log("✓ Membership-gated voting");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

  // Save deployment info
  const deploymentsDir = path.join(process.cwd(), "deployments");
  await fs.mkdir(deploymentsDir, { recursive: true });

  const filename = `deployment-${networkName}-optimized-${Date.now()}.json`;
  const filepath = path.join(deploymentsDir, filename);
  await fs.writeFile(filepath, JSON.stringify(deploymentInfo, null, 2));

  // Save latest deployment
  const latestPath = path.join(deploymentsDir, `latest-${networkName}-optimized.json`);
  await fs.writeFile(latestPath, JSON.stringify(deploymentInfo, null, 2));

  console.log("💾 Deployment info saved to:", filename);
  console.log("💾 Latest deployment:", `latest-${networkName}-optimized.json\n`);

  // Next steps
  console.log("📋 NEXT STEPS");
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  console.log("1. Update your frontend .env file:");
  console.log(`   VITE_CONTRACT_ADDRESS=${contractAddress}`);
  console.log(`   VITE_TOKEN_ADDRESS=${tokenAddress}`);
  console.log(`   VITE_CHAIN_ID=${chainId}`);
  console.log("");
  console.log("2. Verify contracts on Etherscan (if API key configured):");
  console.log(`   npx hardhat verify --network ${networkName} ${contractAddress} ${tokenAddress}`);
  console.log(`   npx hardhat verify --network ${networkName} ${tokenAddress}`);
  console.log("");
  console.log("3. Test the deployment:");
  console.log("   - Add members using addMember()");
  console.log("   - Transfer tokens to users");
  console.log("   - Create test elections");
  console.log("   - Verify vote weighting works correctly");
  console.log("");
  console.log("4. View on Block Explorer:");
  if (networkName === "sepolia") {
    console.log(`   VotingSystem: https://sepolia.etherscan.io/address/${contractAddress}`);
    console.log(`   Token: https://sepolia.etherscan.io/address/${tokenAddress}`);
  }
  console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");

  console.log("🎉 Deployment complete!\n");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ Deployment failed:");
    console.error(error);
    process.exit(1);
  });
