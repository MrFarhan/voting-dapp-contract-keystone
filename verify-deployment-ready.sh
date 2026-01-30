#!/bin/bash

# Pre-Deployment Verification Script
# Ensures everything is perfect before testnet deployment

echo "╔════════════════════════════════════════════════════════╗"
echo "║     PRE-DEPLOYMENT VERIFICATION CHECKLIST             ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0
WARNINGS=0

# Function to print success
success() {
    echo "✅ $1"
}

# Function to print error
error() {
    echo "❌ $1"
    ((ERRORS++))
}

# Function to print warning
warning() {
    echo "⚠️  $1"
    ((WARNINGS++))
}

echo "🔍 1. Checking Node.js and npm..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    success "Node.js installed: $NODE_VERSION"
else
    error "Node.js not found. Please install Node.js v16+"
fi

if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    success "npm installed: $NPM_VERSION"
else
    error "npm not found"
fi

echo ""
echo "🔍 2. Checking dependencies..."
if [ -d "node_modules" ]; then
    success "node_modules directory exists"
else
    error "node_modules not found. Run: npm install"
fi

echo ""
echo "🔍 3. Checking environment configuration..."
if [ -f ".env" ]; then
    success ".env file exists"
    
    # Check for required variables
    if grep -q "PRIVATE_KEY=" .env && ! grep -q "PRIVATE_KEY=your_private_key_here" .env; then
        success "PRIVATE_KEY configured"
    else
        warning "PRIVATE_KEY not configured or using placeholder value"
    fi
    
    if grep -q "SEPOLIA_RPC_URL=" .env && ! grep -q "YOUR-API-KEY" .env; then
        success "SEPOLIA_RPC_URL configured"
    else
        warning "SEPOLIA_RPC_URL not configured or using placeholder"
    fi
    
    if grep -q "ETHERSCAN_API_KEY=" .env; then
        success "ETHERSCAN_API_KEY present (optional)"
    else
        warning "ETHERSCAN_API_KEY not set (contract verification will fail)"
    fi
else
    warning ".env file not found. Copy from .env.example"
fi

echo ""
echo "🔍 4. Compiling contracts..."
npm run compile > /tmp/compile.log 2>&1
if [ $? -eq 0 ]; then
    success "Contracts compiled successfully"
else
    error "Compilation failed. Check /tmp/compile.log"
    cat /tmp/compile.log
fi

echo ""
echo "🔍 5. Running tests..."
npm test > /tmp/test.log 2>&1
if [ $? -eq 0 ]; then
    TEST_COUNT=$(grep -o "passing" /tmp/test.log | wc -l | tr -d ' ')
    if [ "$TEST_COUNT" = "1" ]; then
        PASSING=$(grep "passing" /tmp/test.log | grep -o "[0-9]*" | head -1)
        success "All $PASSING tests passing"
    else
        success "Tests completed"
    fi
else
    error "Tests failed. Check /tmp/test.log"
    tail -20 /tmp/test.log
fi

echo ""
echo "🔍 6. Checking contract files..."
if [ -f "contracts/VotingSystemOptimized.sol" ]; then
    success "VotingSystemOptimized.sol exists"
else
    error "VotingSystemOptimized.sol not found"
fi

if [ -f "contracts/VotingSystem.sol" ]; then
    success "VotingSystem.sol exists"
else
    error "VotingSystem.sol not found"
fi

if [ -f "contracts/MockStakingToken.sol" ]; then
    success "MockStakingToken.sol exists"
else
    error "MockStakingToken.sol not found"
fi

echo ""
echo "🔍 7. Checking deployment scripts..."
if [ -f "scripts/deploy-optimized-testnet.ts" ]; then
    success "deploy-optimized-testnet.ts exists"
else
    error "Testnet deployment script not found"
fi

echo ""
echo "🔍 8. Checking documentation..."
DOCS=("README.md" "TESTNET_DEPLOYMENT.md" "GAS_OPTIMIZATION.md" "TESTING_GUIDE.md")
for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        success "$doc exists"
    else
        warning "$doc not found"
    fi
done

echo ""
echo "🔍 9. Checking hardhat configuration..."
if grep -q "sepolia:" hardhat.config.ts; then
    success "Sepolia network configured in hardhat.config.ts"
else
    error "Sepolia network not configured"
fi

echo ""
echo "🔍 10. Checking package.json scripts..."
if grep -q "deploy:sepolia" package.json; then
    success "deploy:sepolia script exists"
else
    error "deploy:sepolia script not found in package.json"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo ""
    echo "🎉 ALL CHECKS PASSED!"
    echo ""
    echo "✅ Ready for testnet deployment!"
    echo ""
    echo "Next steps:"
    echo "1. Ensure you have Sepolia ETH in your wallet"
    echo "2. Double-check your .env configuration"
    echo "3. Run: npm run deploy:sepolia"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo ""
    echo "⚠️  $WARNINGS warning(s) found"
    echo ""
    echo "You can proceed with deployment, but review warnings above."
    echo ""
    exit 0
else
    echo ""
    echo "❌ $ERRORS error(s) found"
    if [ $WARNINGS -gt 0 ]; then
        echo "⚠️  $WARNINGS warning(s) found"
    fi
    echo ""
    echo "Please fix the errors above before deploying."
    echo ""
    exit 1
fi
