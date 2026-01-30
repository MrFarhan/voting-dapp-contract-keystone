# 🎯 Quick Reference - Testing Commands

## For Your Instructor Presentation

### 1️⃣ Run All Tests (Quick Demo)
```bash
npm test
```
**Time**: ~5 seconds  
**Shows**: All 28 tests passing ✅

---

### 2️⃣ Generate Complete Coverage Report
```bash
npm run generate:report
```
**Time**: ~15-20 seconds  
**Generates**:
- ✅ `coverage/COVERAGE_REPORT.txt` - Text report for submission
- ✅ `coverage/index.html` - Interactive HTML visualization

---

### 3️⃣ View Coverage in Browser
```bash
open coverage/index.html
```
**Shows**: Color-coded line-by-line coverage

---

### 4️⃣ Complete Test Suite (All-in-One)
```bash
./run-tests.sh
```
**Does Everything**:
1. Runs all 28 tests
2. Generates coverage
3. Creates instructor report
4. Shows summary

---

## Quick Stats

| Metric | Value |
|--------|-------|
| **Total Tests** | 28 |
| **Passing** | 28 (100%) |
| **VotingSystem Coverage** | ~82% statements, 75% functions |
| **MockToken Coverage** | 100% |

---

## Files to Show/Submit

1. **Terminal Output**: Run `npm test` and screenshot
2. **Text Report**: `coverage/COVERAGE_REPORT.txt`
3. **HTML Report**: `coverage/index.html` (zip coverage folder)
4. **Test Source**: `test/VotingSystem.test.ts`

---

## What Each Command Does

| Command | Purpose | Output |
|---------|---------|--------|
| `npm test` | Run tests only | Terminal output |
| `npm run test:coverage` | Generate coverage | HTML + JSON reports |
| `npm run generate:report` | Coverage + formatted report | Text + HTML |
| `./run-tests.sh` | Everything | All reports + terminal |

---

## Coverage Report Locations

```
coverage/
├── index.html              ← Open this in browser
├── COVERAGE_REPORT.txt     ← Give this to instructor
├── lcov.info              ← For CI/CD tools
└── coverage-final.json    ← Raw coverage data
```

---

## Example: 5-Minute Demo

```bash
# 1. Show all tests pass
npm test

# 2. Generate report
npm run generate:report

# 3. Open HTML
open coverage/index.html

# 4. Show text report
cat coverage/COVERAGE_REPORT.txt
```

---

## Troubleshooting

**Q: Tests fail?**
```bash
rm -rf artifacts cache typechain-types
npm run compile
npm test
```

**Q: Coverage not found?**
```bash
npm run test:coverage
```

**Q: Clean start?**
```bash
rm -rf coverage
npm run generate:report
```

---

**Created**: January 30, 2026  
**Ready to present!** ✅
