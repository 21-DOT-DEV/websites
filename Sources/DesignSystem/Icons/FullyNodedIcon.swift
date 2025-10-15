//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Fully Noded app icon component with solid fills
public struct FullyNodedIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 460 460") {
            SVGGroup {
                // Black background with circular cutout
                SVGPath("M 0.00 460.00 L 460.00 460.00 L 460.00 0.00 L 0.00 0.00 L 0.00 460.00 M 244.00 15.00 C 331.27 23.44 407.48 81.15 432.93 168.07 C 458.38 254.99 426.79 355.70 349.75 408.75 C 272.72 461.81 164.99 456.60 93.25 396.75 C 21.52 336.89 -1.35 230.21 33.32 147.32 C 67.99 64.44 153.47 6.24 244.00 15.00 Z")
                    .modifier(AttributeModifier("style", value: "fill:#000000;fill-opacity:1.00"))
                
                // Gray circle with inner symbol cutout
                SVGPath("M 244.00 15.00 C 153.47 6.24 67.99 64.44 33.32 147.32 C -1.35 230.21 21.52 336.89 93.25 396.75 C 164.99 456.60 272.72 461.81 349.75 408.75 C 426.79 355.70 458.38 254.99 432.93 168.07 C 407.48 81.15 331.27 23.44 244.00 15.00 M 274.00 74.00 C 249.63 120.53 219.26 168.96 217.00 222.00 C 242.64 159.56 305.68 120.50 363.00 92.00 C 283.94 185.13 222.85 295.15 210.00 417.00 C 143.84 351.31 126.51 248.44 149.00 160.00 C 155.31 185.24 161.81 210.44 167.00 236.00 C 173.87 204.55 189.37 170.36 209.25 144.25 C 229.12 118.13 248.79 95.51 274.00 74.00 Z")
                    .modifier(AttributeModifier("style", value: "fill:#666666;fill-opacity:1.00"))
                
                // Black inner symbol
                SVGPath("M 274.00 74.00 C 248.79 95.51 229.12 118.13 209.25 144.25 C 189.37 170.36 173.87 204.55 167.00 236.00 C 161.81 210.44 155.31 185.24 149.00 160.00 C 126.51 248.44 143.84 351.31 210.00 417.00 C 222.85 295.15 283.94 185.13 363.00 92.00 C 305.68 120.50 242.64 159.56 217.00 222.00 C 219.26 168.96 249.63 120.53 274.00 74.00 Z")
                    .modifier(AttributeModifier("style", value: "fill:#000000;fill-opacity:1.00"))
            }
        }
    }
}
