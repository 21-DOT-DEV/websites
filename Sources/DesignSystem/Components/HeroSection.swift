//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream


/// A hero section component with headline and call-to-action buttons.
/// Provides a prominent, centered layout with responsive design and modern styling.
/// Designed for landing pages and major content sections.
///
/// Example usage:
/// ```swift
/// HeroSection(
///     headline: "Welcome to Our Amazing Platform",
///     primaryButton: CTAButton(text: "Get Started", href: "https://example.com", isExternal: true),
///     secondaryButton: CTAButton(text: "Learn More", href: "/about", style: .secondary)
/// )
/// ```
public struct HeroSection: View {
    public let headline: String
    public let primaryButton: CTAButton?
    public let secondaryButton: CTAButton?
    public let backgroundColor: Slipstream.Color
    
    /// Creates a hero section with headline and optional call-to-action buttons.
    /// - Parameters:
    ///   - headline: The main headline text to display prominently
    ///   - primaryButton: Optional primary call-to-action button (typically orange)
    ///   - secondaryButton: Optional secondary call-to-action button (typically outline style)
    ///   - backgroundColor: Background color for the section (default: gray-50)
    public init(
        headline: String,
        primaryButton: CTAButton? = nil,
        secondaryButton: CTAButton? = nil,
        backgroundColor: Slipstream.Color = .palette(.gray, darkness: 50)
    ) {
        self.headline = headline
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.backgroundColor = backgroundColor
    }
    
    public var body: some View {
        // Full-width background container
        Div {
            // Full-width content area (no Container wrapper to remove width constraints)
            Div {
                VStack(spacing: 64) {
                    // Hero Headline - centered within full browser width
                    H1 {
                        Text(headline)
                    }
                    .fontSize(.fourXLarge) // Base: text-4xl
                    .fontSize(.sixXLarge, condition: Condition(startingAt: .medium)) // md:text-6xl
                    .fontWeight(.bold)
                    .textColor(.palette(.gray, darkness: 900))
                    .textAlignment(.center)
                    
                    // Call-to-Action Buttons - centered group
                    if primaryButton != nil || secondaryButton != nil {
                        CTAButtonGroup(
                            primaryButton: primaryButton,
                            secondaryButton: secondaryButton
                        )
                    }
                }
            }
            .textAlignment(.center)
            .padding(.horizontal, 24)  // px-6
            .padding(.bottom, 128)      // Add bottom padding to push content higher than exact center
            .frame(width: .full)
            .display(.flex)
            .flexDirection(.y)
            .alignItems(.center)
            .justifyContent(.center)   // Center content vertically within full viewport height
            // TODO: Missing Slipstream API for min-height: 100vh on flex items
            .modifier(ClassModifier(add: "min-h-screen"))
        }
        .background(backgroundColor)
        .frame(width: .full)
        .frame(minHeight: .screen) // Ensure at least full viewport height (100vh)
    }
}

