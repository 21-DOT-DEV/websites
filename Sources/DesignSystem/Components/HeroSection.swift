//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A call-to-action button for hero sections.
/// Handles both internal and external links with proper styling options.
public struct HeroCTAButton: Sendable {
    public let text: String
    public let href: String
    public let style: ButtonStyle
    public let isExternal: Bool
    
    public enum ButtonStyle: Sendable {
        case primary   // Orange background, white text
        case secondary // Gray border, gray text
    }
    
    public init(text: String, href: String, style: ButtonStyle = .primary, isExternal: Bool = false) {
        self.text = text
        self.href = href
        self.style = style
        self.isExternal = isExternal
    }
}

/// A hero section component with headline and call-to-action buttons.
/// Provides a prominent, centered layout with responsive design and modern styling.
/// Designed for landing pages and major content sections.
///
/// Example usage:
/// ```swift
/// HeroSection(
///     headline: "Welcome to Our Amazing Platform",
///     primaryButton: HeroCTAButton(text: "Get Started", href: "https://example.com", isExternal: true),
///     secondaryButton: HeroCTAButton(text: "Learn More", href: "/about", style: .secondary)
/// )
/// ```
///
/// ## Missing Slipstream APIs Used
/// - `hover:bg-orange-600` - Button hover state colors
/// - `focus:ring-2 focus:ring-orange-500 focus:ring-offset-2` - Focus ring styling
/// - `transition-colors` - Color transition animations
/// - `hover:border-gray-400` - Border hover states
public struct HeroSection: View {
    public let headline: String
    public let primaryButton: HeroCTAButton?
    public let secondaryButton: HeroCTAButton?
    public let backgroundColor: Slipstream.Color
    
    /// Creates a hero section with headline and optional call-to-action buttons.
    /// - Parameters:
    ///   - headline: The main headline text to display prominently
    ///   - primaryButton: Optional primary call-to-action button (typically orange)
    ///   - secondaryButton: Optional secondary call-to-action button (typically outline style)
    ///   - backgroundColor: Background color for the section (default: gray-50)
    public init(
        headline: String,
        primaryButton: HeroCTAButton? = nil,
        secondaryButton: HeroCTAButton? = nil,
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
                        HeroCTAButtons(
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

/// A container component for rendering call-to-action buttons in hero sections.
/// Handles responsive layout and proper button spacing.
private struct HeroCTAButtons: View {
    let primaryButton: HeroCTAButton?
    let secondaryButton: HeroCTAButton?
    
    init(primaryButton: HeroCTAButton?, secondaryButton: HeroCTAButton?) {
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
    
    var body: some View {
        Div {
            // Primary Button
            if let primary = primaryButton {
                HeroCTAButtonView(button: primary)
            }
            
            // Secondary Button
            if let secondary = secondaryButton {
                HeroCTAButtonView(button: secondary)
            }
        }
        .display(.flex)
        .flexDirection(.y) // flex-col (mobile first - vertical stacking)
        .flexDirection(.x, condition: Condition(startingAt: .medium)) // md:flex-row (horizontal on desktop)
        .flexGap(.y, width: 16) // gap-4 vertical spacing for mobile stacking
        .flexGap(.x, width: 16, condition: Condition(startingAt: .medium)) // gap-4 horizontal spacing on desktop
        .justifyContent(.center)
        .alignItems(.center)
        .frame(width: .full)
    }
}

/// A call-to-action button component for hero sections.
/// Handles different button styles and interactive states.
private struct HeroCTAButtonView: View {
    let button: HeroCTAButton
    
    init(button: HeroCTAButton) {
        self.button = button
    }
    
    var body: some View {
        Link(button.text, destination: URL(string: button.href), openInNewTab: button.isExternal)
            .padding(.horizontal, 32) // px-8
            .padding(.vertical, 12)   // py-3
            .fontWeight(.semibold)
            .textAlignment(.center)
            // TODO: Missing Slipstream APIs for hover states and focus rings
            .modifier(ClassModifier(add: buttonClasses))
            .transition(.colors) // Using official Slipstream API
            .frame(width: 208, height: 48) // w-52 h-12 (208px = 52*4, 48px = 12*4)
            .display(.flex)
            .alignItems(.center)
            .justifyContent(.center)
    }
    
    private var buttonClasses: String {
        switch button.style {
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
