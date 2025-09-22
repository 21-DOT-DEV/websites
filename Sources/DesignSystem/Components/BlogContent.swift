//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A wrapper component for blog post content with consistent styling and layout.
/// Provides proper spacing, typography hierarchy, and responsive design.
public struct BlogContent<Content: View>: View {
    public let content: Content
    public let maxWidth: MaxWidth
    
    /// Creates a blog content wrapper with consistent styling.
    /// - Parameters:
    ///   - maxWidth: Maximum content width (default: 4xl)
    ///   - content: The blog content to wrap
    public init(
        maxWidth: MaxWidth = .fourXL,
        @ViewBuilder content: () -> Content
    ) {
        self.maxWidth = maxWidth
        self.content = content()
    }
    
    public var body: some View {
        Div {
            Div {
                VStack(spacing: 24) {
                    content
                }
            }
            .padding(.horizontal, 16)
            .padding(.horizontal, 24, condition: Condition(startingAt: .small))
            .padding(.horizontal, 32, condition: Condition(startingAt: .large))
            .modifier(ClassModifier(add: maxWidth.cssClass))
            .margin(.horizontal, .auto)
        }
        .padding(.vertical, 64)
        .background(.white)
    }
}
