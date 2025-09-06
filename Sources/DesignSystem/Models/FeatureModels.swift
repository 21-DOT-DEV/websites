//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Represents a feature item for use in feature grids and showcase sections.
/// Provides consistent behavior for feature presentation with icons, titles, and descriptions.
public struct Feature: Sendable, Identifiable {
    /// Unique identifier for the feature
    public let id = UUID()
    /// The title of the feature
    public let title: String
    /// The detailed description of the feature
    public let description: String
    /// The icon to display with the feature
    public let icon: AnyView
    
    /// Creates a feature item.
    /// - Parameters:
    ///   - title: The title of the feature
    ///   - description: The detailed description of the feature
    ///   - icon: The icon to display with the feature
    public init<Icon: View>(title: String, description: String, icon: Icon) {
        self.title = title
        self.description = description
        self.icon = AnyView(icon)
    }
}
