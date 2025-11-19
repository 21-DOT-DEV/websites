//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Nos app icon component with gradient styling
public struct NosIcon: View {
    public init() {}

    public var body: some View {
        SVG(viewBox: "0 0 512 512") {
            SVGDefs {
                SVGLinearGradient(
                    start: Point(x: 108.355, y: 385.145),
                    end: Point(x: 404, y: 145.534),
                    gradientUnits: .userSpaceOnUse
                ) {
                    SVGStop(offset: 0, color: SVGColor.hex("#B50036"), opacity: 1)
                    SVGStop(offset: 1, color: SVGColor.hex("#AF5F00"), opacity: 1)
                }
                .modifier(AttributeModifier("id", value: "paint0_linear_nos"))

                SVGLinearGradient(
                    start: Point(x: 108.355, y: 367.282),
                    end: Point(x: 404, y: 127.671),
                    gradientUnits: .userSpaceOnUse
                ) {
                    SVGStop(offset: 0, color: SVGColor.hex("#FF2E6C"), opacity: 1)
                    SVGStop(offset: 1, color: SVGColor.hex("#FF9416"), opacity: 1)
                }
                .modifier(AttributeModifier("id", value: "paint1_linear_nos"))

                SVGLinearGradient(
                    start: Point(x: 108.355, y: 367.282),
                    end: Point(x: 404, y: 127.671),
                    gradientUnits: .userSpaceOnUse
                ) {
                    SVGStop(offset: 0, color: SVGColor.hex("#FF2E6C"), opacity: 1)
                    SVGStop(offset: 1, color: SVGColor.hex("#FF9416"), opacity: 1)
                }
                .modifier(AttributeModifier("id", value: "paint2_linear_nos"))
            }

            // Background rectangle
            SVGPath("M0,0 L512,0 L512,512 L0,512 Z")
                .modifier(AttributeModifier("style", value: "fill:#160F24"))

            // Main logo path
            SVGPath("M284.13 145.575C350.333 145.575 404 199.301 404 265.576L348.069 265.576C348.013 331.658 294.366 385.21 228.199 385.21C161.998 385.21 108.33 331.601 108.33 265.472H164.261C164.317 199.245 217.963 145.575 284.13 145.575Z")
                .modifier(AttributeModifier("style", value: "fill:url(#paint0_linear_nos)"))

            // Secondary path with gradient
            SVGPath("M284.13 127.712C350.333 127.712 404 181.438 404 247.713L348.069 247.713C348.013 313.795 294.366 367.347 228.199 367.347C161.998 367.347 108.33 313.738 108.33 247.608H164.261C164.317 181.382 217.963 127.712 284.13 127.712Z")
                .modifier(AttributeModifier("style", value: "fill:url(#paint1_linear_nos)"))

            // Stroke outline path
            SVGPath("M404 247.713V254.858H411.145V247.713L404 247.713ZM348.069 247.713V240.567H340.93L340.924 247.707L348.069 247.713ZM108.33 247.608V240.463H101.184V247.608H108.33ZM164.261 247.608V254.754H171.4L171.406 247.614L164.261 247.608ZM411.145 247.713C411.145 177.499 354.286 120.566 284.13 120.566V134.857C346.379 134.857 396.855 185.377 396.855 247.713L411.145 247.713ZM348.069 254.858L404 254.858V240.567L348.069 240.567L348.069 254.858ZM228.199 374.492C298.303 374.492 355.155 317.752 355.214 247.719L340.924 247.707C340.871 309.838 290.429 360.202 228.199 360.202V374.492ZM101.184 247.608C101.184 317.692 158.059 374.492 228.199 374.492V360.202C165.937 360.202 115.475 309.785 115.475 247.608H101.184ZM164.261 240.463H108.33V254.754H164.261V240.463ZM284.13 120.566C214.011 120.566 157.175 177.439 157.115 247.602L171.406 247.614C171.459 185.324 221.914 134.857 284.13 134.857V120.566Z")
                .modifier(AttributeModifier("style", value: "fill:url(#paint2_linear_nos)"))
        }
    }
}
