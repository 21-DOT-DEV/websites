//
//  Sitemap.swift
//  21-DOT-DEV/Sitemap.swift
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem
import UtilLib

@main
struct SiteGenerator {
    /// Patterns for files/directories to exclude from copying (build-time artifacts)
    private static let excludedPatterns: [String] = [
        ".DS_Store",           // macOS metadata
        ".input.css",          // Tailwind CSS input files
        ".base.css",           // Base CSS files
        ".cjs",                // CommonJS config files (tailwind.config.cjs)
        "_headers.dev",        // Dev-only headers
        "_headers.prod",       // Prod headers (renamed to _headers during copy)
        "blog",                // Blog content (processed separately by BlogService)
        "packages",            // Package content (processed separately)
        "static"               // CSS build artifacts (Tailwind input/output)
    ]
    
    /// Generate sitemap XML file from the sitemap dictionary
    /// - Parameters:
    ///   - sitemap: The sitemap dictionary mapping paths to pages
    ///   - outputURL: The output directory URL
    ///   - filename: The sitemap filename (default: "sitemap.xml")
    ///   - baseURL: The base URL for the site (default: "https://21.dev/")
    private static func generateSitemapXML(from sitemap: Sitemap, to outputURL: URL, filename: String = "sitemap.xml", baseURL: String = SiteIdentity.url) async throws {
        // Get lastmod date from git history of the site generator file
        // This represents "when was the site code last updated"
        let lastModDate = await SitemapGenerator.getGitLastmod(for: "Sources/21-dev/SiteGenerator.swift")
        
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
    
    static func main() async throws {
        // Assumes this file is located in a Sources/ sub-directory of a Swift package.
        let projectURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        
        let resourcesURL = projectURL.appending(path: "../Resources/21-dev")
        let outputURL = projectURL.appending(path: "../Websites/21-dev")
        
        // Build page collections
        let posts = BlogService.loadAllPosts()
        let sitemap = SiteRoutes.indexedPages(posts: posts)
        let allPages = SiteRoutes.allPages(posts: posts)
        
        // Render site with automatic CSS collection and generation
        try await renderSitemap(
            allPages,
            to: outputURL,
            baseCSS: projectURL.appending(path: "../Resources/21-dev/static/style.base.css"),
            stylesheet: "../../Resources/21-dev/static/style.input.css"
        )
        
        // Generate sitemap.xml
        try await generateSitemapXML(from: sitemap, to: outputURL)
        
        // Copy static resources after site generation
        try ResourceCopier.copyResources(
            from: resourcesURL,
            to: outputURL,
            excludePatterns: excludedPatterns
        ) { path in
            print("✅ Copied \(path)")
        }
    }
}
