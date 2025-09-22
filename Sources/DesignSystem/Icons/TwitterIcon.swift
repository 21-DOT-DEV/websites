//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Twitter/X logo icon component
public struct TwitterIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 24 24") {
            SVGPath("M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z")
                .modifier(AttributeModifier("fill", value: "currentColor"))
        }
    }
}
