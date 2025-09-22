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
        logoText: "21.dev",
        navigationLinks: [
            NavigationLink(title: "Blog", href: "/blog/"),
            NavigationLink(title: "P256K", href: "/packages/p256k/"),
            NavigationLink(title: "Docs", href: "https://docs.21.dev/", isExternal: true)
        ]
    )
    
    /// Default site footer with company info, links, and social media
    public static let footer = SiteFooter(
        companyName: "21.dev",
        companyDescription: "Building the tools developers need for Bitcoin applications.",
        resourceLinks: [
            FooterLink(text: "Documentation", href: "https://docs.21.dev/", isExternal: true),
            FooterLink(text: "Blog", href: "/blog/"),
            FooterLink(text: "P256K", href: "/packages/p256k/"),
            FooterLink(text: "Donate", href: "/donate/")
        ],
        contactEmail: "hello@21.dev",
        licenseText: "Licensed under MIT",
        socialLinks: [
            SocialLink(url: "https://github.com/21-DOT-DEV", ariaLabel: "GitHub", icon: GitHubIcon()),
            SocialLink(url: "https://x.com/21_DOT_DEV", ariaLabel: "X (Twitter)", icon: TwitterIcon()),
            SocialLink(url: "https://njump.me/npub1...21dev", ariaLabel: "Nostr", icon: NostrIcon())
        ],
        copyrightText: "© 2025 21.dev. All rights reserved."
    )
}
