//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Nostur app icon component with multiple gradient styling
public struct NosturIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 687.7 687.7") {
            SVGDefs {
                SVGLinearGradient(
                    start: Point(x: 9.8476, y: 675.8415),
                    end: Point(x: 673.8476, y: 15.8415),
                    gradientUnits: .userSpaceOnUse
                ) {
                    SVGStop(offset: 0, color: SVGColor.hex("#0F1A1A"), opacity: 1)
                    SVGStop(offset: 0.1187, color: SVGColor.hex("#1E2A2B"), opacity: 1)
                    SVGStop(offset: 0.3088, color: SVGColor.hex("#2D3C3F"), opacity: 1)
                    SVGStop(offset: 0.496, color: SVGColor.hex("#394B4F"), opacity: 1)
                    SVGStop(offset: 0.6766, color: SVGColor.hex("#41555C"), opacity: 1)
                    SVGStop(offset: 0.8479, color: SVGColor.hex("#465C63"), opacity: 1)
                    SVGStop(offset: 1, color: SVGColor.hex("#475E66"), opacity: 1)
                }
                .modifier(AttributeModifier("id", value: "XMLID_3_nostur"))
                
                SVGLinearGradient(
                    start: Point(x: 534.8233, y: 333.4573),
                    end: Point(x: 804.8233, y: 655.4573),
                    gradientUnits: .userSpaceOnUse
                ) {
                    SVGStop(offset: 0, color: SVGColor.hex("#2C3738"), opacity: 1)
                    SVGStop(offset: 1, color: SVGColor.hex("#0E1212"), opacity: 1)
                }
                .modifier(AttributeModifier("id", value: "XMLID_4_nostur"))
                
                SVGLinearGradient(
                    start: Point(x: 316.9406, y: 179.0295),
                    end: Point(x: 656.9406, y: 701.0295),
                    gradientUnits: .userSpaceOnUse
                ) {
                    SVGStop(offset: 0, color: SVGColor.hex("#2C3738"), opacity: 1)
                    SVGStop(offset: 0.05547917, color: SVGColor.hex("#2A3536"), opacity: 1)
                    SVGStop(offset: 0.867, color: SVGColor.hex("#0A0E0E"), opacity: 1)
                }
                .modifier(AttributeModifier("id", value: "XMLID_5_nostur"))
            }
            
            SVGGroup {
                // Background rectangle - fixing the SVGRect call
                SVGRect(origin: .zero, size: Size(width: 687.7, height: 687.7))
                    .modifier(AttributeModifier("style", value: "fill:url(#XMLID_3_nostur)"))
                
                // First path element
                SVGPath("M687.7,417.6v37.1c-7.9,18.7-20,40.4-33.5,41.5c-24,2-260-224.7-271.3-246.7s-34-84.2-53.3-101.1c-19.3-16.9-34.7-20.9-34.7-20.9l8.5-21.7c0,0,35.5,6.7,43.5,6.4c8-0.3,35.6-3.2,35.6-3.2L687.7,417.6z")
                    .modifier(AttributeModifier("style", value: "fill:url(#XMLID_4_nostur)"))
                
                // Second path element
                SVGPath("M387.9,127.5l299.9,300.7v259.5h-46.4c0,0-186.2-37.2-230.5-63.5s-72-108.3-72-108.3s14.9-340.6,0-357s-32-13.5-32.5-19.5s12.5-9,23-8.5S387.9,127.5,387.9,127.5z")
                    .modifier(AttributeModifier("style", value: "fill:url(#XMLID_5_nostur)"))
                
                // Dark solid path
                SVGPath("M82.9,687.7l61.1-50.7c0,0,54.9-39.6,79.4-56.1s66-34.5,100-31s108.5,10,124,18.5s-30-52.5-30-52.5l224,171.9H82.9z")
                    .modifier(AttributeModifier("style", value: "fill:#080A0B"))
                
                // White detailed path (Nostur logo)
                SVGPath("M417.4,515.9h-29.5c0,0-33.7-47-33.7-149v-100c0,0,0.3-61,4.3-88s16-39.3,31-39.3l-1.7-12h-22.1c9.2-10.1,22.6-25.2,22.6-25.2s-21.2-1.5-29.3-3.7c0,0-4,3.1-7.9,6.1h-19.5l-7.9-6.1c-8.2,2.2-29.3,3.7-29.3,3.7s13.5,15.1,22.6,25.2h-22.1l-1.7,12c15,0,27,12.3,31,39.3s4.3,88,4.3,88v100c0,102-33.7,149-33.7,149h-29.5l-139.2,130l143.3-71.7l9.3,9.3h20l42.5,35.3l42.5-35.3h20l9.3-9.3l143.3,71.7L417.4,515.9z M340,111.1l-1-4.7c0,0,1.6,0.1,2.4-0.6c0.8,0.7,2.4,0.6,2.4,0.6l-1,4.7l-1.4,1.1L340,111.1z M313.5,138.6c0,0,2-0.8,5.2-2.4c3.2-1.6,5.7-0.7,5.7-0.7c5.2,5.3,12.3,5.8,17,5.8s11.8-0.5,17-5.8c0,0,2.5-0.9,5.7,0.7c3.2,1.6,5.2,2.4,5.2,2.4s-1.1,4.8-27.8,4.8S313.5,138.6,313.5,138.6z M341.7,151.6c0.2,0.4,0.4,1.2,0.4,2.1c0,1.4-0.4,2.5-0.8,2.5s-0.8-1.1-0.8-2.5c0-0.9,0.2-1.7,0.4-2.1c-0.8-0.2-1.4-0.8-1.4-1.6c0-0.9,0.8-1.6,1.8-1.6s1.8,0.7,1.8,1.6C343.2,150.8,342.6,151.5,341.7,151.6z")
                    .modifier(AttributeModifier("style", value: "fill:#FFFFFF"))
            }
        }
    }
}