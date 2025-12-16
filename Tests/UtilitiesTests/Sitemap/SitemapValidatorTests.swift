//
//  SitemapValidatorTests.swift
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

@Suite("SitemapValidator URL Validation Tests")
struct SitemapURLValidationTests {
    
    @Test("validateURL passes for valid HTTPS URL")
    func validHttpsURL() {
        let result = SitemapValidator.validateURL("https://21.dev/")
        #expect(result.isValid == true)
    }
    
    @Test("validateURL passes for valid HTTP URL")
    func validHttpURL() {
        let result = SitemapValidator.validateURL("http://example.com/page")
        #expect(result.isValid == true)
    }
    
    @Test("validateURL fails for URL without scheme")
    func urlWithoutScheme() {
        let result = SitemapValidator.validateURL("21.dev/page")
        #expect(result.isValid == false)
        #expect(result.errors.contains { $0.code == "INVALID_URL" })
    }
    
    @Test("validateURL fails for non-HTTP scheme")
    func nonHttpScheme() {
        let result = SitemapValidator.validateURL("ftp://files.example.com")
        #expect(result.isValid == false)
    }
    
    @Test("validateURL fails for URL exceeding 2048 characters")
    func urlTooLong() {
        let longPath = String(repeating: "a", count: 2040)
        let longURL = "https://21.dev/\(longPath)"
        
        let result = SitemapValidator.validateURL(longURL)
        #expect(result.isValid == false)
        #expect(result.errors.contains { $0.code == "URL_TOO_LONG" })
    }
}

@Suite("SitemapValidator XML Validation Tests")
struct SitemapXMLValidationTests {
    
    @Test("validateXML passes for valid sitemap")
    func validSitemap() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>https://21.dev/</loc>
          <lastmod>2025-12-15T12:00:00Z</lastmod>
        </url>
        </urlset>
        """
        
        let result = SitemapValidator.validateXML(xml)
        #expect(result.isValid == true)
    }
    
    @Test("validateXML fails for missing XML declaration")
    func missingXMLDeclaration() {
        let xml = """
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>https://21.dev/</loc>
        </url>
        </urlset>
        """
        
        let result = SitemapValidator.validateXML(xml)
        #expect(result.isValid == false)
        #expect(result.errors.contains { $0.code == "MISSING_XML_DECLARATION" })
    }
    
    @Test("validateXML fails for missing urlset")
    func missingUrlset() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <url>
          <loc>https://21.dev/</loc>
        </url>
        """
        
        let result = SitemapValidator.validateXML(xml)
        #expect(result.isValid == false)
        #expect(result.errors.contains { $0.code == "MISSING_URLSET" })
    }
    
    @Test("validateXML fails for invalid URL in sitemap")
    func invalidURLInSitemap() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>not-a-valid-url</loc>
          <lastmod>2025-12-15T12:00:00Z</lastmod>
        </url>
        </urlset>
        """
        
        let result = SitemapValidator.validateXML(xml)
        #expect(result.isValid == false)
        #expect(result.errors.contains { $0.code == "INVALID_URL" })
    }
    
    @Test("validateXML reports all invalid URLs")
    func multipleInvalidURLs() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>invalid1</loc>
        </url>
        <url>
          <loc>invalid2</loc>
        </url>
        <url>
          <loc>https://valid.com/</loc>
        </url>
        </urlset>
        """
        
        let result = SitemapValidator.validateXML(xml)
        #expect(result.isValid == false)
        #expect(result.errors.count == 2)
    }
}

@Suite("SitemapValidator File Validation Tests")
struct SitemapFileValidationTests {
    
    @Test("validateFile passes for valid sitemap file")
    func validFile() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-sitemap-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        let sitemapPath = tempDir.appendingPathComponent("sitemap.xml")
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>https://21.dev/</loc>
          <lastmod>2025-12-15T12:00:00Z</lastmod>
        </url>
        </urlset>
        """
        try xml.write(to: sitemapPath, atomically: true, encoding: .utf8)
        
        let result = SitemapValidator.validateFile(at: sitemapPath.path)
        #expect(result.isValid == true)
    }
    
    @Test("validateFile fails for non-existent file")
    func nonExistentFile() {
        let result = SitemapValidator.validateFile(at: "/nonexistent/sitemap.xml")
        #expect(result.isValid == false)
        #expect(result.errors.contains { $0.code == "FILE_NOT_FOUND" })
    }
}
