//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// A call-to-action button component for various sections.
/// Handles both internal and external links with proper styling options.
public struct CTAButton: Sendable {
    public let text: String
    public let href: String
    public let style: ButtonStyle
    public let isExternal: Bool
    
    public init(text: String, href: String, style: ButtonStyle = .primary, isExternal: Bool = false) {
        self.text = text
        self.href = href
        self.style = style
        self.isExternal = isExternal
    }
}
