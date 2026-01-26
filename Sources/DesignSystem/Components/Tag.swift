//
//  Tag.swift
//  21-DOT-DEV/Tag.swift
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Slipstream

/// A reusable tag badge component for labeling and categorization.
/// Displays text in a rounded, styled container suitable for tags, categories, or status indicators.
public struct Tag: View {
    private let text: String
    
    /// Creates a tag with the specified text.
    /// - Parameter text: The tag text to display
    public init(_ text: String) {
        self.text = text
    }
    
    public var body: some View {
        Span {
            DOMString(text)
        }
        .modifier(ClassModifier(add: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-800"))
    }
}
