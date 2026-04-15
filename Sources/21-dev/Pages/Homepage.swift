//
//  Homepage.swift
//  21-DOT-DEV/Homepage.swift
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem
import SchemaLib

struct Homepage {
    // Page metadata
    private static let pageTitle = "Build Bitcoin Apps in Swift with Open-Source Tools | 21.dev"
    private static let pageDescription = "Build Bitcoin apps in Swift with 21.dev—open-source libsecp256k1 wrapper, SPM tools, and docs to ship faster."
    
    static var page: some View {
        BasePage(
            title: pageTitle,
            description: pageDescription,
            canonicalURL: URL(string: SiteIdentity.url),
            schemas: [
                SiteIdentity.websiteSchema,
                SiteIdentity.organizationSchema,
                SiteIdentity.webPageSchema(
                    url: SiteIdentity.url,
                    name: pageTitle,
                    description: pageDescription
                )
            ],
            favicon: SiteDefaults.faviconConfig,
            openGraph: SiteDefaults.openGraphConfig(
                title: pageTitle,
                url: SiteIdentity.url
            ),
            llmsTxtURL: SiteIdentity.llmsTxtURL
        ) {
            SiteDefaults.header

            HeroSection(
                headline: "Equipping developers with the tools they need today to build the Bitcoin apps of tomorrow. 📱",
                primaryButton: CTAButton(
                    text: "Get Started",
                    href: SiteIdentity.p256kDocsURL,
                    style: .primary,
                    isExternal: true
                ),
                secondaryButton: CTAButton(
                    text: "View on GitHub",
                    href: SiteIdentity.githubURL,
                    style: .secondary,
                    isExternal: true
                )
            )
            AboutSection(
                title: "What is 21.dev?",
                paragraphs: [
                    "21.dev is an organization dedicated to empowering developers with high-quality, open-source tools for building Bitcoin applications. We focus on creating robust software packages and libraries that make Bitcoin development more accessible and efficient for developers across multiple platforms.",
                    "Our mission is to accelerate Bitcoin adoption by providing developers with the foundational tools they need to build and maintain secure, scalable Bitcoin applications. From cryptographic primitives to high-level APIs, we're building the infrastructure that powers the next generation of Bitcoin apps.",
                    "All of our work is open source, community-driven, and designed with developer experience as the top priority. It is our fundamental belief that better tools lead to better applications, which in turn benefits the entire Bitcoin ecosystem."
                ]
            )
            FeaturedPackageCard(
                title: "Featured Package: P256K",
                description: "Enhance your Swift development for Bitcoin apps with seamless secp256k1 integration. P256K provides a clean, efficient Swift interface to Bitcoin's elliptic curve cryptography.",
                ctaButton: CTAButton(
                    text: "Build with P256K →",
                    href: "/packages/p256k/",
                    style: .primary,
                    isExternal: false
                )
            )

            SiteDefaults.footer
        }
    }
}
