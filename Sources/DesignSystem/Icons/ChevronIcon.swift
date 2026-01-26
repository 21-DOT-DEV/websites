//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Chevron right icon component, ideal for accordions and expandable content
public struct ChevronIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 20 20") {
            SVGPath("M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z")
        }
        .modifier(ClassModifier(add: "w-5 h-5 fill-current"))
    }
}
