//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Nostr logo icon component
public struct NostrIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 24 24") {
            SVGGroup {
                SVGPath("M19.7 18.7c0 .3-.2.5-.5.5h-6.4c-.3 0-.5-.2-.5-.5v-1.5c0-1.8.2-3.5.6-4.3.2-.5.6-.7 1.1-.9.9-.3 2.3-.1 3-.1 0 0 1.9.1 1.9-1s-.9-.8-.9-.8c-.9 0-1.7 0-2.1-.2-.8-.3-.8-.9-.8-1.1 0-2.2-3.2-2.4-6-1.9-3.1.6 0 5 0 10.9v.8c0 .3-.2.5-.5.5H5.4c-.3 0-.5-.2-.5-.5V5.3c0-.3.2-.5.5-.5H8.4c.3 0 .5.2.5.5 0 .4.5.7.8.4 1.1-.8 2.4-1.2 4-1.2 3.4 0 6 2 6 6.4v7.8zM14.1 9.3c0-.6-.5-1.1-1.1-1.1s-1.1.5-1.1 1.1.5 1.1 1.1 1.1 1.1-.5 1.1-1.1z")
                    .modifier(AttributeModifier("fill", value: "currentColor"))
            }
            .modifier(AttributeModifier("transform", value: "scale(1.4) translate(-3.2, -3.2)"))
        }
    }
}
