//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Bittr app icon component with solid fills
public struct BittrIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "-69 -22.5 414 414") {
            SVGGroup {
                // Yellow background
                SVGRect(x: "-69", y: "-22.5", width: "414", height: "414")
                    .modifier(AttributeModifier("style", value: "fill:#fdbe10;stroke-width:0"))
                
                SVGGroup {
                    // Black path (default fill)
                    SVGPath("M39.64,141.14c-12.65,46.68,2.8,98.47,43.28,130.15,32.02,25.06,72.48,31.9,108.93,22.05L39.64,141.14Z")
                        .modifier(AttributeModifier("style", value: "fill:#000000;stroke-width:0"))
                    
                    // White path (formerly yellow/orange)
                    SVGPath("M235.81,75.98c-53.93-42.22-131.88-32.73-174.11,21.2-3.62,4.62-6.84,9.44-9.71,14.39l25.52,25.52h0c2.92-6.53,6.66-12.82,11.27-18.7,30.51-38.98,86.84-45.84,125.82-15.33,38.98,30.51,45.84,86.84,15.33,125.82-9.34,11.93-21.09,20.83-34.03,26.58l25.53,25.53c13.36-7.71,25.49-18.03,35.58-30.92,42.22-53.94,32.73-131.88-21.2-174.11h0Z")
                        .modifier(AttributeModifier("style", value: "fill:#ffffff;stroke-width:0"))
                }
                .modifier(AttributeModifier("transform", value: "translate(-15, 10)"))
            }
        }
    }
}
