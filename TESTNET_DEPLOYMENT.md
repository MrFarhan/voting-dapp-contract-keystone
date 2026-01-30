# 🚀 Testnet Deployment Guide

## Prerequisites

### 1. **Get Sepolia ETH** (Free Testnet ETH)
You need testnet ETH to deploy contracts. Get it from faucets:

- **Alchemy Sepolia Faucet**: https://sepoliafaucet.com/
- **Infura Sepolia Faucet**: https://www.infura.io/faucet/sepolia
- **QuickNode Faucet**: https://faucet.quicknode.com/ethereum/sepolia

**Recommended amount**: At least 0.01 ETH for safe deployment

---

### 2. **Get RPC Provider** (Free)

#### Option A: Alchemy (Recommended)
1. Go to https://www.alchemy.com/
2. Sign up for free account
3. Create new app → Select "Ethereum" → "Sepolia"
4. Copy the HTTPS URL

#### Option B: Infura
1. Go to https://infura.io/
2. Sign up for free account
3. Create new project
4. Select "Sepolia" network
5. Copy the endpoint URL

---

### 3. **Get Etherscan API Key** (Optional, for verification)
1. Go to https://etherscan.io/
2. Sign up/Login
3. Go to "API Keys" → "Add"
4. Copy the API key

---

## 📝 Setup Instructions

### Step 1: Configure Environment Variables

```bash
# Copy the example file
cp .env.example .env
```

Edit `.env` file:

```bash
# Your wallet private key (from MetaMask)
PRIVATE_KEY=your_private_key_without_0x_prefix

# Your Alchemy/Infura RPC URL
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR-API-KEY

# Your Etherscan API key (optional)
ETHERSCAN_API_KEY=your_etherscan_api_key
```

#### 🔐 How to get Private Key from MetaMask:
1. Open MetaMask
2. Click account icon → "Account Details"
3. Click "Export Private Key"
4. Enter password
5. Copy the key (remove the `0x` prefix)

⚠️ **IMPORTANT**: Never share or commit your private key!

---

### Step 2: Verify Setup

```bash
# Compile contracts
npm run compile

# Run all tests (should show 36/36 passing)
npm test

# Run gas comparison tests
npm run test:gas
```

All tests must pass before deployment! ✅

---

### Step 3: Deploy to Sepolia Testnet

```bash
npm run deploy:sepolia
```

This will:
1. ✅ Deploy MockStakingToken
2. ✅ Deploy VotingSystemOptimized (gas-optimized version)
3. ✅ Setup initial membership
4. ✅ Verify deployment
5. ✅ Save deployment info to `deployments/`

---

### Step 4: Verify Contracts on Etherscan (Optional)

After deployment, verify your contracts:

```bash
# Verify VotingSystemOptimized
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> <TOKEN_ADDRESS>

# Verify MockStakingToken
npx hardhat verify --network sepolia <TOKEN_ADDRESS>
```

Replace `<CONTRACT_ADDRESS>` and `<TOKEN_ADDRESS>` with actual addresses from deployment output.

---

## 📊 Expected Output

```
⚡ Deploying Gas-Optimized BSV to Testnet...

🌐 Network: sepolia
🔗 Chain ID: 11155111
📝 Deploying with account: 0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb
💰 Account balance: 0.05 ETH

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  DEPLOYING CONTRACTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1️⃣  Deploying MockStakingToken...
   ✅ MockStakingToken deployed to: 0x1234...
   ⏳ Waiting for 2 block confirmations...
   ✅ Confirmed!

2️⃣  Deploying VotingSystemOptimized (Gas-Optimized BSV)...
   ✅ VotingSystemOptimized deployed to: 0x5678...
   ⏳ Waiting for 2 block confirmations...
   ✅ Confirmed!

3️⃣  Setting up initial membership...
   ⏳ Waiting for transaction confirmation...
   ✅ Deployer added as verified member

4️⃣  Verifying deployment...
   ✅ Deployment verification passed!

╔════════════════════════════════════════════════════════╗
║           DEPLOYMENT SUCCESSFUL! ⚡                    ║
╚════════════════════════════════════════════════════════╝
```

---

## 📁 Deployment Artifacts

After successful deployment, you'll find:

```
deployments/
├── deployment-sepolia-optimized-1706644800000.json  # Timestamped
└── latest-sepolia-optimized.json                     # Latest (use this)
```

The JSON file contains:
- Contract addresses
- Network information
- Deployer details
- Transaction hashes
- Feature configuration

---

## 🔗 Update Frontend

Copy addresses to your frontend `.env`:

```bash
VITE_CONTRACT_ADDRESS=0x... # From deployment output
VITE_TOKEN_ADDRESS=0x...    # From deployment output
VITE_CHAIN_ID=11155111      # Sepolia
VITE_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR-API-KEY
```

---

## ✅ Post-Deployment Verification

### 1. Check on Etherscan
Visit: https://sepolia.etherscan.io/address/YOUR_CONTRACT_ADDRESS

Verify:
- ✅ Contract is deployed
- ✅ Transactions are visible
- ✅ Contract is verified (if you ran verification)

### 2. Test Contract Functions

```bash
# Run the interaction script
npx hardhat run scripts/interact.ts --network sepolia
```

Test:
- ✅ Add members
- ✅ Stake tokens
- ✅ Calculate vote weights
- ✅ Create elections
- ✅ Cast votes

---

## 🐛 Troubleshooting

### Error: "insufficient funds"
**Solution**: Get more Sepolia ETH from faucets

### Error: "invalid private key"
**Solution**: Check your `.env` file, remove `0x` prefix from private key

### Error: "network does not exist"
**Solution**: Make sure you're using `--network sepolia`

### Error: "nonce too high"
**Solution**: Reset MetaMask account or wait a few minutes

### Deployment hangs
**Solution**: Check your RPC URL is correct and working

---

## 💰 Estimated Costs (Sepolia Testnet)

| Operation | Gas | ETH (50 gwei) | USD ($3k ETH) |
|-----------|-----|---------------|---------------|
| Deploy Token | ~800K | 0.04 | ~$120 |
| Deploy VotingSystem | ~3.5M | 0.175 | ~$525 |
| Setup Membership | ~50K | 0.0025 | ~$7.50 |
| **Total** | **~4.35M** | **~0.22** | **~$652** |

**Testnet ETH is FREE** - This is just for estimation! 🎉

---

## 🎯 Production Deployment

For mainnet deployment:

1. **Security Audit**: Get contract audited
2. **Test Thoroughly**: Run on testnet for weeks
3. **Insurance**: Consider getting smart contract insurance
4. **Multisig**: Use multisig wallet for admin
5. **Gradual Rollout**: Start with small amounts

**DO NOT** deploy to mainnet without proper testing and auditing!

---

## 📚 Additional Resources

- **Hardhat Docs**: https://hardhat.org/docs
- **Etherscan**: https://sepolia.etherscan.io/
- **Alchemy Dashboard**: https://dashboard.alchemy.com/
- **OpenZeppelin**: https://docs.openzeppelin.com/

---

## ✅ Deployment Checklist

Before deploying:

- [ ] All tests passing (36/36)
- [ ] `.env` file configured
- [ ] Sepolia ETH in wallet (>0.01 ETH)
- [ ] RPC URL working
- [ ] Private key correct (without 0x)
- [ ] Contracts compiled successfully
- [ ] Git repo backed up

After deploying:

- [ ] Contract addresses saved
- [ ] Verified on Etherscan
- [ ] Frontend .env updated
- [ ] Test contract functions
- [ ] Document deployment
- [ ] Backup deployment JSON files

---

**Ready to deploy?** Run:

```bash
npm run deploy:sepolia
```

🚀 **Good luck!**
