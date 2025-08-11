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

**AVOID: Manual flexbox layouts**
```swift
// ❌ Don't manually create flex layouts
Div {
    Text("Title")
    Text("Subtitle")  
}
.modifier(ClassModifier(add: "flex flex-col items-center space-y-4"))
```

## Typography APIs (Always Use These)

```swift
// Font sizing - Tailwind equivalent in comments
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

## CRITICAL: API Discovery Workflow

### Step-by-Step Process (REQUIRED Before ClassModifier)

**ALWAYS follow this process before using `.modifier(ClassModifier(add: ...))`:**

#### 1. Search Slipstream Source Directories

Search the specific category directories in `.build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/`:

```bash
# Layout & Sizing (most common)
ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/Sizing/
ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/Layout/

# Flexbox & Grid (very common)  
ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/FlexboxAndGrid/

# Typography (common)
ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/Typography/

# Colors & Effects (common)
ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/Backgrounds/
ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/Borders/

# Interactive States (often missing)
ls .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/TransitionsAndAnimations/
```

#### 2. Examine Key API Files

Look inside relevant files for the API you need:
```bash
# For sizing needs
cat .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/Sizing/View+frame.swift

# For flexbox needs  
cat .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/FlexboxAndGrid/View+justifyContent.swift

# For interactive states
cat .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/State.swift
```

#### 3. Search for Specific Functionality

Use grep to find related APIs:
```bash
# Find hover/interactive APIs
grep -r "hover\|State\|Condition" .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/

# Find responsive APIs
grep -r "Condition\|startingAt" .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/

# Find positioning APIs
grep -r "position\|sticky" .build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/
```

#### 4. Test Official API First

Always test the official API before falling back to ClassModifier:
```swift
// ✅ PREFERRED - Official API discovered through search
.frame(width: .full)           // instead of ClassModifier(add: "w-full")
.justifyContent(.between)      // instead of ClassModifier(add: "justify-between")
.transition(.colors)           // instead of ClassModifier(add: "transition-colors")
```

## Common Patterns Reference

Based on real refactoring experience, these are the most frequently encountered patterns:

### Layout & Sizing (High Priority - Almost Always Available)

| Tailwind Class | Slipstream API | Notes |
|----------------|----------------|--------|
| `w-full` | `.frame(width: .full)` | ✅ Available |
| `h-screen` | `.frame(height: .screen)` | ✅ Available |  
| `min-h-screen` | `.frame(minHeight: .screen)` | ✅ Available |
| `w-52 h-12` | `.frame(width: 208, height: 48)` | ✅ Available |

### Flexbox Layout (High Priority - Usually Available)

| Tailwind Class | Slipstream API | Notes |
|----------------|----------------|--------|
| `justify-between` | `.justifyContent(.between)` | ✅ Available |
| `justify-center` | `.justifyContent(.center)` | ✅ Available |
| `items-center` | `.alignItems(.center)` | ✅ Available |
| `flex-col` | `.flexDirection(.y)` | ✅ Available |
| `flex-row` | `.flexDirection(.x)` | ✅ Available |

### Interactive States (Medium Priority - Often Available)

| Tailwind Class | Slipstream API | Notes |
|----------------|----------------|--------|
| `hover:opacity-80` | `.opacity(0.8, condition: .hover)` | ✅ Available via State |
| `transition-colors` | `.transition(.colors)` | ✅ Available |
| `transition-opacity` | `.transition(.opacity)` | ✅ Available |

### Typography (Medium Priority - Mixed Availability)

| Tailwind Class | Slipstream API | Notes |
|----------------|----------------|--------|
| `text-center` | `.textAlignment(.center)` | ✅ Available |
| `font-bold` | `.fontWeight(.bold)` | ✅ Available |
| `text-3xl` | `.modifier(ClassModifier(add: "text-3xl"))` | ❌ Missing - Use TODO |

### Positioning (Low Priority - Often Missing)

| Tailwind Class | Slipstream API | Notes |
|----------------|----------------|--------|
| `sticky top-0` | `.position(.sticky)` + TODO | ⚠️ Partial - position available, offset missing |
| `z-50` | `.modifier(ClassModifier(add: "z-50"))` | ❌ Missing - Use TODO |

## ClassModifier Usage Rules

### Required Documentation Pattern

When you must use `.modifier(ClassModifier(add: ...))`, document it this way:

```swift
// TODO: Missing Slipstream API for [specific functionality]
// MISSING APIs: [list the ideal API calls that should exist]
// ClassModifier used for: [exact CSS classes used]
.modifier(ClassModifier(add: "text-3xl cursor-pointer"))
```

**Example from real code:**
```swift
Text("☰")
    // TODO: Missing Slipstream API for text-3xl and cursor styles  
    // MISSING APIs: .fontSize(.threeXLarge), .cursor(.pointer)
    // ClassModifier used for: text-3xl cursor-pointer
    .modifier(ClassModifier(add: "text-3xl cursor-pointer"))
```

### ClassModifier Categories to Track

**HIGH PRIORITY for Slipstream contribution:**
- Cursor styles: `cursor-pointer`, `cursor-not-allowed`
- Large typography: `text-3xl`, `text-4xl`, `text-5xl`
- Z-index: `z-10`, `z-50`, `z-auto`

**MEDIUM PRIORITY for Slipstream contribution:**
- Focus rings: `focus:ring-2`, `focus:ring-offset-2`
- Advanced positioning: `inset-0`, `top-4`, `left-8`
- Backdrop effects: `backdrop-blur-sm`, `bg-opacity-90`

## Performance and Build Considerations

### TailwindCSS Configuration

Ensure your `tailwind.config.cjs` includes only generated HTML:
```javascript
// ✅ CORRECT - Only include generated HTML output
content: ["./Websites/<SiteName>/**/*.html"]

// ❌ WRONG - Don't include Swift source files
content: ["./Sources/**/*.swift", "./Websites/<SiteName>/**/*.html"]
```

### Build Command Consistency

Use identical Tailwind commands locally and in CI:
```bash
# ✅ CORRECT - Include --config flag
swift package --disable-sandbox tailwindcss \
  --input Resources/<SiteName>/static/style.css \
  --output Websites/<SiteName>/static/style.output.css \
  --config Resources/<SiteName>/tailwind.config.cjs

# ❌ WRONG - Missing --config causes style failures
swift package --disable-sandbox tailwindcss build \
  -i Resources/<SiteName>/static/style.css \
  -o Websites/<SiteName>/static/style.output.css
```

## Troubleshooting

### Component Rendering Failures

When components fail silently:
1. **Test with inline HTML** first to verify basic rendering
2. **Add components incrementally** to isolate the problem  
3. **Check generic constraints** - avoid complex generics
4. **Verify proper `any View` usage** with `AnyView` wrapper

### Missing API Debugging

When you suspect an API exists but can't find it:
1. **Search broader directory patterns**: `find .build/checkouts/slipstream -name "*.swift" | xargs grep -l "keyword"`
2. **Check enum definitions**: Look for enum cases that match your need
3. **Examine View+extensions**: Most APIs are in `View+<functionality>.swift` files
4. **Test similar APIs**: If `.frame(width:)` exists, try `.frame(height:)`