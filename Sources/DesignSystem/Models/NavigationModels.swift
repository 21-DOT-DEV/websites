//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Represents a navigation link for use in headers, menus, and navigation components.
/// Provides consistent behavior for both internal and external links.
public struct NavigationLink: Sendable {
    /// The display text for the navigation link
    public let title: String
    /// The URL or path the link points to
    public let href: String
    /// Whether this link points to an external domain
    public let isExternal: Bool
    
    /// Creates a navigation link component.
    /// - Parameters:
    ///   - title: The display text for the link
    ///   - href: The URL or path the link points to
    ///   - isExternal: Whether this link points to an external domain (defaults to false)
    public init(title: String, href: String, isExternal: Bool = false) {
        self.title = title
        self.href = href
        self.isExternal = isExternal
    }
}
