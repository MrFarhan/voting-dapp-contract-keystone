# Quick Start Guide

## Setup Complete! ✅

Your contract repository is now ready to use. Here's how to work with it:

## Two-Terminal Workflow (Recommended)

### Terminal 1: Run the Local Blockchain
```bash
npm run node
```

This starts a local Ethereum node at `http://127.0.0.1:8545`. Keep this terminal running.

You'll see 20 test accounts with 10000 ETH each. Example:
```
Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Terminal 2: Deploy the Contract
```bash
npm run deploy:local
```

After deployment, you'll see:
```
✅ VotingSystem deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3
📄 Deployment Summary:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Network: localhost
Chain ID: 1337
Contract Address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
...
```

## Copy Contract Address for Frontend

The contract address is saved in: **`deployments/latest-localhost.json`**

```bash
# View the contract address
cat deployments/latest-localhost.json
```

## Update Your Frontend

1. Copy the contract address from the terminal output or from `deployments/latest-localhost.json`
2. In your frontend repo, update the `.env` file:
   ```env
   VITE_CONTRACT_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3
   VITE_RPC_URL=http://127.0.0.1:8545
   VITE_CHAIN_ID=1337
   ```
3. Start your frontend app
4. Make sure MetaMask is connected to `Localhost 8545` (Chain ID: 1337)

## Important Notes

- **Keep Terminal 1 running** - the Hardhat node must stay active for the frontend to work
- **Deterministic deployment** - The contract address will always be `0x5FbDB2315678afecb367f032d93F642f64180aa3` on first deployment
- **Restarting** - If you restart the node, you need to redeploy the contract
- **Test accounts** - Use Account #0's private key in MetaMask for testing

## Common Commands

```bash
# Compile contracts
npm run compile

# Run tests (when you add test files)
npm run test

# Start local node
npm run node

# Deploy to local node (in separate terminal)
npm run deploy:local
```

## Troubleshooting

### "Cannot connect to network localhost"
Make sure Terminal 1 is running `npm run node`

### "Port 8545 already in use"
```bash
lsof -ti:8545 | xargs kill -9
npm run node
```

### "Nonce too high" error in frontend
Restart the Hardhat node and redeploy, then reset MetaMask account:
Settings → Advanced → Clear activity tab data

### Contract address changed
This happens if you cleared cache or restarted the node. Update your frontend `.env` with the new address from `deployments/latest-localhost.json`

## Test It Works

1. Start node: `npm run node` ✅
2. Deploy: `npm run deploy:local` (in new terminal) ✅
3. Copy address from `deployments/latest-localhost.json` ✅
4. Update frontend `.env` ✅
5. Start frontend and test voting! ✅

---

**Your contract is ready! Keep the node running and enjoy building your Bounded Stake Voting dApp!** 🚀
