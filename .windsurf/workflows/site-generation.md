---
description: Step-by-step process for generating static sites from Swift code, including proper URL handling and output verification
---

# Site Generation Workflow

## Overview
Comprehensive guide for generating static HTML sites from Slipstream Swift code, with focus on proper URL construction and output verification to prevent CI runtime failures.

## Prerequisites
- Slipstream project with configured site target
- Swift 6.1 environment
- Resources directory with Tailwind configuration

## Steps

### 1. Verify Site Target Setup
```bash
# Check that site target exists in Package.swift
grep -A 5 'name: "21-dev"' Package.swift

# Verify main.swift exists and has proper URL construction
ls -la Sources/21-dev/main.swift
```

### 2. Check main.swift URL Construction
**CRITICAL**: Ensure proper file URL construction to prevent runtime failures:

```swift
// ✅ CORRECT - Use this pattern
let projectURL = URL(fileURLWithPath: #filePath)
  .deletingLastPathComponent()
  .deletingLastPathComponent()

let outputURL = projectURL.appending(path: "../Websites/21-dev")

// ❌ WRONG - Will cause CI runtime failure  
guard let projectURL = URL(string: #filePath)? // Missing file:// scheme
```

### 3. Generate Site HTML
```bash
# Generate site (creates Websites/<SiteName>/ directory)
swift run 21-dev

# Check for successful generation
echo $?  # Should be 0 for success
```

### 4. Verify Output Structure
```bash
# Check that output directory was created
ls -la Websites/

# Verify index.html exists and has content
ls -la Websites/21-dev/
cat Websites/21-dev/index.html | head -10
```

### 5. Validate HTML Content
```bash
# Check for essential HTML structure
if grep -q "<html" Websites/21-dev/index.html; then
  echo "✅ HTML document structure found"
else
  echo "❌ Missing HTML document structure"
fi

# Check for head section with title
if grep -q "<head>" Websites/21-dev/index.html && grep -q "<title>" Websites/21-dev/index.html; then
  echo "✅ Head section with title found"
else
  echo "❌ Missing head section or title"
fi

# Check for body content
if grep -q "<body>" Websites/21-dev/index.html; then
  echo "✅ Body section found"
else
  echo "❌ Missing body section"
fi
```

### 6. Verify Static Directory Setup
```bash
# Check that static directory exists for CSS
ls -la Websites/21-dev/static/

# Create static directory if missing
mkdir -p Websites/21-dev/static/
```

### 7. Test Integration with Tailwind CSS
```bash
# Verify Tailwind config exists
ls -la Resources/21-dev/tailwind.config.cjs

# Test CSS compilation (should work without errors)
swift package --disable-sandbox tailwindcss \
  --input Resources/21-dev/static/style.css \
  --output Websites/21-dev/static/style.output.css \
  --config Resources/21-dev/tailwind.config.cjs
```

## Expected Results
- ✅ `Websites/21-dev/` directory exists
- ✅ `index.html` file contains valid HTML structure
- ✅ HTML includes `<html>`, `<head>`, `<title>`, and `<body>` tags
- ✅ Static directory ready for CSS output
- ✅ No runtime URL construction errors

## Common Issues & Solutions

### Empty or Missing index.html
**Cause**: Component rendering failure or silent Swift errors
**Solution**:
1. Test with minimal HTML first:
   ```swift
   let testPage = HTML {
     Head { Title("Test") }
     Body { Text("Site generation test") }
   }
   ```
2. Add components incrementally to identify failures

### Runtime URL Construction Errors  
**Symptoms**: `CFURLCopyResourcePropertyForKey failed` or `URL type isn't supported`
**Cause**: Using `URL(string: #filePath)` instead of `URL(fileURLWithPath: #filePath)`
**Solution**: Always use `fileURLWithPath` for file system paths

### Permission Errors
**Symptoms**: "Permission denied" when creating output directory
**Solution**:
```bash
# Check directory permissions
ls -la Websites/
# Ensure write permissions exist
chmod 755 Websites/
```

### Site Content Not Updating
**Cause**: Cached build artifacts
**Solution**:
```bash
# Clean build and regenerate
rm -rf .build
rm -rf Websites/21-dev/
swift run 21-dev
```

## Integration Notes
- **Before CSS compilation**: Always generate site HTML first
- **CI compatibility**: Use same URL construction patterns locally and in CI
- **Testing**: Validate site generation in tests before deployment
- **Output verification**: Check both file existence and content structure

## Next Steps
After successful site generation:
1. Run Tailwind CSS compilation (@build-and-test workflow)
2. Verify complete build output
3. Test in browser for visual verification