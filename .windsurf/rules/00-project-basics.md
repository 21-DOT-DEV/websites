---
trigger: always_on
description: >
  Project configuration and development guidelines for Swift-based static sites using Slipstream and Tailwind CSS.
  Includes local Slipstream API references, build commands, TestUtils architecture, and troubleshooting guidance.
---

# Project Basics

## Stack & Tools
- **ALWAYS use**: Swift 6.1 with Swift Package Manager
- **ALWAYS use**: Slipstream v2.0 for static site generation (local source: `.build/checkouts/slipstream/`)
- **ALWAYS use**: Tailwind CSS via SwiftPM plugin (`swift-plugin-tailwindcss`) - no Node runtime required
- **ALWAYS use**: Swift's built-in `swift-testing` framework for all testing

## Repository Structure & Commands

### Target Layout
- **CREATE** each site as standalone Swift executable target in `Sources/<SiteName>/`
- **CURRENT TARGETS**: 21-dev
- **PLACE** shared code in `Sources/DesignSystem/` (sub-folders: Components/, Layouts/, Tags/, Utilities/)
- **PLACE** shared test utilities in `Tests/TestUtils/` (reusable across all test targets)
- **ORGANIZE** tests in `Tests/DesignSystemTests/` (unit tests) and `Tests/IntegrationTests/` (site tests)
- **OUTPUT** generated HTML to `Websites/<SiteName>/` (git-ignored)

#### Always Reference Build Commands
**See /build-and-test workflow** for essential development commands including:
- Building the project with Swift 6.1
- Running tests (all tests, specific test suites)
- Generating site HTML
- Compiling Tailwind CSS with proper local/CI consistency
- Verifying complete build output

## Component Development & Debugging

#### Always Reference Component Development Workflow
**See /component-development workflow** for best practices for creating, testing, and integrating DesignSystem components including:
- Component design and architecture (simple APIs, avoiding complex generics)
- Step-by-step development process from design to integration
- TestUtils-based testing with templates and validation patterns
- Site integration strategies and incremental debugging
- Advanced component patterns (flexible content, layouts, utilities)
- Common issues and solutions (silent failures, styling problems, type complexity)

## Site Generation Architecture

#### Always Reference Site Generation Workflow
**See /site-generation workflow** for comprehensive site generation guidance including:
- Proper URL construction to prevent CI runtime failures
- Step-by-step site generation process and output verification
- HTML content validation and structure checking
- Static directory setup and CSS integration
- Common troubleshooting scenarios and solutions

## TestUtils Architecture & Usage

### TestUtils Module Purpose
- **PROVIDE** shared test utilities across all test targets (DesignSystemTests, IntegrationTests)
- **ENSURE** consistent HTML rendering using official Slipstream APIs
- **ELIMINATE** code duplication in test assertions and file operations
- **STANDARDIZE** validation patterns for HTML structure, Tailwind classes, and content

### CRITICAL: TestUtils Import Rules
**TestUtils is a REGULAR target, not a test target** - strict import requirements:

```swift
// ✅ CORRECT - TestUtils.swift imports
import Foundation
import Slipstream
import Testing

// ❌ WRONG - Causes CI failure: "module not compiled for testing"
@testable import DesignSystem  // NEVER use in TestUtils
```

**Why**: Regular targets cannot use `@testable import` during production builds. TestUtils provides generic utilities and doesn't need internal DesignSystem APIs.

### Essential TestUtils APIs
```swift
// HTML Rendering (always use official Slipstream API)
TestUtils.renderHTML(view)                    // Wraps Slipstream.renderHTML()

// Structural Validation
TestUtils.assertValidHTMLDocument(html)       // Complete HTML document structure
TestUtils.assertValidTitle(html, expectedTitle: "...") // Title tag validation
TestUtils.assertContainsStylesheet(html)      // Stylesheet link validation

// Tailwind CSS Validation
TestUtils.assertContainsTailwindClasses(html, classes: [...]) // Batch class validation
TestUtils.placeholderViewClasses             // Predefined common PlaceholderView classes

// Content Validation
TestUtils.assertContainsText(html, texts: [...]) // Batch text content validation
TestUtils.assertDoesNotContainText(html, texts: [...]) // Negative text validation

// File System Operations
TestUtils.createTempDirectory(suffix: "...")  // Safe temporary directories
TestUtils.cleanupDirectory(url)               // Safe cleanup operations

// HTML Processing
TestUtils.normalizeHTML(html)                 // Normalize whitespace for comparisons
```

### TestUtils Consistency Standards
- **ALWAYS** use TestUtils utilities instead of manual `#expect(html.contains(...))` for:
  - HTML document structure validation
  - Batch Tailwind class checking
  - Stylesheet presence validation
  - Batch text content validation
- **PREFER** TestUtils.renderHTML() over manual rendering helpers
- **USE** systematic code review to catch manual assertions that should use TestUtils
- **SEARCH** for patterns like `#expect(html.contains(` to identify inconsistencies

## Slipstream Development Patterns

#### Always Reference Slipstream Best Practices Workflow
**See /slipstream-best-practices workflow** for comprehensive Slipstream development guidance including:
- SwiftUI-like component usage (VStack, HStack, Container) with decision trees
- **CRITICAL API discovery workflow** - systematic process to find existing APIs before ClassModifier
- Local Slipstream codebase exploration and directory-specific search strategies
- **Common patterns reference** - quick lookup for layout, flexbox, interactive, and typography APIs
- CSS integration and Tailwind configuration best practices
- Component architecture guidelines and styling consistency
- Performance optimization and build troubleshooting

### CRITICAL: Slipstream API Usage Rules
**ALWAYS use the systematic API discovery workflow before resorting to ClassModifier**:

#### Step 1: Search Slipstream Source Directories
```bash
# REQUIRED: Search category-specific directories first
ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/Sizing/
ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/FlexboxAndGrid/
ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/Layout/
```

#### Step 2: Check Common Patterns Reference
**See /slipstream-best-practices workflow** for quick reference tables covering:
- Layout & Sizing: `w-full` → `.frame(width: .full)`, `min-h-screen` → `.frame(minHeight: .screen)`
- Flexbox: `justify-between` → `.justifyContent(.between)`, `items-center` → `.alignItems(.center)`
- Interactive States: `hover:*` → State/Condition APIs, `transition-*` → `.transition()` APIs

#### Step 3: Document Missing APIs Properly
```swift
// TODO: Missing Slipstream API for [specific functionality]
// MISSING APIs: [list the ideal API calls that should exist]
// ClassModifier used for: [exact CSS classes used]
.modifier(ClassModifier(add: "text-3xl cursor-pointer"))
```

#### Step 4: Track for Future Contribution
- **HIGH PRIORITY**: Cursor styles, large typography, z-index
- **MEDIUM PRIORITY**: Focus rings, advanced positioning, backdrop effects

### CRITICAL: Slipstream API Discovery Commands
**Most frequently needed search commands**:
```bash
# For sizing/layout needs (most common)
cat .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/Sizing/View+frame.swift
cat .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/FlexboxAndGrid/View+justifyContent.swift

# For interactive states
cat .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/State.swift

# General grep searches
grep -r "hover\|State\|Condition" .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/
```

## Tailwind Configuration

### Required Files per Site
- **CREATE**: `Resources/<SiteName>/tailwind.config.cjs`
- **CREATE**: `Resources/<SiteName>/static/style.css` with Tailwind directives

### Critical Configuration Rules
**IMPORTANT**: Tailwind content globs should **ONLY** include generated HTML:
```javascript
content: ["./Websites/<SiteName>/**/*.html"]
```
**NEVER include** `Sources/**/*.swift` - Tailwind processes HTML output, not Swift source

### CRITICAL: Local/CI Command Consistency
**The Tailwind compilation command used locally MUST exactly match CI workflow**:

```bash
# ✅ CORRECT - Use this exact command both locally and in CI
swift package --disable-sandbox tailwindcss \
  --input Resources/<SiteName>/static/style.css \
  --output Websites/<SiteName>/static/style.output.css \
  --config Resources/<SiteName>/tailwind.config.cjs

# ❌ WRONG - Missing --config causes style failures in deployment
swift package --disable-sandbox tailwindcss build \
  -i Resources/<SiteName>/static/style.css \
  -o Websites/<SiteName>/static/style.output.css
```

### CRITICAL: Build Command Requirements
**NEVER use bare "swift build" in conversations** - it breaks chat flow:
```bash
# ✅ CORRECT - Always use nocorrect prefix
nocorrect swift build
nocorrect swift build --configuration release  
nocorrect swift run 21-dev
nocorrect swift test

# ❌ WRONG - Causes zsh autocorrect interruption  
swift build
swift run 21-dev
```

## Troubleshooting

#### Always Reference Troubleshooting Workflow
**See /troubleshooting-common-issues workflow** for systematic debugging guidance including:
- Component rendering failures and debugging strategies
- TestUtils compilation errors and import rule violations  
- SwiftPM plugin issues and resolution steps
- CI-specific troubleshooting scenarios and environment problems
- Build and test system configuration issues
- Local development environment problems and prevention strategies

## Site Organization Patterns

### Clean Sitemap Structure (Proven Pattern)
```swift
// Use let variables instead of wrapper structs for simple pages
let homepage = BasePage(title: "Site Title") {
    PlaceholderView(text: "Welcome")
}

let sitemap: Sitemap = [
    "index.html": homepage
]
```

### Multi-Page Sites
```swift
let homepage = BasePage(title: "Home") { HomePage() }
let aboutPage = BasePage(title: "About") { AboutPage() }

let sitemap: Sitemap = [
    "index.html": homepage,
    "about.html": aboutPage
]
```

## Multi-Site Setup
**TO ADD** new sites:
1. **CREATE** `Sources/<NewSite>/` (executable target)
2. **CREATE** `Resources/<NewSite>/` (config and assets)  
3. **OUTPUT** generated to `Websites/<NewSite>/` (auto-ignored)
4. **NAME** sites to reflect production domain (e.g., `my-site` → `https://my.site/`)

## Version Control & Deployment
- **Websites/** folder is git-ignored
- **USE** GitHub Actions with macOS-15 runners + Swift 6.1 toolchain (requires DEVELOPER_DIR)
- **DEPLOY** contents of `Websites/<SiteName>/` to GitHub Pages or CloudFlare Pages
