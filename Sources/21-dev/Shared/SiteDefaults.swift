//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem

/// Centralized site configuration with shared header and footer defaults
public struct SiteDefaults {
    
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
        copyrightText: "© 2026 \(SiteIdentity.name). All rights reserved.",
        builtWithLogo: BuiltWithLogo(
            imagePath: "/svg/built-with-slipstream.svg",
            linkURL: SiteIdentity.slipstreamRepoURL,
            altText: "Built with Slipstream"
        )
    )
}
