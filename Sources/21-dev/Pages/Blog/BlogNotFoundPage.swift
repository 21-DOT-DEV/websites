//
//  BlogNotFoundPage.swift
//  21-DOT-DEV/BlogNotFoundPage.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem

/// Section-specific 404 page for the blog.
/// Served when a blog post URL doesn't match any existing content.
struct BlogNotFoundPage {
    
    static var page: some View {
        BasePage(
            title: "404: Post not found | 21.dev Blog",
            description: "The blog post you're looking for doesn't exist.",
            robotsDirective: "noindex, nofollow"
        ) {
            SiteDefaults.header
            
            NotFoundContent(
                headline: "404: Post not found",
                description: "This blog post doesn't exist or may have been moved.",
                navigationLinks: [
                    NavigationLink(title: "Browse all posts", href: "/blog/"),
                    NavigationLink(title: "Homepage", href: "/")
                ]
            )
            
            SiteDefaults.footer
        }
    }
}
