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
        // Note: sitemap.xml is generated dynamically, not copied
        let staticFiles = ["llms.txt", "robots.txt", "_headers", "_redirects"]
        
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
    
    /// Generate sitemap XML file from the sitemap dictionary
    /// - Parameters:
    ///   - sitemap: The sitemap dictionary mapping paths to pages
    ///   - outputURL: The output directory URL
    ///   - filename: The sitemap filename (default: "sitemap.xml")
    ///   - baseURL: The base URL for the site (default: "https://21.dev/")
    private static func generateSitemapXML(from sitemap: Sitemap, to outputURL: URL, filename: String = "sitemap.xml", baseURL: String = "https://21.dev/") throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let lastModDate = dateFormatter.string(from: Date())
        
        // Start with standard sitemap header
        var xmlContent = sitemapXMLHeader()
        
        for path in sitemap.keys.sorted() {
            // Convert relative path to absolute URL
            var absoluteURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let cleanPath = path.replacingOccurrences(of: "index.html", with: "")
            
            if !cleanPath.isEmpty {
                absoluteURL += "/" + cleanPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            }
            
            // Ensure trailing slash for directory-style URLs
            if !absoluteURL.hasSuffix("/") {
                absoluteURL += "/"
            }
            
            // Add URL entry using utility function
            xmlContent += sitemapURLEntry(url: absoluteURL, lastmod: lastModDate)
        }
        
        // Close with standard footer
        xmlContent += sitemapXMLFooter()
        
        let sitemapURL = outputURL.appending(path: filename)
        try xmlContent.write(to: sitemapURL, atomically: true, encoding: .utf8)
        print("✅ Generated \(filename)")
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
        
        // Generate sitemap.xml for 21.dev
        try generateSitemapXML(from: sitemap, to: outputURL)
        
        // Copy static resources after site generation
        try copyStaticResources(from: resourcesURL, to: outputURL)
    }
}
