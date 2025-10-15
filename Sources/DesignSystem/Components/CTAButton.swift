//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream


/// A container component for rendering multiple call-to-action buttons.
/// Handles responsive layout and proper button spacing.
public struct CTAButtonGroup: View {
    let primaryButton: CTAButton?
    let secondaryButton: CTAButton?
    
    public init(primaryButton: CTAButton?, secondaryButton: CTAButton?) {
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
    
    public var body: some View {
        Div {
            // Primary Button
            if let primary = primaryButton {
                CTAButtonView(button: primary)
            }
            
            // Secondary Button
            if let secondary = secondaryButton {
                CTAButtonView(button: secondary)
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

/// A call-to-action button view component.
/// Handles different button styles and interactive states.
public struct CTAButtonView: View {
    let button: CTAButton
    
    public init(button: CTAButton) {
        self.button = button
    }
    
    public var body: some View {
        Link(button.text, destination: URL(string: button.href), openInNewTab: button.isExternal)
            .padding(.horizontal, 32) // px-8
            .padding(.vertical, 12)   // py-3
            .fontWeight(.semibold)
            .textAlignment(.center)
            // TODO: Missing Slipstream APIs - using ClassModifier for:
            // - hover states (hover:bg-orange-600, hover:border-gray-400)
            // - focus rings (focus:ring-2 focus:ring-orange-500 focus:ring-offset-2)
            // - transition-colors
            // - white-space: nowrap (prevent text wrapping)
            .modifier(ClassModifier(add: buttonClasses + " whitespace-nowrap"))
            .transition(.colors) // Using official Slipstream API
            .frame(width: 208, height: 48) // w-52 h-12 (208px = 52*4, 48px = 12*4)
            .display(.flex)
            .alignItems(.center)
            .justifyContent(.center)
    }
    
    private var buttonClasses: String {
        return button.style.cssClasses
    }
}
