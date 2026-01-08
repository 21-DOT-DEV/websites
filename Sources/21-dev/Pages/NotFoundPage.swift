//
//  NotFoundPage.swift
//  21-DOT-DEV/NotFoundPage.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem

/// Root 404 page for the site.
/// Served when no matching content is found at any path.
struct NotFoundPage {
    
    static var page: some View {
        BasePage(
            title: "404: Page not found | 21.dev",
            description: "The page you're looking for doesn't exist.",
            robotsDirective: "noindex, nofollow"
        ) {
            SiteDefaults.header
            
            NotFoundContent(
                headline: "404: Page not found",
                description: "This URL doesn't match any content on our site.",
                navigationLinks: [
                    NavigationLink(title: "Homepage", href: "/"),
                    NavigationLink(title: "Blog", href: "/blog/"),
                    NavigationLink(title: "P256K", href: "/packages/p256k/")
                ]
            )
            
            SiteDefaults.footer
        }
    }
}
