//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A footer section with configurable company info, resources, contact details, and social links.
/// Provides a 4-column responsive layout with built-in social platform icons and custom SVG support.
/// Designed to be fully reusable across different sites and organizations.
///
/// Example usage:
/// ```swift
/// SiteFooter(
///     companyName: "21.dev",
///     companyDescription: "Building the tools developers need for Bitcoin applications.",
///     resourceLinks: [
///         FooterLink(text: "Documentation", href: "https://docs.21.dev", isExternal: true),
///         FooterLink(text: "Blog", href: "/blog")
///     ],
///     contactEmail: "hello@21.dev",  // Automatically obfuscated with RTL CSS
///     licenseText: "Licensed under MIT",
///     socialLinks: [
///         SocialLink(url: "https://github.com/21-dot-dev", ariaLabel: "GitHub", platform: .github),
///         SocialLink(url: "https://x.com/21dotdev", ariaLabel: "X (Twitter)", platform: .twitter)
///     ],
///     copyrightText: " 2025 21.dev. All rights reserved."
/// )
/// ```
///
/// ## Features
/// - **Responsive 4-column grid layout** using CSS Grid
/// - **Type-safe social platform icons** with built-in SVG paths
/// - **Custom SVG support** for unique social platforms
/// - **Accessibility-first** with proper ARIA labels and semantic HTML
/// - **Consistent styling** with hover states and transitions
/// - **External link handling** with automatic `target="_blank"` and `rel="noopener"`
public struct SiteFooter: View, StyleModifier {
    
    // MARK: - StyleModifier
    
    public var style: String {
        """
        /* Email obfuscation - displays RTL to deter scrapers */
        .email-obfuscated {
            unicode-bidi: bidi-override;
            direction: rtl;
        }
        """
    }
    
    public var componentName: String { "SiteFooter" }
    
    // MARK: - Properties
    
    public let companyName: String
    public let companyDescription: String
    public let resourceLinks: [FooterLink]
    public let contactEmail: String?
    public let licenseText: String?
    public let socialLinks: [SocialLink]
    public let copyrightText: String
    public let builtWithLogo: BuiltWithLogo?
    public let backgroundColor: Slipstream.Color
    
    /// Creates a footer with configurable sections and content.
    /// - Parameters:
    ///   - companyName: The company or organization name
    ///   - companyDescription: Brief description of the company/organization
    ///   - resourceLinks: Array of links for the Resources section
    ///   - contactEmail: Optional contact email address
    ///   - licenseText: Optional license information text
    ///   - socialLinks: Array of social media links with icons
    ///   - copyrightText: Copyright notice text
    ///   - backgroundColor: Background color for the footer (default: gray-900)
    public init(
        companyName: String,
        companyDescription: String,
        resourceLinks: [FooterLink] = [],
        contactEmail: String? = nil,
        licenseText: String? = nil,
        socialLinks: [SocialLink] = [],
        copyrightText: String,
        builtWithLogo: BuiltWithLogo? = nil,
        backgroundColor: Slipstream.Color = .palette(.gray, darkness: 900)
    ) {
        self.companyName = companyName
        self.companyDescription = companyDescription
        self.resourceLinks = resourceLinks
        self.contactEmail = contactEmail
        self.licenseText = licenseText
        self.socialLinks = socialLinks
        self.copyrightText = copyrightText
        self.builtWithLogo = builtWithLogo
        self.backgroundColor = backgroundColor
    }
    
    
    public var body: some View {
        Div {
            // Main footer content container
            Div {
                // 4-column grid layout
                Div {
                    // Company info column
                    Div {
                        H3(companyName)
                            .fontSize(.large)
                            .fontWeight(.semibold)
                            .margin(.bottom, 16)
                            .textColor(.white)
                        
                        Paragraph(companyDescription)
                            .textColor(.palette(.gray, darkness: 400))
                    }
                    
                    // Resources column
                    Div {
                        H3("Resources")
                            .fontSize(.large)
                            .fontWeight(.semibold)
                            .margin(.bottom, 16)
                            .textColor(.white)
                        
                        // Use ForEach for type-safe resource link rendering
                        ForEach(resourceLinks, id: \.href) { (link: FooterLink) in
                            Link(link.text, destination: URL(string: link.href), openInNewTab: link.isExternal)
                                .textColor(.palette(.gray, darkness: 400))
                                .display(.block)
                                .margin(.bottom, 8)
                                .transition(.colors)
                                .textColor(.white, condition: .hover)
                        }
                    }
                    
                    // Contact column
                    Div {
                        H3("Contact")
                            .fontSize(.large)
                            .fontWeight(.semibold)
                            .margin(.bottom, 16)
                            .textColor(.white)
                        
                        if let email = contactEmail {
                            Paragraph {
                                Link(URL(string: "mailto:\(email)")) {
                                    Span(String(email.reversed()))
                                        .modifier(ClassModifier(add: "email-obfuscated"))
                                }
                                .textColor(.palette(.gray, darkness: 400))
                                .transition(.colors)
                                .textColor(.white, condition: .hover)
                                .accessibilityLabel("Contact Us")
                            }
                            .margin(.bottom, 8)
                        }
                    }
                    
                    // Social links column
                    Div {
                        H3("Follow Us")
                            .fontSize(.large)
                            .fontWeight(.semibold)
                            .margin(.bottom, 16)
                            .textColor(.white)
                        
                        // Horizontal social links layout
                        Div {
                            ForEach(socialLinks, id: \.url) { socialLink in
                                SocialLinkView(socialLink: socialLink)
                            }
                        }
                        .display(.flex)
                        .flexGap(.x, width: 16)
                    }
                }
                // TODO: Missing Slipstream API - using ClassModifier for grid layout
                .modifier(ClassModifier(add: "grid grid-cols-1 md:grid-cols-4 gap-8"))
                
                // Copyright section with optional Built with Slipstream badge
                Div {
                    Paragraph(copyrightText + (licenseText.map { " | \($0)" } ?? ""))
                        .textColor(.palette(.gray, darkness: 400))
                    
                    if let logo = builtWithLogo {
                        Link(URL(string: logo.linkURL), openInNewTab: true) {
                            Image(URL(string: logo.imagePath))
                                .accessibilityLabel(logo.altText)
                                .modifier(AttributeModifier("width", value: "\(logo.width)"))
                                .modifier(AttributeModifier("height", value: "\(logo.height)"))
                                .modifier(ClassModifier(add: "h-8"))
                                .modifier(AttributeModifier("loading", value: "lazy"))
                        }
                    }
                }
                .display(.flex)
                .justifyContent(.between)
                .alignItems(.center)
                // TODO: Missing Slipstream API - using ClassModifier for border-t
                .modifier(ClassModifier(add: "border-t border-gray-800 mt-8 pt-8"))
            }
            .padding(.horizontal, 16) // px-4
            .padding(.horizontal, 24, condition: Condition(startingAt: .small)) // sm:px-6
            .padding(.horizontal, 32, condition: Condition(startingAt: .large)) // lg:px-8
            .frame(maxWidth: .sixXLarge)
            .margin(.horizontal, .auto)
        }
        .padding(.vertical, 48) // py-12
        .background(.palette(.gray, darkness: 900))
    }
}

