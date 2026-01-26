//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// nostrTV placeholder icon component with text styling
public struct NostrTVPlaceholderIcon: View {
    public init() {}

    public var body: some View {
        SVG(viewBox: "0 0 256 256") {
            SVGGroup {
                // Text with slight shadow effect
                SVGText("nostrTV", at: Point(x: 129, y: 141))
                    .fontSize("56")
                    .fontFamily("system-ui, -apple-system, sans-serif")
                    .fontWeight("600")
                    .textAnchor("middle")
                    .fill(SVGColor.hex("#333333"))

                SVGText("nostrTV", at: Point(x: 128, y: 140))
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
