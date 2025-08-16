//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A generic about section component for displaying a title with multiple content paragraphs.
/// Provides sensible defaults for styling while allowing customization through optional parameters.
public struct AboutSection: View {
    public let title: String
    public let paragraphs: [String]
    public let backgroundColor: Slipstream.Color
    public let maxWidth: MaxWidth
    
    public enum MaxWidth: Sendable {
        case fourXL    // max-w-4xl (matches original)
        case sixXL     // max-w-6xl
        case full      // max-w-full
    }
    
    /// Creates an about section with title and content paragraphs.
    /// - Parameters:
    ///   - title: The section heading
    ///   - paragraphs: Array of paragraph content strings
    ///   - backgroundColor: Background color for the section (default: white)
    ///   - maxWidth: Maximum content width (default: 4xl)
    public init(
        title: String,
        paragraphs: [String],
        backgroundColor: Slipstream.Color = .white,
        maxWidth: MaxWidth = .fourXL
    ) {
        self.title = title
        self.paragraphs = paragraphs
        self.backgroundColor = backgroundColor
        self.maxWidth = maxWidth
    }
    
    @ViewBuilder private var paragraphViews: some View {
        // Handle up to 3 paragraphs directly for the 21.dev use case
        if paragraphs.count >= 1 {
            Div {
                Text(paragraphs[0])
            }
            .fontSize(.large)
            .textColor(.palette(.gray, darkness: 700))
        }
        if paragraphs.count >= 2 {
            Div {
                Text(paragraphs[1])
            }
            .fontSize(.large)
            .textColor(.palette(.gray, darkness: 700))
        }
        if paragraphs.count >= 3 {
            Div {
                Text(paragraphs[2])
            }
            .fontSize(.large)
            .textColor(.palette(.gray, darkness: 700))
        }
        // Add more if needed for future use cases
    }
    
    public var body: some View {
        Div {
            Div {
                VStack(spacing: 24) {
                    H2 {
                        Text(title)
                    }
                    .fontSize(.extraExtraExtraLarge)
                    .fontWeight(.bold)
                    .textColor(.palette(.gray, darkness: 900))
                    .margin(.bottom, 24)
                    
                    VStack(spacing: 16) {
                        paragraphViews
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.horizontal, 24, condition: Condition(startingAt: .small))
            .padding(.horizontal, 32, condition: Condition(startingAt: .large))
            // TODO: Missing Slipstream APIs - using ClassModifier for:
            // - max-w-* (max-width utilities)
            .modifier(ClassModifier(add: maxWidthClassName))
            .margin(.horizontal, .auto)
        }
        .padding(.vertical, 64)
        .background(backgroundColor)
    }
    
    private var maxWidthClassName: String {
        switch maxWidth {
        case .fourXL:
            "max-w-4xl"
        case .sixXL:
            "max-w-6xl"  
        case .full:
            "max-w-full"
        }
    }
}
