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
///     contactEmail: "hello@21.dev",
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
public struct SiteFooter: View {
    public let companyName: String
    public let companyDescription: String
    public let resourceLinks: [FooterLink]
    public let contactEmail: String?
    public let licenseText: String?
    public let socialLinks: [SocialLink]
    public let copyrightText: String
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
        backgroundColor: Slipstream.Color = .palette(.gray, darkness: 900)
    ) {
        self.companyName = companyName
        self.companyDescription = companyDescription
        self.resourceLinks = resourceLinks
        self.contactEmail = contactEmail
        self.licenseText = licenseText
        self.socialLinks = socialLinks
        self.copyrightText = copyrightText
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
                            .modifier(ClassModifier(add: "text-white"))
                        
                        Paragraph(companyDescription)
                            .modifier(ClassModifier(add: "text-gray-400"))
                    }
                    
                    // Resources column
                    Div {
                        H3("Resources")
                            .fontSize(.large)
                            .fontWeight(.semibold)
                            .margin(.bottom, 16)
                            .modifier(ClassModifier(add: "text-white"))
                        
                        // Use ForEach for type-safe resource link rendering
                        ForEach(resourceLinks, id: \.href) { (link: FooterLink) in
                            Link(link.text, destination: URL(string: link.href), openInNewTab: link.isExternal)
                                .modifier(ClassModifier(add: Set(["text-gray-400", "hover:text-white", "transition-colors", "block", "mb-2"])))
                        }
                    }
                    
                    // Contact column
                    Div {
                        H3("Contact")
                            .fontSize(.large)
                            .fontWeight(.semibold)
                            .margin(.bottom, 16)
                            .modifier(ClassModifier(add: "text-white"))
                        
                        if let email = contactEmail {
                            Paragraph {
                                Link(email, destination: URL(string: "mailto:\(email)"))
                                    .modifier(ClassModifier(add: "text-gray-400 hover:text-white transition-colors"))
                            }
                            .margin(.bottom, 8)
                        }
                        
                        if let license = licenseText {
                            Paragraph(license)
                                .fontSize(.small)
                                .modifier(ClassModifier(add: "text-gray-400"))
                        }
                    }
                    
                    // Social links column
                    Div {
                        H3("Follow Us")
                            .fontSize(.large)
                            .fontWeight(.semibold)
                            .margin(.bottom, 16)
                            .modifier(ClassModifier(add: "text-white"))
                        
                        // Use ForEach for type-safe social link rendering
                        ForEach(socialLinks, id: \.url) { socialLink in
                            SocialLinkView(socialLink: socialLink)
                        }
                    }
                }
                // TODO: Missing Slipstream API - using ClassModifier for grid layout
                .modifier(ClassModifier(add: "grid grid-cols-1 md:grid-cols-4 gap-8"))
                
                // Copyright section
                Div {
                    Paragraph(copyrightText)
                        .textAlignment(.center)
                        .modifier(ClassModifier(add: "text-gray-400"))
                }
                // TODO: Missing Slipstream API - using ClassModifier for border-t
                .modifier(ClassModifier(add: "border-t border-gray-800 mt-8 pt-8"))
            }
            .padding(.horizontal, 16) // px-4
            .padding(.horizontal, 24, condition: Condition(startingAt: .small)) // sm:px-6
            .padding(.horizontal, 32, condition: Condition(startingAt: .large)) // lg:px-8
            // TODO: Missing Slipstream API - using ClassModifier for max-width
            .modifier(ClassModifier(add: "max-w-6xl mx-auto"))
        }
        .padding(.vertical, 48) // py-12
        .modifier(ClassModifier(add: "bg-gray-900"))
    }
}

