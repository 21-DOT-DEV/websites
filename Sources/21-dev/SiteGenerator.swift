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
        "static",              // CSS build artifacts (Tailwind input/output)
        "functions",           // Cloudflare Pages Functions (deployed as sibling, not inside output)
        "llms.txt"             // Generated with blog section by generateBlogMarkdownAlternates
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
    
    /// Copy blog markdown files to output as AI-agent-readable alternates,
    /// then append an auto-generated blog section to llms.txt.
    private static func generateBlogMarkdownAlternates(
        posts: [BlogPost],
        resourcesURL: URL,
        outputURL: URL
    ) throws {
        let blogOutputDir = outputURL.appending(path: "data/blog")
        try FileManager.default.createDirectory(at: blogOutputDir, withIntermediateDirectories: true)
        
        let blogSourceDir = resourcesURL.appending(path: "blog")
        guard FileManager.default.fileExists(atPath: blogSourceDir.path) else {
            print("⚠️ Blog source directory not found at \(blogSourceDir.path), skipping markdown alternates")
            return
        }
        
        guard !posts.isEmpty else {
            print("ℹ️ No blog posts found, skipping markdown alternates")
            return
        }
        
        // Duplicate slug detection
        var seenSlugs = Set<String>()
        for post in posts {
            guard seenSlugs.insert(post.metadata.slug).inserted else {
                fatalError("Duplicate blog slug: '\(post.metadata.slug)' — each post must have a unique slug in frontmatter")
            }
        }
        
        // Copy each post as stripped markdown
        for post in posts {
            let content = post.content.trimmingCharacters(in: .whitespacesAndNewlines)
            let markdownContent = "# \(post.metadata.title)\n\n\(content)\n"
            let outputFile = blogOutputDir.appending(path: "\(post.metadata.slug).md")
            try markdownContent.write(to: outputFile, atomically: true, encoding: .utf8)
        }
        print("✅ Generated \(posts.count) blog markdown alternate(s)")
        
        // Auto-generate llms.txt blog section
        let llmsSourceFile = resourcesURL.appending(path: "llms.txt")
        guard FileManager.default.fileExists(atPath: llmsSourceFile.path) else {
            print("⚠️ llms.txt source not found at \(llmsSourceFile.path), skipping blog section")
            return
        }
        
        var llmsContent = try String(contentsOf: llmsSourceFile, encoding: .utf8)
        
        // Sort posts by date descending (newest first)
        let sortedPosts = posts.sorted { $0.metadata.date > $1.metadata.date }
        
        llmsContent += "\n\n## Blog Posts (Markdown)\n\n"
        for post in sortedPosts {
            llmsContent += "- [\(post.metadata.title)](\(SiteIdentity.url)data/blog/\(post.metadata.slug).md): \(post.metadata.excerpt)\n"
        }
        
        let llmsOutputFile = outputURL.appending(path: "llms.txt")
        try llmsContent.write(to: llmsOutputFile, atomically: true, encoding: .utf8)
        print("✅ Generated llms.txt with blog section")
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
        
        // Generate blog markdown alternates and llms.txt blog section
        try generateBlogMarkdownAlternates(
            posts: posts,
            resourcesURL: resourcesURL,
            outputURL: outputURL
        )
        
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
