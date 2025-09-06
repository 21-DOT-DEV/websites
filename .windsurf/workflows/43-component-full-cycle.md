---
description: >
  Complete component development cycle: scaffold, implement, and verify.
---

# Component Full Cycle

## 1. Scaffold Component

1. **Create component file**:
   ```bash
   # For UI components
   touch Sources/DesignSystem/Components/<ComponentName>.swift
   
   # For models (if needed)
   touch Sources/DesignSystem/Models/<ComponentName>Models.swift
   ```

2. **Basic Slipstream structure**:
   ```swift
   import Foundation
   import Slipstream

   /// Brief description of the component's purpose
   @available(iOS 17.0, macOS 14.0, *)
   public struct ComponentName: View {
       public init() {}
       
       public var body: some View {
           Div {
               // Component implementation
           }
       }
   }
   ```

## 2. Implement Component

3. **Check existing Slipstream APIs first**:
   ```bash
   # Search for existing HTML elements before using RawHTML
   find /path/to/slipstream/Sources/Slipstream/W3C/Elements/ -name "*.swift"
   ```

4. **Add SwiftUI/Slipstream implementation**:
   - Use structured Slipstream APIs (`.display(.flex)`, `.fontSize(.large)`)
   - Apply Tailwind utilities via idiomatic modifiers
   - Follow DesignSystem patterns for consistency
   - Use DesignSystem/Tokens for colors, spacing, typography
   - **Avoid RawHTML** unless no Slipstream API exists

5. **Add public documentation**:
   ```swift
   /// Component description with usage example
   ///
   /// ```swift
   /// ComponentName()
   ///     .modifier(...)
   /// ```
   ```

## 3. Verify Component

6. **Create unit tests**:
   ```bash
   touch Tests/DesignSystemTests/Components/<ComponentName>Tests.swift
   ```

7. **Test structure**:
   ```swift
   import Testing
   import TestUtils
   @testable import DesignSystem

   @Suite struct ComponentNameTests {
       @Test func rendersCorrectHTML() async throws {
           let html = TestUtils.renderHTML {
               ComponentName()
           }
           #expect(html.contains("expected-content"))
       }
   }
   ```

8. **Add integration test**:
   ```bash
   # Add to Tests/IntegrationTests/Site21DevTests.swift
   ```

9. **Run verification**:
   ```bash
   nocorrect swift build
   nocorrect swift test --filter ComponentNameTests
   ```

## 4. Integration

10. **Update site integration** (if applicable):
    - Add to appropriate page in `Sources/21-dev/`
    - Update imports and component usage
    - Test full site generation: `nocorrect swift run 21-dev`

## 5. Quality Check

11. **Run RawHTML audit** (if component uses RawHTML):
    ```bash
    # Use dedicated audit workflow
    /46-rawhtml-audit-workflow
    ```
