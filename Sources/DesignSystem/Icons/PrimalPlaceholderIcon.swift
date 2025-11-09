//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Primal placeholder icon component with text styling
public struct PrimalPlaceholderIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 256 256") {
            SVGGroup {
                // Text with slight shadow effect
                SVGText("Primal", at: Point(x: 129, y: 141))
                    .fontSize("56")
                    .fontFamily("system-ui, -apple-system, sans-serif")
                    .fontWeight("600")
                    .textAnchor("middle")
                    .fill(.hex("#333333"))
                
                SVGText("Primal", at: Point(x: 128, y: 140))
                    .fontSize("56")
                    .fontFamily("system-ui, -apple-system, sans-serif")
                    .fontWeight("600")
                    .textAnchor("middle")
                    .fill(.hex("#f8f8f8"))
                    .stroke(.hex("#666666"))
                    .strokeWidth("0.5")
            }
        }
    }
}