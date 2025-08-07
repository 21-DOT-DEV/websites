---
trigger: glob
description: > 
  Swift architecture guidelines for multi-site static generation with Slipstream.
  Emphasizes reusable DesignSystem components, clean module boundaries, iterative development,
  and comprehensive TestUtils architecture for maintainable testing infrastructure.
globs: **/*.swift"
---

# Swift Architecture & Organization

## DesignSystem Target Philosophy

### Purpose & Scope
- **BUILD** foundational, reusable components that multiple sites can leverage
- **START** with essential pieces like placeholder components for new sites
- **GROW** iteratively - add components as patterns emerge across sites
- **AVOID** over-engineering - build what you need, when you need it

### Component API Design
- **DEFAULT**: Simple, focused APIs with sensible defaults
- **ENHANCE**: Use Slipstream modifier composition for customization
- **EXAMPLE**: `PlaceholderView(text: String).fontSize(.custom).backgroundColor(.blue)`

## Directory Structure

### DesignSystem Organization
**START** with familiar structure, **EXPAND** as the design system matures:

```
Sources/DesignSystem/
├── Components/        # Reusable UI components
├── Layouts/          # Page-level layout containers  
├── Services/         # Shared business logic
├── Tags/             # HTML/Tailwind helpers
├── Utilities/        # Cross-cutting utilities
├── Foundation/       # Design tokens, base styles (add when needed)
├── Primitives/       # Building block components (add when needed)
└── Patterns/         # Common layout patterns (add when needed)
```

### Site Target Organization
Each site target mirrors the structure but focuses on site-specific implementations:

```
Sources/<SiteName>/
├── Components/       # Site-specific components
├── Layouts/         # Site-specific layouts
├── Services/        # Site-specific business logic
├── Tags/            # Site-specific HTML helpers
├── Utilities/       # Site-specific utilities
└── main.swift       # Sitemap and entry point
```

### Test Architecture Organization
**IMPLEMENT** comprehensive test structure with shared utilities:

```
Tests/
├── TestUtils/                    # Shared test utilities (regular target)
│   └── TestUtils.swift          # Central test helper APIs
├── DesignSystemTests/           # Unit tests for DesignSystem components
│   ├── Components/
│   └── Layouts/
└── IntegrationTests/            # End-to-end site generation tests
    └── Site21DEVTests.swift
```

## Package.swift Target Architecture

### Target Configuration Pattern
```swift
.target(
    name: "TestUtils",
    dependencies: [.product(name: "Slipstream", package: "slipstream"), "DesignSystem"],
    path: "Tests/TestUtils"
),
.testTarget(
    name: "DesignSystemTests",
    dependencies: ["DesignSystem", "TestUtils"]
)
```

**KEY RULE**: Use regular `.target()` not `.testTarget()` for TestUtils to avoid SwiftPM module complications.

## Naming Conventions

| Folder | Type Suffix | Example | Purpose |
|--------|-------------|---------|----------|
| Components | `View` | `HeroView.swift` | Visual pieces that render HTML |
| Layouts | `Layout` | `ArticleLayout.swift` | Page-level layout containers |
| Services | `Service` | `ImageCacheService.swift` | Business/infrastructure helpers |
| Tags | `Tag` (optional) | `LinkTag.swift` | HTML/Tailwind string helpers |
| Utilities | (no suffix) | `DateFormatterUtil.swift` | Cross-cutting utilities |
| Tests | `Tests` | `PlaceholderViewTests.swift` | Test files for components/services |

## Module Dependencies & Boundaries

### Import Rules
1. **DesignSystem** → May be imported by any site target
2. **Site targets** → Must NOT import each other (e.g., `21-dev` cannot import `bitcoin-how`)
3. **TestUtils** → May be imported by all test targets (DesignSystemTests, IntegrationTests)
4. **Test targets** → Must NOT import each other; share code via TestUtils
5. **Utilities/** → Leaf-only - may import Foundation but not other project modules

### Dependency Management
- **PREFER** strategic external dependencies in DesignSystem that benefit multiple sites
- **USE** protocol-based abstraction when sites need different implementations
- **KEEP** DesignSystem lightweight but powerful for common needs
- **CENTRALIZE** test utilities in TestUtils to eliminate duplication across test targets

## Quality Standards

### File & Type Organization
- **ONE** public type per file
- **MAX** 300 lines per file
- **VIEWS**: Keep body under 250 lines; extract sub-views as needed

### Composition Guidelines
- **FAVOR** small, composable Views over monoliths
- **EXTRACT** repeated HTML fragments into DesignSystem Components/
- **SEPARATE** business logic from Views; place in Services/

### Generic Complexity Management (CRITICAL)
**❌ AVOID**: Complex generic constraints that can cause silent rendering failures
**✅ PREFER**: Simple types with `any View` patterns

```swift
// ❌ Complex generics - can fail silently
public struct BasePage<Content: View>: View { ... }

// ✅ Simple with any View - reliable
public struct BasePage: View {
    let bodyContent: any View
    // Use AnyView(bodyContent) in body
}
```

### Testing Requirements
- **CREATE** unit tests for DesignSystem components using TestUtils patterns
- **USE** `TestUtils.renderHTML()` for consistent HTML rendering (wraps official Slipstream API)
- **MAINTAIN** TestUtils module as architectural peer to DesignSystem
- **INCLUDE** integration tests for complete site generation workflows

### TestUtils Consistency Standards
**ALWAYS** use TestUtils utilities instead of manual assertions for:
- **HTML structure**: `TestUtils.assertValidHTMLDocument(html)` 
- **Title validation**: `TestUtils.assertValidTitle(html, expectedTitle: "...")`
- **Stylesheet validation**: `TestUtils.assertContainsStylesheet(html)`
- **Batch operations**: `TestUtils.assertContainsTailwindClasses()`, `TestUtils.assertContainsText()`

**ENFORCE** through systematic code review for `#expect(html.contains(` patterns.

### Documentation Standards
- **DOCUMENT** DesignSystem components with usage examples
- **INCLUDE** parameter descriptions and expected behaviors  
- **SHOW** modifier composition patterns in documentation

## Proven DesignSystem Patterns

### 1. PlaceholderView Component (Components/)
**PURPOSE**: Reusable placeholder for new sites and content areas
```swift
public struct PlaceholderView: View {
    let text: String
    public init(text: String) { self.text = text }
    
    public var body: some View {
        Div { Text(text) }
            .frame(height: .screen).display(.flex)
            .alignItems(.center).justifyContent(.center)
            .fontSize(.sevenXLarge).textAlignment(.center)
    }
}
```

### 2. BasePage Layout (Layouts/)
**PURPOSE**: Complete HTML document wrapper with head/body structure
```swift
public struct BasePage: View {
    let title: String
    let bodyContent: any View  // Note: any View pattern
    
    public var body: some View {
        HTML {
            Head { Title(title); Stylesheet(URL(string: "static/style.output.css")) }
            Body { AnyView(bodyContent) }
        }
    }
}
```

### 3. TestUtils Module (Tests/TestUtils/)
**PURPOSE**: Shared test utilities eliminating duplication across all test targets
```swift
public enum TestUtils {
    public static func renderHTML<T: View>(_ view: T) throws -> String { ... }
    public static func assertValidHTMLDocument(_ html: String) { ... }
    public static func assertContainsTailwindClasses(_ html: String, classes: [String]) { ... }
    public static let placeholderViewClasses = ["h-screen", "flex", "items-center", ...]
}
```

### 4. Clean Sitemap Organization
**PATTERN**: Use `let` variables instead of unnecessary struct wrappers
```swift
let homepage = BasePage(title: "Site Name") {
    PlaceholderView(text: "Coming Soon")
}

let sitemap: Sitemap = ["index.html": homepage]
```

## Development Workflow Integration

### Component Development Cycle
1. **DESIGN** component API in DesignSystem/Components/
2. **IMPLEMENT** using idiomatic Slipstream patterns (see Generic Complexity section)
3. **TEST** using TestUtils patterns for rendering and validation
4. **INTEGRATE** into site target with incremental testing
5. **REFINE** based on usage patterns across multiple sites

### Component Debugging Process
When components fail silently:
1. **TEST** with inline HTML first to verify basic rendering works
2. **ADD** components incrementally to isolate the problem
3. **CHECK** generic constraints (see Generic Complexity Management section)
4. **VERIFY** proper `any View` usage with `AnyView` wrapper

## Scaling Patterns

### Adding New Sites
1. **CREATE** new executable target in Package.swift
2. **REUSE** DesignSystem components with site-specific customization
3. **ADD** site-specific integration tests using TestUtils patterns
4. **LEVERAGE** TestUtils for consistent validation across all sites

### Growing DesignSystem
1. **EXTRACT** common patterns from site-specific code
2. **GENERALIZE** APIs for multi-site usage (avoid complex generics)
3. **TEST** using comprehensive TestUtils patterns
4. **DOCUMENT** with TestUtils-based examples

### Maintaining Test Quality
1. **CENTRALIZE** all shared test logic in TestUtils
2. **SYSTEMATICALLY** review for manual assertion patterns during code review
3. **REFACTOR** repetitive test code into TestUtils methods
4. **ENFORCE** consistency through automated tooling and systematic review
