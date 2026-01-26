//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Olas placeholder icon component with text styling
public struct OlasPlaceholderIcon: View {
    public init() {}

    public var body: some View {
        SVG(viewBox: "0 0 256 256") {
            SVGGroup {
                // Text with slight shadow effect
                SVGText("Olas", at: Point(x: 129, y: 141))
                    .fontSize("56")
                    .fontFamily("system-ui, -apple-system, sans-serif")
                    .fontWeight("600")
                    .textAnchor("middle")
                    .fill(SVGColor.hex("#333333"))

                SVGText("Olas", at: Point(x: 128, y: 140))
                    .fontSize("56")
                    .fontFamily("system-ui, -apple-system, sans-serif")
                    .fontWeight("600")
                    .textAnchor("middle")
                    .fill(SVGColor.hex("#f8f8f8"))
                    .stroke(SVGColor.hex("#666666"))
                    .strokeWidth("0.5")
            }
        }
    }
}
