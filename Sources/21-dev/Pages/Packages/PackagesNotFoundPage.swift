//
//  PackagesNotFoundPage.swift
//  21-DOT-DEV/PackagesNotFoundPage.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem

/// Section-specific 404 page for packages.
/// Served when a package URL doesn't match any existing content.
struct PackagesNotFoundPage {
    
    static var page: some View {
        BasePage(
            title: "404: Package not found | 21.dev",
            description: "The package page you're looking for doesn't exist.",
            robotsDirective: "noindex, nofollow"
        ) {
            SiteDefaults.header
            
            NotFoundContent(
                headline: "404: Package not found",
                description: "This package page doesn't exist.",
                navigationLinks: [
                    NavigationLink(title: "P256K", href: "/packages/p256k/"),
                    NavigationLink(title: "Homepage", href: "/")
                ]
            )
            
            SiteDefaults.footer
        }
    }
}
