---
description: >
  Manage DesignSystem Icons, Models, and Tokens directories.
  Add, update, and maintain design system assets.
---

# DesignSystem Management

## Icons Management

1. **Add new social icon**:
   ```swift
   // In Sources/DesignSystem/Icons/SocialIcon.swift
   public enum SocialIcon {
       case github, twitter, linkedin, newPlatform
       
       public var svgPath: String {
           switch self {
           case .newPlatform:
               return "M... // SVG path data"
           }
       }
   }
   ```

2. **Add custom icon component**:
   ```bash
   touch Sources/DesignSystem/Icons/<IconName>Icon.swift
   ```

3. **Test icon rendering**:
   - Add test case in `Tests/DesignSystemTests/Components/`
   - Verify SVG output with TestUtils

## Models Management

4. **Add new component model**:
   ```bash
   touch Sources/DesignSystem/Models/<ComponentName>Models.swift
   ```

5. **Model structure pattern**:
   ```swift
   import Foundation

   /// Models for ComponentName configuration
   @available(iOS 17.0, macOS 14.0, *)
   public struct ComponentNameConfiguration {
       public let title: String
       public let style: ComponentNameStyle
       
       public init(title: String, style: ComponentNameStyle = .default) {
           self.title = title
           self.style = style
       }
   }

   @available(iOS 17.0, macOS 14.0, *)
   public enum ComponentNameStyle {
       case `default`, primary, secondary
   }
   ```

## Tokens Management

6. **Update design tokens**:
   ```swift
   // In Sources/DesignSystem/Tokens/StyleTokens.swift
   public enum StyleTokens {
       public static let newColorToken = "new-color-class"
       public static let newSpacingToken = "spacing-value"
   }
   ```

7. **Add layout tokens**:
   ```swift
   // In Sources/DesignSystem/Tokens/LayoutTokens.swift  
   public enum LayoutTokens {
       public static let newBreakpoint = "breakpoint-class"
       public static let newGridToken = "grid-configuration"
   }
   ```

## Verification Steps

8. **Build and test changes**:
   ```bash
   nocorrect swift build
   nocorrect swift test --filter DesignSystemTests
   ```

9. **Update documentation**:
   - Add doc comments to new public APIs
   - Update component usage examples
   - Verify imports work across targets
