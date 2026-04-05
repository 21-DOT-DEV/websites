//
//  LLMsTxtLink.swift
//  DesignSystem
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import SwiftSoup

/// A view that renders `<link rel="llms-txt" href="..." />` in the document head.
///
/// Enables AI agent discovery of the site's llms.txt file.
/// Follows the same pattern as Slipstream's built-in link views (Canonical, Alternate, etc.).
///
/// ```swift
/// Head {
///     LLMsTxtLink(URL(string: "https://example.com/llms.txt"))
/// }
/// ```
public struct LLMsTxtLink: View {
    /// Creates an llms-txt link view.
    ///
    /// - Parameter url: The absolute URL to the site's llms.txt file.
    public init(_ url: URL?) {
        self.url = url
    }

    @_documentation(visibility: private)
    public func render(_ container: Element, environment: EnvironmentValues) throws {
        guard let url else {
            return
        }
        let element = try container.appendElement("link")
        try element.attr("rel", "llms-txt")
        try element.attr("href", url.absoluteString)
    }

    private let url: URL?
}
