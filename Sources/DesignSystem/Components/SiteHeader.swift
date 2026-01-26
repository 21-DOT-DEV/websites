//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream


/// A responsive header component with configurable branding and navigation links.
/// 
/// Provides sticky positioning with backdrop blur for modern web design.
/// The header automatically adapts between mobile and desktop layouts,
/// showing a hamburger menu on mobile devices and full navigation on larger screens.
/// 
/// ## Features
/// - Responsive design with mobile-first approach
/// - Sticky positioning with backdrop blur effects
/// - Accessible hamburger menu for mobile navigation
/// - Support for external links with proper `target="_blank"` handling
/// - Consistent vertical rhythm using the same padding approach as working examples
/// 
/// ## Usage
/// ```swift
/// SiteHeader(
///     logoText: "My Site", 
///     navigationLinks: [
///         NavigationLink(title: "Home", href: "/"),
///         NavigationLink(title: "About", href: "/about"),
///         NavigationLink(title: "Docs", href: "https://docs.example.com", isExternal: true)
///     ]
/// )
/// ```
/// 
/// ## Implementation Notes
/// This component maximizes the use of Slipstream's type-safe APIs while maintaining
/// the exact CSS class ordering for visual consistency. Missing Slipstream APIs are
/// documented and use `ClassModifier` as a temporary solution.
/// 
/// ## Missing Slipstream APIs
/// The following CSS features require `ClassModifier` until Slipstream adds native support:
/// - `flex-grow` - Flex grow properties
/// - `menu-button`, `menu-items` - Custom classes for CSS toggle functionality
/// - `aria-current-page` - Conditional accessibility attribute
public struct SiteHeader: View, StyleModifier {
    /// The text to display as the site logo/title
    public let logoText: String
    /// Array of navigation links to display in the header
    public let navigationLinks: [NavigationLink]
    
    /// Creates a header with configurable branding and navigation links.
    /// - Parameters:
    ///   - logoText: The text to display as the site logo/title
    ///   - navigationLinks: Array of navigation links to display
    public init(logoText: String, navigationLinks: [NavigationLink]) {
        self.logoText = logoText
        self.navigationLinks = navigationLinks
    }
    
    // Instance-based CSS generation for mobile menu functionality
    public var style: String {
        return """
        /* SiteHeader Mobile Menu Styles */
        @media (max-width: 767px) {
            .menu-button {
                background: none;
            }
            .menu-items {
                display: none;
            }

            div:has(#menu-toggle:checked) ~ .menu-items {
                display: flex;
            }
        }
        """
    }
    
    public var componentName: String {
        return "SiteHeader"
    }
    
    public var body: some View {
        Header {
            Section {
                Div {
                    // Logo and hamburger container (matches working example: flex justify-between items-center flex-row)
                    Div {
                        // Logo/Site Title
                        SiteHeaderLogoTitle(logoText: logoText)
                        // Mobile Menu Toggle
                        SiteHeaderMobileToggle()
                    }
                    .display(.flex)                     // flex
                    .justifyContent(.between)   // justify-between
                    .alignItems(.center)        // items-center
                    .flexDirection(.x)          // flex-row

                    // Navigation Links (matches working example navigation structure)
                    HeaderNavigationLinks(links: navigationLinks)
                }
                .display(.flex)                         // flex
                .padding(.horizontal, 32)               // px-8 equivalent (8 * 4 = 32pt)
                .flexDirection(.y)                      // flex-col
                .flexDirection(.x, condition: .startingAt(.medium)) // md:flex-row
                .alignItems(.center, condition: .startingAt(.medium)) // md:items-center
                .justifyContent(.between, condition: .startingAt(.medium)) // md:justify-between
                .padding(.horizontal, 48, condition: .startingAt(.medium)) // md:px-12
                .margin(.horizontal, .auto)                // mx-auto
                .padding(.vertical, 20)                 // py-5 equivalent (5 * 4 = 20pt)
                .position(.relative)                    // relative
                .frame(width: .full) // w-full
            }
            .frame(maxWidth: .fourXLarge)               // max-w-4xl
            .margin(.horizontal, .auto)                 // mx-auto
            .padding(.all, 16)                          // p-4 equivalent (4 * 4 = 16pt)
            .display(.flex)                             // flex
            .flexDirection(.x, condition: .startingAt(.medium)) // md:flex-row
            .justifyContent(.between)                   // justify-between
        }
        .background(Color.white.opacity(0.9))      // bg-white bg-opacity-90
        .border(Color(.gray, darkness: 200), width: 1, edges: [.bottom]) // border-b border-gray-200
        .position(.sticky)                          // sticky
        .placement(top: 0)                          // top-0
        .background(.ultraThin)                     // backdrop-blur-sm
        .zIndex(50)
    }
}

/// The logo/title component for the site header.
/// 
/// Renders the site logo with a link to the homepage.
/// Uses large typography for visual hierarchy while avoiding duplicate H1 tags for SEO.
private struct SiteHeaderLogoTitle: View {
    /// The text to display as the logo/title
    let logoText: String
    
    /// Creates a logo/title component.
    /// - Parameter logoText: The text to display as the logo/title
    init(logoText: String) {
        self.logoText = logoText
    }
    
    var body: some View {
        Div {
            Link(URL(string: "/")) {
                Text(logoText)
                    .fontSize(.extraExtraExtraLarge)       // text-3xl
                    .fontWeight(.bold)
                    .textColor(.palette(.gray, darkness: 900))
            }
        }
        .fontSize(.extraExtraExtraLarge)                   // text-3xl
        .fontWeight(.medium)
    }
}

/// The mobile hamburger menu toggle component.
/// 
/// Provides a checkbox-based toggle mechanism for mobile navigation.
/// Uses a hamburger icon (☰) and is hidden on medium+ screen sizes.
/// The toggle works through CSS-only interactions for better performance.
private struct SiteHeaderMobileToggle: View {
    var body: some View {
        Checkbox(name: "menu-toggle", id: "menu-toggle")
            .hidden()                               // hidden
        Label("☰", for: "menu-toggle")
            .pointerStyle(.pointer)
            .modifier(ClassModifier(add: "menu-button"))
            .fontSize(.extraExtraExtraLarge)                // text-3xl
            .hidden(condition: .startingAt(.medium))
    }
}

/// A container component for rendering navigation links in the header.
/// 
/// Handles responsive visibility and spacing for multiple navigation items.
/// On mobile, links are hidden by default and revealed via the hamburger toggle.
/// On desktop, links are displayed horizontally with proper spacing.
/// 
/// The component uses CSS flexbox for layout and includes proper mobile menu behavior
/// through the `menu-items` class that works with the hamburger toggle.
private struct HeaderNavigationLinks: View {
    /// The navigation links to render
    let links: [NavigationLink]
    
    /// Creates a navigation links container.
    /// - Parameter links: The navigation links to render
    init(links: [NavigationLink]) {
        self.links = links
    }
    
    var body: some View {
        Navigation {
            // Use ForEach for type-safe navigation link rendering
            ForEach(links, id: \.href) { (link: NavigationLink) in
                HeaderNavigationLink(
                    title: link.title,
                    href: link.href,
                    isActive: link.href == links.first?.href, // First link is active
                    isExternal: link.isExternal
                )
            }
        }
        // TODO: Missing Slipstream APIs - using ClassModifier for:
        // - menu-items (custom class for mobile toggle functionality)
        .modifier(ClassModifier(add: "menu-items"))
        .flexDirection(.y)                              // flex-col
        // TODO: Missing Slipstream APIs - using ClassModifier for:
        // - flex-grow (flex grow)
        .modifier(ClassModifier(add: "flex-grow"))
        .alignItems(.center)                            // items-center
        .hidden()                                   // hidden
        .display(.flex, condition: .startingAt(.medium)) // md:flex
        .flexDirection(.x, condition: .startingAt(.medium)) // md:flex-row
        .justifyContent(.end, condition: .startingAt(.medium)) // md:justify-end
        .padding(.bottom, 0, condition: .startingAt(.medium)) // md:pb-0
    }
}

/// A navigation link component for the header.
/// 
/// Handles both internal and external links with proper styling and responsive behavior.
/// Links adapt their display and padding based on screen size, showing as block elements
/// on mobile and inline-block on desktop with increased horizontal padding.
/// 
/// ## Features
/// - Responsive padding that increases on larger screens
/// - Hover effects with color transitions
/// - Active state indication with `aria-current-page`
/// - Proper handling of external links
private struct HeaderNavigationLink: View {
    /// The display text for the link
    let title: String
    /// The URL or path the link points to
    let href: String
    /// Whether this link represents the currently active page
    let isActive: Bool
    /// Whether this link points to an external domain
    let isExternal: Bool
    
    /// Creates a navigation link component.
    /// - Parameters:
    ///   - title: The display text for the link
    ///   - href: The URL or path the link points to
    ///   - isActive: Whether this link represents the currently active page (defaults to false)
    ///   - isExternal: Whether this link points to an external domain (defaults to false)
    init(title: String, href: String, isActive: Bool = false, isExternal: Bool = false) {
        self.title = title
        self.href = href
        self.isActive = isActive
        self.isExternal = isExternal
    }
    
    var body: some View {
        Link(title, destination: URL(string: href), openInNewTab: isExternal)
            .display(.block)                            // block
            .display(.inlineBlock, condition: .startingAt(.medium)) // md:inline-block
            .padding(.horizontal, 12, condition: .startingAt(.medium)) // md:px-3 (3 * 4 = 12pt)
            .padding(.horizontal, 24, condition: .startingAt(.large)) // lg:px-6 (6 * 4 = 24pt)
            .padding(.horizontal, 8)                    // px-2 equivalent (2 * 4 = 8pt)
            .padding(.vertical, 8)                      // py-2 equivalent (2 * 4 = 8pt)
            .fontSize(.small)                       // text-sm
            .textColor(.palette(.gray, darkness: 700))  // text-gray-700
            .fontWeight(.medium)                        // font-medium
            .textColor(.palette(.orange, darkness: 500), condition: .hover)
            .transition(.colors)
            .modifier(ClassModifier(add: isActive ? ["aria-current-page"] : []))
    }
}
