//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A view component for rendering the OpenSats logo as an SVG.
///
/// This component renders a simplified version of the OpenSats logo with solid colors.
/// The logo links to the OpenSats website and opens in a new tab.
public struct OpenSatsLogo: View {
    /// The width class for the logo
    public let widthClass: String
    /// The href URL for the logo link
    public let href: String
    
    /// Creates a new OpenSatsLogo.
    ///
    /// - Parameters:
    ///   - widthClass: The width class for the logo (defaults to "w-20")
    ///   - href: The href URL for the logo link (defaults to "https://opensats.org/")
    public init(widthClass: String = "w-20", href: String = "https://opensats.org/") {
        self.widthClass = widthClass
        self.href = href
    }
    
    public var body: some View {
        Link(URL(string: href), openInNewTab: true, content: {
            SVG(viewBox: "344.5639097744361 330.27819548872174 111.73684210526318 91.21804511278197") {
                SVGDefs {
                    // Linear gradient definition for radial gradient reference
                    SVGLinearGradient(start: Point(x: 0, y: 0), end: Point(x: 0, y: 0)) {
                        SVGStop(offset: 0, color: .hex("#ffb200"), opacity: 1)
                        SVGStop(offset: 0.49295774, color: .hex("#ff6b01"), opacity: 1)
                    }
                    .id("linearGradient7054")

                    // Radial gradients for the logo paths
                    SVGRadialGradient(
                        center: Point(x: 31.832577, y: 29.662136),
                        radius: 42.553486,
                        gradientUnits: .userSpaceOnUse
                    ) {
                        SVGStop(offset: 0, color: .hex("#ffb200"), opacity: 1)
                        SVGStop(offset: 0.49295774, color: .hex("#ff6b01"), opacity: 1)
                    }
                    .id("radialGradient7056")

                    SVGRadialGradient(
                        center: Point(x: 31.832577, y: 29.662136),
                        radius: 42.553486,
                        gradientUnits: .userSpaceOnUse
                    ) {
                        SVGStop(offset: 0, color: .hex("#ffb200"), opacity: 1)
                        SVGStop(offset: 0.49295774, color: .hex("#ff6b01"), opacity: 1)
                    }
                    .id("radialGradient7056-7")
                }
                
                SVGGroup {
                    // Horizontal bar path
                    SVGPath("m 32.574123,39.318559 v 3.810103 h 16.109611 v -3.810103 z")
                        .modifier(ClassModifier(add: "fill-[url(#radialGradient7056)] fill-opacity-100"))
                    
                    // Angular left shape path
                    SVGPath("m 14.849106,16.062097 v 4.551143 l 8.944674,5.680791 v 0.136942 l -8.944674,5.680274 V 36.66239 L 27.877769,28.107357 V 24.61713 Z")
                        .modifier(ClassModifier(add: "fill-[url(#radialGradient7056-7)] fill-opacity-100"))
                }
                .transform(.matrix(a: 2.3991507,b: 0,c: 0,d: 2.3991507,e: 324.2199,f: 304.88344))
            }
            .frame(width: 54, height: 44)
            // TODO: Missing Slipstream APIs - using ClassModifier for object-contain
            .modifier(ClassModifier(add: "\(widthClass) object-contain"))
        })
        .display(.flex)
    }
}
