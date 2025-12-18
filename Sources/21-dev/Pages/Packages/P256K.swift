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
        headline: "Efficient SECP256K1 for Swift",
        description: "Seamlessly integrate, test, and utilize the elliptic curve cryptography for development of Bitcoin applications.",
        sponsorText: "Supported by",
        sponsorLogos: [.geyser, .openSats],
        ctaButton: CTAButton(
            text: "Get Started",
            href: "https://github.com/21-DOT-DEV/swift-secp256k1",
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
        options: [
            InstallationOption(
                title: "Xcode",
                codeSnippet: "https://github.com/21-DOT-DEV/swift-secp256k1",
                language: "text",
                instructions: "In Xcode, go to File → Add Package Dependencies, paste the URL above, select version 0.21.1, and add to your target."
            ),
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
    
    // Static organizations showcase data
    static let organizationsSection = SectionIntro(
        badge: "Ecosystem",
        title: "Used by Organizations",
        description: "Several applications use our package for their SECP256K1 needs."
    ) {
        IconGallery(items: [
            ContentItem(
                title: "Bittr",
                description: "Bitcoin trading and portfolio management",
                icon: BittrIcon(),
                link: "https://getbittr.com/"
            ),
            ContentItem(
                title: "Fully Noded",
                description: "Full Bitcoin node iOS wallet and toolkit",
                icon: FullyNodedIcon(),
                link: "https://fullynoded.app"
            ),
            ContentItem(
                title: "Macadamia",
                description: "Bitcoin development toolkit",
                icon: MacadamiaIcon(),
                link: "https://macadamia.cash/"
            ),
            ContentItem(
                title: "Nos",
                description: "Social network client for Nostr protocol",
                icon: NosIcon(),
                link: "https://nos.social"
            ),
            ContentItem(
                title: "Nostur",
                description: "Advanced Nostr client with powerful features",
                icon: NosturIcon(),
                link: "https://nostur.com"
            ),
            ContentItem(
                title: "Bitchat",
                description: "Bitcoin-powered messaging app",
                icon: BitchatPlaceholderIcon(),
                link: "https://bitchat.free/"
            ),
            ContentItem(
                title: "Damus",
                description: "Decentralized social network powered by Nostr protocol",
                icon: DamusPlaceholderIcon(),
                link: "https://damus.io"
            ),
            ContentItem(
                title: "Galaxoid Labs",
                description: "Bitcoin and Lightning development",
                icon: GalaxoidLabsPlaceholderIcon(),
                link: "https://galaxoidlabs.com"
            ),
            ContentItem(
                title: "Gordian Seed Tool",
                description: "Cryptographic seed phrase management tool",
                icon: GordianSeedToolPlaceholderIcon(),
                link: "https://apps.apple.com/us/app/gordian-seed-tool/id1545088229"
            ),
            ContentItem(
                title: "Olas",
                description: "Decentralized autonomous services",
                icon: OlasPlaceholderIcon(),
                link: "https://olas.app/"
            ),
            ContentItem(
                title: "Primal",
                description: "Nostr client with modern interface",
                icon: PrimalPlaceholderIcon(),
                link: "https://primal.net"
            ),
            ContentItem(
                title: "Synonym",
                description: "Bitcoin Lightning infrastructure",
                icon: SynonymPlaceholderIcon(),
                link: "https://synonym.to"
            )
        ])
    }
    
    // Accordion component for FAQ section
    static let faqAccordion = Accordion(items: [
        AccordionItem(
            question: "What makes P256K different from other SECP256K1 libraries?",
            answer: Text("P256K is built specifically for Swift developers with modern language features, comprehensive test coverage, and seamless integration with Swift Package Manager. It provides type-safe APIs and follows Swift conventions.")
        ),
        AccordionItem(
            question: "What Swift versions are supported?",
            answer: Text("p256k supports Swift 5.9+ and is tested on macOS, iOS, watchOS, tvOS, and Linux. It requires no external packages and works with both UIKit and SwiftUI applications.")
        ),
        AccordionItem(
            question: "Where can I find code examples and tutorials?",
            answer: Div {
                Span("Visit our comprehensive ")
                Link("documentation site", destination: URL(string: "https://docs.21.dev/p256k")!)
                    .textColor(.palette(.orange, darkness: 500))
                Span(" for tutorials, API reference, and real-world examples. You can also explore the ")
                Link("example projects", destination: URL(string: "https://github.com/21-DOT-DEV/swift-secp256k1")!)
                    .textColor(.palette(.orange, darkness: 500))
                Span(" repository on GitHub.")
            }
        )
    ])

    // CSS components for rendering styles
    static var cssComponents: [any HasComponentCSS] {
        [SiteDefaults.header, codeHeroSection, installationSection, faqAccordion]
    }
    
    static var page: some View {
        BasePage(
            title: "P256K - Swift secp256k1 for Bitcoin Development",
            canonicalURL: URL(string: "https://21.dev/packages/p256k/")
        ) {
            SiteDefaults.header
            
            codeHeroSection
            
            // Features section using new components
            SectionIntro(
                badge: "Integration",
                title: "Streamline your development: utilize the efficiency of libsecp256k1 for Swift",
                description: {
                    Span("We've wrapped ")
                    Link("libsecp256k1", destination: URL(string: "https://github.com/bitcoin-core/secp256k1")!)
                        .textColor(.palette(.orange, darkness: 500))
                    Span(" into a package and made it super simple to include into your Xcode project. And it works with Swift Packages too!")
                }
            ) {
                FeaturesGrid(features: [
                    ContentItem(
                        title: "Easy Integration",
                        description: "Unlock simplicity and efficiency with just a few lines from P256K1 APIs. Leave the heavy lifting of project mutations to libsecp256k1 while you focus on what truly matters.",
                        icon: LightningIcon()
                    ),
                    ContentItem(
                        title: "Swift Packages Support",
                        description: "Most of the time you don't need to compile sources of your Swift Package dependencies. Therefore we wrapped libsecp256k1 for others to integrate.",
                        icon: SwiftPackagesIcon()
                    ),
                    ContentItem(
                        title: "Flexibility",
                        description: "Schnorr and ECDSA Signatures functionality with ease. Exposed C bindings to take full control of the implementation.",
                        icon: CodeBracketsIcon()
                    )
                ])
            }
            
            // Organizations section
            organizationsSection
            
            // Installation section
            SectionIntro(
                badge: "Installation",
                title: "Get Started",
                description: "Add P256K using your preferred package manager."
            ) {
                installationSection
            }
            
            // API Documentation section using new CardGrid
            SectionIntro(
                badge: "Documentation",
                title: "Explore the APIs",
                description: "Comprehensive API documentation for P256K cryptography."
            ) {
                CardGrid(items: [
                    ContentItem(
                        title: "ECDSA Signatures",
                        description: "Elliptic Curve Digital Signature Algorithm (ECDSA) offers a variant of the Digital Signature Algorithm (DSA) which uses elliptic-curve cryptography.",
                        icon: LightningIcon(),
                        link: "https://docs.21.dev/documentation/p256k/secp256k1/signing"
                    ),
                    ContentItem(
                        title: "Schnorr Signatures",
                        description: "Schnorr signatures provide enhanced privacy and efficiency with mathematical properties that enable advanced Bitcoin scripting capabilities.",
                        icon: SignatureIcon(),
                        link: "https://docs.21.dev/documentation/p256k/secp256k1/schnorr"
                    ),
                    ContentItem(
                        title: "Key Management",
                        description: "Secure key generation, derivation, and management utilities for Bitcoin development with industry-standard practices.",
                        icon: SwiftPackagesIcon(),
                        link: "https://docs.21.dev/documentation/p256k/secp256k1/signing/privatekey"
                    )
                ])
            }
            
            // FAQ section using SectionIntro + Accordion
            SectionIntro(
                badge: "FAQ",
                title: "Frequently Asked Questions",
                description: "Common questions about using P256K for Swift integration."
            ) {
                faqAccordion
            }
            
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
            
            SiteDefaults.footer
        }
    }
}
