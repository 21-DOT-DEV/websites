//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Lightning icon component
public struct LightningIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 24 24") {
            SVGPath("M13 10V3L4 14h7v7l9-11h-7z")
        }
        .frame(width: 24, height: 24)
        .modifier(ClassModifier(add: "w-6 h-6 stroke-current fill-none stroke-[1.5] [stroke-linecap:round] [stroke-linejoin:round]"))
    }
}
