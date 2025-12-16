//
//  SitemapGeneratorTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import Utilities

@Suite("SitemapGenerator URL Discovery Tests")
struct URLDiscoveryTests {
    
    @Test("discoverHTMLFiles finds .html files in directory")
    func discoverHTMLFiles() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-html-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // Create test HTML files
        try "<!DOCTYPE html>".write(to: tempDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        try "<!DOCTYPE html>".write(to: tempDir.appendingPathComponent("about.html"), atomically: true, encoding: .utf8)
        
        // Create subdirectory with HTML
        let subdir = tempDir.appendingPathComponent("blog")
        try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
        try "<!DOCTYPE html>".write(to: subdir.appendingPathComponent("post.html"), atomically: true, encoding: .utf8)
        
        let files = try SitemapGenerator.discoverHTMLFiles(in: tempDir.path)
        
        #expect(files.count == 3)
        #expect(files.contains { $0.hasSuffix("index.html") })
        #expect(files.contains { $0.hasSuffix("about.html") })
        #expect(files.contains { $0.hasSuffix("blog/post.html") })
    }
    
    @Test("discoverHTMLFiles ignores non-HTML files")
    func ignoreNonHTML() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-nonhtml-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        try "<!DOCTYPE html>".write(to: tempDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        try "body { }".write(to: tempDir.appendingPathComponent("style.css"), atomically: true, encoding: .utf8)
        try "console.log()".write(to: tempDir.appendingPathComponent("app.js"), atomically: true, encoding: .utf8)
        
        let files = try SitemapGenerator.discoverHTMLFiles(in: tempDir.path)
        
        #expect(files.count == 1)
        #expect(files.first?.hasSuffix("index.html") == true)
    }
    
    @Test("discoverMarkdownFiles finds .md files in directory")
    func discoverMarkdownFiles() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-md-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        try "# Title".write(to: tempDir.appendingPathComponent("index.md"), atomically: true, encoding: .utf8)
        try "# About".write(to: tempDir.appendingPathComponent("about.md"), atomically: true, encoding: .utf8)
        
        let files = try SitemapGenerator.discoverMarkdownFiles(in: tempDir.path)
        
        #expect(files.count == 2)
        #expect(files.contains { $0.hasSuffix("index.md") })
        #expect(files.contains { $0.hasSuffix("about.md") })
    }
    
    @Test("discoverHTMLFiles throws for non-existent directory")
    func nonExistentDirectory() async {
        #expect(throws: SitemapError.self) {
            _ = try SitemapGenerator.discoverHTMLFiles(in: "/nonexistent/path")
        }
    }
}

@Suite("SitemapGenerator Path to URL Conversion Tests")
struct PathToURLTests {
    
    @Test("pathToURL converts index.html to base URL")
    func indexHTML() {
        let url = SitemapGenerator.pathToURL(
            filePath: "Websites/21-dev/index.html",
            baseURL: "https://21.dev",
            outputDirectory: "Websites/21-dev"
        )
        
        #expect(url == "https://21.dev/")
    }
    
    @Test("pathToURL converts nested path to URL")
    func nestedPath() {
        let url = SitemapGenerator.pathToURL(
            filePath: "Websites/21-dev/blog/hello-world/index.html",
            baseURL: "https://21.dev",
            outputDirectory: "Websites/21-dev"
        )
        
        #expect(url == "https://21.dev/blog/hello-world/")
    }
    
    @Test("pathToURL handles non-index HTML files")
    func nonIndexHTML() {
        let url = SitemapGenerator.pathToURL(
            filePath: "Websites/21-dev/about.html",
            baseURL: "https://21.dev",
            outputDirectory: "Websites/21-dev"
        )
        
        #expect(url == "https://21.dev/about.html")
    }
    
    @Test("pathToURL handles markdown files")
    func markdownFile() {
        let url = SitemapGenerator.pathToURL(
            filePath: "Websites/md-21-dev/api/overview.md",
            baseURL: "https://md.21.dev",
            outputDirectory: "Websites/md-21-dev"
        )
        
        #expect(url == "https://md.21.dev/api/overview.md")
    }
}

@Suite("SitemapGenerator Generation Tests")
struct GenerationTests {
    
    @Test("generate creates valid sitemap XML")
    func generateSitemap() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-gen-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // Create test HTML file
        try "<!DOCTYPE html>".write(to: tempDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        
        let config = SiteConfiguration(
            name: .dev21,
            baseURL: "https://21.dev",
            outputDirectory: tempDir.path,
            urlDiscoveryStrategy: .htmlFiles(directory: tempDir.path),
            lastmodStrategy: .currentDate
        )
        
        let sitemap = try await SitemapGenerator.generate(for: config)
        
        #expect(sitemap.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
        #expect(sitemap.contains("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">"))
        #expect(sitemap.contains("<loc>https://21.dev/</loc>"))
        #expect(sitemap.contains("</urlset>"))
    }
    
    @Test("generate includes all discovered URLs")
    func multipleURLs() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-multi-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        try "<!DOCTYPE html>".write(to: tempDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        try "<!DOCTYPE html>".write(to: tempDir.appendingPathComponent("about.html"), atomically: true, encoding: .utf8)
        
        let config = SiteConfiguration(
            name: .dev21,
            baseURL: "https://21.dev",
            outputDirectory: tempDir.path,
            urlDiscoveryStrategy: .htmlFiles(directory: tempDir.path),
            lastmodStrategy: .currentDate
        )
        
        let sitemap = try await SitemapGenerator.generate(for: config)
        
        #expect(sitemap.contains("<loc>https://21.dev/</loc>"))
        #expect(sitemap.contains("<loc>https://21.dev/about.html</loc>"))
    }
}
