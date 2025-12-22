//
//  Homepage.swift
//  21-DOT-DEV/Homepage.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem

struct Homepage {
    
    static var page: some View {
        BasePage(
            title: "21.dev - Bitcoin Development Tools",
            canonicalURL: URL(string: "https://21.dev/")
        ) {
            SiteDefaults.header

            HeroSection(
                headline: "Equipping developers with the tools they need today to build the Bitcoin apps of tomorrow. 📱",
                primaryButton: CTAButton(
                    text: "Get Started",
                    href: "https://docs.21.dev/documentation/p256k/",
                    style: .primary,
                    isExternal: true
                ),
                secondaryButton: CTAButton(
                    text: "View on GitHub",
                    href: "https://github.com/21-DOT-DEV",
                    style: .secondary,
                    isExternal: true
                )
            )
            AboutSection(
                title: "What is 21.dev?",
                paragraphs: [
                    "21.dev is a organization dedicated to empowering developers with high-quality, open-source tools for building Bitcoin applications. We focus on creating robust software packages and libraries that make Bitcoin development more accessible and efficient for developers across multiple platforms.",
                    "Our mission is to accelerate Bitcoin adoption by providing developers with the foundational tools they need to build and maintainsecure, scalable Bitcoin applications. From cryptographic primitives to high-level APIs, we're building the infrastructure that powers the next generation of Bitcoin apps.",
                    "All of our work is open source, community-driven, and designed with developer experience as the top priority. It is our fundamental belief that better tools lead to better applications, which in turn benefits the entire Bitcoin ecosystem."
                ]
            )
            FeaturedPackageCard(
                title: "Featured Package: P256K",
                description: "Enhance your Swift development for Bitcoin apps with seamless secp256k1 integration. P256K provides a clean, efficient Swift interface to Bitcoin's elliptic curve cryptography.",
                ctaButton: CTAButton(
                    text: "Build with P256K →",
                    href: "https://github.com/21-DOT-DEV/swift-secp256k1",
                    style: .primary,
                    isExternal: true
                )
            )

            SiteDefaults.footer
        }
    }
}
