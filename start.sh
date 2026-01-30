#!/bin/bash

echo "🚀 Starting Hardhat Node and Deploying Contract..."
echo ""

# Start Hardhat node in background
echo "📡 Starting Hardhat node..."
npm run node &
NODE_PID=$!

# Wait for node to be ready
echo "⏳ Waiting for node to start..."
sleep 5

# Deploy the contract
echo "📦 Deploying contract..."
npm run deploy:local

# Check if deployment was successful
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Setup complete!"
    echo ""
    echo "📋 Contract address saved in: deployments/latest-localhost.json"
    echo ""
    echo "🔗 You can now:"
    echo "   1. Copy the contract address from deployments/latest-localhost.json"
    echo "   2. Update your frontend .env file"
    echo "   3. Start your frontend app"
    echo ""
    echo "⚠️  Keep this terminal open - the Hardhat node is running in the background"
    echo "   To stop: Press Ctrl+C or run: kill $NODE_PID"
    echo ""
    
    # Wait for Ctrl+C
    wait $NODE_PID
else
    echo ""
    echo "❌ Deployment failed!"
    kill $NODE_PID
    exit 1
fi
