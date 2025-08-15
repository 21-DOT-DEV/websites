//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A reusable placeholder component for new sites during initial development.
///
/// `PlaceholderView` provides a centered, large text layout with sensible defaults
/// for rapid prototyping and site scaffolding. It's designed to be easily customizable
/// using Slipstream modifiers for enhanced styling.
///
/// ## Overview
///
/// Use `PlaceholderView` when you need a quick, visually prominent placeholder during
/// development. The component automatically centers content both horizontally and
/// vertically within the available space.
///
/// ## Usage
///
/// ```swift
/// // Basic placeholder
/// PlaceholderView(text: "Welcome to My Site")
///
/// // Enhanced with custom styling
/// PlaceholderView(text: "Coming Soon 🚀")
///     .textColor(.blue)
///     .backgroundColor(.gray, darkness: .50)
///
/// // In a site layout
/// BasePage(title: "My Site") {
///     PlaceholderView(text: "Under Construction")
/// }
/// ```
///
/// ## Styling
///
/// The component uses these default styles:
/// - **Font Size**: `.sevenXLarge` (very large text)
/// - **Alignment**: Center-aligned text and layout
/// - **Layout**: Full screen height with vertical centering
/// - **Font**: Sans-serif design
///
/// You can override these defaults using Slipstream modifiers on the component.
@available(iOS 17.0, macOS 14.0, *)
public struct PlaceholderView: View {
    let text: String
    
    /// Creates a placeholder view with the specified text.
    ///
    /// - Parameter text: The text content to display in the centered layout.
    ///   This text will be rendered with large, prominent styling.
    public init(text: String) {
        self.text = text
    }
    
    public var body: some View {
        VStack(alignment: .center) {
            Text(text)
                .fontSize(.sevenXLarge)
                .textAlignment(.center)
                .fontDesign(.sans)
        }
        .frame(height: .screen)
        .justifyContent(.center)
    }
}
