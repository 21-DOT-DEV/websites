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
    
    /// Generate sitemap.xml from the sitemap dictionary
    private static func generateSitemapXML(from sitemap: Sitemap, to outputURL: URL, baseURL: String = "https://21.dev/") throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let lastModDate = dateFormatter.string(from: Date())
        
        // Function to escape XML special characters in URLs
        func escapeXMLSpecialCharacters(_ string: String) -> String {
            return string
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "'", with: "&apos;")
                .replacingOccurrences(of: "\"", with: "&quot;")
        }
        
        var xmlContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        
        """
        
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
            
            // Escape special characters for XML
            let escapedURL = escapeXMLSpecialCharacters(absoluteURL)
            
            xmlContent += """
            <url>
              <loc>\(escapedURL)</loc>
              <lastmod>\(lastModDate)</lastmod>
            </url>
            
            """
        }
        
        xmlContent += "</urlset>"
        
        let sitemapURL = outputURL.appending(path: "sitemap.xml")
        try xmlContent.write(to: sitemapURL, atomically: true, encoding: .utf8)
        print("✅ Generated sitemap.xml")
    }
    
    static func main() async throws {
        // Assumes this file is located in a Sources/ sub-directory of a Swift package.
        let projectURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        
        let resourcesURL = projectURL.appending(path: "../Resources/21-dev")
        let outputURL = projectURL.appending(path: "../Websites/21-dev")
        
        // Build sitemap with all pages
        let posts = BlogService.loadAllPosts()
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
        
        // Render site with automatic CSS collection and generation
        try await renderSitemap(
            sitemap,
            to: outputURL,
            baseCSS: projectURL.appending(path: "../Resources/21-dev/static/style.base.css"),
            stylesheet: "static/style.input.css"
        )
        
        // Generate sitemap.xml
        try generateSitemapXML(from: sitemap, to: outputURL)
        
        // Copy static resources after site generation
        try copyStaticResources(from: resourcesURL, to: outputURL)
    }
}
