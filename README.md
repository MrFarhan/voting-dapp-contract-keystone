# Voting DApp - Smart Contract

**Version**: 0.2.2 | **Status**: Testnet Ready - Security Audited  
📋 [Changelog](CHANGELOG.md) | 📦 [Release Guide](RELEASE.md) | 🔒 [Security Audit](SECURITY_AUDIT.md) | 🏷️ [Semantic Versioning](https://semver.org/)

This is the smart contract repository for the Bounded Stake Voting (BSV) system, maintained separately from the frontend.

## ⚡ Quick Frontend Connection

**Just 2 commands to connect your React/Vite frontend:**

```bash
# Terminal 1
npm run node

# Terminal 2
npm run deploy:connect
```

**That's it!** Auto-deploys contracts, copies ABIs, and updates frontend `.env.local`  
📖 See [QUICK_CONNECT.md](QUICK_CONNECT.md) for details

## ⚡ Gas Optimized Version Available!

We've created an optimized version that saves **up to 20% gas** on operations:
- **VotingSystemOptimized.sol** - Gas-efficient implementation
- See [GAS_OPTIMIZATION_SUMMARY.md](GAS_OPTIMIZATION_SUMMARY.md) for details
- Run `npx hardhat test test/GasComparison.test.ts` to see savings

## 🚀 Testnet Deployment Ready!

Deploy the gas-optimized version to Sepolia testnet:
- Complete setup guide: [TESTNET_DEPLOYMENT.md](TESTNET_DEPLOYMENT.md)
- Automated deployment script with verification
- Command: `npm run deploy:sepolia`
- Includes contract verification on Etherscan

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn

## Installation

```bash
npm install
```

## Usage

### Quick Start (Two Terminals Required)

**Terminal 1 - Start Local Blockchain:**
```bash
npm run node
```
Keep this terminal running. It provides 20 test accounts with 10000 ETH each.

**Terminal 2 - Deploy Contract:**
```bash
npm run deploy:local
```

**Copy Contract Address:**
After deployment, find the contract address in `deployments/latest-localhost.json`:
```bash
cat deployments/latest-localhost.json
```

**Update Your Frontend `.env`:**
```env
VITE_CONTRACT_ADDRESS=<address-from-json>
VITE_RPC_URL=http://127.0.0.1:8545
VITE_CHAIN_ID=1337
```

**See [QUICKSTART.md](QUICKSTART.md) for detailed step-by-step instructions.**

## Available Scripts

### Development
- `npm run compile` - Compile smart contracts
- `npm run node` - Start local Hardhat node
- `npm run deploy:local` - Deploy to localhost

### Testing
- `npm test` - Run all 28 test cases
- `npm run test:verbose` - Run tests with detailed output
- `npm run test:coverage` - Generate test coverage report
- `npm run generate:report` - Generate comprehensive instructor report
- `./run-tests.sh` - Run all tests + generate coverage (all-in-one)

### Coverage Reports
After running coverage, view reports at:
- `coverage/COVERAGE_REPORT.txt` - Text summary for submission
- `coverage/index.html` - Interactive HTML visualization

## 🧪 Testing & Coverage

### Quick Test
```bash
npm test
```
Runs all 28 test cases in ~5 seconds.

### Generate Coverage Report (For Instructor)
```bash
npm run generate:report
```
Creates comprehensive coverage report including:
- Statement, branch, and function coverage
- All 28 test cases documented
- Security features verification
- Formula validation

**Reports Generated:**
- `coverage/COVERAGE_REPORT.txt` - Formatted text report
- `coverage/index.html` - Interactive visualization

### View Coverage in Browser
```bash
open coverage/index.html
```

### All-in-One Test Suite
```bash
./run-tests.sh
```
Runs tests + generates coverage + creates reports.

**📚 Full testing documentation**: See [TESTING_GUIDE.md](TESTING_GUIDE.md)

## Contract Address

After deployment, find the contract address in `deployments/latest-localhost.json`

## Network Configuration

- **Network**: Hardhat Local
- **RPC URL**: http://127.0.0.1:8545
- **Chain ID**: 1337

## Project Structure

```
contracts/          # Solidity smart contracts
scripts/            # Deployment scripts
test/              # Contract tests
deployments/       # Deployment artifacts
artifacts/         # Compiled contracts
typechain-types/   # TypeScript types for contracts
```

## Integration with Frontend

1. Start the local node: `npm run node`
2. Deploy the contract: `npm run deploy:local`
3. Copy the contract address from `deployments/latest-localhost.json`
4. Update your frontend `.env` with the contract address
5. Make sure your frontend is configured to connect to `http://127.0.0.1:8545`

## Important Notes

- Keep the Hardhat node running while testing with the frontend
- Each time you restart the node, you'll need to redeploy the contract
- The contract address will remain the same if you don't clear the cache
- Test accounts and private keys are shown in the console when the node starts

## Troubleshooting

**Port already in use:**
```bash
# Kill the process using port 8545
lsof -ti:8545 | xargs kill -9
```

**Contract not found:**
Make sure you've deployed to the correct network and the node is running.

**Reset local blockchain:**
```bash
# Clear cache and redeploy
rm -rf cache artifacts deployments
npm run compile
npm run node  # In one terminal
npm run deploy:local  # In another terminal
```
