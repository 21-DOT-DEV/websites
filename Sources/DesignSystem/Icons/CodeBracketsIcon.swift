//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Code brackets icon component
public struct CodeBracketsIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 24 24") {
            SVGPath("M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4")
        }
        .frame(width: 24, height: 24)
        .modifier(ClassModifier(add: "w-6 h-6 stroke-current fill-none stroke-[1.5] [stroke-linecap:round] [stroke-linejoin:round]"))
    }
}
