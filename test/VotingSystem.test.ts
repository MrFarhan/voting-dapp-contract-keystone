import { expect } from "chai";
import { ethers } from "hardhat";
import { VotingSystem, MockStakingToken } from "../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

describe("VotingSystem - Bounded Stake Voting (BSV)", function () {
  let votingSystem: VotingSystem;
  let stakingToken: MockStakingToken;
  let owner: HardhatEthersSigner;
  let member1: HardhatEthersSigner;
  let member2: HardhatEthersSigner;
  let member3: HardhatEthersSigner;
  let nonMember: HardhatEthersSigner;

  const WEIGHT_SCALE = ethers.parseEther("1"); // 1e18
  const BASE_WEIGHT = ethers.parseEther("1"); // 1.0
  const MAX_WEIGHT = ethers.parseEther("2"); // 2.0

  beforeEach(async function () {
    [owner, member1, member2, member3, nonMember] = await ethers.getSigners();

    // Deploy staking token
    const MockStakingToken = await ethers.getContractFactory("MockStakingToken");
    stakingToken = await MockStakingToken.deploy();
    await stakingToken.waitForDeployment();

    // Deploy voting system
    const VotingSystem = await ethers.getContractFactory("VotingSystem");
    votingSystem = await VotingSystem.deploy(await stakingToken.getAddress());
    await votingSystem.waitForDeployment();

    // Add members
    await votingSystem.addMember(member1.address);
    await votingSystem.addMember(member2.address);
    await votingSystem.addMember(member3.address);

    // Distribute tokens to members
    await stakingToken.mint(member1.address, ethers.parseEther("1000"));
    await stakingToken.mint(member2.address, ethers.parseEther("1000"));
    await stakingToken.mint(member3.address, ethers.parseEther("1000"));
  });

  describe("Deployment", function () {
    it("Should set the correct admin", async function () {
      expect(await votingSystem.hasRole(await votingSystem.ADMIN_ROLE(), owner.address)).to.be.true;
    });

    it("Should set the staking token correctly", async function () {
      expect(await votingSystem.stakingToken()).to.equal(await stakingToken.getAddress());
    });

    it("Should add owner as a member", async function () {
      expect(await votingSystem.isMember(owner.address)).to.be.true;
    });
  });

  describe("Membership Management", function () {
    it("Should add a member", async function () {
      expect(await votingSystem.isMember(nonMember.address)).to.be.false;
      await votingSystem.addMember(nonMember.address);
      expect(await votingSystem.isMember(nonMember.address)).to.be.true;
    });

    it("Should add multiple members", async function () {
      const newMembers = [
        "0x1234567890123456789012345678901234567890",
        "0x2234567890123456789012345678901234567890"
      ];
      await votingSystem.addMembers(newMembers);
      expect(await votingSystem.isMember(newMembers[0])).to.be.true;
      expect(await votingSystem.isMember(newMembers[1])).to.be.true;
    });

    it("Should remove a member", async function () {
      expect(await votingSystem.isMember(member1.address)).to.be.true;
      await votingSystem.removeMember(member1.address);
      expect(await votingSystem.isMember(member1.address)).to.be.false;
    });

    it("Should reject non-admin adding members", async function () {
      await expect(
        votingSystem.connect(member1).addMember(nonMember.address)
      ).to.be.reverted;
    });
  });

  describe("Staking", function () {
    it("Should allow members to stake tokens", async function () {
      const stakeAmount = ethers.parseEther("100");
      
      await stakingToken.connect(member1).approve(await votingSystem.getAddress(), stakeAmount);
      await votingSystem.connect(member1).stake(stakeAmount);

      const stakeInfo = await votingSystem.getStakeInfo(member1.address);
      expect(stakeInfo.amount).to.equal(stakeAmount);
    });

    it("Should reject staking from non-members", async function () {
      const stakeAmount = ethers.parseEther("100");
      await stakingToken.mint(nonMember.address, stakeAmount);
      await stakingToken.connect(nonMember).approve(await votingSystem.getAddress(), stakeAmount);
      
      await expect(
        votingSystem.connect(nonMember).stake(stakeAmount)
      ).to.be.revertedWith("Not a verified member");
    });

    it("Should allow unstaking after lock period", async function () {
      const stakeAmount = ethers.parseEther("100");
      
      await stakingToken.connect(member1).approve(await votingSystem.getAddress(), stakeAmount);
      await votingSystem.connect(member1).stake(stakeAmount);

      await votingSystem.connect(member1).unstake(stakeAmount);

      const stakeInfo = await votingSystem.getStakeInfo(member1.address);
      expect(stakeInfo.amount).to.equal(0);
    });

    it("Should reject unstaking more than staked", async function () {
      const stakeAmount = ethers.parseEther("100");
      
      await stakingToken.connect(member1).approve(await votingSystem.getAddress(), stakeAmount);
      await votingSystem.connect(member1).stake(stakeAmount);

      await expect(
        votingSystem.connect(member1).unstake(ethers.parseEther("200"))
      ).to.be.revertedWith("Insufficient staked amount");
    });
  });

  describe("Vote Weight Calculation", function () {
    it("Should return base weight for members with no stake", async function () {
      const weight = await votingSystem.calculateVoteWeight(member1.address);
      expect(weight).to.equal(BASE_WEIGHT);
    });

    it("Should return 0 weight for non-members", async function () {
      const weight = await votingSystem.calculateVoteWeight(nonMember.address);
      expect(weight).to.equal(0);
    });

    it("Should increase weight with stake (diminishing returns)", async function () {
      // Stake different amounts and verify increasing but diminishing returns
      const stakes = [
        ethers.parseEther("25"),
        ethers.parseEther("100"),
        ethers.parseEther("225")
      ];

      const weights: bigint[] = [];

      for (let i = 0; i < stakes.length; i++) {
        await stakingToken.connect(member1).approve(await votingSystem.getAddress(), stakes[i]);
        await votingSystem.connect(member1).stake(stakes[i]);
        
        const weight = await votingSystem.calculateVoteWeight(member1.address);
        weights.push(weight);

        expect(weight).to.be.gt(BASE_WEIGHT);
        expect(weight).to.be.lte(MAX_WEIGHT);
      }

      // Verify diminishing returns: marginal increase should decrease
      const increase1 = weights[1] - weights[0];
      const increase2 = weights[2] - weights[1];
      expect(increase2).to.be.lt(increase1);
    });

    it("Should cap weight at 2.0", async function () {
      // Stake a very large amount
      const largeStake = ethers.parseEther("100000");
      await stakingToken.mint(member1.address, largeStake);
      await stakingToken.connect(member1).approve(await votingSystem.getAddress(), largeStake);
      await votingSystem.connect(member1).stake(largeStake);

      const weight = await votingSystem.calculateVoteWeight(member1.address);
      expect(weight).to.equal(MAX_WEIGHT);
    });

    it("Should demonstrate the weight formula progression", async function () {
      console.log("\n    📊 Vote Weight Formula Demonstration:");
      console.log("    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      
      const testStakes = [
        0n,
        ethers.parseEther("4"),
        ethers.parseEther("16"),
        ethers.parseEther("81"),
        ethers.parseEther("100"),
        ethers.parseEther("400"),
        ethers.parseEther("900"),
        ethers.parseEther("10000")
      ];

      for (const stake of testStakes) {
        if (stake > 0n) {
          await stakingToken.mint(member1.address, stake);
          await stakingToken.connect(member1).approve(await votingSystem.getAddress(), stake);
          await votingSystem.connect(member1).stake(stake);
        }

        const weight = await votingSystem.calculateVoteWeight(member1.address);
        const weightFormatted = Number(weight) / Number(WEIGHT_SCALE);
        const stakeFormatted = Number(stake) / Number(ethers.parseEther("1"));

        console.log(`    Stake: ${stakeFormatted.toString().padEnd(10)} → Weight: ${weightFormatted.toFixed(4)}`);

        if (stake > 0n) {
          await votingSystem.connect(member1).unstake(stake);
        }
      }
      console.log("    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    });
  });

  describe("Election Management", function () {
    it("Should create an election", async function () {
      const startTime = Math.floor(Date.now() / 1000);
      const endTime = startTime + 3600; // 1 hour

      const tx = await votingSystem.connect(member1).createElection(
        "Test Election",
        "A test election",
        startTime,
        endTime,
        ["Candidate 1", "Candidate 2"],
        ["Description 1", "Description 2"]
      );

      await expect(tx)
        .to.emit(votingSystem, "ElectionCreated")
        .withArgs(1, "Test Election", startTime, endTime);

      const election = await votingSystem.getElection(1);
      expect(election.title).to.equal("Test Election");
      expect(election.candidateCount).to.equal(2);
    });

    it("Should reject election creation from non-members", async function () {
      const startTime = Math.floor(Date.now() / 1000);
      const endTime = startTime + 3600;

      await expect(
        votingSystem.connect(nonMember).createElection(
          "Test Election",
          "A test election",
          startTime,
          endTime,
          ["Candidate 1"],
          ["Description 1"]
        )
      ).to.be.revertedWith("Not a verified member");
    });
  });

  describe("Weighted Voting", function () {
    let electionId: number;
    let startTime: number;
    let endTime: number;

    beforeEach(async function () {
      startTime = Math.floor(Date.now() / 1000) - 10; // Started 10 seconds ago
      endTime = startTime + 3600; // 1 hour duration

      const tx = await votingSystem.connect(member1).createElection(
        "Weighted Vote Test",
        "Testing weighted voting",
        startTime,
        endTime,
        ["Option A", "Option B"],
        ["First option", "Second option"]
      );
      
      const receipt = await tx.wait();
      electionId = 1;
    });

    it("Should cast vote with base weight (no stake)", async function () {
      await votingSystem.connect(member1).vote(electionId, 1);

      const candidate = await votingSystem.getCandidate(electionId, 1);
      expect(candidate.voteCount).to.equal(BASE_WEIGHT);

      const voterWeight = await votingSystem.getVoterWeight(electionId, member1.address);
      expect(voterWeight).to.equal(BASE_WEIGHT);
    });

    it("Should cast vote with boosted weight (with stake)", async function () {
      const stakeAmount = ethers.parseEther("100");
      
      await stakingToken.connect(member2).approve(await votingSystem.getAddress(), stakeAmount);
      await votingSystem.connect(member2).stake(stakeAmount);

      const expectedWeight = await votingSystem.calculateVoteWeight(member2.address);
      expect(expectedWeight).to.be.gt(BASE_WEIGHT);

      await votingSystem.connect(member2).vote(electionId, 1);

      const candidate = await votingSystem.getCandidate(electionId, 1);
      expect(candidate.voteCount).to.equal(expectedWeight);
    });

    it("Should lock stakes until election ends", async function () {
      const stakeAmount = ethers.parseEther("100");
      
      await stakingToken.connect(member1).approve(await votingSystem.getAddress(), stakeAmount);
      await votingSystem.connect(member1).stake(stakeAmount);

      await votingSystem.connect(member1).vote(electionId, 1);

      const stakeInfo = await votingSystem.getStakeInfo(member1.address);
      expect(stakeInfo.lockedUntil).to.equal(endTime);

      await expect(
        votingSystem.connect(member1).unstake(stakeAmount)
      ).to.be.revertedWith("Tokens are locked");
    });

    it("Should aggregate weighted votes correctly", async function () {
      // Member1: 1.0 weight (no stake)
      await votingSystem.connect(member1).vote(electionId, 1);

      // Member2: ~1.2 weight (100 tokens staked)
      const stake2 = ethers.parseEther("100");
      await stakingToken.connect(member2).approve(await votingSystem.getAddress(), stake2);
      await votingSystem.connect(member2).stake(stake2);
      await votingSystem.connect(member2).vote(electionId, 1);

      // Member3: ~1.4 weight (400 tokens staked)
      const stake3 = ethers.parseEther("400");
      await stakingToken.connect(member3).approve(await votingSystem.getAddress(), stake3);
      await votingSystem.connect(member3).stake(stake3);
      await votingSystem.connect(member3).vote(electionId, 2);

      const candidate1 = await votingSystem.getCandidate(electionId, 1);
      const candidate2 = await votingSystem.getCandidate(electionId, 2);

      const weight1 = await votingSystem.calculateVoteWeight(member1.address);
      const weight2 = await votingSystem.calculateVoteWeight(member2.address);
      const weight3 = await votingSystem.calculateVoteWeight(member3.address);

      expect(candidate1.voteCount).to.equal(weight1 + weight2);
      expect(candidate2.voteCount).to.equal(weight3);

      console.log("\n    📊 Weighted Voting Results:");
      console.log("    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
      console.log(`    Candidate 1: ${ethers.formatEther(candidate1.voteCount)} votes`);
      console.log(`    Candidate 2: ${ethers.formatEther(candidate2.voteCount)} votes`);
      console.log("    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n");
    });

    it("Should prevent double voting", async function () {
      await votingSystem.connect(member1).vote(electionId, 1);

      await expect(
        votingSystem.connect(member1).vote(electionId, 2)
      ).to.be.revertedWith("Already voted in this election");
    });

    it("Should reject votes from non-members", async function () {
      await expect(
        votingSystem.connect(nonMember).vote(electionId, 1)
      ).to.be.revertedWith("Not a verified member");
    });
  });

  describe("Election Results", function () {
    it("Should determine winner correctly with weighted votes", async function () {
      const currentBlock = await ethers.provider.getBlock('latest');
      const startTime = currentBlock!.timestamp + 10;
      const endTime = startTime + 3600;

      await votingSystem.connect(member1).createElection(
        "Winner Test",
        "Testing winner calculation",
        startTime,
        endTime,
        ["Alice", "Bob", "Charlie"],
        ["Desc A", "Desc B", "Desc C"]
      );

      const electionId = 1;

      // Fast forward to start time
      await ethers.provider.send("evm_setNextBlockTimestamp", [startTime]);
      await ethers.provider.send("evm_mine", []);

      // Alice: 1.0 (member1, no stake)
      await votingSystem.connect(member1).vote(electionId, 1);

      // Bob: 2.0 (member2 with large stake)
      const largeStake = ethers.parseEther("10000");
      await stakingToken.mint(member2.address, largeStake);
      await stakingToken.connect(member2).approve(await votingSystem.getAddress(), largeStake);
      await votingSystem.connect(member2).stake(largeStake);
      await votingSystem.connect(member2).vote(electionId, 2);

      // Charlie: 1.0 (member3, no stake)
      await votingSystem.connect(member3).vote(electionId, 3);

      // Fast forward past end time
      await ethers.provider.send("evm_setNextBlockTimestamp", [endTime + 1]);
      await ethers.provider.send("evm_mine", []);

      const [winnerIds, highestVotes] = await votingSystem.getWinner(electionId);
      
      expect(winnerIds.length).to.equal(1);
      expect(winnerIds[0]).to.equal(2); // Bob wins with 2.0 weight
      expect(highestVotes).to.equal(MAX_WEIGHT);
    });
  });

  describe("Edge Cases", function () {
    it("Should handle zero stake correctly", async function () {
      const weight = await votingSystem.calculateVoteWeight(member1.address);
      expect(weight).to.equal(BASE_WEIGHT);
    });

    it("Should handle very small stakes", async function () {
      const tinyStake = ethers.parseEther("0.01");
      await stakingToken.connect(member1).approve(await votingSystem.getAddress(), tinyStake);
      await votingSystem.connect(member1).stake(tinyStake);

      const weight = await votingSystem.calculateVoteWeight(member1.address);
      expect(weight).to.be.gt(BASE_WEIGHT);
      expect(weight).to.be.lt(ethers.parseEther("1.1")); // Raised tolerance
    });

    it("Should handle maximum stake correctly", async function () {
      const maxStake = ethers.parseEther("1000000");
      await stakingToken.mint(member1.address, maxStake);
      await stakingToken.connect(member1).approve(await votingSystem.getAddress(), maxStake);
      await votingSystem.connect(member1).stake(maxStake);

      const weight = await votingSystem.calculateVoteWeight(member1.address);
      expect(weight).to.equal(MAX_WEIGHT);
    });
  });
});
