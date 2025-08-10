---
description: Systematic debugging guide for common Swift/Slipstream development issues, component failures, TestUtils problems, and CI-specific troubleshooting
---

# Troubleshooting Common Issues

## Overview
Comprehensive debugging guide for Slipstream Swift development, covering component rendering failures, TestUtils compilation errors, CI-specific issues, and systematic problem resolution strategies.

## Issue Categories

### 1. Component Rendering Failures

#### Empty or Missing index.html
**Symptoms**: 
- `swift run <SiteName>` completes successfully but generates no `index.html`
- `Websites/<SiteName>/` directory exists but is empty
- No error messages during build

**Root Causes & Solutions**:

**A. Silent Component Implementation Errors**
```swift
// ❌ PROBLEMATIC - Complex generics can cause silent failures
struct MyComponent<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View { /* complex logic */ }
}

// ✅ SOLUTION - Simplify to any View pattern
struct MyComponent: View {
    var content: () -> any View
    var body: some View {
        AnyView(content())
    }
}
```

**B. Missing Import Statements**
```swift
// ❌ MISSING - Site target doesn't import DesignSystem
import Slipstream  // Only base import

// ✅ CORRECT - Import both dependencies
import Slipstream
import DesignSystem
```

**Debugging Strategy**:
1. **Start with minimal HTML**:
   ```swift
   let testPage = HTML {
     Head { Title("Debug Test") }
     Body { Text("Site generation working") }
   }
   ```
2. **Add components incrementally** to identify the failing component
3. **Check build logs** for any warnings about unused dependencies

#### Component Not Rendering Visual Content
**Symptoms**: HTML generates but components appear empty or unstyled

**Solutions**:
```bash
# 1. Verify component structure
grep -r "struct.*View" Sources/DesignSystem/

# 2. Check for ViewBuilder issues
grep -r "@ViewBuilder" Sources/DesignSystem/

# 3. Test component in isolation
swift test --filter "ComponentNameTests"
```

### 2. TestUtils Compilation Errors

#### "Module not compiled for testing" Error
**Symptoms**: 
- CI test failures: `module 'DesignSystem' was not compiled for testing`
- Local tests pass but CI fails

**Root Cause**: TestUtils is a regular target, not a test target

**Solution**:
```swift
// ❌ WRONG - TestUtils.swift with @testable import
import Foundation
import Slipstream
@testable import DesignSystem  // CAUSES CI FAILURE
import Testing

// ✅ CORRECT - TestUtils.swift without @testable import
import Foundation
import Slipstream
import Testing
// No @testable import needed - TestUtils provides utilities only
```

**Verification**:
```bash
# Check TestUtils imports
grep -n "import" Tests/TestUtils/TestUtils.swift

# Ensure no @testable imports in TestUtils
grep "@testable" Tests/TestUtils/TestUtils.swift
```

#### Test Assertion Inconsistencies
**Symptoms**: Manual assertions scattered across test files

**Solution**: Standardize on TestUtils APIs
```swift
// ❌ INCONSISTENT - Manual assertions
#expect(html.contains("<title>"))
#expect(html.contains("bg-blue-500"))

// ✅ CONSISTENT - TestUtils utilities
TestUtils.assertValidHTMLDocument(html)
TestUtils.assertContainsTailwindClasses(html, classes: ["bg-blue-500"])
```

### 3. SwiftPM Plugin Issues

#### Tailwind CSS Compilation Failures
**Symptoms**: 
- "Operation not permitted" errors
- CSS output file not generated or empty

**Solutions**:
```bash
# 1. Remove conflicting output files
rm Websites/<SiteName>/static/style.output.css

# 2. Check directory permissions
ls -la Websites/<SiteName>/static/
chmod 755 Websites/<SiteName>/static/

# 3. Use exact command format (include --config)
swift package --disable-sandbox tailwindcss \
  --input Resources/<SiteName>/static/style.css \
  --output Websites/<SiteName>/static/style.output.css \
  --config Resources/<SiteName>/tailwind.config.cjs

# 4. Verify config file exists
ls -la Resources/<SiteName>/tailwind.config.cjs
```

#### Missing Tailwind Styles in Browser
**Symptoms**: HTML has correct classes but no visual styling

**Root Cause**: Local/CI command mismatch or content glob issues

**Solutions**:
```bash
# 1. Verify Tailwind content configuration
cat Resources/<SiteName>/tailwind.config.cjs

# 2. Check content glob includes generated HTML only
# Should be: ["./Websites/<SiteName>/**/*.html"]
# NOT: ["./Sources/**/*.swift"]

# 3. Ensure command consistency between local and CI
# Check .github/workflows/cloudflare-deployment.yml matches local command
```

### 4. CI-Specific Issues

#### Swift 6.1 Compatibility on macOS-15
**Symptoms**: 
- Build failures on macOS-15 runners
- "Swift compiler not found" or version mismatch errors

**Solution**:
```yaml
# GitHub Actions workflow
env:
  DEVELOPER_DIR: /Applications/Xcode_16.4.app/Contents/Developer
```

**Verification**:
```bash
# Local verification
echo $DEVELOPER_DIR
swift --version  # Should show Swift 6.1
```

#### Site Generation Runtime Failures
**Symptoms**: 
- `CFURLCopyResourcePropertyForKey failed`
- `URL type isn't supported`

**Root Cause**: Incorrect URL construction from `#filePath`

**Solution**:
```swift
// ❌ WRONG - String URL construction
guard let projectURL = URL(string: #filePath)? 

// ✅ CORRECT - File URL construction  
let projectURL = URL(fileURLWithPath: #filePath)
```

### 5. Build and Test System Issues

#### Dependency Resolution Failures
**Symptoms**: "Package dependency could not be resolved"

**Solutions**:
```bash
# 1. Clean package resolution
rm -rf .build
swift package resolve

# 2. Check Package.swift syntax
swift package dump-package

# 3. Verify dependency versions
swift package show-dependencies
```

#### Test Target Configuration Issues
**Symptoms**: Tests can't find modules or imports fail

**Verification**:
```bash
# Check Package.swift test target configuration
grep -A 10 "testTarget" Package.swift

# Ensure proper dependencies:
# DesignSystemTests depends on: ["DesignSystem", "TestUtils"]
# IntegrationTests depends on: ["DesignSystem", "<SiteName>", "TestUtils"]
```

### 6. Local Development Environment Issues

#### Build Cache Corruption
**Symptoms**: Inconsistent build behavior or outdated artifacts

**Solution**:
```bash
# Full clean and rebuild
rm -rf .build
rm -rf Websites/<SiteName>/
swift clean
nocorrect swift build --configuration release
```

#### Permission Errors
**Symptoms**: "Permission denied" when creating output directories

**Solutions**:
```bash
# Check current permissions
ls -la Websites/

# Fix directory permissions
chmod 755 Websites/
chmod -R 755 Websites/<SiteName>/

# Recreate directories if needed
rm -rf Websites/<SiteName>/
mkdir -p Websites/<SiteName>/static/
```

## Systematic Debugging Process

### Step 1: Identify Issue Category
- **Build Phase**: SwiftPM, dependency resolution
- **Generation Phase**: Site rendering, component failures  
- **CSS Phase**: Tailwind compilation, styling issues
- **Test Phase**: TestUtils, assertion problems
- **CI Phase**: Environment, runtime failures

### Step 2: Reproduce Locally
```bash
# Use build-and-test workflow for comprehensive verification
# Run each step individually to isolate the problem:

# 1. Build
nocorrect swift build --configuration release

# 2. Test  
swift test

# 3. Generate
swift run <SiteName>

# 4. CSS
swift package --disable-sandbox tailwindcss \
  --input Resources/<SiteName>/static/style.css \
  --output Websites/<SiteName>/static/style.output.css \
  --config Resources/<SiteName>/tailwind.config.cjs
```

### Step 3: Check Common Patterns
- **URL Construction**: Always use `URL(fileURLWithPath: #filePath)`
- **TestUtils Imports**: Never use `@testable import` in TestUtils
- **Command Consistency**: Local and CI commands must be identical
- **Content Globs**: Tailwind should process HTML output, not Swift source

### Step 4: Incremental Testing
- **Component Issues**: Start with inline HTML, add components one by one
- **Test Issues**: Use TestUtils utilities instead of manual assertions
- **Build Issues**: Clean environment and rebuild from scratch

## Prevention Strategies

### Code Review Checklist
- [ ] URL construction uses `fileURLWithPath`
- [ ] TestUtils has no `@testable` imports
- [ ] Tailwind commands match between local/CI
- [ ] Components use simple `any View` patterns
- [ ] Test files use TestUtils consistently

### Local Validation
- [ ] Run full build-and-test workflow before commits
- [ ] Verify site generation produces expected output
- [ ] Check CSS compilation generates styles
- [ ] Validate HTML structure and content

### CI Monitoring
- [ ] Watch for environment variable requirements
- [ ] Monitor for new Swift/Xcode version compatibility
- [ ] Verify deployment artifacts are correctly generated