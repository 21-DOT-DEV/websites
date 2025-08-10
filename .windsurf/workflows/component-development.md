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
}
```

### Step 4: Test Component in Isolation
```bash
# Run component-specific tests
nocorrect swift test --filter PlaceholderViewTests

# Verify TestUtils integration
nocorrect swift test --filter DesignSystemTests
```

### Step 5: Integrate with Site

#### Add to Site Temporarily for Visual Testing
```swift
// In Sources/21-dev/main.swift
let homepage = BasePage(title: "Testing Component") {
    VStack {
        PlaceholderView(text: "Testing New Component")
        // Add existing content below...
    }
}
```

#### Generate and Test Site
```bash
# Generate site with new component
nocorrect swift run 21-dev && \
swift package --disable-sandbox tailwindcss \
  --input Resources/21-dev/static/style.css \
  --output Websites/21-dev/static/style.output.css \
  --config Resources/21-dev/tailwind.config.cjs

# Open in browser to verify visual appearance
```

### Step 6: Component Documentation

#### Document Missing Slipstream APIs
When you must use `.modifier(ClassModifier(add: ...))`, document it:

```swift
public var body: some View {
    Div {
        Text(title)
            .fontSize(.extraExtraLarge)
            .fontWeight(.bold)
            .textColor(.palette(.gray, darkness: 900))
            
            // TODO: Need Slipstream API for hover states and transitions
            // MISSING APIs: .hover(.opacity(0.8)), .transition(.opacity)
            // Issue: Slipstream lacks pseudo-state modifiers for interactive elements
            // ClassModifier used for: hover:opacity-80 transition-opacity
            .modifier(ClassModifier(add: "hover:opacity-80 transition-opacity"))
    }
}
```

#### Update Component Documentation
```swift
/// A generic navigation header component with configurable branding and links.
/// Provides responsive design with proper spacing and accessibility.
/// 
/// Example usage:
/// ```swift
/// Header(
///     logoText: "My Site", 
///     navigationLinks: [
///         .init(title: "Home", href: "/"),
///         .init(title: "About", href: "/about")
///     ]
/// )
/// ```
///
/// ## Missing Slipstream APIs Used
/// - `hover:opacity-80 transition-opacity` - Interactive hover states
/// - `hidden md:flex` - Responsive visibility controls
/// - `sticky top-0 z-50` - Fixed positioning with z-index
public struct Header: View {
    // Component implementation...
}
```

### Step 7: Follow Referenced Workflows

#### Always Reference Related Workflows
Before component development:
1. **See /slipstream-best-practices workflow** for API usage patterns
2. **See /build-and-test workflow** for proper command usage
3. **See /troubleshooting-common-issues workflow** for debugging strategies

#### Critical API Usage Rules from /slipstream-best-practices
1. **SEARCH** `.build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/` for existing APIs
2. **ONLY USE** `.modifier(ClassModifier(add: ...))` after confirming no Slipstream API exists
3. **DOCUMENT** all missing APIs with TODO comments and specific API suggestions
4. **TRACK** ClassModifier usage for future Slipstream contributions

## Generic Component Design Patterns

### Make Components Site-Agnostic
```swift
// ✅ GOOD - Generic, reusable across sites
public struct Header: View {
    let logoText: String
    let navigationLinks: [NavigationLink]
    
    public init(logoText: String, navigationLinks: [NavigationLink]) {
        self.logoText = logoText
        self.navigationLinks = navigationLinks
    }
}

// ❌ AVOID - Site-specific, not reusable
public struct TwentyOneDevHeader: View {
    // Hardcoded 21.dev specific content...
}
```

### Configurable Navigation Pattern
```swift
public struct NavigationLink {
    public let title: String
    public let href: String
    public let isExternal: Bool
    
    public init(title: String, href: String, isExternal: Bool = false) {
        self.title = title
        self.href = href
        self.isExternal = isExternal
    }
}
```

## Advanced Component Patterns

### Flexible Content with ViewBuilder
```swift
public struct Card<Content: View>: View {
    let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        Div {
            content
        }
        .backgroundColor(.white)
        .padding(.all, 16)
        .border(.palette(.gray, darkness: 200), width: 1)
    }
}
```

### Layout Components
```swift
public struct Section<Content: View>: View {
    let content: Content
    let backgroundColor: Color?
    
    public init(backgroundColor: Color? = nil, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.backgroundColor = backgroundColor
    }
    
    public var body: some View {
        Div {
            Container {
                content
            }
            .padding(.vertical, 64)
            .padding(.horizontal, 16)
        }
        .background(backgroundColor ?? .transparent)
    }
}
```

## Common Issues and Solutions

### Issue: Component Doesn't Fill Width
**Problem**: Component appears narrow or doesn't span full container width.
**Solution**: Ensure proper Container usage and check for missing width constraints.

```swift
// ✅ CORRECT - Full width header
Div {
    Container {
        HStack { /* navigation content */ }
    }
}

// ❌ WRONG - May not fill width properly  
HStack { /* navigation content directly */ }
```

### Issue: Responsive Design Not Working
**Problem**: Components don't adapt properly on different screen sizes.
**Solution**: Use proper breakpoint conditions and responsive utilities.

```swift
// ✅ CORRECT - Responsive padding
.padding(.horizontal, 16)
.padding(.horizontal, 24, condition: Condition(startingAt: .medium))
.padding(.horizontal, 32, condition: Condition(startingAt: .large))
```

### Issue: Silent Component Failures
**Problem**: Component compiles but doesn't render as expected.
**Solution**: Use TestUtils to validate HTML output and check for missing APIs.

```swift
// Add comprehensive tests with TestUtils
let html = TestUtils.renderHTML(component)
TestUtils.assertValidHTMLDocument(html)
TestUtils.assertContainsTailwindClasses(html, expectedClasses)
```
