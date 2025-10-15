//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Galaxoid Labs placeholder icon component with text styling
public struct GalaxoidLabsPlaceholderIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 256 256") {
            SVGGroup {
                // Text with slight shadow effect - multiline for longer text
                // Shadow text
                SVGText("Galaxoid", x: "129", y: "115")
                    .fontSize("56")
                    .fontFamily("system-ui, -apple-system, sans-serif")
                    .fontWeight("600")
                    .textAnchor("middle")
                    .fill("#333333")
                SVGText("Labs", x: "129", y: "175")
                    .fontSize("56")
                    .fontFamily("system-ui, -apple-system, sans-serif")
                    .fontWeight("600")
                    .textAnchor("middle")
                    .fill("#333333")
                
                // Main text
                SVGText("Galaxoid", x: "128", y: "114")
                    .fontSize("56")
                    .fontFamily("system-ui, -apple-system, sans-serif")
                    .fontWeight("600")
                    .textAnchor("middle")
                    .fill("#f8f8f8")
                    .stroke("#666666")
                    .strokeWidth("0.5")
                SVGText("Labs", x: "128", y: "174")
                    .fontSize("56")
                    .fontFamily("system-ui, -apple-system, sans-serif")
                    .fontWeight("600")
                    .textAnchor("middle")
                    .fill("#f8f8f8")
                    .stroke("#666666")
                    .strokeWidth("0.5")
            }
        }
    }
}
