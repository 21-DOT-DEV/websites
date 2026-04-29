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
import SiteIdentity
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
    
    /// Generate sitemap XML file from the sitemap dictionary.
    ///
    /// Emits `<url><loc>...</loc></url>` entries without `<lastmod>` per
    /// sitemap protocol 0.9 (lastmod is optional). Previously this used a
    /// single git commit date from `Sources/21-dev/SiteGenerator.swift`
    /// applied uniformly to every URL — that signal was unreliable (every
    /// edit to this file changed all timestamps; edits to individual pages
    /// did not), so it has been removed.
    ///
    /// - Parameters:
    ///   - sitemap: The sitemap dictionary mapping paths to pages
    ///   - outputURL: The output directory URL
    ///   - filename: The sitemap filename (default: "sitemap.xml")
    ///   - baseURL: The base URL for the site (default: "https://21.dev/")
    private static func generateSitemapXML(from sitemap: Sitemap, to outputURL: URL, filename: String = "sitemap.xml", baseURL: String = SiteIdentity.url) throws {
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
            
            // Add URL entry using utility function (no <lastmod> emitted)
            xmlContent += sitemapURLEntry(url: absoluteURL)
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
    
    /// Generate llms-full.txt using XML-structured format per llmstxt.org convention.
    /// Wraps llms.txt preamble in a `<project>` element and inlines each linked
    /// resource as a `<doc>` element inside `<docs>`, following the FastHTML
    /// reference implementation (`llms_txt2ctx`).
    private static func generateLlmsFullTxt(
        posts: [BlogPost],
        resourcesURL: URL,
        outputURL: URL
    ) throws {
        let summary = "Swift cryptography project hub for the swift-secp256k1 package — secp256k1 elliptic curve operations, ECDSA/Schnorr signatures, and zero-knowledge proofs."
        
        var out = """
        <project title="21.dev" summary='\(summary)'>
        Things to know when working with this documentation:
        
        - P256K and ZKP are sibling modules wrapping different C libraries — pick one, do not import both
        - All APIs are Swift 6.1+ with strict concurrency (swift-tools-version: 6.1, swiftLanguageModes: [.v6])
        - Consumers should use only the public Swift APIs in P256K or ZKP, never the underlying C bindings directly
        - Documentation auto-updates with package releases; the DocC HTML version (docs.21.dev) includes GitHub source links
        
        <docs>
        
        """
        
        // Homepage
        out += """
        <doc title="Homepage" desc="Project overview, mission, and featured packages" url="\(SiteIdentity.url)">
        # 21.dev
        
        Equipping developers with the tools they need today to build the Bitcoin apps of tomorrow.
        
        ## What is 21.dev?
        
        21.dev is a organization dedicated to empowering developers with high-quality, open-source tools for building Bitcoin applications. We focus on creating robust software packages and libraries that make Bitcoin development more accessible and efficient for developers across multiple platforms.
        
        Our mission is to accelerate Bitcoin adoption by providing developers with the foundational tools they need to build and maintain secure, scalable Bitcoin applications. From cryptographic primitives to high-level APIs, we're building the infrastructure that powers the next generation of Bitcoin apps.
        
        All of our work is open source, community-driven, and designed with developer experience as the top priority. It is our fundamental belief that better tools lead to better applications, which in turn benefits the entire Bitcoin ecosystem.
        
        ## Featured Package: P256K
        
        Enhance your Swift development for Bitcoin apps with seamless secp256k1 integration. P256K provides a clean, efficient Swift interface to Bitcoin's elliptic curve cryptography.
        </doc>
        
        """
        
        // P256K package page
        out += """
        <doc title="P256K Package" desc="Detailed package page with features, FAQ, and getting started" url="\(SiteIdentity.url)packages/p256k/">
        # P256K: Swift secp256k1 (ECDSA + Schnorr)
        
        P256K is a Swift wrapper for libsecp256k1 with ECDSA + Schnorr, type-safe APIs, and Swift Package Manager support for Bitcoin and Nostr apps.
        
        ## Installation
        
        Swift Package Manager (recommended):
        ```swift
        .package(url: "https://github.com/21-DOT-DEV/swift-secp256k1", exact: "0.23.1")
        ```
        
        ## FAQ
        
        **What is P256K?**
        P256K is a Swift library for working with the secp256k1 elliptic curve, commonly used in Bitcoin and related ecosystems. It provides idiomatic, type-safe Swift APIs built on top of the widely used libsecp256k1 library.
        
        **What makes P256K different from other secp256k1 libraries?**
        P256K is designed specifically for Swift developers. It focuses on modern Swift language features, type safety, comprehensive test coverage, and seamless integration with Swift Package Manager. The API follows Swift conventions rather than exposing low-level C interfaces directly.
        
        **Is P256K safe for production use?**
        P256K is built on libsecp256k1, a widely used cryptographic library in the Bitcoin ecosystem. The Swift wrapper is actively maintained and extensively tested. As with all cryptographic software, review the code for your threat model and pin versions for production deployments.
        
        **What Swift versions and platforms are supported?**
        P256K supports Swift 6.1 and newer and is tested on iOS, macOS, watchOS, tvOS, and Linux. It works with UIKit, SwiftUI, and server-side Swift environments.
        
        **What cryptographic operations does P256K support?**
        P256K supports common secp256k1 operations including ECDSA signing and verification, Schnorr signatures, public key recovery, key agreement, key tweaking, and MuSig-related primitives commonly used in Bitcoin-adjacent protocols.
        
        **Is P256K suitable for Bitcoin, Lightning, Nostr, Ecash, or Liquid applications?**
        Yes. P256K is suitable anywhere you need secp256k1 cryptography in Swift, including Bitcoin apps and related ecosystems like Lightning, Nostr, Ecash, and Liquid.
        
        **Is the API stable?**
        P256K is pre-1.0.0, so APIs may change between releases. For production use, pin an exact version in Swift Package Manager to avoid unexpected breaking changes.
        </doc>
        
        """
        
        // Blog posts — inline full markdown content
        let sortedPosts = posts.sorted { $0.metadata.date > $1.metadata.date }
        for post in sortedPosts {
            let body = post.content.trimmingCharacters(in: .whitespacesAndNewlines)
            let postURL = "\(SiteIdentity.url)blog/\(post.metadata.slug)/"
            let tags = post.metadata.tags.isEmpty ? "" : " [\(post.metadata.tags.joined(separator: ", "))]"
            out += "<doc title=\"\(post.metadata.title)\" desc=\"\(post.metadata.excerpt)\" url=\"\(postURL)\">\n"
            out += "# \(post.metadata.title)\n\n"
            out += "Published: \(post.metadata.date)\(tags)\n\n"
            out += body + "\n"
            out += "</doc>\n\n"
        }
        
        out += "</docs>\n</project>\n"
        
        let fullOutputFile = outputURL.appending(path: "llms-full.txt")
        try out.write(to: fullOutputFile, atomically: true, encoding: .utf8)
        print("✅ Generated llms-full.txt")
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
        try generateSitemapXML(from: sitemap, to: outputURL)
        
        // Generate blog markdown alternates and llms.txt blog section
        try generateBlogMarkdownAlternates(
            posts: posts,
            resourcesURL: resourcesURL,
            outputURL: outputURL
        )
        
        // Generate llms-full.txt (must run after llms.txt is generated)
        try generateLlmsFullTxt(
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
