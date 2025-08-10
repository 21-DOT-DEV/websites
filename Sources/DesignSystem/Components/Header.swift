//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A generic navigation link for header components.
/// Handles both internal and external links with proper accessibility.
public struct NavigationLink: Sendable {
    public let title: String
    public let href: String
    public let isExternal: Bool
    
    public init(title: String, href: String, isExternal: Bool = false) {
        self.title = title
        self.href = href
        self.isExternal = isExternal
    }
}

/// A responsive header component with configurable branding and navigation links.
/// Provides sticky positioning with backdrop blur for modern web design.
/// Basic version includes logo and navigation - interactive features to be added later.
///
/// Example usage:
/// ```swift
/// Header(
///     logoText: "My Site", 
///     navigationLinks: [
///         NavigationLink(title: "Home", href: "/"),
///         NavigationLink(title: "About", href: "/about"),
///         NavigationLink(title: "Docs", href: "https://docs.example.com", isExternal: true)
///     ]
/// )
/// ```
///
/// ## Missing Slipstream APIs Used
/// - `hover:opacity-80 transition-opacity` - Interactive hover states for logo
/// - `hidden md:flex` - Responsive visibility controls for navigation
/// - `sticky top-0 z-50 backdrop-blur-sm bg-opacity-90` - Fixed positioning with backdrop effects
public struct Header: View {
    public let logoText: String
    public let navigationLinks: [NavigationLink]
    
    /// Creates a header with configurable branding and navigation links.
    /// - Parameters:
    ///   - logoText: The text to display as the site logo/title
    ///   - navigationLinks: Array of navigation links to display
    public init(logoText: String, navigationLinks: [NavigationLink]) {
        self.logoText = logoText
        self.navigationLinks = navigationLinks
    }
    
    public var body: some View {
        Div {
            Container {
                HStack(alignment: .center, spacing: 32) {
                    // Logo/Site Title
                    Link(URL(string: "/")) {
                        Text(logoText)
                            .fontSize(.extraExtraLarge)
                            .fontWeight(.bold)
                            .textColor(.palette(.gray, darkness: 900))
                            
                            // TODO: Need Slipstream API for interactive hover states
                            // MISSING APIs: .hover(.opacity(0.8)), .transition(.opacity)
                            // Issue: Slipstream v2.0 lacks pseudo-state modifier support
                            // ClassModifier used for: hover:opacity-80 transition-opacity
                            .modifier(ClassModifier(add: "hover:opacity-80 transition-opacity"))
                    }
                    
                    Div { /* Spacer */ }
                        // TODO: Need Slipstream API for flex-grow
                        // MISSING APIs: .flexGrow(1) or .flex(.grow)
                        // ClassModifier used for: flex-1
                        .modifier(ClassModifier(add: "flex-1"))
                    
                    // Navigation Links
                    HeaderNavigationLinks(links: navigationLinks)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .padding(.horizontal, 24, condition: Condition(startingAt: .medium))
                .padding(.horizontal, 32, condition: Condition(startingAt: .large))
            }
        }
        // TODO: Need Slipstream API for full width
        // MISSING APIs: .frame(width: .full) or .width(.full)
        // ClassModifier used for: w-full to ensure header spans browser width
        .modifier(ClassModifier(add: "w-full"))
        .background(.white)
        .border(.palette(.gray, darkness: 200), width: 1, edges: .bottom)
        
        // TODO: Need Slipstream API for positioning, z-index, and backdrop effects
        // MISSING APIs: .position(.sticky, top: 0), .zIndex(50), .backdropBlur(.small), .backgroundOpacity(0.9)
        // Issue: Complex positioning and backdrop effects not available in Slipstream
        // ClassModifier used for: sticky top-0 z-50 backdrop-blur-sm bg-opacity-90
        .modifier(ClassModifier(add: "sticky top-0 z-50 backdrop-blur-sm bg-opacity-90"))
    }
}

/// A container component for rendering navigation links in the header.
/// Handles responsive visibility and spacing for multiple navigation items.
private struct HeaderNavigationLinks: View {
    let links: [NavigationLink]
    
    init(links: [NavigationLink]) {
        self.links = links
    }
    
    var body: some View {
        HStack(spacing: 32) {
            // Render all navigation links dynamically
            // First link is automatically marked as active, others are inactive
            for (index, link) in links.enumerated() {
                HeaderNavigationLink(
                    title: link.title,
                    href: link.href,
                    isActive: index == 0, // First link is active
                    isExternal: link.isExternal
                )
            }
        }
        // TODO: Need Slipstream API for responsive visibility
        // MISSING APIs: .display(.hidden, condition: .belowMedium), .display(.flex, condition: .mediumAndAbove)
        // ClassModifier used for: hidden md:flex
        .modifier(ClassModifier(add: "hidden md:flex"))
    }
}

/// A navigation link component for the header.
/// Handles both internal and external links with proper styling.
private struct HeaderNavigationLink: View {
    let title: String
    let href: String
    let isActive: Bool
    let isExternal: Bool
    
    init(title: String, href: String, isActive: Bool = false, isExternal: Bool = false) {
        self.title = title
        self.href = href
        self.isActive = isActive
        self.isExternal = isExternal
    }
    
    var body: some View {
        Link(title, destination: URL(string: href), openInNewTab: isExternal)
            .textColor(.palette(.gray, darkness: 700))
            .fontWeight(.medium)
            
            // TODO: Need Slipstream API for hover color states and transitions
            // MISSING APIs: .hover(.textColor(.palette(.orange, darkness: 500))), .transition(.colors)
            // Issue: Interactive pseudo-states and transition effects not available
            // ClassModifier used for: hover:text-orange-500 transition-colors
            .modifier(ClassModifier(add: "hover:text-orange-500 transition-colors"))
            
            // TODO: Need Slipstream API for accessibility attributes
            // MISSING APIs: .accessibilityLabel(), .ariaCurrent()
            // ClassModifier used for: aria-current="page" attribute
            .modifier(ClassModifier(add: isActive ? "aria-current-page" : ""))
    }
}
