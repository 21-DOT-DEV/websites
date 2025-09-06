---
description: >
  Chain build and test operations with enhanced error handling.
  Consolidates /10-build and /11-test with better failure recovery.
---

# Build and Test Chain

## 1. Swift Build
// turbo
```bash
nocorrect swift build
```

**Error handling**:
- If build fails with dependency issues, run `swift package resolve`
- If Swift version errors occur, verify Swift 6.1+ is installed: `swift --version`
- Check Package.swift for syntax errors if compilation fails

**Verify build output**:
- Confirm executable targets are built in `.build/debug/`
- For 21-dev site: verify `.build/debug/21-dev` exists
- No compilation warnings should remain unaddressed

## 2. Run Tests
// turbo
```bash
nocorrect swift test
```

**Error handling**:
- If tests fail due to missing TestUtils imports, verify TestUtils target builds correctly
- For HTML rendering test failures, check if components use proper Slipstream APIs
- If snapshot tests fail, run `/70-update-snapshots` workflow

**Verify test results**:
- All test cases should pass
- No test compilation warnings
- Test coverage should include new components and models

## 3. RawHTML Audit (if needed)
If any test failures involve component rendering:
```bash
# Check for RawHTML that should use Slipstream APIs
grep -r "RawHTML(" Sources/DesignSystem/ --include="*.swift"
```
