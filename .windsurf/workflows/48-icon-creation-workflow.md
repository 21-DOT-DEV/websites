---
description: Create new SVG icon components for the DesignSystem with proper styling and CSS generation
---

# Icon Creation Workflow

## 1. Create Icon Component File

```bash
touch Sources/DesignSystem/Icons/<IconName>Icon.swift
```

## 2. Implement Icon Structure

```swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// [IconName] app icon component with full gradient styling
public struct [IconName]Icon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 256 256") {
            SVGDefs {
                // Add gradient definitions here
                SVGLinearGradient(
                    id: "linearGradient[ID]",
                    x1: "x1_value",
                    y1: "y1_value", 
                    x2: "x2_value",
                    y2: "y2_value",
                    gradientUnits: "userSpaceOnUse"
                ) {
                    SVGStop(offset: "0", stopColor: "#color1", stopOpacity: "1")
                    SVGStop(offset: "1", stopColor: "#color2", stopOpacity: "1")
                }
            }
            
            // SVG content groups
            SVGGroup {
                SVGPath("path_data_here")
                    .modifier(AttributeModifier("style", value: "fill:url(#linearGradient[ID]);fill-opacity:1;stroke-width:value"))
            }
        }
    }
}
```

## 3. Use AttributeModifier for Complex SVG Styling

**IMPORTANT**: For SVG elements with gradients, strokes, or complex styling:

✅ **DO**: Use `AttributeModifier` with inline `style` attribute
```swift
.modifier(AttributeModifier("style", value: "fill:url(#gradient);stroke:#ffffff;stroke-width:2"))
```

❌ **DON'T**: Use `ClassModifier` with Tailwind classes for complex SVG properties
```swift
.modifier(ClassModifier(add: "fill-[url(#gradient)] stroke-white stroke-2"))  // Won't compile!
```

## 4. Add to IconGallery (if applicable)

// turbo
Update `Sources/21-dev/P256KPage.swift` to include new icon:
```swift
ContentItem(
    id: "[icon-id]", 
    title: "[Icon Name]", 
    icon: AnyView([IconName]Icon()), 
    link: "https://example.com"
)
```

## 5. Build and Test

// turbo
Build the project:
```bash
nocorrect swift build
```

// turbo  
Generate site HTML:
```bash
swift run 21-dev
```

// turbo
Compile Tailwind CSS:
```bash
swift package --disable-sandbox tailwindcss --input Resources/21-dev/static/style.input.css --output Websites/21-dev/static/style.css --config Resources/21-dev/tailwind.config.cjs
```

## 6. Verify Output

Check generated HTML in `Websites/21-dev/*/index.html`:
- Ensure `style` attributes are present on SVG elements
- Verify gradient definitions in `<defs>` section
- Confirm no uncompiled CSS classes remain

## 7. Apply Rounded Corners (if needed)

For rounded icon display in galleries:
```swift
item.icon
    .cornerRadius(.large)
```

## Troubleshooting

- **Missing gradients**: Check gradient `id` references match between `<defs>` and `fill:url(#id)`
- **No styling applied**: Ensure using `AttributeModifier` not `ClassModifier` for complex SVG properties
- **CSS not updating**: Re-run Tailwind compilation step after HTML generation
