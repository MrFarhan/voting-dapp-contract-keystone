import { ethers } from "hardhat";

/**
 * This script demonstrates how to interact with the deployed VotingSystem contract
 * Useful for testing contract functions manually
 */
async function main() {
  console.log("🔗 Interacting with VotingSystem contract...\n");

  // Get signers
  const [admin, voter1, voter2, voter3] = await ethers.getSigners();
  console.log("Admin address:", admin.address);
  console.log("Voter 1 address:", voter1.address);
  console.log("Voter 2 address:", voter2.address);
  console.log("Voter 3 address:", voter3.address);
  console.log("");

  // Connect to deployed contract (update this address after deployment)
  const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS || "";
  
  if (!CONTRACT_ADDRESS) {
    console.error("❌ Please set CONTRACT_ADDRESS in your .env file");
    process.exit(1);
  }

  const VotingSystem = await ethers.getContractFactory("VotingSystem");
  const votingSystem = VotingSystem.attach(CONTRACT_ADDRESS);

  // 1. Register voters
  console.log("📝 Registering voters...");
  await votingSystem.registerVotersBatch([
    voter1.address,
    voter2.address,
    voter3.address,
  ]);
  console.log("✅ Voters registered\n");

  // 2. Create an election
  console.log("🗳️  Creating election...");
  const currentTime = Math.floor(Date.now() / 1000);
  const startTime = currentTime + 60; // Starts in 1 minute
  const endTime = startTime + 3600; // Ends 1 hour after start

  const tx = await votingSystem.createElection(
    "University Student Council Election 2026",
    "Vote for your student council representatives",
    startTime,
    endTime
  );
  await tx.wait();
  console.log("✅ Election created with ID: 1\n");

  // 3. Add candidates
  console.log("👥 Adding candidates...");
  await votingSystem.addCandidate(1, "Alice Johnson", "Computer Science Major, 3rd Year");
  await votingSystem.addCandidate(1, "Bob Smith", "Engineering Major, 4th Year");
  await votingSystem.addCandidate(1, "Carol Davis", "Business Major, 2nd Year");
  console.log("✅ Candidates added\n");

  // 4. Get election details
  console.log("📊 Election Details:");
  const election = await votingSystem.getElection(1);
  console.log("Title:", election.title);
  console.log("Description:", election.description);
  console.log("Start Time:", new Date(Number(election.startTime) * 1000).toLocaleString());
  console.log("End Time:", new Date(Number(election.endTime) * 1000).toLocaleString());
  console.log("Is Active:", election.isActive);
  console.log("Total Votes:", election.totalVotes.toString());
  console.log("Candidate Count:", election.candidateCount.toString());
  console.log("");

  // 5. Get all candidates
  console.log("👥 Candidates:");
  const candidates = await votingSystem.getAllCandidates(1);
  candidates.forEach((candidate, index) => {
    console.log(`${index + 1}. ${candidate.name} - ${candidate.description}`);
    console.log(`   Votes: ${candidate.voteCount.toString()}`);
  });
  console.log("");

  console.log("✅ Interaction complete!");
  console.log("\nNote: To cast votes, wait for the election to start and run the voting script");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error:", error);
    process.exit(1);
  });
