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
    
    // FAQ component with JSON-LD structured data
    // Answer text is automatically derived from content - no duplication needed
    static let faqItems: [FAQItem] = [
        FAQItem(question: "What is P256K?", includeInJSONLD: true) {
            Text("P256K is a Swift library for working with the secp256k1 elliptic curve, commonly used in Bitcoin and related ecosystems. It provides idiomatic, type-safe Swift APIs built on top of the widely used libsecp256k1 library.")
        },
        FAQItem(question: "How do I install P256K with Swift Package Manager?") {
            Div {
                Span("Add P256K to your project using Swift Package Manager. See the ")
                Link("Install via SPM", destination: URL(string: "#installation")!)
                    .textColor(.palette(.orange, darkness: 500))
                Span(" section above for step-by-step instructions.")
            }
        },
        FAQItem(question: "What makes P256K different from other secp256k1 libraries?", includeInJSONLD: true) {
            Text("P256K is designed specifically for Swift developers. It focuses on modern Swift language features, type safety, comprehensive test coverage, and seamless integration with Swift Package Manager. The API follows Swift conventions rather than exposing low-level C interfaces directly.")
        },
        FAQItem(question: "Is P256K safe for production use?", includeInJSONLD: true) {
            Text("P256K is built on libsecp256k1, a widely used cryptographic library in the Bitcoin ecosystem. The Swift wrapper is actively maintained and extensively tested. As with all cryptographic software, review the code for your threat model and pin versions for production deployments.")
        },
        FAQItem(question: "Has P256K been security audited?") {
            Text("The underlying libsecp256k1 has been heavily reviewed and tested in the Bitcoin ecosystem over many years. P256K (the Swift wrapper) has not yet undergone a dedicated third-party security audit.")
        },
        FAQItem(question: "What Swift versions and platforms are supported?", includeInJSONLD: true) {
            Text("P256K supports Swift 5.9 and newer and is tested on iOS, macOS, watchOS, tvOS, and Linux. It works with UIKit, SwiftUI, and server-side Swift environments.")
        },
        FAQItem(question: "What cryptographic operations does P256K support?", includeInJSONLD: true) {
            Text("P256K supports common secp256k1 operations including ECDSA signing and verification, Schnorr signatures, public key recovery, key agreement, key tweaking, and MuSig-related primitives commonly used in Bitcoin-adjacent protocols.")
        },
        FAQItem(question: "Is P256K suitable for Bitcoin, Lightning, Nostr, Ecash, or Liquid applications?", includeInJSONLD: true) {
            Text("Yes. P256K is suitable anywhere you need secp256k1 cryptography in Swift, including Bitcoin apps and related ecosystems like Lightning, Nostr, Ecash, and Liquid.")
        },
        FAQItem(question: "Is the API stable?", includeInJSONLD: true) {
            Text("P256K is pre-1.0.0, so APIs may change between releases. For production use, pin an exact version in Swift Package Manager to avoid unexpected breaking changes.")
        },
        FAQItem(question: "Where can I find documentation and examples?") {
            Div {
                Span("To get started, ")
                Link("Install via SPM", destination: URL(string: "#installation")!)
                    .textColor(.palette(.orange, darkness: 500))
                Span(". Comprehensive documentation, tutorials, and API references are available on the official ")
                Link("documentation site", destination: URL(string: "https://docs.21.dev/documentation/p256k/")!)
                    .textColor(.palette(.orange, darkness: 500))
                Span(". Example projects and additional usage patterns can be found in the ")
                Link("GitHub repository", destination: URL(string: "https://github.com/21-DOT-DEV/swift-secp256k1")!)
                    .textColor(.palette(.orange, darkness: 500))
                Span(".")
            }
        }
    ]
    
    static let faq = FAQ(items: faqItems)
    
    static let organization = OrganizationSchema(
        id: "https://21.dev/#organization",
        name: "21.dev",
        url: "https://21.dev/",
        sameAs: [
            "https://github.com/21-DOT-DEV",
            "https://x.com/21_DOT_DEV",
            "https://primal.net/21"
        ]
    )
    
    static let softwareSourceCode = SoftwareSourceCodeSchema(
        id: "https://21.dev/packages/p256k/#software",
        name: "P256K",
        description: "Swift wrapper for libsecp256k1 with ECDSA and Schnorr signatures, type-safe APIs, and Swift Package Manager support for Bitcoin and Nostr apps.",
        url: "https://21.dev/packages/p256k/",
        mainEntityOfPage: WebPageSchema(id: "https://21.dev/packages/p256k/"),
        codeRepository: "https://github.com/21-DOT-DEV/swift-secp256k1",
        programmingLanguage: ComputerLanguageSchema(name: "Swift"),
        license: "https://opensource.org/licenses/MIT",
        author: SchemaReference(id: "https://21.dev/#organization"),
        creator: SchemaReference(id: "https://21.dev/#organization"),
        runtimePlatform: ["iOS", "macOS", "watchOS", "tvOS", "Linux"],
        sameAs: [
            "https://github.com/21-DOT-DEV/swift-secp256k1",
            "https://docs.21.dev/documentation/p256k/",
            "https://swiftpackageindex.com/21-DOT-DEV/swift-secp256k1"
        ],
        softwareVersion: "0.21.1",
        keywords: [
            "secp256k1",
            "Swift",
            "Swift Package Manager",
            "cryptography",
            "ECDSA",
            "Schnorr",
            "Bitcoin",
            "Nostr"
        ],
        isBasedOn: "https://github.com/bitcoin-core/secp256k1",
        potentialAction: [
            PotentialActionSchema(type: .read, target: "https://docs.21.dev/documentation/p256k/"),
            PotentialActionSchema(type: .view, target: "https://github.com/21-DOT-DEV/swift-secp256k1")
        ],
        applicationCategory: ["DeveloperApplication", "Cryptography Library"]
    )
    
    static var page: some View {
        BasePage(
            title: "P256K: Swift secp256k1 (ECDSA + Schnorr) + SPM | 21.dev",
            description: "P256K is a Swift wrapper for libsecp256k1 with ECDSA + Schnorr, type-safe APIs, and Swift Package Manager support for Bitcoin and Nostr apps.",
            canonicalURL: URL(string: "https://21.dev/packages/p256k/"),
            schemas: [faq.schema, softwareSourceCode, organization]
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
                        description: "Unlock simplicity and efficiency with just a few lines using the P256K APIs. Leave the heavy lifting of project mutations to libsecp256k1 while you focus on what truly matters.",
                        icon: LightningIcon()
                    ),
                    ContentItem(
                        title: "Swift Packages Support",
                        description: "Most of the time you don't need to compile sources of your Swift Package dependencies. Therefore we wrapped libsecp256k1 for others to integrate.",
                        icon: SwiftPackagesIcon()
                    ),
                    ContentItem(
                        title: "Advanced Control",
                        description: "Schnorr and ECDSA Signatures functionality with ease. Optional low-level C bindings are available for advanced use cases.",
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
                description: "Add P256K using your preferred package manager.",
                id: "installation"
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
            
            // FAQ section with JSON-LD structured data
            SectionIntro(
                badge: "FAQ",
                title: "Frequently Asked Questions",
                description: "Common questions about using P256K for Swift integration."
            ) {
                faq
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
