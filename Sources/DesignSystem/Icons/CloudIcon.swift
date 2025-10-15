//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Cloud icon component
public struct CloudIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 24 24") {
            SVGPath("M2.25 15a4.5 4.5 0 004.5 4.5H18a3.75 3.75 0 001.332-7.257 3 3 0 00-3.758-3.848 5.25 5.25 0 00-10.233 2.33A4.502 4.502 0 002.25 15z")
        }
        .frame(width: 24, height: 24)
        .modifier(ClassModifier(add: "w-6 h-6 stroke-current fill-none stroke-[1.5] [stroke-linecap:round] [stroke-linejoin:round]"))
    }
}
