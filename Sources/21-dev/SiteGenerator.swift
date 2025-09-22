//
//  Sitemap.swift
//  21-DOT-DEV/Sitemap.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem

@main
struct SiteGenerator {
    static func main() throws {
        // Assumes this file is located in a Sources/ sub-directory of a Swift package.
        let projectURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        
        let outputURL = projectURL.appending(path: "../Websites/21-dev")
        
        var stylemap = [
            "static/style.input.css": Homepage.cssComponents,
            "packages/p256k/static/style.input.css": P256KPage.cssComponents,
            "blog/static/style.input.css": BlogListingPage.cssComponents
        ]
        
        // Add CSS for individual blog posts
        let posts = BlogService.loadAllPosts()
        for post in posts {
            stylemap["blog/\(post.metadata.slug)/static/style.input.css"] = BlogPostPage.cssComponents
        }
        
        for style in stylemap {
            try renderStyles(
                from: style.value,
                baseCSS: projectURL.appending(path: "../Resources/21-dev/static/style.base.css"),
                to: projectURL.appending(path: "../Resources/21-dev/\(style.key)")
            )
        }
        
        // Then render site
        var sitemap: Sitemap = [
            "index.html": Homepage.page,
            "packages/p256k/index.html": P256KPage.page,
            "blog/index.html": BlogListingPage.page
        ]
        
        // Add individual blog posts to sitemap
        for post in posts {
            if let postPage = BlogPostPage.page(for: post.metadata.slug) {
                sitemap["blog/\(post.metadata.slug)/index.html"] = postPage
            }
        }
        
        try renderSitemap(sitemap, to: outputURL)
    }
}
