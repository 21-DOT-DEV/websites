//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem

/// Centralized site configuration with shared header and footer defaults
public struct SiteDefaults {
    
    /// Favicon configuration with cache-busting version string
    public static let faviconConfig = FaviconConfig(version: "20260413", appTitle: SiteIdentity.name, themeColor: "#ffffff")
    
    /// Absolute URL of the default Open Graph share image.
    private static let ogImageURL = "\(SiteIdentity.url)images/og-image.png"
    
    /// Creates an Open Graph configuration with site-wide defaults.
    ///
    /// `og:description` is auto-populated by `BasePage` from its own `description`
    /// when `openGraph.description` is nil, so it is not needed here.
    ///
    /// - Parameters:
    ///   - title: The page title for `og:title`.
    ///   - type: The OG object type (defaults to `.website`).
    ///   - url: The absolute canonical URL for `og:url`.
    static func openGraphConfig(
        title: String,
        type: OpenGraphConfig.OGType = .website,
        url: String
    ) -> OpenGraphConfig {
        OpenGraphConfig(
            title: title,
            type: type,
            url: url,
            siteName: SiteIdentity.name,
            twitterCard: "summary_large_image",
            twitterSite: SiteIdentity.twitterHandle,
            image: ogImageURL,
            imageWidth: 1200,
            imageHeight: 600,
            imageAlt: "21.dev — Open-source tools for Bitcoin developers"
        )
    }
    
    /// Default site header with logo and navigation links
    public static let header = SiteHeader(
        logoText: SiteIdentity.name,
        navigationLinks: [
            NavigationLink(title: "Blog", href: "/blog/"),
            NavigationLink(title: "P256K", href: "/packages/p256k/"),
            NavigationLink(title: "Docs", href: SiteIdentity.p256kDocsURL, isExternal: true)
        ]
    )
    
    /// Default site footer with company info, links, and social media
    public static let footer = SiteFooter(
        companyName: SiteIdentity.name,
        companyDescription: "Equipping developers with the tools they need today to build the Bitcoin apps of tomorrow.",
        resourceLinks: [
            FooterLink(text: "Documentation", href: SiteIdentity.docsBaseURL + "documentation/", isExternal: true),
            FooterLink(text: "Blog", href: "/blog/"),
            FooterLink(text: "P256K", href: "/packages/p256k/"),
            FooterLink(text: "Swift Package Index", href: SiteIdentity.spiURL, isExternal: true)
        ],
        contactEmail: SiteIdentity.contactEmail,
        licenseText: "Licensed under MIT",
        socialLinks: [
            SocialLink(url: SiteIdentity.githubURL, ariaLabel: "GitHub", icon: GitHubIcon()),
            SocialLink(url: SiteIdentity.twitterURL, ariaLabel: "X (Twitter)", icon: TwitterIcon()),
            SocialLink(url: SiteIdentity.nostrURL, ariaLabel: "Nostr", icon: NostrIcon())
        ],
        copyrightText: "© 2026 \(SiteIdentity.legalName) All rights reserved.",
        builtWithLogo: BuiltWithLogo(
            imagePath: "/svg/built-with-slipstream.svg",
            linkURL: SiteIdentity.slipstreamRepoURL,
            altText: "Built with Slipstream",
            width: 350,
            height: 100
        )
    )
}
