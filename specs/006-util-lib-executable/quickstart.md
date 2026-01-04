# Quickstart: Util CLI Architecture Alignment

**Feature**: 006-util-lib-executable  
**Purpose**: Validation commands for each milestone

---

## Prerequisites

```bash
# Ensure you're on feature branch
git branch --show-current  # Should show: 006-util-lib-executable

# Ensure working directory is clean
git status  # Should show: nothing to commit, working tree clean

# Verify current tests pass (baseline)
nocorrect swift test
```

---

## Milestone 1: Documentation

**Changes**: Add `.windsurf/rules/util-architecture.md`

### Validation Commands

```bash
# Verify documentation file exists
test -f .windsurf/rules/util-architecture.md && echo "✅ Documentation exists" || echo "❌ Missing"

# Verify all existing tests still pass (no code changes)
nocorrect swift test

# Verify build still works
nocorrect swift build
```

**Expected Results**:
- ✅ Documentation file exists
- ✅ All tests pass (same count as baseline)
- ✅ Build succeeds

**Commit**: `git commit -m "docs: add util CLI architecture guide"`

---

## Milestone 2: TestHarness Foundation

**Changes**: 
- Add `Tests/UtilIntegrationTests/TestHarness.swift`
- Add TestHarness validation tests

### Validation Commands

```bash
# Verify TestHarness file exists
test -f Tests/UtilIntegrationTests/TestHarness.swift && echo "✅ TestHarness exists" || echo "❌ Missing"

# Build to verify no syntax errors
nocorrect swift build

# Run TestHarness-specific tests
nocorrect swift test --filter TestHarness

# Verify existing tests unchanged
nocorrect swift test --filter UtilitiesTests
nocorrect swift test --filter UtilitiesCLITests

# Run all tests
nocorrect swift test
```

**Expected Results**:
- ✅ TestHarness.swift exists
- ✅ Build succeeds
- ✅ TestHarness validation tests pass (new tests)
- ✅ UtilitiesTests pass (unchanged)
- ✅ UtilitiesCLITests pass (unchanged)
- ✅ Total test count increases by TestHarness tests

**Commit**: `git commit -m "test: add TestHarness for CLI integration testing"`

---

## Milestone 3: Library Rename + Consumer Updates (ATOMIC)

**Changes** (all in one commit):
- Rename `Sources/Utilities/` → `Sources/UtilLib/`
- Rename `Tests/UtilitiesTests/` → `Tests/UtilLibTests/`
- Update Package.swift targets: Utilities → UtilLib, UtilitiesTests → UtilLibTests
- Update util dependency: Utilities → UtilLib
- Update 4 consumers: 21-dev, DesignSystem, IntegrationTests, DesignSystemTests
- Update all test imports: `import Utilities` → `import UtilLib`

### Validation Commands

```bash
# Verify directories renamed
test -d Sources/UtilLib && echo "✅ UtilLib directory exists" || echo "❌ Missing"
test ! -d Sources/Utilities && echo "✅ Utilities directory removed" || echo "❌ Still exists"
test -d Tests/UtilLibTests && echo "✅ UtilLibTests directory exists" || echo "❌ Missing"
test ! -d Tests/UtilitiesTests && echo "✅ UtilitiesTests directory removed" || echo "❌ Still exists"

# Verify Package.swift targets renamed
grep "name: \"UtilLib\"" Package.swift && echo "✅ UtilLib target exists" || echo "❌ Missing"
grep "name: \"UtilLibTests\"" Package.swift && echo "✅ UtilLibTests target exists" || echo "❌ Missing"
! grep "name: \"Utilities\"" Package.swift && echo "✅ Utilities target removed" || echo "❌ Still exists"

# Verify util dependency updated
grep "\.target(name: \"UtilLib\")" Package.swift | grep -A5 "name: \"util\"" && echo "✅ util depends on UtilLib" || echo "❌ Wrong dependency"

# Build all targets
nocorrect swift build

# Run all unit tests
nocorrect swift test --filter UtilLibTests

# Run all tests
nocorrect swift test

# Verify consumer targets compile
nocorrect swift build --target 21-dev
nocorrect swift build --target DesignSystem
nocorrect swift build --target IntegrationTests
nocorrect swift build --target DesignSystemTests
```

**Expected Results**:
- ✅ UtilLib directory exists, Utilities removed
- ✅ UtilLibTests directory exists, UtilitiesTests removed  
- ✅ Package.swift shows UtilLib, UtilLibTests targets
- ✅ util depends on UtilLib (not Utilities)
- ✅ All targets build successfully
- ✅ UtilLibTests pass (same test count as before)
- ✅ All tests pass (including integration tests)
- ✅ All 4 consumer targets compile

**Commit**: `git commit -m "refactor: rename Utilities→UtilLib with atomic consumer updates"`

---

## Milestone 4: Integration Test Migration

**Changes**:
- Rename `Tests/UtilitiesCLITests/` → `Tests/UtilIntegrationTests/`
- Update Package.swift: UtilitiesCLITests → UtilIntegrationTests
- Remove UtilLib, util, TestUtils dependencies
- Add only Subprocess dependency
- Migrate tests to use TestHarness
- Remove all `import Utilities`, `import util` statements

### Validation Commands

```bash
# Verify directory renamed
test -d Tests/UtilIntegrationTests && echo "✅ UtilIntegrationTests directory exists" || echo "❌ Missing"
test ! -d Tests/UtilitiesCLITests && echo "✅ UtilitiesCLITests directory removed" || echo "❌ Still exists"

# Verify Package.swift target renamed
grep "name: \"UtilIntegrationTests\"" Package.swift && echo "✅ UtilIntegrationTests target exists" || echo "❌ Missing"
! grep "name: \"UtilitiesCLITests\"" Package.swift && echo "✅ UtilitiesCLITests target removed" || echo "❌ Still exists"

# Verify dependencies (Subprocess only, no UtilLib/util/TestUtils)
grep -A10 "name: \"UtilIntegrationTests\"" Package.swift | grep "Subprocess" && echo "✅ Has Subprocess" || echo "❌ Missing Subprocess"
! grep -A10 "name: \"UtilIntegrationTests\"" Package.swift | grep "UtilLib" && echo "✅ No UtilLib dependency" || echo "❌ Still has UtilLib"
! grep -A10 "name: \"UtilIntegrationTests\"" Package.swift | grep "\"util\"" && echo "✅ No util dependency" || echo "❌ Still has util"
! grep -A10 "name: \"UtilIntegrationTests\"" Package.swift | grep "TestUtils" && echo "✅ No TestUtils dependency" || echo "❌ Still has TestUtils"

# Verify no forbidden imports in test files
! grep -r "import Utilities" Tests/UtilIntegrationTests && echo "✅ No Utilities imports" || echo "❌ Found Utilities import"
! grep -r "import util" Tests/UtilIntegrationTests && echo "✅ No util imports" || echo "❌ Found util import"

# Build integration tests
nocorrect swift build --target UtilIntegrationTests

# Run integration tests
nocorrect swift test --filter UtilIntegrationTests

# Run all tests
nocorrect swift test
```

**Expected Results**:
- ✅ UtilIntegrationTests directory exists, UtilitiesCLITests removed
- ✅ Package.swift shows UtilIntegrationTests target
- ✅ Only Subprocess dependency (no UtilLib, util, TestUtils)
- ✅ No `import Utilities` or `import util` in test files
- ✅ UtilIntegrationTests builds successfully
- ✅ UtilIntegrationTests pass (same test count as before)
- ✅ All tests pass (unit + integration)

**Commit**: `git commit -m "test: migrate to black-box UtilIntegrationTests with TestHarness"`

---

## Milestone 5: CI Validation

**Changes**: Verify all CI workflows pass, update any target name references

### Validation Commands

```bash
# Run full test suite
nocorrect swift test

# Build all targets
nocorrect swift build

# Verify no references to old target names in CI
! grep -r "Utilities" .github/workflows/ | grep -v "UtilLib" && echo "✅ No old Utilities references" || echo "⚠️  Found old references"
! grep -r "UtilitiesTests" .github/workflows/ && echo "✅ No old UtilitiesTests references" || echo "⚠️  Found old references"
! grep -r "UtilitiesCLITests" .github/workflows/ && echo "✅ No old UtilitiesCLITests references" || echo "⚠️  Found old references"

# Push to trigger CI
git push origin 006-util-lib-executable

# Monitor CI status (GitHub Actions UI or gh CLI)
gh run list --branch 006-util-lib-executable --limit 1
```

**Expected Results**:
- ✅ All tests pass locally
- ✅ All targets build locally
- ✅ No old target name references in CI (or updated appropriately)
- ✅ CI workflows pass on GitHub Actions
- ✅ macOS-15 runner succeeds
- ✅ No deployment/integration failures

**Commit** (if CI updates needed): `git commit -m "ci: update workflows for renamed targets"`

---

## Final Validation: Success Criteria

Verify all 8 success criteria from spec.md satisfied:

```bash
# SC-001: UtilLibTests uses @testable import UtilLib
grep -r "@testable import UtilLib" Tests/UtilLibTests && echo "✅ SC-001" || echo "❌ SC-001"

# SC-002: UtilIntegrationTests has zero UtilLib dependency
! grep -A10 "name: \"UtilIntegrationTests\"" Package.swift | grep "UtilLib" && echo "✅ SC-002" || echo "❌ SC-002"

# SC-003: TestHarness provides CLI execution
test -f Tests/UtilIntegrationTests/TestHarness.swift && grep "func run" Tests/UtilIntegrationTests/TestHarness.swift && echo "✅ SC-003" || echo "❌ SC-003"

# SC-004: All tests pass
nocorrect swift test && echo "✅ SC-004" || echo "❌ SC-004"

# SC-005: Clear separation (UtilLibTests for logic, UtilIntegrationTests for CLI)
test -d Tests/UtilLibTests && test -d Tests/UtilIntegrationTests && echo "✅ SC-005" || echo "❌ SC-005"

# SC-006: Architecture documentation exists
test -f .windsurf/rules/util-architecture.md && echo "✅ SC-006" || echo "❌ SC-006"

# SC-007: CI workflows pass (check GitHub Actions UI)
echo "⏳ SC-007: Verify CI manually at https://github.com/21-DOT-DEV/websites/actions"

# SC-008: util executable is minimal wrapper
wc -l Sources/util/*.swift && echo "ℹ️  SC-008: Verify util files are minimal (Commands stay in util is acceptable)"
```

**All Success Criteria**:
- ✅ SC-001: UtilLibTests uses @testable import UtilLib
- ✅ SC-002: UtilIntegrationTests has zero UtilLib dependency  
- ✅ SC-003: TestHarness provides CLI execution
- ✅ SC-004: All tests pass (100% pass rate)
- ✅ SC-005: Clear separation (unit vs integration)
- ✅ SC-006: Architecture documentation exists
- ✅ SC-007: CI workflows pass
- ✅ SC-008: util executable minimal (Commands in util acceptable per clarifications)

---

## Troubleshooting

### Issue: Tests fail after library rename

**Symptoms**: Import errors, undefined symbols

**Solutions**:
```bash
# Check for missed import updates
grep -r "import Utilities" Sources/
grep -r "import Utilities" Tests/

# Rebuild from scratch
rm -rf .build
nocorrect swift build
nocorrect swift test
```

### Issue: UtilIntegrationTests still coupled to UtilLib

**Symptoms**: Package.swift shows UtilLib dependency, or test files import UtilLib

**Solutions**:
```bash
# Verify Package.swift dependencies
grep -A10 "name: \"UtilIntegrationTests\"" Package.swift

# Check for forbidden imports
grep -r "import UtilLib" Tests/UtilIntegrationTests
grep -r "import util" Tests/UtilIntegrationTests

# Remove forbidden imports manually
# Update tests to use TestHarness.run() instead
```

### Issue: Consumer targets don't compile

**Symptoms**: 21-dev, DesignSystem, etc. show import errors

**Solutions**:
```bash
# Check each consumer's import statements
grep -r "import Utilities" Sources/21-dev/
grep -r "import Utilities" Sources/DesignSystem/
grep -r "import Utilities" Tests/IntegrationTests/
grep -r "import Utilities" Tests/DesignSystemTests/

# Update to import UtilLib
find Sources Tests -name "*.swift" -exec sed -i '' 's/import Utilities/import UtilLib/g' {} +
```

### Issue: CI fails but local passes

**Symptoms**: GitHub Actions show failures, local swift test succeeds

**Solutions**:
```bash
# Check for platform-specific issues
# Verify CI uses correct Swift version (6.1)
# Check CI workflow files for old target names
grep -r "UtilitiesTests" .github/workflows/
grep -r "UtilitiesCLITests" .github/workflows/

# Test in clean environment
rm -rf .build
nocorrect swift build
nocorrect swift test
```

---

## Quick Reference

**Test Commands**:
```bash
# All tests
nocorrect swift test

# Specific target
nocorrect swift test --filter UtilLibTests
nocorrect swift test --filter UtilIntegrationTests

# Verbose output
nocorrect swift test --verbose
```

**Build Commands**:
```bash
# All targets
nocorrect swift build

# Specific target
nocorrect swift build --target UtilLib
nocorrect swift build --target util
nocorrect swift build --target 21-dev
```

**Cleanup Commands**:
```bash
# Clean build artifacts
rm -rf .build

# Reset to last commit
git reset --hard HEAD

# Discard uncommitted changes
git checkout -- .
```

---

## Quickstart Complete

All validation commands defined for:
- ✅ Milestone 1: Documentation
- ✅ Milestone 2: TestHarness Foundation
- ✅ Milestone 3: Library Rename + Consumer Updates
- ✅ Milestone 4: Integration Test Migration
- ✅ Milestone 5: CI Validation
- ✅ Final Success Criteria Verification
- ✅ Troubleshooting Guide

**Ready for**: Implementation (execute milestones following validation commands)
