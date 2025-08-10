//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A reusable placeholder component for new sites during initial development.
/// Provides a centered, large text layout with sensible defaults.
/// Can be customized using Slipstream modifiers for enhanced styling.
public struct PlaceholderView: View {
    let text: String
    
    /// Creates a placeholder view with the specified text.
    /// - Parameter text: The text to display in the centered layout
    public init(text: String) {
        self.text = text
    }
    
    public var body: some View {
        Div {
            Text(text)
        }
        .frame(height: .screen)
        .display(.flex)
        .alignItems(.center)
        .justifyContent(.center)
        .fontSize(.sevenXLarge)
        .textAlignment(.center)
        .fontDesign(.sans)
    }
}
