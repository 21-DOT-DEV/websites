---
description: Essential commands for building, testing, and verifying the Slipstream websites project during daily development.
---

# Build and Test Workflow

## Overview
Essential commands for building, testing, and verifying the Slipstream websites project during daily development.

## Prerequisites
- Swift 6.1 with Swift Package Manager
- Project cloned and in working directory

## Steps

### 1. Build the Project
```bash
# Build all targets (development build)
nocorrect swift build

# Optional: Build for production (releases)
nocorrect swift build --configuration release
```

### 2. Run Tests
```bash
# Run all tests in parallel
nocorrect swift test

# Run specific test suites
nocorrect swift test --filter DesignSystemTests     # Component unit tests
nocorrect swift test --filter IntegrationTests      # Site integration tests
```

### 3. Generate Site HTML
```bash
# Generate specific site (replace with your site name)
nocorrect swift run 21-dev

# Verify output was created
ls -la Websites/21-dev/
```

### 4. Compile Tailwind CSS
```bash
# Compile CSS for specific site (must match CI exactly)
swift package --disable-sandbox tailwindcss \
  --input Resources/21-dev/static/style.css \
  --output Websites/21-dev/static/style.output.css \
  --config Resources/21-dev/tailwind.config.cjs
```

### 5. Verify Complete Build
```bash
# Check that both HTML and CSS were generated
ls -la Websites/21-dev/
# Should show: index.html and static/style.output.css
```

## Quick Development Loop
For rapid iteration during development:

```bash
# 1. Make changes to Swift code or resources
# 2. Quick rebuild and test
nocorrect swift run 21-dev && \
swift package --disable-sandbox tailwindcss \
  --input Resources/21-dev/static/style.css \
  --output Websites/21-dev/static/style.output.css \
  --config Resources/21-dev/tailwind.config.cjs
# 3. Open Websites/21-dev/index.html in browser to preview
```

## Expected Results
- ✅ Build completes without errors
- ✅ Tests pass
- ✅ `Websites/21-dev/index.html` exists and contains expected content
- ✅ `Websites/21-dev/static/style.output.css` exists and contains compiled Tailwind styles

## CRITICAL: Command Usage Requirements

### Always Use "nocorrect" Prefix for Swift Commands
**NEVER use bare swift commands in conversations** - they break chat flow:

```bash
# ✅ CORRECT - Always use nocorrect prefix to prevent zsh autocorrect
nocorrect swift build
nocorrect swift build --configuration release  
nocorrect swift run 21-dev
nocorrect swift test

# ❌ WRONG - Causes zsh autocorrect interruption in chat flow
swift build
swift run 21-dev
swift test
```

**Why**: The zsh shell attempts to autocorrect "swift" commands, which interrupts conversation flow and requires user intervention.

## Troubleshooting
- **Build fails**: Check Swift version with `nocorrect swift --version` (should be 6.1+)
- **Tests fail**: Run single test suite to isolate issue
- **Site generation fails**: See troubleshooting-common-issues workflow
- **CSS not compiling**: Ensure Tailwind config file exists at `Resources/21-dev/tailwind.config.cjs`
