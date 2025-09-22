//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Represents a content item for use in grids and showcase sections.
/// Provides consistent behavior for content presentation with icons, titles, descriptions, and optional links.
public struct ContentItem: Sendable, Identifiable {
    /// Unique identifier for the feature
    public let id = UUID()
    /// The title of the feature
    public let title: String
    /// The detailed description of the feature
    public let description: String
    /// The icon to display with the content item
    public let icon: AnyView
    /// Optional URL for the content item link
    public let link: String?
    
    /// Creates a content item.
    /// - Parameters:
    ///   - title: The title of the content item
    ///   - description: The detailed description of the content item
    ///   - icon: The icon to display with the content item
    ///   - link: Optional URL for the content item link
    public init<Icon: View>(title: String, description: String, icon: Icon, link: String? = nil) {
        self.title = title
        self.description = description
        self.icon = AnyView(icon)
        self.link = link
    }
}
