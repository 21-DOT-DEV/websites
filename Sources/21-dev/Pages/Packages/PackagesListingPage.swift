//
//  PackagesListingPage.swift
//  21-DOT-DEV/PackagesListingPage.swift
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

struct PackagesListingPage {
    // Page metadata
    private static let pageTitle = "Open-Source Swift Packages for Bitcoin | 21.dev"
    private static let pageDescription = "Browse 21.dev's open-source Swift packages for Bitcoin development: cryptography, networking, and foundational C/C++ dependencies."
    private static let pageURL = "\(SiteIdentity.url)packages/"
    
    private static let packages: [(name: String, description: String, href: String, isExternal: Bool)] = [
        (
            name: "P256K",
            description: "Swift wrapper for libsecp256k1 with ECDSA, Schnorr, ECDH, and MuSig2. Type-safe APIs and Swift Package Manager support for Bitcoin and Nostr apps.",
            href: "/packages/p256k/",
            isExternal: false
        ),
        (
            name: "swift-event",
            description: "Swift package for libevent, a portable event notification library used for building scalable network services.",
            href: "https://github.com/21-DOT-DEV/swift-event",
            isExternal: true
        ),
        (
            name: "swift-openssl",
            description: "Swift package for OpenSSL, providing cryptographic functions and TLS support as a foundational dependency.",
            href: "https://github.com/21-DOT-DEV/swift-openssl",
            isExternal: true
        ),
        (
            name: "swift-boost",
            description: "Swift package for Boost C++ libraries, providing portable foundational utilities used by higher-level packages.",
            href: "https://github.com/21-DOT-DEV/swift-boost",
            isExternal: true
        )
    ]
    
    static var page: some View {
        let itemList = ItemListSchema(id: "\(pageURL)#itemlist", items: packages.enumerated().map { index, pkg in
            ListItemSchema(
                position: index + 1,
                url: pkg.isExternal ? pkg.href : "\(SiteIdentity.url)packages/\(pkg.href.trimmingCharacters(in: CharacterSet(charactersIn: "/")).components(separatedBy: "/").last ?? "")/",
                name: pkg.name,
                description: pkg.description
            )
        })
        
        return BasePage(
            title: pageTitle,
            description: pageDescription,
            canonicalURL: URL(string: pageURL),
            schemas: [
                SiteIdentity.webPageSchema(
                    url: pageURL,
                    pageType: .collectionPage,
                    name: pageTitle,
                    description: pageDescription,
                    mainEntity: SchemaReference(id: "\(pageURL)#itemlist")
                ),
                itemList,
                SiteIdentity.organizationSchema,
                BreadcrumbListSchema(items: [
                    BreadcrumbItemSchema(position: 1, name: "Home", item: SiteIdentity.url),
                    BreadcrumbItemSchema(position: 2, name: "Packages")
                ])
            ],
            llmsTxtURL: SiteIdentity.llmsTxtURL
        ) {
            SiteDefaults.header
            
            packagesSection
            
            SiteDefaults.footer
        }
    }
    
    @ViewBuilder
    private static var packagesSection: some View {
        Div {
            Div {
                H1 {
                    Text("Packages")
                }
                .fontSize(.fourXLarge)
                .fontWeight(.bold)
                .margin(.bottom, 16)
                
                Div {
                    Text("Open-source Swift packages for Bitcoin development. From cryptographic primitives to foundational C/C++ dependencies.")
                }
                .fontSize(.large)
                .textColor(.palette(.gray, darkness: 600))
                .margin(.bottom, 48)
                
                VStack(spacing: 24) {
                    packageCard(
                        name: packages[0].name,
                        description: packages[0].description,
                        href: packages[0].href,
                        isExternal: packages[0].isExternal
                    )
                    packageCard(
                        name: packages[1].name,
                        description: packages[1].description,
                        href: packages[1].href,
                        isExternal: packages[1].isExternal
                    )
                    packageCard(
                        name: packages[2].name,
                        description: packages[2].description,
                        href: packages[2].href,
                        isExternal: packages[2].isExternal
                    )
                    packageCard(
                        name: packages[3].name,
                        description: packages[3].description,
                        href: packages[3].href,
                        isExternal: packages[3].isExternal
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.horizontal, 24, condition: Condition(startingAt: .small))
            .padding(.horizontal, 32, condition: Condition(startingAt: .large))
            .frame(maxWidth: .fourXLarge)
            .margin(.horizontal, .auto)
        }
        .padding(.vertical, 64)
        .background(.palette(.gray, darkness: 50))
    }
    
    @ViewBuilder
    private static func packageCard(name: String, description: String, href: String, isExternal: Bool) -> some View {
        Link(URL(string: href), openInNewTab: isExternal) {
            Div {
                VStack(spacing: 12) {
                    H2 {
                        Text(name)
                    }
                    .fontSize(.extraExtraLarge)
                    .fontWeight(.semibold)
                    .textColor(.palette(.gray, darkness: 900))
                    
                    Div {
                        Text(description)
                    }
                    .fontSize(.base)
                    .textColor(.palette(.gray, darkness: 600))
                    
                    Div {
                        Text(isExternal ? "View on GitHub →" : "View package →")
                    }
                    .fontSize(.small)
                    .fontWeight(.medium)
                    .textColor(.palette(.blue, darkness: 600))
                }
            }
            .padding(24)
            .modifier(ClassModifier(add: "bg-white border border-gray-200 rounded-lg hover:border-blue-300 hover:shadow-md transition-all"))
        }
        .modifier(ClassModifier(add: "block"))
    }
}
