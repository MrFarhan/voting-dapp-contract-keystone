# Frontend Integration Guide - Connecting React/Vite to Smart Contracts

**Super Simple Setup** - Keep contracts and frontend in separate VS Code windows!

---

## ⚡ TL;DR - Just 3 Things You Need

1. **Run contracts** in separate terminal (get addresses from deployment)
2. **Add `.env.local`** in frontend with contract addresses
3. **Copy ABIs once** (2 JSON files) - they rarely change

**No complex scripts needed!** Just update `.env.local` when you redeploy.

---

## 🚀 Quick Start

### Step 1: Start Contracts (Separate Terminal/VS Code)

```bash
# Terminal 1 - Start blockchain
cd /Users/zenkoders/Desktop/Farhan/uni/voting-dapp-contract-keystone
npm run node
# Keep running!

# Terminal 2 - Deploy contracts
npm run deploy:local
```

**Copy the addresses from output:**
```
✅ MockStakingToken deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
✅ VotingSystem deployed to: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
```

---

### Step 2: Configure Frontend Environment Variables

In your **React/Vite project**, create `.env.local`:

```env
VITE_VOTING_SYSTEM_ADDRESS=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
VITE_STAKING_TOKEN_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
VITE_CHAIN_ID=1337
VITE_RPC_URL=http://127.0.0.1:8545
```

**That's it for addresses!** ✅

---

### Step 3: Add Contract ABIs to Frontend

You need the ABIs (just once) to interact with contracts.

**Two simple ways:**

**Option A: Copy JSON files once** (Recommended - Simple)

```bash
# In your frontend project
mkdir -p src/contracts

# Copy the ABI files (one-time setup)
cp /Users/zenkoders/Desktop/Farhan/uni/voting-dapp-contract-keystone/artifacts/contracts/VotingSystem.sol/VotingSystem.json \
   src/contracts/VotingSystem.json

cp /Users/zenkoders/Desktop/Farhan/uni/voting-dapp-contract-keystone/artifacts/contracts/MockStakingToken.sol/MockStakingToken.json \
   src/contracts/MockStakingToken.json
```

**Option B: Import from contract project path** (Even simpler if using monorepo)

In your frontend code, import directly:
```typescript
import VotingSystemABI from '../../../voting-dapp-contract-keystone/artifacts/contracts/VotingSystem.sol/VotingSystem.json';
```

---

## ✅ That's All You Need!

**Summary:**
1. ✅ Contracts run in **separate terminal** (or VS Code window)
2. ✅ Frontend uses **environment variables** for contract addresses
3. ✅ ABIs copied **once** (they rarely change)

**No complex build scripts or automation needed!** 

---

## 💡 Why You Need ABIs?

The ABI tells your frontend:
- What functions the contract has
- What parameters they accept
- What they return

**You only copy ABIs once** (or when you change contract functions). The addresses change every time you redeploy.

---

## Old Complex Approach (You Can Skip This)

**File: `scripts/export-contracts.ts`**
```typescript
import fs from 'fs';
import path from 'path';

async function exportContracts() {
  const frontendPath = process.env.FRONTEND_PATH || '../your-frontend-project';
  const contractsDir = path.join(frontendPath, 'src/contracts');

  // Create contracts directory if it doesn't exist
  if (!fs.existsSync(contractsDir)) {
    fs.mkdirSync(contractsDir, { recursive: true });
  }

  // Read deployment info
  const deployment = JSON.parse(
    fs.readFileSync('deployments/latest-localhost.json', 'utf8')
  );

  // Copy ABIs
  const votingSystemABI = JSON.parse(
    fs.readFileSync('artifacts/contracts/VotingSystem.sol/VotingSystem.json', 'utf8')
  );
  
  const stakingTokenABI = JSON.parse(
    fs.readFileSync('artifacts/contracts/MockStakingToken.sol/MockStakingToken.json', 'utf8')
  );

  // Write to frontend
  fs.writeFileSync(
    path.join(contractsDir, 'VotingSystemABI.json'),
    JSON.stringify(votingSystemABI.abi, null, 2)
  );

  fs.writeFileSync(
    path.join(contractsDir, 'MockStakingTokenABI.json'),
    JSON.stringify(stakingTokenABI.abi, null, 2)
  );

  fs.writeFileSync(
    path.join(contractsDir, 'addresses.json'),
    JSON.stringify({
      localhost: {
        chainId: 1337,
        votingSystem: deployment.votingSystem,
        stakingToken: deployment.stakingToken
      }
    }, null, 2)
  );

  console.log('✅ Contract ABIs and addresses exported to frontend!');
  console.log('📁 Location:', contractsDir);
}

---

## 🛠️ Complete Setup Guide

### Step 4: Configure MetaMask for Local Network

**1. Open MetaMask**

**2. Add Local Network:**
   - Click network dropdown → "Add Network" → "Add a network manually"
   
   **Network Details:**
   ```
   Network Name: Hardhat Local
   RPC URL: http://127.0.0.1:8545
   Chain ID: 1337
   Currency Symbol: ETH
   ```

**3. Import Test Account:**
   - Copy private key from Hardhat node output (Account #0)
   - MetaMask → Import Account → Paste private key
   
   **Test Account #0 Private Key:**
   ```
   0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
   ```
   
   This account has 10,000 ETH for testing.

---

### Step 5: Install Frontend Dependencies

In your React/Vite project:

```bash
cd /path/to/your/frontend

# Install ethers.js (for contract interactions)
npm install ethers

# Optional: Install Wagmi + RainbowKit (for wallet connection UI)
npm install wagmi viem@2.x @tanstack/react-query
npm install @rainbow-me/rainbowkit
```

---

### Step 6: Use in Your React Components

**File: `src/config/contracts.ts`**

```typescript
import VotingSystemABI from '../contracts/VotingSystem.json';
import MockStakingTokenABI from '../contracts/MockStakingToken.json';

export const CONTRACTS = {
  votingSystem: {
    address: import.meta.env.VITE_VOTING_SYSTEM_ADDRESS as `0x${string}`,
    abi: VotingSystemABI.abi, // Extract just the ABI array
  },
  stakingToken: {
    address: import.meta.env.VITE_STAKING_TOKEN_ADDRESS as `0x${string}`,
    abi: MockStakingTokenABI.abi,
  },
};

export const CHAIN_ID = parseInt(import.meta.env.VITE_CHAIN_ID || '1337');
export const RPC_URL = import.meta.env.VITE_RPC_URL || 'http://127.0.0.1:8545';
```

---

### Step 7: Create Contract Hooks

**File: `src/hooks/useVotingSystem.ts`**

```typescript
import { ethers } from 'ethers';
import { CONTRACTS } from '../config/contracts';

export function useVotingSystem() {
  const getProvider = () => {
    return new ethers.BrowserProvider(window.ethereum);
  };

  const getContract = async (withSigner = false) => {
    const provider = getProvider();
    
    if (withSigner) {
      const signer = await provider.getSigner();
      return new ethers.Contract(
        CONTRACTS.votingSystem.address,
        CONTRACTS.votingSystem.abi,
        signer
      );
    }
    
    return new ethers.Contract(
      CONTRACTS.votingSystem.address,
      CONTRACTS.votingSystem.abi,
      provider
    );
  };

  // Read functions (no gas cost)
  const isRegisteredVoter = async (address: string) => {
    const contract = await getContract();
    return await contract.isRegisteredVoter(address);
  };

  const getElection = async (electionId: number) => {
    const contract = await getContract();
    return await contract.getElection(electionId);
  };

  const calculateVoteWeight = async (address: string) => {
    const contract = await getContract();
    const weight = await contract.calculateVoteWeight(address);
    return ethers.formatEther(weight); // Convert from wei to decimal
  };

  // Write functions (require gas)
  const vote = async (electionId: number, candidateId: number) => {
    const contract = await getContract(true);
    const tx = await contract.vote(electionId, candidateId);
    await tx.wait(); // Wait for confirmation
    return tx;
  };

  const stake = async (amount: string) => {
    const contract = await getContract(true);
    const amountInWei = ethers.parseEther(amount);
    const tx = await contract.stake(amountInWei);
    await tx.wait();
    return tx;
  };

  return {
    isRegisteredVoter,
    getElection,
    calculateVoteWeight,
    vote,
    stake,
  };
}
```

---

### Step 8: Example Component

**File: `src/components/VotingDemo.tsx`**

```typescript
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { useVotingSystem } from '../hooks/useVotingSystem';

export default function VotingDemo() {
  const [account, setAccount] = useState<string>('');
  const [isMember, setIsMember] = useState(false);
  const [voteWeight, setVoteWeight] = useState('0');
  const { isRegisteredVoter, calculateVoteWeight } = useVotingSystem();

  // Connect wallet
  const connectWallet = async () => {
    if (window.ethereum) {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const accounts = await provider.send('eth_requestAccounts', []);
      setAccount(accounts[0]);
    }
  };

  // Check membership status
  useEffect(() => {
    if (account) {
      isRegisteredVoter(account).then(setIsMember);
      calculateVoteWeight(account).then(setVoteWeight);
    }
  }, [account]);

  return (
    <div>
      <h1>BSV Voting System</h1>
      
      {!account ? (
        <button onClick={connectWallet}>Connect Wallet</button>
      ) : (
        <div>
          <p>Connected: {account}</p>
          <p>Member Status: {isMember ? '✅ Member' : '❌ Not a member'}</p>
          <p>Vote Weight: {voteWeight}x</p>
        </div>
      )}
    </div>
  );
}
```

---

### Step 9: Start Your Frontend

**File: `.env.local`**

```env
VITE_CONTRACT_VOTING_SYSTEM=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
VITE_CONTRACT_STAKING_TOKEN=0x5FbDB2315678afecb367f032d93F642f64180aa3
VITE_CHAIN_ID=1337
VITE_RPC_URL=http://127.0.0.1:8545
```

---

## 🔄 Development Workflow

### Daily Workflow:

1. **Terminal 1:** Start Hardhat node
   ```bash
   npm run node
   ```

2. **Terminal 2:** Deploy contracts
   ```bash
   npm run deploy:local
   ```

3. **Terminal 3:** Start frontend
   ```bash
   cd ../your-frontend
   npm run dev
   ```

### When You Make Contract Changes:

1. Stop deployment (Ctrl+C in Terminal 2)
2. Update contract code
3. Redeploy:
   ```bash
   npm run compile
   npm run deploy:local
   npm run export:contracts  # If using automated export
   ```
4. Refresh frontend browser

---

## 🧪 Testing the Integration

### Test Checklist:

1. ✅ **Wallet connects** to localhost (Chain ID 1337)
2. ✅ **Contract addresses** match deployment output
3. ✅ **Read functions** work (e.g., `isRegisteredVoter`)
4. ✅ **Write functions** work (e.g., `vote`, `stake`)
5. ✅ **MetaMask** shows transaction confirmations
6. ✅ **Events** are emitted and can be listened to

### Test in Browser Console:

```javascript
// Test connection
const provider = new ethers.BrowserProvider(window.ethereum);
const network = await provider.getNetwork();
console.log('Chain ID:', network.chainId); // Should be 1337

// Test contract read
const votingSystem = new ethers.Contract(
  '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512',
  VotingSystemABI,
  provider
);
const count = await votingSystem.electionCount();
console.log('Election count:', count);
```

---

## 🚨 Common Issues & Solutions

### Issue 1: "Network not found" or wrong Chain ID
**Solution:** Make sure:
- Hardhat node is running
- MetaMask is connected to "Hardhat Local" (1337)
- RPC URL is `http://127.0.0.1:8545`

### Issue 2: "Contract not deployed"
**Solution:**
- Check contract addresses match deployment
- Redeploy contracts: `npm run deploy:local`
- Clear browser cache

### Issue 3: "Nonce too high" error
**Solution:**
- MetaMask → Settings → Advanced → Clear Activity Tab Data
- Reset account in MetaMask

### Issue 4: Contracts reset after restarting node
**Solution:**
- This is normal - local node doesn't persist data
- Redeploy contracts each time you restart the node
- For persistence, consider using `--fork` option

### Issue 5: "Gas estimation failed"
**Solution:**
- Check if you're a registered member (for vote, stake functions)
- Ensure sufficient balance
- Check function parameters are correct

---

## 📚 Next Steps

1. **Implement full UI** for:
   - Creating elections
   - Adding candidates
   - Voting with weight display
   - Staking tokens
   - Viewing results

2. **Add event listeners** for real-time updates:
   ```typescript
   const contract = await getContract();
   contract.on('VoteCast', (electionId, candidateId, voter, weight) => {
     console.log('New vote cast:', { electionId, candidateId, voter, weight });
   });
   ```

3. **Error handling** with try-catch blocks

4. **Loading states** for transactions

5. **Toast notifications** for success/error messages

---

## 🔗 Useful Resources

- **Ethers.js Docs:** https://docs.ethers.org/v6/
- **Hardhat Docs:** https://hardhat.org/hardhat-runner/docs/getting-started
- **Wagmi Docs:** https://wagmi.sh/
- **RainbowKit:** https://www.rainbowkit.com/

---

**Need help?** Check the contract documentation in this project's README.md
