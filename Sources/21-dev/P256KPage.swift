//
//  P256KPage.swift
//  21-DOT-DEV/P256KPage.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem

struct P256KPage {
    // Static component instances for CSS generation and page content
    static let codeHeroSection = CodeHeroSection(
        icon: "🔏",
        title: "P256K",
        headline: "Efficient P-256 cryptography for Swift",
        description: "A high-performance, security-focused P-256 elliptic curve implementation built specifically for Swift developers. Optimized for speed without compromising cryptographic integrity.",
        sponsorText: "Supported by",
        sponsorLogos: [.geyser, .openSats],
        ctaButton: CTAButton(
            text: "Get Started",
            href: "https://github.com/21-dev/p256k",
            style: .primary,
            isExternal: true
        ),
        codeBlock: .tabbed(TabbedCodeBlock(tabs: [
            CodeTab(
                title: "ECDSA",
                codeLines: [
                    CodeLine(text: "import P256K", style: .normal, highlights: [
                        CodeHighlight(text: "import", style: .keyword)
                    ]),
                    CodeLine(text: "", style: .normal),
                    CodeLine(text: "// Create ECDSA keypair", style: .comment),
                    CodeLine(text: "let priv = try! P256K.Signing.PrivateKey()", style: .normal, highlights: [
                        CodeHighlight(text: "let", style: .keyword),
                        CodeHighlight(text: "try", style: .keyword),
                        CodeHighlight(text: "Signing", style: .type),
                        CodeHighlight(text: "PrivateKey", style: .type)
                    ]),
                    CodeLine(text: "let pub = priv.publicKey", style: .normal, highlights: [
                        CodeHighlight(text: "let", style: .keyword),
                        CodeHighlight(text: "publicKey", style: .property)
                    ]),
                    CodeLine(text: "", style: .normal),
                    CodeLine(text: "// Sign message with private key", style: .comment),
                    CodeLine(text: "let msg = \"Hello Bitcoin\".data(using: .utf8)!", style: .normal, highlights: [
                        CodeHighlight(text: "let", style: .keyword),
                        CodeHighlight(text: "\"Hello Bitcoin\"", style: .string),
                        CodeHighlight(text: "data", style: .function),
                        CodeHighlight(text: "using", style: .property),
                        CodeHighlight(text: "utf8", style: .property)
                    ]),
                    CodeLine(text: "let sig = try! priv.signature(for: msg)", style: .normal, highlights: [
                        CodeHighlight(text: "let", style: .keyword),
                        CodeHighlight(text: "try", style: .keyword),
                        CodeHighlight(text: "signature", style: .function)
                    ]),
                    CodeLine(text: "", style: .normal),
                    CodeLine(text: "// Verify signature with public key", style: .comment),
                    CodeLine(text: "let valid = pub.isValidSignature(sig, for: msg)", style: .normal, highlights: [
                        CodeHighlight(text: "let", style: .keyword),
                        CodeHighlight(text: "isValidSignature", style: .function)
                    ])
                ]
            ),
            CodeTab(
                title: "Schnorr",
                codeLines: [
                    CodeLine(text: "import P256K", style: .normal, highlights: [
                        CodeHighlight(text: "import", style: .keyword)
                    ]),
                    CodeLine(text: "", style: .normal),
                    CodeLine(text: "// Create Schnorr keypair", style: .comment),
                    CodeLine(text: "let priv = try! P256K.Schnorr.PrivateKey()", style: .normal, highlights: [
                        CodeHighlight(text: "let", style: .keyword),
                        CodeHighlight(text: "try", style: .keyword),
                        CodeHighlight(text: "Schnorr", style: .type),
                        CodeHighlight(text: "PrivateKey", style: .type)
                    ]),
                    CodeLine(text: "let pub = priv.publicKey", style: .normal, highlights: [
                        CodeHighlight(text: "let", style: .keyword),
                        CodeHighlight(text: "publicKey", style: .property)
                    ]),
                    CodeLine(text: "", style: .normal),
                    CodeLine(text: "// Sign message with private key", style: .comment),
                    CodeLine(text: "let msg = \"Bitcoin Script\".data(using: .utf8)!", style: .normal, highlights: [
                        CodeHighlight(text: "let", style: .keyword),
                        CodeHighlight(text: "\"Bitcoin Script\"", style: .string),
                        CodeHighlight(text: "data", style: .function),
                        CodeHighlight(text: "using", style: .property),
                        CodeHighlight(text: "utf8", style: .property)
                    ]),
                    CodeLine(text: "let sig = try! priv.signature(for: msg)", style: .normal, highlights: [
                        CodeHighlight(text: "let", style: .keyword),
                        CodeHighlight(text: "try", style: .keyword),
                        CodeHighlight(text: "signature", style: .function)
                    ]),
                    CodeLine(text: "", style: .normal),
                    CodeLine(text: "// Verify signature with public key", style: .comment),
                    CodeLine(text: "let valid = pub.isValidSignature(sig, for: msg)", style: .normal, highlights: [
                        CodeHighlight(text: "let", style: .keyword),
                        CodeHighlight(text: "isValidSignature", style: .function)
                    ])
                ]
            )
        ]))
    )
    
    static let installationSection = InstallationSection(
        badge: "Installation",
        title: "Get Started",
        description: "Add P256K to your project using your preferred package manager.",
        options: [
            InstallationOption(
                title: "Swift Package Manager",
                codeSnippet: ".package(url: \"https://github.com/21-DOT-DEV/swift-secp256k1\", exact: \"0.21.1\")",
                language: "swift",
                instructions: "Add this line to your Package.swift dependencies array, then run `swift build` to integrate P256K into your project."
            ),
            InstallationOption(
                title: "CocoaPods",
                codeSnippet: "pod 'swift-secp256k1', '0.21.1'",
                language: "ruby",
                instructions: "Add this line to your Podfile, then run `pod install` to integrate P256K into your Xcode workspace."
            )
        ]
    )
    
    static let siteHeader = SiteHeader(
        logoText: "21.dev",
        navigationLinks: [
            NavigationLink(title: "Blog", href: "/blog/"),
            NavigationLink(title: "P256K", href: "/p256k/"),
            NavigationLink(title: "Docs", href: "https://docs.21.dev/", isExternal: true)
        ]
    )
    
    // CSS components for rendering styles
    static var cssComponents: [any HasComponentCSS] {
        [siteHeader, codeHeroSection, installationSection]
    }
    
    static var page: some View {
        BasePage(title: "P256K - Swift secp256k1 for Bitcoin Development") {
            siteHeader
            
            codeHeroSection
            
            // Features section using new components
            Section {
                Div {
                    SectionIntro(
                        badge: "Integration",
                        title: "Streamline your development: utilize the efficiency of libsecp256k1 for swift",
                        description: "We've wrapped libsecp256k1 into a package and made it super simple to include into your Xcode project. And it works with Swift Packages too!"
                    )
                    
                    FeaturesGrid(features: [
                        Feature(
                            title: "Easy Integration",
                            description: "Unlock simplicity and efficiency with just a few lines from P256K1 APIs. Leave the heavy lifting of project mutations to libsecp256k1 while you focus on what truly matters.",
                            icon: LightningIcon()
                        ),
                        Feature(
                            title: "Swift Packages Support",
                            description: "Most of the time you don't need to compile sources of your Swift Package dependencies. Therefore we wrapped libsecp256k1 for others to integrate.",
                            icon: SwiftPackagesIcon()
                        ),
                        Feature(
                            title: "Flexibility",
                            description: "Schnorr and ECDSA Signatures functionality with ease. Exposed C bindings to take full control of the implementation.",
                            icon: CodeBracketsIcon()
                        )
                    ])
                }
                .padding(.horizontal, 32)
                .padding(.horizontal, 48, condition: Condition(startingAt: .medium))
                .padding(.horizontal, 128, condition: Condition(startingAt: .large))
                .modifier(ClassModifier(add: "max-w-7xl"))
                .margin(.horizontal, .auto)
                .padding(.vertical, 48)
                .padding(.vertical, 96, condition: Condition(startingAt: .large))
                .modifier(ClassModifier(add: "relative"))
            }
            
            // Installation section
            installationSection
            
            // Get Help section using existing components
            Section {
                Div {
                    H2("Need help? Let us help you get started")
                        .fontSize(.extraExtraLarge)
                        .fontWeight(.bold)
                        .textColor(.palette(.gray, darkness: 900))
                        .margin(.bottom, 24)
                    
                    CTAButtonView(button: CTAButton(
                        text: "Contact us →",
                        href: "mailto:hello@21.dev",
                        style: .primary,
                        isExternal: false
                    ))
                }
                .display(.flex)
                .flexDirection(.y)
                .flexDirection(.x, condition: .startingAt(.medium))
                .alignItems(.center)
                .justifyContent(.between, condition: .startingAt(.medium))
                .padding(.horizontal, 16)
                .padding(.horizontal, 24, condition: .startingAt(.small))
                .padding(.horizontal, 32, condition: .startingAt(.large))
                .frame(maxWidth: .fourXLarge)
                .margin(.horizontal, .auto)
            }
            .padding(.vertical, 64)
            .background(.palette(.orange, darkness: 50))
            
            SiteFooter(
                companyName: "21.dev",
                companyDescription: "Building the tools developers need for Bitcoin applications.",
                resourceLinks: [
                    FooterLink(text: "Documentation", href: "https://docs.21.dev/", isExternal: true),
                    FooterLink(text: "Blog", href: "/blog/"),
                    FooterLink(text: "P256K", href: "/p256k/"),
                    FooterLink(text: "Donate", href: "/donate/")
                ],
                contactEmail: "hello@21.dev",
                licenseText: "Licensed under MIT",
                socialLinks: [
                    SocialLink(url: "https://github.com/21-dot-dev", ariaLabel: "GitHub", platform: .github),
                    SocialLink(url: "https://x.com/21dotdev", ariaLabel: "X (Twitter)", platform: .twitter),
                    SocialLink(url: "https://njump.me/npub1...21dev", ariaLabel: "Nostr", platform: .nostr)
                ],
                copyrightText: "© 2025 21.dev. All rights reserved."
            )
        }
    }
}
