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
        Link(URL(string: href), openInNewTab: true) {
            SVG(viewBox: "344.5639097744361 330.27819548872174 111.73684210526318 91.21804511278197") {
                SVGDefs {
                    // Linear gradient definition for radial gradient reference
                    SVGLinearGradient(id: "linearGradient7054", x1: "0", y1: "0", x2: "0", y2: "1") {
                        SVGStop(offset: "0", stopColor: "#ffb200", stopOpacity: "1")
                        SVGStop(offset: "0.49295774", stopColor: "#ff6b01", stopOpacity: "1")
                    }
                    
                    // Radial gradients for the logo paths
                    SVGRadialGradient(
                        id: "radialGradient7056", 
                        cx: "31.832577", 
                        cy: "29.662136", 
                        r: "42.553486",
                        gradientUnits: "userSpaceOnUse"
                    ) {
                        SVGStop(offset: "0", stopColor: "#ffb200", stopOpacity: "1")
                        SVGStop(offset: "0.49295774", stopColor: "#ff6b01", stopOpacity: "1")
                    }
                    
                    SVGRadialGradient(
                        id: "radialGradient7056-7", 
                        cx: "31.832577", 
                        cy: "29.662136", 
                        r: "42.553486",
                        gradientUnits: "userSpaceOnUse"
                    ) {
                        SVGStop(offset: "0", stopColor: "#ffb200", stopOpacity: "1")
                        SVGStop(offset: "0.49295774", stopColor: "#ff6b01", stopOpacity: "1")
                    }
                }
                
                SVGGroup {
                    // Horizontal bar path
                    SVGPath("m 32.574123,39.318559 v 3.810103 h 16.109611 v -3.810103 z")
                        .modifier(ClassModifier(add: "fill-[url(#radialGradient7056)] fill-opacity-100"))
                    
                    // Angular left shape path
                    SVGPath("m 14.849106,16.062097 v 4.551143 l 8.944674,5.680791 v 0.136942 l -8.944674,5.680274 V 36.66239 L 27.877769,28.107357 V 24.61713 Z")
                        .modifier(ClassModifier(add: "fill-[url(#radialGradient7056-7)] fill-opacity-100"))
                }
                .transform("matrix(2.3991507,0,0,2.3991507,324.2199,304.88344)")
            }
            .frame(width: 54, height: 44)
            // TODO: Missing Slipstream APIs - using ClassModifier for object-contain
            .modifier(ClassModifier(add: "\(widthClass) object-contain"))
        }
        .display(.flex)
    }
}
