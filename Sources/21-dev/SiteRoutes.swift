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
    
    /// Static pages with fixed paths (pages that don't depend on posts)
    static var staticPages: Sitemap {
        [
            "index.html": Homepage.page,
            "packages/p256k/index.html": P256KPage.page
        ]
    }
    
    /// Dynamically generated blog post pages
    static func blogPostPages(from posts: [BlogPost]) -> Sitemap {
        var pages: Sitemap = [:]
        for post in posts {
            pages["blog/\(post.metadata.slug)/index.html"] = BlogPostPage.page(for: post)
        }
        return pages
    }
    
    /// All pages for sitemap.xml
    static func indexedPages(posts: [BlogPost]) -> Sitemap {
        var pages = staticPages
        pages["blog/index.html"] = BlogListingPage.page(posts: posts)
        return pages.merging(blogPostPages(from: posts)) { _, new in new }
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
