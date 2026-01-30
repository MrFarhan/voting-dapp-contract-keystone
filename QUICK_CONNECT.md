# 🚀 Quick Frontend Connection Guide

## Super Simple 2-Command Setup

### Step 1: Start Hardhat Node (Terminal 1)
```bash
npm run node
```
**Keep this running!**

---

### Step 2: Deploy & Auto-Connect (Terminal 2)
```bash
npm run deploy:connect
```

**That's it!** 🎉

---

## What `deploy:connect` Does Automatically

✅ Deploys contracts to localhost  
✅ Copies ABIs to `../voting-dapp-keystone/src/contracts/`  
✅ Creates/Updates `../voting-dapp-keystone/.env.local`  
✅ Generates `addresses.ts` config file  

**Everything is ready for your frontend!**

---

## Your Frontend Files (Auto-Generated)

```
voting-dapp-keystone/
├── .env.local                          # ← Contract addresses
└── src/
    └── contracts/
        ├── VotingSystem.json           # ← ABI
        ├── MockStakingToken.json       # ← ABI
        └── addresses.ts                # ← TypeScript config
```

---

## Example Usage in Frontend

**Using the auto-generated config:**

```typescript
import { CONTRACT_ADDRESSES } from './contracts/addresses';
import VotingSystemABI from './contracts/VotingSystem.json';
import { ethers } from 'ethers';

// Using addresses.ts
const votingSystemAddress = CONTRACT_ADDRESSES.votingSystem;

// Or using .env.local
const votingSystemAddress = import.meta.env.VITE_VOTING_SYSTEM_ADDRESS;

// Create contract instance
const provider = new ethers.BrowserProvider(window.ethereum);
const contract = new ethers.Contract(
  votingSystemAddress,
  VotingSystemABI.abi,
  provider
);

// Now use it!
const electionCount = await contract.electionCount();
```

---

## When to Redeploy

**Run `npm run deploy:connect` again when:**
- You restart the Hardhat node (addresses change)
- You modify smart contract functions (ABI changes)
- You want to reset to fresh contracts

**Just re-run the command - it updates everything automatically!**

---

## Folder Structure Requirement

Your projects must be in the same parent folder:

```
uni/
├── voting-dapp-contract-keystone/    # ← This project (contracts)
└── voting-dapp-keystone/              # ← Frontend project
```

If your frontend has a different name, update the path in `scripts/deploy-and-connect.ts`:

```typescript
const frontendPath = path.join(__dirname, "..", "..", "your-frontend-name");
```

---

## Troubleshooting

### ❌ "Frontend project not found"
**Solution:** Make sure both projects are in the same parent folder (`uni/`)

### ❌ ".env.local not updating"
**Solution:** Check file permissions, or manually delete `.env.local` and re-run

### ❌ "Contract not found" in frontend
**Solution:** 
1. Make sure contracts are compiled: `npm run compile`
2. Re-run: `npm run deploy:connect`
3. Restart your frontend dev server

---

## Full Workflow Example

```bash
# Terminal 1 - Hardhat Node
cd /Users/zenkoders/Desktop/Farhan/uni/voting-dapp-contract-keystone
npm run node

# Terminal 2 - Deploy & Connect
npm run deploy:connect

# Terminal 3 - Start Frontend
cd /Users/zenkoders/Desktop/Farhan/uni/voting-dapp-keystone
npm run dev

# Done! Your frontend is connected to contracts 🎉
```

---

## Manual Commands (If You Need Them)

**Old way (manual):**
```bash
npm run deploy:local                                    # Deploy only
# Then manually copy ABIs and update .env...
```

**New way (automated):**
```bash
npm run deploy:connect                                  # Does everything!
```

---

## What Gets Updated Each Time

| File | What Changes | Why |
|------|-------------|-----|
| `.env.local` | Contract addresses | Addresses change on each deploy |
| `VotingSystem.json` | ABI | Only when contract functions change |
| `MockStakingToken.json` | ABI | Only when contract functions change |
| `addresses.ts` | TypeScript config | For type-safe imports |

---

**Need help?** Check [FRONTEND_INTEGRATION.md](FRONTEND_INTEGRATION.md) for detailed documentation.
