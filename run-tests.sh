#!/bin/bash

# BSV Test Suite Runner
# Runs all tests and generates comprehensive coverage report

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║     Bounded Stake Voting (BSV) - Test & Coverage Suite            ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
  echo "⚠️  Dependencies not installed. Running npm install..."
  npm install
fi

echo "🧪 Step 1: Running all test cases..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
npm test

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Tests failed. Please fix errors before generating coverage report."
  exit 1
fi

echo ""
echo "✅ All tests passed!"
echo ""
echo "🧪 Step 2: Generating coverage report..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
npm run generate:report

if [ $? -eq 0 ]; then
  echo ""
  echo "╔════════════════════════════════════════════════════════════════════╗"
  echo "║                    ✅ ALL COMPLETE!                                ║"
  echo "╚════════════════════════════════════════════════════════════════════╝"
  echo ""
  echo "📊 Reports Generated:"
  echo "   • coverage/index.html - Interactive HTML report"
  echo "   • coverage/COVERAGE_REPORT.txt - Text summary for instructor"
  echo ""
  echo "💡 To view HTML report, run:"
  echo "   open coverage/index.html"
  echo ""
fi
