//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Macadamia app icon component
public struct MacadamiaIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 100 100") {
            // Background rectangle
            SVGPath("M0,0 L100,0 L100,100 L0,100 Z")
                .modifier(AttributeModifier("style", value: "fill:#231f20;stroke-width:0"))
            
            // White macadamia path
            SVGPath("M77.21,48.48c0,10.14-4.56,16.34-13.01,20.65-3.55,1.81-12.83-1.35-17.06-1.89-5.03-.63-9.73,1.61-13.99-1.41-6.65-4.72-7.7-9.61-7.7-18.39,0-11.92,9.82-18.52,18.28-20.63.98-.25,1.98-.78,3.65-.75,1.73.22-8.53,13.02-3.80,38.63-1.59-27.12,8.45-39.02,8.78-39.11,1.99-1.03,4.23-1.56,5.98-1.28,2.28.36,3.81,3.10,6.50,4.12,8.49,3.23,12.38,9.94,12.38,20.05Z")
                .modifier(AttributeModifier("style", value: "fill:#ffffff;stroke-width:0"))
        }
    }
}
