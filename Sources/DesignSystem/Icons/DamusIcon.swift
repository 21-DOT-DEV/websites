//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Damus app icon component with full gradient styling
public struct DamusIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 256 256") {
            SVGDefs {
                SVGLinearGradient(
                    id: "linearGradient2119",
                    x1: "10.067794",
                    y1: "248.81357", 
                    x2: "246.56145",
                    y2: "7.1864405",
                    gradientUnits: "userSpaceOnUse"
                ) {
                    SVGStop(offset: "0", stopColor: "#1c55ff", stopOpacity: "1")
                    SVGStop(offset: "0.5", stopColor: "#7f35ab", stopOpacity: "1") 
                    SVGStop(offset: "1", stopColor: "#ff0bd6", stopOpacity: "1")
                }
                
                SVGLinearGradient(
                    id: "linearGradient39361",
                    x1: "62.104473",
                    y1: "128.78963",
                    x2: "208.25758", 
                    y2: "128.78963",
                    gradientUnits: "userSpaceOnUse"
                ) {
                    SVGStop(offset: "0", stopColor: "#0de8ff", stopOpacity: "0.78082192")
                    SVGStop(offset: "1", stopColor: "#d600fc", stopOpacity: "0.95433789")
                }
            }
            
            // Background layer
            SVGGroup {
                SVGPath("M-5.3875166e-08,-1.0775033e-07 L256,-1.0775033e-07 L256,256 L-5.3875166e-08,256 Z")
                .modifier(AttributeModifier("style", value: "fill:url(#linearGradient2119);fill-opacity:1;stroke-width:0.264583"))
            }
            
            // Logo layer
            SVGGroup {
                // LogoStroke sublayer
                SVGGroup {
                    SVGPath("M 101.1429,213.87373 C 67.104473,239.1681 67.104473,42.67112 67.104473,42.67112 135.18122,57.58146 203.25844,72.491904 203.25758,105.24181 c -8.6e-4,32.74991 -68.07625,83.33755 -102.11468,108.63192 z")
                        .modifier(AttributeModifier("style", value: "fill:url(#linearGradient39361);fill-opacity:1;stroke:#ffffff;stroke-width:10;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"))
                }
                
                // Poly sublayer
                SVGGroup {
                    SVGPath("M 67.32839,76.766948 112.00424,99.41949 100.04873,52.226693 Z")
                        .modifier(AttributeModifier("style", value: "fill:#ffffff;fill-opacity:0.325424;stroke:#ffffff;stroke-width:2;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"))
                    
                    SVGPath("M 111.45696,98.998695 107.00758,142.60261 70.077729,105.67276 Z")
                        .modifier(AttributeModifier("style", value: "fill:#ffffff;fill-opacity:0.274576;stroke:#ffffff;stroke-width:2;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"))
                    
                    SVGPath("m 111.01202,99.221164 29.14343,-37.15232 25.80641,39.377006 z")
                        .modifier(AttributeModifier("style", value: "fill:#ffffff;fill-opacity:0.379661;stroke:#ffffff;stroke-width:2;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"))
                    
                    SVGPath("m 111.45696,99.443631 57.17452,55.172309 -2.89209,-53.17009 z")
                        .modifier(AttributeModifier("style", value: "fill:#ffffff;fill-opacity:0.447458;stroke:#ffffff;stroke-width:2;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"))
                    
                    SVGPath("m 106.78511,142.38015 62.06884,12.68073 -57.17452,-55.617249 z")
                        .modifier(AttributeModifier("style", value: "fill:#ffffff;fill-opacity:0.20678;stroke:#ffffff;stroke-width:2;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"))
                    
                    SVGPath("m 106.78511,142.38015 -28.47603,32.9254 62.51378,7.56395 z")
                        .modifier(AttributeModifier("style", value: "fill:#ffffff;fill-opacity:0.244068;stroke:#ffffff;stroke-width:2;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"))
                    
                    SVGPath("M 165.96186,101.44585 195.7727,125.02756 182.64703,78.754017 Z")
                        .modifier(AttributeModifier("style", value: "fill:#ffffff;fill-opacity:0.216949;stroke:#ffffff;stroke-width:2;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"))
                }
                
                // Vertices sublayer
                SVGGroup {
                    SVGCircle(cx: "106.86934", cy: "142.38014", r: "2.0022209")
                        .modifier(AttributeModifier("style", value: "fill:#ffffff;fill-opacity:1;stroke:none;stroke-width:4;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"))
                    
                    SVGCircle(cx: "111.54119", cy: "99.221161", r: "2.0022209")
                        .modifier(AttributeModifier("style", value: "fill:#ffffff;fill-opacity:1;stroke:none;stroke-width:4;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"))
                    
                    SVGCircle(cx: "165.90784", cy: "101.36163", r: "2.0022209")
                        .modifier(AttributeModifier("style", value: "fill:#ffffff;fill-opacity:1;stroke:none;stroke-width:4;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"))
                }
            }
        }
    }
}
