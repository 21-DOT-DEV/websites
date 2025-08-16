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
/// Footer(
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
///     copyrightText: "2025 21.dev. All rights reserved."
/// )
/// ```
///
/// ## Missing Slipstream APIs Used
/// - `grid-cols-1 md:grid-cols-4` - Responsive grid layout
/// - SVG rendering and paths
/// - `border-t` - Top border styling
/// - Custom spacing and hover states
public struct Footer: View {
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
    
    private var resourceLinksHTML: String {
        resourceLinks.map { link in
            let target = link.isExternal ? " target=\"_blank\" rel=\"noopener\"" : ""
            return "<a href=\"\(link.href)\"\(target) class=\"text-gray-400 hover:text-white transition-colors block mb-2\">\(link.text)</a>"
        }.joined(separator: "")
    }
    
    private var socialLinksHTML: String {
        socialLinks.map { socialLink in
            let target = " target=\"_blank\" rel=\"noopener\""
            if let platform = socialLink.platform {
                if let displayText = platform.displayText {
                    return "<a href=\"\(socialLink.url)\"\(target) class=\"text-gray-400 hover:text-white transition-colors font-mono text-sm mb-3 block\" aria-label=\"\(socialLink.ariaLabel)\">\(displayText)</a>"
                } else if !platform.svgPath.isEmpty {
                    return "<a href=\"\(socialLink.url)\"\(target) class=\"text-gray-400 hover:text-white transition-colors mb-3 block\" aria-label=\"\(socialLink.ariaLabel)\"><svg class=\"w-6 h-6\" fill=\"currentColor\" viewBox=\"0 0 24 24\" aria-hidden=\"true\"><path d=\"\(platform.svgPath)\"/></svg></a>"
                }
            } else if let customSVG = socialLink.customSVG {
                return "<a href=\"\(socialLink.url)\"\(target) class=\"text-gray-400 hover:text-white transition-colors mb-3 block\" aria-label=\"\(socialLink.ariaLabel)\">\(customSVG)</a>"
            }
            return ""
        }.joined(separator: "")
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
                        
                        // TODO: Simplify for now - will enhance with proper loop handling
                        RawHTML(resourceLinksHTML)
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
                        
                        // TODO: Simplify for now - will enhance with proper loop handling  
                        RawHTML(socialLinksHTML)
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

/// Represents a footer navigation link.
public struct FooterLink: Sendable {
    public let text: String
    public let href: String
    public let isExternal: Bool
    
    public init(text: String, href: String, isExternal: Bool = false) {
        self.text = text
        self.href = href
        self.isExternal = isExternal
    }
}

/// Represents a social media link with built-in platform icons or custom SVG support.
public struct SocialLink: Sendable {
    public let url: String
    public let ariaLabel: String
    public let platform: SocialPlatform?
    public let customSVG: String?
    
    public init(url: String, ariaLabel: String, platform: SocialPlatform) {
        self.url = url
        self.ariaLabel = ariaLabel
        self.platform = platform
        self.customSVG = nil
    }
    
    public init(url: String, ariaLabel: String, customSVG: String) {
        self.url = url
        self.ariaLabel = ariaLabel
        self.platform = nil
        self.customSVG = customSVG
    }
}

/// Supported social media platforms with built-in SVG icons.
public enum SocialPlatform: Sendable {
    case github
    case twitter
    case nostr
    
    var svgPath: String {
        switch self {
        case .github:
            return "M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"
        case .twitter:
            return "M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"
        case .nostr:
            return "" // Nostr will use text fallback
        }
    }
    
    var displayText: String? {
        switch self {
        case .nostr:
            return "nostr"
        default:
            return nil
        }
    }
}

