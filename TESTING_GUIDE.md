# 🧪 Testing Guide - BSV Smart Contract

## Quick Commands

### Run All Tests
```bash
npm test
```

### Run Tests with Verbose Output
```bash
npm run test:verbose
```

### Generate Coverage Report
```bash
npm run test:coverage
```

### Complete Test Suite + Coverage Report
```bash
./run-tests.sh
```

### Generate Instructor Report Only
```bash
npm run generate:report
```

---

## 📊 Available Commands Explained

### 1. **Basic Test Run**
```bash
npm test
```
- Runs all 28 test cases
- Shows pass/fail status
- Quick validation (< 10 seconds)

**Output Example:**
```
  VotingSystem - Bounded Stake Voting (BSV)
    Deployment
      ✓ Should set the correct admin
      ✓ Should set the staking token correctly
    ...
  28 passing (3s)
```

---

### 2. **Coverage Analysis**
```bash
npm run test:coverage
```
- Runs tests with coverage instrumentation
- Generates detailed coverage metrics
- Creates HTML report in `coverage/` folder

**What it shows:**
- **Statements Coverage**: % of code statements executed
- **Branch Coverage**: % of decision branches tested
- **Function Coverage**: % of functions called
- **Line Coverage**: % of lines executed

**Output Location:**
- `coverage/index.html` - Interactive HTML report
- `coverage/coverage-final.json` - Raw coverage data

---

### 3. **Complete Test Suite** (Recommended for Instructor)
```bash
./run-tests.sh
```

**This script does everything:**
1. Runs all 28 test cases
2. Generates coverage analysis
3. Creates formatted instructor report
4. Shows summary in terminal

**Generates:**
- ✅ `coverage/COVERAGE_REPORT.txt` - Text summary
- ✅ `coverage/index.html` - Interactive visualization
- ✅ Terminal output with all metrics

---

### 4. **View Coverage Report in Browser**
```bash
# macOS
open coverage/index.html

# Linux
xdg-open coverage/index.html

# Windows
start coverage/index.html
```

---

## 📋 Test Suite Breakdown

### Total: 28 Test Cases

| Category | Tests | Description |
|----------|-------|-------------|
| **Deployment** | 3 | Contract initialization, admin setup |
| **Membership** | 4 | Add/remove members, access control |
| **Staking** | 4 | Token staking, unstaking, validation |
| **Vote Weights** | 5 | Formula calculation, caps, edge cases |
| **Elections** | 2 | Proposal creation, validation |
| **Voting** | 6 | Weighted votes, aggregation, security |
| **Results** | 1 | Winner determination |
| **Edge Cases** | 3 | Zero stakes, max stakes, boundaries |

---

## 📊 Expected Coverage

Based on the comprehensive test suite:

| Metric | Expected | Description |
|--------|----------|-------------|
| **Statements** | ~95%+ | Most code paths tested |
| **Branches** | ~85%+ | Decision logic validated |
| **Functions** | ~100% | All public functions tested |
| **Lines** | ~95%+ | High line coverage |

---

## 🎯 What to Show Your Instructor

### Option 1: Quick Demo (5 minutes)
```bash
npm test
```
Show all 28 tests passing in real-time.

---

### Option 2: Comprehensive Report (10 minutes)
```bash
./run-tests.sh
```
Then open `coverage/COVERAGE_REPORT.txt` to show:
- ✅ All 28 tests passing
- ✅ Coverage percentages
- ✅ Security features tested
- ✅ Formula verification

---

### Option 3: Interactive Visualization (15 minutes)
```bash
npm run test:coverage
open coverage/index.html
```
Show the HTML report with:
- Color-coded coverage visualization
- Line-by-line coverage highlights
- Interactive contract exploration

---

## 📝 Files for Submission

If your instructor wants files to review:

1. **Test Results**: Screenshot of `npm test` output
2. **Coverage Report**: `coverage/COVERAGE_REPORT.txt`
3. **HTML Report**: `coverage/index.html` (can zip the whole coverage folder)
4. **Test Code**: `test/VotingSystem.test.ts` (source of all tests)

---

## 🔍 Understanding Coverage Reports

### What the HTML Report Shows

```
contracts/VotingSystem.sol
├── Statements: 142/148 (95.95%)
├── Branches: 45/52 (86.54%)
├── Functions: 24/24 (100%)
└── Lines: 195/203 (96.06%)
```

**Color Coding:**
- 🟢 **Green**: Fully covered (tested)
- 🟡 **Yellow**: Partially covered
- 🔴 **Red**: Not covered (untested)

---

## 🚀 CI/CD Integration (Optional)

You can add these to your workflow:

```json
{
  "scripts": {
    "test:ci": "npm test -- --reporter json > test-results.json",
    "coverage:ci": "npm run test:coverage && node scripts/parse-coverage.js"
  }
}
```

---

## ⚡ Performance Tips

- **First run**: May take 15-20 seconds (contract compilation)
- **Subsequent runs**: ~5-10 seconds (cached)
- **Coverage analysis**: ~15-30 seconds (instrumentation overhead)

---

## 🐛 Troubleshooting

### Issue: Tests fail
```bash
# Clean and rebuild
rm -rf artifacts cache typechain-types
npm run compile
npm test
```

### Issue: Coverage not generating
```bash
# Reinstall coverage package
npm install --save-dev solidity-coverage
npm run test:coverage
```

### Issue: Old coverage data
```bash
# Clean coverage folder
rm -rf coverage
npm run test:coverage
```

---

## 📚 Additional Resources

- Test file: `test/VotingSystem.test.ts`
- Contract code: `contracts/VotingSystem.sol`
- Complete docs: `BSV_COMPLETE.md`

---

## ✅ Verification Checklist

Before showing to instructor:

- [ ] All 28 tests passing
- [ ] Coverage report generated
- [ ] HTML report opens correctly
- [ ] COVERAGE_REPORT.txt readable
- [ ] No compilation errors
- [ ] Hardhat network running (if needed)

---

**Generated**: January 30, 2026  
**Version**: 1.0.0  
**Status**: Ready for Submission ✅
