---
description: Best practices for Slipstream development with SwiftUI-like components and API-first approach
---

# Slipstream Best Practices

This workflow provides comprehensive guidance for developing with Slipstream v2.0, emphasizing SwiftUI-like components and API-first development patterns.

## Core Principles

- **ALWAYS use** SwiftUI-like stack components (VStack, HStack, Container) over manual flex layouts
- **NEVER manually write** CSS class names - always use Slipstream APIs
- **SEARCH the codebase** `.build/checkouts/slipstream/Sources/Slipstream` when unsure about APIs
- **PREFER** structured APIs over raw Tailwind classes

## Component Development

### 1. Choose the Right Layout Component

Use this decision tree to select the appropriate Slipstream layout approach:

```
Need to layout multiple views?
├─ YES: Vertically stacked?
│  ├─ YES: Use VStack(alignment: .center/.leading/.trailing)
│  └─ NO: Use HStack(alignment: .top/.bottom)
├─ NO: Single view with container constraints?
│  ├─ YES: Use Container { ... }
│  └─ NO: Use Div { ... } with styling modifiers
└─ Need responsive/breakpoint behavior?
   └─ YES: Use Container + VStack/HStack combination
```

### 2. SwiftUI-like Component Patterns

**PREFERRED: Stack-based layouts**
```swift
// ✅ Use VStack for vertical arrangements
VStack(alignment: .center, spacing: 16) {
    Text("Title")
        .fontSize(.fourXLarge)
        .fontWeight(.bold)
    
    Text("Subtitle")
        .fontSize(.large)
        .textColor(.palette(.gray, darkness: 600))
}
.frame(height: .screen)
.justifyContent(.center)
```

**AVOID: Manual flex styling**
```swift
// ❌ Don't manually configure flex properties
Div {
    Text("Content")
}
.display(.flex)
.alignItems(.center)
.justifyContent(.center)
```

### 3. Component Architecture Checklist

Before creating a new component, verify:

- [ ] **Simple API**: Component accepts minimal, focused parameters
- [ ] **Stack-based**: Uses VStack/HStack/Container for layout
- [ ] **API styling**: All styling uses Slipstream modifiers, no raw CSS classes
- [ ] **Composable**: Works well with other Slipstream components
- [ ] **Testable**: Renders properly with TestUtils.renderHTML()

## Styling & Layout

### Typography APIs (Always Use These)

```swift
// Font sizing
.fontSize(.extraSmall)     // xs
.fontSize(.small)          // sm  
.fontSize(.base)           // base (default)
.fontSize(.large)          // lg
.fontSize(.extraLarge)     // xl
.fontSize(.extraExtraLarge) // 2xl
.fontSize(.fourXLarge)     // 4xl
.fontSize(.sevenXLarge)    // 7xl
.fontSize(.nineXLarge)     // 9xl

// Point-based sizing for precision
.fontSize(72)              // Maps to closest Tailwind size

// Text styling
.textAlignment(.center/.left/.right)
.fontDesign(.sans/.serif/.monospace)
.fontWeight(.bold/.light/.medium)
.fontStyle(.italic)
.textColor(.palette(.zinc, darkness: 800))
```

### Layout APIs (Always Use These)

```swift
// Sizing
.frame(height: .screen)    // Full viewport height
.frame(width: .full)       // Full width

// Flexbox (when needed with stacks)
.justifyContent(.center/.start/.end/.between)
.alignItems(.center/.start/.end)

// Spacing (built into stacks)
VStack(spacing: 16) { ... }  // Automatic spacing
HStack(spacing: 8) { ... }   // Automatic spacing
```

### CSS Integration

**ALWAYS link stylesheets using relative paths**:
```swift
// ✅ CORRECT - Relative path for local file URLs
Stylesheet(URL(string: "static/style.output.css"))

// ❌ WRONG - Absolute path breaks local development
Stylesheet(URL(string: "/static/style.output.css"))
```

## API Discovery

### 1. When You Don't Know the Right API

Follow this systematic search process:

1. **Search by category** in `.build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/`:
   ```bash
   # Typography APIs
   ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/Typography/
   
   # Layout APIs  
   ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/Layout/
   
   # Flexbox/Grid APIs
   ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/FlexboxAndGrid/
   
   # Sizing APIs
   ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/Sizing/
   ```

2. **Examine key API files**:
   - `View+fontSize.swift` - Font sizing options
   - `View+textAlignment.swift` - Text alignment
   - `View+background.swift` - Background colors and effects
   - `View+border.swift` - Border styling
   - `View+padding.swift` - Spacing and padding

3. **Search for specific functionality**:
   ```bash
   # Find hover-related APIs
   grep -r "hover" .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/
   
   # Find responsive APIs
   grep -r "Condition\|Breakpoint" .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/
   
   # Find positioning APIs
   grep -r "position\|sticky" .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/
   ```

## CRITICAL: ClassModifier Usage Rules

### Before Using ClassModifier - Required Steps

1. **ALWAYS search** for existing Slipstream APIs first
2. **DOCUMENT** why ClassModifier is necessary  
3. **LIST** specific missing APIs that should be added to Slipstream
4. **TRACK** usage for future contributions

### Proper ClassModifier Documentation Pattern

When you must use `.modifier(ClassModifier(add: ...))`, document it properly:

```swift
public var body: some View {
    Link(URL(string: href)) {
        Text(title)
            .fontSize(.extraExtraLarge)
            .fontWeight(.bold)
            .textColor(.palette(.gray, darkness: 900))
            
            // TODO: Need Slipstream API for interactive hover states
            // MISSING APIs: 
            // - .hover(.opacity(0.8))
            // - .transition(.opacity, duration: .short)
            // Issue: Slipstream v2.0 lacks pseudo-state modifier support
            // ClassModifier used for: hover:opacity-80 transition-opacity
            .modifier(ClassModifier(add: "hover:opacity-80 transition-opacity"))
    }
}
```

### Common Missing APIs to Document

Track these commonly missing Slipstream APIs:

```swift
// Interactive States (most commonly missing)
// TODO: Need Slipstream hover/focus/active state APIs
.modifier(ClassModifier(add: "hover:opacity-80"))        // .hover(.opacity(0.8))
.modifier(ClassModifier(add: "focus:ring-2"))            // .focus(.ring(width: 2))
.modifier(ClassModifier(add: "active:transform"))        // .active(.scale(0.95))

// Responsive Visibility (commonly missing)  
// TODO: Need Slipstream responsive display APIs
.modifier(ClassModifier(add: "hidden md:flex"))          // .display(.hidden, condition: .belowMedium)
.modifier(ClassModifier(add: "block lg:hidden"))         // .display(.block, condition: .belowLarge)

// Positioning and Z-Index (commonly missing)
// TODO: Need Slipstream positioning APIs
.modifier(ClassModifier(add: "sticky top-0 z-50"))       // .position(.sticky, top: 0).zIndex(50)
.modifier(ClassModifier(add: "absolute inset-0"))        // .position(.absolute, inset: 0)

// Transitions and Animations (commonly missing)
// TODO: Need Slipstream transition APIs
.modifier(ClassModifier(add: "transition-all"))          // .transition(.all)
.modifier(ClassModifier(add: "duration-300"))            // .duration(.milliseconds(300))
.modifier(ClassModifier(add: "ease-in-out"))             // .timingFunction(.easeInOut)
```

### Creating API Gap Issues

For each missing API, create structured documentation:

```swift
// TODO: SLIPSTREAM API GAP - Hover States
// Current: .modifier(ClassModifier(add: "hover:opacity-80"))
// Needed: .hover(.opacity(0.8))
// Priority: HIGH - Interactive components are essential
// Tailwind classes: hover:opacity-{value}, hover:bg-{color}, hover:text-{color}
// Suggested API pattern:
//   extension View {
//     func hover<T>(_ modifier: (Self) -> T) -> some View where T: View
//   }
```

## Performance and Build Troubleshooting

### Component Rendering Issues

**Problem**: Component compiles but renders unexpectedly
**Solution**: Use TestUtils to validate HTML output

```swift
// Validate component HTML output
let html = TestUtils.renderHTML(component)
TestUtils.assertValidHTMLDocument(html)
TestUtils.assertContainsTailwindClasses(html, expectedClasses)

// Check for missing or incorrect CSS classes  
print("Generated HTML: \(html)")
```

### Build Performance

```bash
# Build only specific targets during development
nocorrect swift build --target 21-dev
nocorrect swift build --target DesignSystem

# Parallel testing for faster feedback
nocorrect swift test --parallel
```

### Common API Discovery Mistakes

```swift
// ❌ WRONG - Using ClassModifier without searching
.modifier(ClassModifier(add: "text-2xl"))

// ✅ CORRECT - Use discovered Slipstream API
.fontSize(.extraExtraLarge)

// ❌ WRONG - Combining manual CSS with Slipstream
.fontSize(.large)
.modifier(ClassModifier(add: "font-bold"))

// ✅ CORRECT - Use proper Slipstream APIs
.fontSize(.large)
.fontWeight(.bold)
```

## Local Development Patterns

### API Exploration Commands

```bash
# Explore available Slipstream APIs by category
find .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/ -name "*.swift" -exec basename {} \; | sort

# Search for specific API patterns
grep -r "func.*Color" .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/
grep -r "extension View" .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/

# Find examples of API usage in Slipstream tests
find .build/checkouts/slipstream/Tests/ -name "*.swift" -exec grep -l "fontSize\|textColor" {} \;
```

### Integration Testing

```swift
// Test components with realistic site integration
let testPage = BasePage(title: "Component Test") {
    VStack(spacing: 32) {
        Header(logoText: "Test Site", navigationLinks: testLinks)
        Section {
            PlaceholderView(text: "Testing Integration")
        }
    }
}

let html = TestUtils.renderHTML(testPage)
TestUtils.assertValidHTMLDocument(html)
```

## Summary: API-First Development Workflow

1. **Design component** using SwiftUI-like patterns (VStack/HStack/Container)
2. **Search for APIs** in `.build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/`
3. **Use Slipstream APIs** for all styling (colors, typography, spacing, layout)
4. **Document missing APIs** when ClassModifier is required
5. **Test with TestUtils** to validate HTML output
6. **Integrate gradually** with existing site structure
7. **Track API gaps** for future Slipstream contributions
