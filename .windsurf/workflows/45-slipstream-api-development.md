---
description: >
  Develop and contribute Slipstream API enhancements.
  Based on experience with ForEach, SVG, and Layout API implementations.
---

# Slipstream API Development

## Analysis & Planning

1. **Identify API gaps**:
   - Review current ClassModifier workarounds in DesignSystem components
   - Look for repeated raw HTML patterns that could be componentized
   - Check for missing Tailwind CSS API coverage in Slipstream

2. **Prioritize by impact**:
   - High: APIs that eliminate ClassModifier usage
   - Medium: APIs that improve type safety 
   - Low: Convenience APIs for common patterns

## Implementation Process

3. **Fork Slipstream repository**:
   ```bash
   cd /Users/csjones/Developer/
   git clone https://github.com/jverkoey/slipstream.git slipstream-fork
   cd slipstream-fork
   git remote add upstream https://github.com/jverkoey/slipstream.git
   ```

4. **Study existing patterns**:
   - Review `Sources/Slipstream/W3C/Elements/` for component structure
   - Examine `Sources/Slipstream/TailwindCSS/` for modifier patterns
   - Follow `ConditionalView` pattern for new components

## Component Development

5. **Create new component** (e.g., Grid):
   ```swift
   // Sources/Slipstream/W3C/Elements/GroupingContent/Grid.swift
   @available(iOS 17.0, macOS 14.0, *)
   public struct Grid<Content>: W3CElement where Content: View {
       private let content: Content
       private let columns: [GridColumn]
       
       public init(columns: [GridColumn], @ViewBuilder content: () -> Content) {
           self.columns = columns
           self.content = content()
       }
       
       public var body: some View {
           Div {
               content
           }
           .display(.grid)
           .modifier(GridColumnsModifier(columns: columns))
       }
   }
   ```

6. **Add supporting types**:
   ```swift
   // Sources/Slipstream/TailwindCSS/GridColumn.swift
   @available(iOS 17.0, macOS 14.0, *)
   public enum GridColumn {
       case repeat(Int, condition: Condition? = nil)
       case auto(condition: Condition? = nil)
       case minMax(String, condition: Condition? = nil)
   }
   ```

## Testing & Documentation

7. **Add comprehensive tests**:
   ```bash
   touch Tests/SlipstreamTests/W3C/GridTests.swift
   ```

8. **Test implementation**:
   ```swift
   @Test func rendersGridWithColumns() async throws {
       let html = render {
           Grid(columns: [.repeat(3)]) {
               Text("Item 1")
               Text("Item 2") 
               Text("Item 3")
           }
       }
       #expect(html.contains("grid grid-cols-3"))
   }
   ```

9. **Add documentation**:
   - Include usage examples in doc comments
   - Add to appropriate .docc files if needed
   - Reference Tailwind CSS documentation

## Integration & Contribution

10. **Test in websites repository**:
    ```swift
    // Update Package.swift to use local Slipstream fork
    .package(path: "../slipstream-fork")
    ```

11. **Validate with real components**:
    - Replace ClassModifier usage in SiteFooter
    - Test responsive behavior 
    - Verify CSS output correctness

12. **Submit upstream contribution**:
    ```bash
    git checkout -b feature/grid-component
    git add .
    git commit -m "Add Grid component with responsive column support"
    git push origin feature/grid-component
    # Create pull request on GitHub
    ```

## Common API Patterns

### **Component Structure**:
- Follow W3CElement protocol for HTML elements
- Use @ViewBuilder for content closures
- Support Condition parameters for responsive behavior

### **Modifier Structure**:
- Extend View with modifier functions
- Use TailwindClassModifier internally
- Support conditional application

### **Type Safety**:
- Use enums for predefined values
- Provide String escape hatches when needed
- Follow Swift API design guidelines
