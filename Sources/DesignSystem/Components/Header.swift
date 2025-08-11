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
                // Single flex container for logo, hamburger, and navigation (matches working example)
                HStack(alignment: .center, spacing: 0) {
                    // Logo/Site Title
                    Link(URL(string: "/")) {
                        Text(logoText)
                            // TODO: Missing Slipstream API for text-3xl (large typography)
                            .modifier(ClassModifier(add: "text-3xl"))
                            .fontWeight(.bold)
                            .textColor(.palette(.gray, darkness: 900))
                    }
                    
                    // Mobile Menu Toggle (visible only on mobile)
                    HeaderMobileToggleComplete()
                    
                    // Navigation Links (visible only on desktop, positioned to the right)
                    HeaderNavigationLinks(links: navigationLinks)
                }
                .justifyContent(.between) // justify-between
                .alignItems(.center)      // items-center
                .frame(width: .full)      // w-full
                .padding(.horizontal, 32)  // px-8 equivalent
                .padding(.vertical, 20)    // py-5 equivalent (consistent with working example)
                .frame(width: .full)       // w-full
            }
        }
        .frame(width: .full)
        .background(.white)
        .border(.palette(.gray, darkness: 200), width: 1, edges: .bottom)
        .position(.sticky)
        // TODO: Missing Slipstream APIs for z-index and backdrop effects
        .modifier(ClassModifier(add: "top-0 z-50 backdrop-blur-sm bg-opacity-90"))
    }
}

/// A mobile menu toggle component for header navigation.
/// 
/// DESIRED SLIPSTREAM INPUT/LABEL API:
/// This component should generate the following HTML structure for CSS-only mobile menu toggle:
/// 
/// ```html
/// <input type="checkbox" name="menu-toggle" id="menu-toggle" class="hidden">
/// <label for="menu-toggle" class="menu-button cursor-pointer text-3xl md:hidden">☰</label>
/// ```
/// 
/// PROPOSED SLIPSTREAM API:
/// ```swift
/// VStack {
///     Input()
///         .type(.checkbox)
///         .name("menu-toggle")
///         .id("menu-toggle")
///         .modifier(ClassModifier(add: "hidden"))
///     
///     Label {
///         Text("☰")
///             .fontSize(.extraLarge)
///             .textColor(.palette(.gray, darkness: 700))
///     }
///     .htmlFor("menu-toggle")
///     .modifier(ClassModifier(add: "menu-button cursor-pointer text-3xl md:hidden"))
/// }
/// ```
/// 
/// CURRENT IMPLEMENTATION: Placeholder until APIs are available
private struct HeaderMobileToggleComplete: View {
    var body: some View {
        // Placeholder implementation - shows hamburger icon but no toggle functionality
        Text("☰")
            // TODO: Missing Slipstream API for text-3xl and cursor styles  
            .modifier(ClassModifier(add: "text-3xl cursor-pointer")) // Match logo text-3xl size
            .textColor(.palette(.gray, darkness: 700))
            .hidden(condition: Condition(startingAt: .medium)) // md:hidden (only visible on mobile)
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
        .hidden() // hidden by default on mobile
        .display(.flex, condition: Condition(startingAt: .medium)) // md:flex (visible on desktop)
        .alignItems(.center) // Align with logo height
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
            
            .textColor(.palette(.orange, darkness: 500), condition: .hover)
            .transition(.colors)
            
            // TODO: Missing Slipstream API for accessibility attributes
            .modifier(ClassModifier(add: isActive ? "aria-current-page" : ""))
    }
}
