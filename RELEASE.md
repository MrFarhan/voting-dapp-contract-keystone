# Release Guide - Semantic Versioning

## Current Version: **0.2.0**

All version numbers follow [Semantic Versioning 2.0.0](https://semver.org/)

---

## Version Number Format

```
MAJOR.MINOR.PATCH
```

### Rules

1. **MAJOR** version (X.0.0): Incompatible API changes
   - Breaking changes to contract interfaces
   - Removal of features
   - Changes that require migration scripts
   - Example: `1.0.0` → `2.0.0`

2. **MINOR** version (0.X.0): New features (backward-compatible)
   - New functions added
   - New features that don't break existing code
   - Performance improvements
   - Example: `0.2.0` → `0.3.0`

3. **PATCH** version (0.0.X): Bug fixes (backward-compatible)
   - Bug fixes
   - Security patches
   - Documentation updates
   - Example: `0.2.0` → `0.2.1`

---

## Pre-1.0 Development

**Current Status**: Version 0.x.x indicates **pre-release/development**

- Major version **0** means public API is not stable yet
- Breaking changes may occur in MINOR versions (0.X.0)
- Ready for testing and development
- NOT recommended for production mainnet without audit

---

## Version Tracking Files

All version numbers must be synchronized across:

| File | Location | Format |
|------|----------|--------|
| **package.json** | Root | `"version": "0.2.0"` |
| **.version** | Root | `VERSION=0.2.0` |
| **CHANGELOG.md** | Root | `## [0.2.0] - 2026-01-30` |

### Update Checklist

When releasing a new version:

- [ ] Update `package.json` version field
- [ ] Update `.version` VERSION value
- [ ] Add new entry to `CHANGELOG.md`
- [ ] Update `RELEASE_DATE` in `.version`
- [ ] Update `RELEASE_NAME` in `.version`
- [ ] Tag the release in git
- [ ] Push tag to repository

---

## Release Process

### 1. Prepare the Release

```bash
# Run all tests
npm test

# Check test coverage
npm run test:coverage

# Run gas comparison
npm run test:gas

# Verify deployment readiness
./verify-deployment-ready.sh

# Compile contracts
npm run compile
```

### 2. Update Version Numbers

**For Minor Release (0.2.0 → 0.3.0):**

```bash
# Edit package.json
{
  "version": "0.3.0"
}

# Edit .version
VERSION=0.3.0
RELEASE_DATE=2026-XX-XX
RELEASE_NAME="Feature Name"

# Edit CHANGELOG.md
## [0.3.0] - 2026-XX-XX
### Added
- New feature 1
- New feature 2
```

**For Patch Release (0.2.0 → 0.2.1):**

```bash
# Edit package.json
{
  "version": "0.2.1"
}

# Edit .version
VERSION=0.2.1

# Edit CHANGELOG.md
## [0.2.1] - 2026-XX-XX
### Fixed
- Bug fix 1
- Bug fix 2
```

### 3. Commit and Tag

```bash
# Commit version updates
git add package.json .version CHANGELOG.md
git commit -m "chore: bump version to 0.3.0"

# Create annotated tag
git tag -a v0.3.0 -m "Release v0.3.0: Feature Name

Major changes:
- New feature 1
- New feature 2
- Performance improvements"

# Push commits and tags
git push origin main
git push origin v0.3.0
```

### 4. Deploy (if applicable)

```bash
# Deploy to testnet
npm run deploy:sepolia

# Verify on Etherscan
npm run verify:sepolia <CONTRACT_ADDRESS>
```

---

## Version History

| Version | Date | Description | Breaking |
|---------|------|-------------|----------|
| **0.2.0** | 2026-01-30 | Gas optimization + testnet deployment | No |
| **0.1.0** | 2026-01-30 | Initial BSV implementation | - |

---

## Upcoming Releases

### 0.3.0 - Frontend Integration (Planned)
- React frontend components
- Web3 wallet integration
- Contract interaction UI
- **Target**: February 2026

### 0.4.0 - Advanced Voting Mechanisms (Planned)
- Quadratic voting option
- Ranked choice voting
- Delegation support
- **Target**: March 2026

### 0.5.0 - Multi-Chain Support (Planned)
- Polygon deployment
- Arbitrum deployment
- Cross-chain compatibility
- **Target**: April 2026

### 1.0.0 - Production Release (Planned)
- **Full security audit required**
- Mainnet deployment scripts
- Production documentation
- Bug bounty program
- **Target**: Q2 2026 (after audit)

---

## Git Tag Naming Convention

```bash
# Format: vMAJOR.MINOR.PATCH
v0.1.0  # Initial release
v0.2.0  # Gas optimization
v0.2.1  # Bug fix (if needed)
v1.0.0  # Production release

# Pre-release tags (for testing)
v0.3.0-alpha.1
v0.3.0-beta.1
v0.3.0-rc.1
```

---

## Commands

### View All Tags
```bash
git tag
```

### View Specific Tag Details
```bash
git show v0.2.0
```

### Checkout Specific Version
```bash
git checkout v0.2.0
```

### Compare Versions
```bash
git diff v0.1.0 v0.2.0
```

### Delete Tag (if mistake)
```bash
# Local
git tag -d v0.2.0

# Remote
git push origin :refs/tags/v0.2.0
```

---

## Release Checklist Template

Copy this for each release:

```markdown
## Release X.Y.Z Checklist

### Pre-Release
- [ ] All tests passing (36/36)
- [ ] Test coverage maintained (>80%)
- [ ] Gas benchmarks run
- [ ] Contracts compile without errors
- [ ] No security warnings
- [ ] Documentation updated
- [ ] CHANGELOG.md entry added

### Version Updates
- [ ] package.json version updated
- [ ] .version VERSION updated
- [ ] .version RELEASE_DATE updated
- [ ] .version RELEASE_NAME updated
- [ ] CHANGELOG.md updated

### Git Operations
- [ ] Changes committed
- [ ] Tag created with descriptive message
- [ ] Pushed to main branch
- [ ] Tag pushed to remote

### Deployment (if applicable)
- [ ] Deployed to testnet
- [ ] Verified on block explorer
- [ ] Tested live contract
- [ ] Deployment artifacts saved

### Communication
- [ ] Release notes published
- [ ] Team notified
- [ ] Documentation updated
- [ ] Instructor informed (if applicable)
```

---

## Best Practices

1. **Always test before releasing**
   - Run full test suite
   - Check gas consumption
   - Verify on testnet first

2. **Write clear CHANGELOG entries**
   - Use categories: Added, Changed, Fixed, Removed
   - Be specific about changes
   - Include migration notes if needed

3. **Use annotated tags**
   - Include release notes in tag message
   - Reference important commits
   - Link to CHANGELOG

4. **Never skip version numbers**
   - No jumping from 0.2.0 to 0.4.0
   - Sequential releases only

5. **Coordinate mainnet releases**
   - Require security audit for 1.0.0+
   - Have rollback plan
   - Coordinate with team

---

## Emergency Hotfix Process

For critical bugs in production:

```bash
# 1. Create hotfix branch from tag
git checkout -b hotfix/v0.2.1 v0.2.0

# 2. Fix the bug
# ... make changes ...

# 3. Update version to 0.2.1 (patch)
# Update package.json, .version, CHANGELOG.md

# 4. Test thoroughly
npm test

# 5. Commit and tag
git commit -m "fix: critical bug description"
git tag -a v0.2.1 -m "Hotfix: critical bug"

# 6. Merge to main and deploy
git checkout main
git merge hotfix/v0.2.1
git push origin main v0.2.1
```

---

**Maintained By**: Development Team  
**Last Updated**: January 30, 2026  
**Reference**: [Semantic Versioning 2.0.0](https://semver.org/)
