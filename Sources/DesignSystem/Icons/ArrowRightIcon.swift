//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Arrow right icon component
public struct ArrowRightIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 20 20") {
            SVGPath("M12.293 5.293a1 1 0 011.414 0l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414-1.414L14.586 11H3a1 1 0 110-2h11.586l-2.293-2.293a1 1 0 010-1.414z")
        }
        .frame(width: 16, height: 16)
        .modifier(ClassModifier(add: "w-4 h-4 fill-current"))
    }
}
