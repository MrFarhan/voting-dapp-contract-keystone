#!/bin/bash

echo "🔍 Verifying Contract Repository Setup..."
echo ""

# Check if in correct directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: Not in contract repository directory"
    exit 1
fi

echo "✅ In correct directory: $(pwd)"
echo ""

# Check dependencies
if [ -d "node_modules" ]; then
    echo "✅ Dependencies installed"
else
    echo "❌ Dependencies not installed - run: npm install"
    exit 1
fi

# Check hardhat config
if [ -f "hardhat.config.ts" ]; then
    echo "✅ Hardhat configuration exists"
else
    echo "❌ hardhat.config.ts missing"
    exit 1
fi

# Check if contract is compiled
if [ -f "artifacts/contracts/VotingSystem.sol/VotingSystem.json" ]; then
    echo "✅ Contract compiled"
else
    echo "⚠️  Contract not compiled yet - run: npm run compile"
fi

# Check deployment files
if [ -f "deployments/latest-localhost.json" ]; then
    echo "✅ Deployment history exists"
    echo ""
    echo "📄 Latest Deployment Info:"
    cat deployments/latest-localhost.json | grep -E '(network|chainId|contractAddress)' | sed 's/^/   /'
else
    echo "⚠️  No deployments yet - deploy with: npm run deploy:local"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Repository is ready to use!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next steps:"
echo "  1. Terminal 1: npm run node"
echo "  2. Terminal 2: npm run deploy:local"
echo "  3. Copy address from deployments/latest-localhost.json"
echo "  4. Update frontend .env file"
echo ""
