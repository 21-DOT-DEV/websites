//
//  Breadcrumb.swift
//  DesignSystem
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A single breadcrumb level with a name and optional URL.
/// The last item should have a `nil` href (current page).
public struct BreadcrumbLevel: Sendable {
    public let name: String
    public let href: String?
    
    public init(name: String, href: String? = nil) {
        self.name = name
        self.href = href
    }
}

/// A visual breadcrumb navigation component rendered as a `<nav aria-label="Breadcrumb">`.
///
/// The last item is plain text (not a link) since it represents the current page,
/// matching Google's structured data pattern where the final ListItem omits the URL.
///
/// ## Usage
/// ```swift
/// Breadcrumb(levels: [
///     BreadcrumbLevel(name: "Home", href: "/"),
///     BreadcrumbLevel(name: "Blog", href: "/blog/"),
///     BreadcrumbLevel(name: "Hello World")
/// ])
/// ```
public struct Breadcrumb: View {
    private let levels: [BreadcrumbLevel]
    
    public init(levels: [BreadcrumbLevel]) {
        self.levels = levels
    }
    
    // RawHTML justified: Slipstream's ViewBuilder cannot infer types for
    // for-loop + conditional patterns needed here. The outer <nav> element
    // still uses Slipstream's Navigation + AttributeModifier for aria-label.
    public var body: some View {
        Navigation {
            RawHTML(renderItems())
        }
        .modifier(AttributeModifier("aria-label", value: "Breadcrumb"))
        .fontSize(.small)
    }
    
    private func renderItems() -> String {
        levels.enumerated().map { index, level in
            var html = ""
            if index > 0 {
                html += "<span class=\"text-gray-400\"> › </span>"
            }
            if let href = level.href {
                html += "<a href=\"\(href)\" class=\"text-gray-500 hover:underline\">\(level.name)</a>"
            } else {
                html += "<span class=\"text-gray-700\">\(level.name)</span>"
            }
            return html
        }.joined()
    }
}
