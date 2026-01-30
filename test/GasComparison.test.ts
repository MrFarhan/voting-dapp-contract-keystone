import { expect } from "chai";
import { ethers } from "hardhat";
import { VotingSystem, VotingSystemOptimized, MockStakingToken } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("Gas Optimization Comparison", function () {
  let originalContract: VotingSystem;
  let optimizedContract: VotingSystemOptimized;
  let stakingToken: MockStakingToken;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy staking token
    const MockStakingToken = await ethers.getContractFactory("MockStakingToken");
    stakingToken = await MockStakingToken.deploy();

    // Deploy original contract
    const VotingSystem = await ethers.getContractFactory("VotingSystem");
    originalContract = await VotingSystem.deploy(await stakingToken.getAddress());

    // Deploy optimized contract
    const VotingSystemOptimized = await ethers.getContractFactory("VotingSystemOptimized");
    optimizedContract = await VotingSystemOptimized.deploy(await stakingToken.getAddress());

    // Setup: Add members and distribute tokens
    await originalContract.addMember(addr1.address);
    await optimizedContract.addMember(addr1.address);

    await stakingToken.transfer(addr1.address, ethers.parseEther("1000"));
    await stakingToken.connect(addr1).approve(await originalContract.getAddress(), ethers.parseEther("1000"));
    await stakingToken.connect(addr1).approve(await optimizedContract.getAddress(), ethers.parseEther("1000"));
  });

  describe("Gas Usage Comparison", function () {
    it("Should compare gas for adding members", async function () {
      const tx1 = await originalContract.addMember(addr2.address);
      const receipt1 = await tx1.wait();
      const gas1 = receipt1?.gasUsed || 0n;

      const tx2 = await optimizedContract.addMember(addr2.address);
      const receipt2 = await tx2.wait();
      const gas2 = receipt2?.gasUsed || 0n;

      console.log("\n📊 ADD MEMBER");
      console.log("  Original:  ", gas1.toString(), "gas");
      console.log("  Optimized: ", gas2.toString(), "gas");
      console.log("  Saved:     ", (gas1 - gas2).toString(), "gas");
      console.log("  Reduction: ", ((Number(gas1 - gas2) / Number(gas1)) * 100).toFixed(2), "%");
    });

    it("Should compare gas for batch adding members", async function () {
      const members = [addr2.address, await ethers.Wallet.createRandom().getAddress()];

      const tx1 = await originalContract.addMembers(members);
      const receipt1 = await tx1.wait();
      const gas1 = receipt1?.gasUsed || 0n;

      const tx2 = await optimizedContract.addMembers(members);
      const receipt2 = await tx2.wait();
      const gas2 = receipt2?.gasUsed || 0n;

      console.log("\n📊 ADD MULTIPLE MEMBERS (2)");
      console.log("  Original:  ", gas1.toString(), "gas");
      console.log("  Optimized: ", gas2.toString(), "gas");
      console.log("  Saved:     ", (gas1 - gas2).toString(), "gas");
      console.log("  Reduction: ", ((Number(gas1 - gas2) / Number(gas1)) * 100).toFixed(2), "%");
    });

    it("Should compare gas for staking", async function () {
      const stakeAmount = ethers.parseEther("100");

      const tx1 = await originalContract.connect(addr1).stake(stakeAmount);
      const receipt1 = await tx1.wait();
      const gas1 = receipt1?.gasUsed || 0n;

      const tx2 = await optimizedContract.connect(addr1).stake(stakeAmount);
      const receipt2 = await tx2.wait();
      const gas2 = receipt2?.gasUsed || 0n;

      console.log("\n📊 STAKE TOKENS");
      console.log("  Original:  ", gas1.toString(), "gas");
      console.log("  Optimized: ", gas2.toString(), "gas");
      console.log("  Saved:     ", (gas1 - gas2).toString(), "gas");
      console.log("  Reduction: ", ((Number(gas1 - gas2) / Number(gas1)) * 100).toFixed(2), "%");
    });

    it("Should compare gas for creating election", async function () {
      const startTime = Math.floor(Date.now() / 1000) + 3600;
      const endTime = startTime + 86400;

      const tx1 = await originalContract.createElection(
        "Test Election",
        "Description",
        startTime,
        endTime,
        ["Alice", "Bob"],
        ["Candidate A", "Candidate B"]
      );
      const receipt1 = await tx1.wait();
      const gas1 = receipt1?.gasUsed || 0n;

      const tx2 = await optimizedContract.createElection(
        "Test Election",
        "Description",
        startTime,
        endTime,
        ["Alice", "Bob"],
        ["Candidate A", "Candidate B"]
      );
      const receipt2 = await tx2.wait();
      const gas2 = receipt2?.gasUsed || 0n;

      console.log("\n📊 CREATE ELECTION (2 candidates)");
      console.log("  Original:  ", gas1.toString(), "gas");
      console.log("  Optimized: ", gas2.toString(), "gas");
      console.log("  Saved:     ", (gas1 - gas2).toString(), "gas");
      console.log("  Reduction: ", ((Number(gas1 - gas2) / Number(gas1)) * 100).toFixed(2), "%");
    });

    it("Should compare gas for voting", async function () {
      const startTime = Math.floor(Date.now() / 1000);
      const endTime = startTime + 86400;

      // Create elections on both contracts
      await originalContract.createElection(
        "Test",
        "Desc",
        startTime,
        endTime,
        ["Alice"],
        ["Candidate"]
      );
      await optimizedContract.createElection(
        "Test",
        "Desc",
        startTime,
        endTime,
        ["Alice"],
        ["Candidate"]
      );

      // Stake first
      await originalContract.connect(addr1).stake(ethers.parseEther("100"));
      await optimizedContract.connect(addr1).stake(ethers.parseEther("100"));

      const tx1 = await originalContract.connect(addr1).vote(1, 1);
      const receipt1 = await tx1.wait();
      const gas1 = receipt1?.gasUsed || 0n;

      const tx2 = await optimizedContract.connect(addr1).vote(1, 1);
      const receipt2 = await tx2.wait();
      const gas2 = receipt2?.gasUsed || 0n;

      console.log("\n📊 CAST VOTE (with stake)");
      console.log("  Original:  ", gas1.toString(), "gas");
      console.log("  Optimized: ", gas2.toString(), "gas");
      console.log("  Saved:     ", (gas1 - gas2).toString(), "gas");
      console.log("  Reduction: ", ((Number(gas1 - gas2) / Number(gas1)) * 100).toFixed(2), "%");
    });

    it("Should show total gas summary", async function () {
      console.log("\n╔════════════════════════════════════════════════════════╗");
      console.log("║           GAS OPTIMIZATION SUMMARY                     ║");
      console.log("╚════════════════════════════════════════════════════════╝");
      console.log("\n✅ Optimizations Applied:");
      console.log("  • Custom errors instead of require strings");
      console.log("  • Cached storage reads in memory");
      console.log("  • Unchecked arithmetic where safe");
      console.log("  • Immutable stakingToken");
      console.log("  • Bit shift for division by 2");
      console.log("  • Pre-increment (++i) in loops");
      console.log("  • calldata for external function parameters");
      console.log("\n📈 Expected Savings: 10-30% per transaction");
      console.log("💰 Impact: Significant on high-volume operations\n");
    });
  });

  describe("Functionality Verification", function () {
    it("Should maintain identical functionality", async function () {
      // Test that optimized contract produces same results
      const stakeAmount = ethers.parseEther("81");
      
      await originalContract.connect(addr1).stake(stakeAmount);
      await optimizedContract.connect(addr1).stake(stakeAmount);

      const weight1 = await originalContract.calculateVoteWeight(addr1.address);
      const weight2 = await optimizedContract.calculateVoteWeight(addr1.address);

      expect(weight1).to.equal(weight2);
      console.log("\n✅ Vote weight calculation identical:", ethers.formatEther(weight1));
    });

    it("Should handle same edge cases", async function () {
      // Test zero stake
      const weight1 = await originalContract.calculateVoteWeight(addr1.address);
      const weight2 = await optimizedContract.calculateVoteWeight(addr1.address);
      
      expect(weight1).to.equal(weight2);
      expect(weight1).to.equal(ethers.parseEther("1.0"));
      
      console.log("✅ Zero stake handled correctly:", ethers.formatEther(weight1));
    });
  });
});
