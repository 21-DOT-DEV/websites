//
//  SiteRoutes.swift
//  21-DOT-DEV/SiteRoutes.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem

/// Centralized route definitions for all site pages.
/// Separates indexed pages (included in sitemap.xml) from non-indexed pages (404s, etc.)
struct SiteRoutes {
    
    // MARK: - Indexed Pages (included in sitemap.xml)
    
    /// Static pages with fixed paths
    static var staticPages: Sitemap {
        [
            "index.html": Homepage.page,
            "packages/p256k/index.html": P256KPage.page,
            "blog/index.html": BlogListingPage.page
        ]
    }
    
    /// Dynamically generated blog post pages
    static func blogPostPages(from posts: [BlogPost]) -> Sitemap {
        var pages: Sitemap = [:]
        for post in posts {
            if let postPage = BlogPostPage.page(for: post.metadata.slug) {
                pages["blog/\(post.metadata.slug)/index.html"] = postPage
            }
        }
        return pages
    }
    
    /// All pages for sitemap.xml
    static func indexedPages(posts: [BlogPost]) -> Sitemap {
        staticPages.merging(blogPostPages(from: posts)) { _, new in new }
    }
    
    // MARK: - Non-Indexed Pages (excluded from sitemap.xml)
    
    /// 404 error pages
    static var notFoundPages: Sitemap {
        [
            "404.html": NotFoundPage.page,
            "blog/404.html": BlogNotFoundPage.page,
            "packages/404.html": PackagesNotFoundPage.page
        ]
    }
    
    // MARK: - Combined
    
    /// All pages for rendering
    static func allPages(posts: [BlogPost]) -> Sitemap {
        indexedPages(posts: posts).merging(notFoundPages) { _, new in new }
    }
}
