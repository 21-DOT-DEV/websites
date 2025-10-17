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
    /// Copy static resource files from Resources/ to Websites/ output directory
    private static func copyStaticResources(from resourcesURL: URL, to outputURL: URL) throws {
        let fileManager = FileManager.default
        
        // Define static files to copy (root-level files only)
        let staticFiles = ["llms.txt", "robots.txt", "sitemap.xml"]
        
        for filename in staticFiles {
            let sourceURL = resourcesURL.appendingPathComponent(filename)
            let destinationURL = outputURL.appendingPathComponent(filename)
            
            // Only copy if source exists
            if fileManager.fileExists(atPath: sourceURL.path) {
                // Remove destination if it exists (for idempotency)
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                
                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                print("✅ Copied \(filename)")
            }
        }
    }
    
    static func main() throws {
        // Assumes this file is located in a Sources/ sub-directory of a Swift package.
        let projectURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        
        let resourcesURL = projectURL.appending(path: "../Resources/21-dev")
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
        
        // Copy static resources after site generation
        try copyStaticResources(from: resourcesURL, to: outputURL)
    }
}
