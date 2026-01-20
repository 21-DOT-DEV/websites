//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A featured package card component for highlighting packages and tools.
/// Provides flexible styling options while maintaining design consistency and future dark mode support.
public struct FeaturedPackageCard: View {
    public let title: String
    public let description: String
    public let ctaButton: CTAButton
    public let cardStyle: CardStyle
    public let backgroundColor: Slipstream.Color
    public let maxWidth: MaxWidth
    
    
    /// Creates a featured package card with configurable content and styling.
    /// - Parameters:
    ///   - title: The package/feature title
    ///   - description: Descriptive text explaining the package
    ///   - ctaButton: Call-to-action button configuration
    ///   - cardStyle: Visual style of the card (default: elevated)
    ///   - backgroundColor: Section background color (default: white)
    ///   - maxWidth: Maximum content width (default: 4xl)
    public init(
        title: String,
        description: String,
        ctaButton: CTAButton,
        cardStyle: CardStyle = .elevated,
        backgroundColor: Slipstream.Color = .palette(.gray, darkness: 50),
        maxWidth: MaxWidth = .fourXL
    ) {
        self.title = title
        self.description = description
        self.ctaButton = ctaButton
        self.cardStyle = cardStyle
        self.backgroundColor = backgroundColor
        self.maxWidth = maxWidth
    }
    
    public var body: some View {
        Div {
            Div {
                Div {
                    VStack(spacing: 32) {
                        H2 {
                            Text(title)
                        }
                        .fontSize(.extraExtraLarge) // text-2xl
                        .fontWeight(.bold)
                        .textColor(.palette(.gray, darkness: 900))
                        
                        Div {
                            Text(description)
                        }
                        .fontSize(.large)
                        .textColor(.palette(.gray, darkness: 700))
                        
                        CTAButtonView(button: ctaButton)
                    }
                    .alignItems(.start) // Left-align content within the card
                }
                .padding(.vertical, 48) // py-12 equivalent
                .padding(.horizontal, 32) // px-8 equivalent
                // TODO: Missing Slipstream APIs - using ClassModifier for:
                // - rounded corners (rounded-lg)
                // - card borders and backgrounds
                .modifier(ClassModifier(add: cardStyleClasses))
            }
            .padding(.horizontal, 16)
            .padding(.horizontal, 24, condition: Condition(startingAt: .small))
            .padding(.horizontal, 32, condition: Condition(startingAt: .large))
            // TODO: Missing Slipstream API - using ClassModifier for max-width constraint
            .modifier(ClassModifier(add: maxWidth.cssClass))
            .margin(.horizontal, .auto)
        }
        .padding(.vertical, 128) // py-32 equivalent for more section spacing
        .background(backgroundColor)
    }
    
    private var cardStyleClasses: String {
        switch cardStyle {
        case .elevated:
            return "bg-white border border-gray-200 rounded-lg"
        case .outlined:
            return "border border-gray-200 rounded-lg"
        case .filled:
            return "bg-gray-50 rounded-lg"
        }
    }
    
}
