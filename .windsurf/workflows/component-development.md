---
description: Best practices for creating, testing, and integrating DesignSystem components with TestUtils validation and site structure integration
---

# Component Development Workflow

## Overview
Comprehensive guide for developing reusable DesignSystem components using proven patterns from PlaceholderView success, including TestUtils integration, systematic testing, and site integration strategies.

## Development Philosophy

### Core Principles
1. **Simple APIs First** - Prefer straightforward initialization over complex generics
2. **Test-Driven Development** - Write TestUtils tests before site integration
3. **Incremental Integration** - Add components gradually to isolate issues
4. **Type Safety with Flexibility** - Use `any View` patterns for complex content

## Step-by-Step Component Development

### Step 1: Component Design and Architecture

#### Choose the Right Pattern
```swift
// ✅ PREFERRED - Simple, testable component
struct PlaceholderView: View {
    let text: String
    
    var body: some View {
        Div {
            Text(text)
        }
        .frame(height: .screen)
        .display(.flex)
        .alignItems(.center)
        .justifyContent(.center)
        .fontSize(.sevenXLarge)
        .textAlignment(.center)
        .fontDesign(.sans)
    }
}

// ❌ AVOID - Complex generics can cause silent failures
struct ComplexComponent<Content: View>: View {
    @ViewBuilder var content: () -> Content
    // Complex generic logic...
}
```

#### API Design Guidelines
- **Keep initializers simple** - Prefer direct parameters over closures when possible
- **Use meaningful parameter names** - `text: String` instead of `content: String`
- **Provide sensible defaults** - Optional parameters with common defaults
- **Document component purpose** - Clear docstring explaining usage

### Step 2: Create Component Structure

#### File Organization
```bash
# Create component in appropriate DesignSystem subfolder
Sources/DesignSystem/Components/PlaceholderView.swift  # UI components
Sources/DesignSystem/Layouts/BasePage.swift            # Layout components
Sources/DesignSystem/Tags/CustomTag.swift              # Custom HTML tags
Sources/DesignSystem/Utilities/StyleHelpers.swift     # Utility functions
```

#### Component Template
```swift
import Foundation
import Slipstream

/// A reusable placeholder component for development and testing.
/// Displays centered text with consistent styling across sites.
public struct PlaceholderView: View {
    public let text: String
    
    public init(text: String) {
        self.text = text
    }
    
    public var body: some View {
        Div {
            Text(text)
        }
        // Add Tailwind styling using Slipstream APIs
        .frame(height: .screen)
        .display(.flex)
        .alignItems(.center)
        .justifyContent(.center)
        .fontSize(.sevenXLarge)
        .textAlignment(.center)
        .fontDesign(.sans)
    }
}
```

### Step 3: Write TestUtils-Based Tests

#### Create Component Test File
```bash
# Add test file in DesignSystemTests
Tests/DesignSystemTests/Components/PlaceholderViewTests.swift
```

#### Test Structure Template
```swift
import Foundation
import Testing
import Slipstream
import DesignSystem
import TestUtils

@Suite("PlaceholderView Tests")
struct PlaceholderViewTests {
    
    @Test("renders basic placeholder with text")
    func testBasicPlaceholder() throws {
        let placeholder = PlaceholderView(text: "Test Content")
        let html = TestUtils.renderHTML(placeholder)
        
        // Use TestUtils for consistent validation
        TestUtils.assertValidHTMLDocument(html)
        TestUtils.assertContainsText(html, texts: ["Test Content"])
        
        // Validate expected Tailwind classes
        TestUtils.assertContainsTailwindClasses(html, classes: [
            "h-screen",
            "flex", 
            "items-center",
            "justify-center",
            "text-7xl",
            "text-center",
            "font-sans"
        ])
    }
    
    @Test("handles various text content")
    func testVariousTextContent() throws {
        let testCases = [
            "Simple text",
            "Text with 123 numbers",
            "Text with special chars: @#$%",
            "Multi-word test content"
        ]
        
        for testText in testCases {
            let placeholder = PlaceholderView(text: testText)
            let html = TestUtils.renderHTML(placeholder)
            
            TestUtils.assertContainsText(html, texts: [testText])
        }
    }
    
    @Test("generates expected HTML structure")
    func testHTMLStructure() throws {
        let placeholder = PlaceholderView(text: "Structure Test")
        let html = TestUtils.renderHTML(placeholder)
        
        // Verify div > p structure
        #expect(html.contains("<div"))
        #expect(html.contains("<p>Structure Test</p>"))
        #expect(html.contains("</div>"))
        
        // Ensure proper nesting
        let divIndex = html.firstIndex(of: "<")
        let pIndex = html.range(of: "<p>")?.lowerBound
        #expect(divIndex != nil && pIndex != nil)
        #expect(divIndex! < pIndex!)
    }
}
```

### Step 4: Run Component Tests

```bash
# Test specific component
swift test --filter PlaceholderViewTests

# Test all DesignSystem components
swift test --filter DesignSystemTests

# Verify no TestUtils import issues
swift test
```

### Step 5: Integration with Site Structure

#### Update Site Main.swift
```swift
import Foundation
import Slipstream
import DesignSystem

// Create page using new component
let homepage = BasePage(title: "21.dev - Bitcoin Development Tools") {
    PlaceholderView(text: "Equipping developers with the tools they need today to build the Bitcoin apps of tomorrow. 📱")
}

let sitemap: Sitemap = [
    "index.html": homepage
]
```

#### Test Site Generation
```bash
# Generate site with new component
swift run 21-dev

# Verify output includes component
cat Websites/21-dev/index.html | grep "Bitcoin apps"
```

### Step 6: Styling Integration

#### Verify Tailwind Classes in Output
```bash
# Check that component classes appear in generated HTML
grep -o 'class="[^"]*"' Websites/21-DEV/index.html

# Compile CSS to ensure classes are processed
swift package --disable-sandbox tailwindcss \
  --input Resources/21-dev/static/style.css \
  --output Websites/21-dev/static/style.output.css \
  --config Resources/21-dev/tailwind.config.cjs
```

#### Visual Verification
```bash
# Open in browser for visual confirmation
open Websites/21-dev/index.html
```

## Advanced Component Patterns

### Complex Content Components
```swift
// For components that need flexible content
public struct FlexibleComponent: View {
    private let content: any View
    
    public init(@ViewBuilder content: () -> any View) {
        self.content = AnyView(content())
    }
    
    public var body: some View {
        Div {
            content
        }
        .padding(.medium)
    }
}
```

### Layout Components
```swift
// Base page layout with consistent structure
public struct BasePage: View {
    public let title: String
    private let content: any View
    
    public init(title: String, @ViewBuilder content: () -> any View) {
        self.title = title
        self.content = AnyView(content())
    }
    
    public var body: some View {
        HTML {
            Head {
                Title(title)
                Stylesheet(URL(string: "static/style.output.css"))
            }
            Body {
                content
            }
        }
    }
}
```

### Utility Components
```swift
// Helper components for common patterns
public struct CenteredContent: View {
    private let content: any View
    
    public init(@ViewBuilder content: () -> any View) {
        self.content = AnyView(content())
    }
    
    public var body: some View {
        Div {
            content
        }
        .frame(height: .screen)
        .display(.flex)
        .alignItems(.center)
        .justifyContent(.center)
    }
}
```

## Testing Strategies

### TestUtils Best Practices
```swift
// Create reusable test utilities for common patterns
extension TestUtils {
    static let centeredContentClasses = [
        "h-screen", "flex", "items-center", "justify-center"
    ]
    
    static func assertCenteredContent(_ html: String) {
        assertContainsTailwindClasses(html, classes: centeredContentClasses)
    }
}
```

### Integration Testing
```swift
// Test components within site context
@Test("component renders in site context")
func testSiteIntegration() throws {
    let page = BasePage(title: "Test") {
        PlaceholderView(text: "Integration test")
    }
    
    let html = TestUtils.renderHTML(page)
    
    TestUtils.assertValidHTMLDocument(html)
    TestUtils.assertValidTitle(html, expectedTitle: "Test")
    TestUtils.assertContainsStylesheet(html)
    TestUtils.assertContainsText(html, texts: ["Integration test"])
}
```

## Common Issues and Solutions

### Silent Component Failures
**Symptoms**: Component doesn't appear in generated HTML
**Debug Process**:
1. Test component in isolation with TestUtils
2. Check for complex generic patterns
3. Verify all imports are present
4. Add incrementally to site structure

### Styling Not Applied
**Symptoms**: Component renders but lacks visual styling
**Solutions**:
1. Verify Tailwind classes using TestUtils validation
2. Ensure CSS compilation includes component classes
3. Check content glob in `tailwind.config.cjs`
4. Use browser developer tools to inspect applied styles

### TestUtils Import Errors
**Symptoms**: Test compilation fails with module errors
**Solution**: Ensure proper imports in test files:
```swift
import Foundation
import Testing
import Slipstream
import DesignSystem
import TestUtils
```

### Type Complexity Errors
**Symptoms**: Complex ViewBuilder expressions cause compilation errors
**Solution**: Use `any View` with `AnyView` wrapper:
```swift
// Instead of complex generics
private let content: any View = AnyView(content())
```

## Component Checklist

### Before Creating Component
- [ ] Design simple, focused API
- [ ] Choose appropriate DesignSystem subfolder
- [ ] Plan TestUtils validation strategy

### During Development
- [ ] Write TestUtils-based tests first
- [ ] Use Slipstream APIs for styling
- [ ] Validate HTML structure and classes
- [ ] Test various input scenarios

### Integration Phase
- [ ] Add to site structure incrementally
- [ ] Generate site and verify output
- [ ] Compile CSS and check styling
- [ ] Perform visual verification

### Maintenance
- [ ] Update tests when component changes
- [ ] Maintain TestUtils consistency
- [ ] Document breaking changes
- [ ] Review for optimization opportunities

## Integration with Existing Workflows

### Before Site Generation
- Run component tests: `@build-and-test` workflow
- Ensure TestUtils validation passes

### After Component Updates
- Follow `@site-generation` workflow for output verification
- Use `@troubleshooting-common-issues` for debugging

This workflow ensures reliable, testable, and maintainable component development within the Slipstream ecosystem.