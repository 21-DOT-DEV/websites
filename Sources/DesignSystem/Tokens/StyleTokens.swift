//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Design tokens for button styling variants.
public enum ButtonStyle: Sendable {
    case primary   // Orange background, white text
    case secondary // Gray border, gray text
    
    /// CSS classes for the button style
    public var cssClasses: String {
        switch self {
        case .primary:
            return """
            bg-orange-500 hover:bg-orange-600 text-white rounded-lg \
            focus:ring-2 focus:ring-orange-500 focus:ring-offset-2
            """
        case .secondary:
            return """
            border border-gray-300 hover:border-gray-400 text-gray-700 rounded-lg \
            focus:ring-2 focus:ring-gray-500 focus:ring-offset-2
            """
        }
    }
}

/// Design tokens for card styling variants.
public enum CardStyle: Sendable {
    case elevated   // White background with border and rounded corners (default)
    case outlined   // Border only, transparent background
    case filled     // Solid background, no border
}
