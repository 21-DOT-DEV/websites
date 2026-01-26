//
//  CopyIcon.swift
//  21-DOT-DEV/DesignSystem
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//

import Foundation
import Slipstream

/// A copy clipboard icon component
public struct CopyIcon: View {
    public init() {}
    
    public var body: some View {
        SVG(viewBox: "0 0 24 24") {
            SVGRect(origin: Point(x: 8, y: 8), size: Size(width: 14, height: 14), radiusX: 2, radiusY: 2)
            SVGPath("M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2")
        }
        .modifier(ClassModifier(add: "h-4 w-4"))
        .modifier(AttributeModifier("fill", value: "none"))
        .modifier(AttributeModifier("stroke", value: "currentColor"))
        .modifier(AttributeModifier("stroke-width", value: "2"))
        .modifier(AttributeModifier("stroke-linecap", value: "round"))
        .modifier(AttributeModifier("stroke-linejoin", value: "round"))
    }
}
