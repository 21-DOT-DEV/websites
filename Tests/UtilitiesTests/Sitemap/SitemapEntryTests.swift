//
//  SitemapEntryTests.swift
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

@Suite("SitemapEntry Tests")
struct SitemapEntryTests {
    
    @Test("SitemapEntry initializes with valid URL and date")
    func validInitialization() throws {
        let date = Date()
        let entry = try SitemapEntry(url: "https://21.dev/", lastmod: date)
        
        #expect(entry.url == "https://21.dev/")
        #expect(entry.lastmod == date)
    }
    
    @Test("SitemapEntry throws for invalid URL")
    func invalidURL() {
        let date = Date()
        
        #expect(throws: SitemapError.self) {
            _ = try SitemapEntry(url: "not a url", lastmod: date)
        }
    }
    
    @Test("SitemapEntry throws for URL without scheme")
    func urlWithoutScheme() {
        let date = Date()
        
        #expect(throws: SitemapError.self) {
            _ = try SitemapEntry(url: "21.dev/page", lastmod: date)
        }
    }
    
    @Test("SitemapEntry throws for non-HTTP scheme")
    func nonHttpScheme() {
        let date = Date()
        
        #expect(throws: SitemapError.self) {
            _ = try SitemapEntry(url: "ftp://files.example.com", lastmod: date)
        }
    }
    
    @Test("SitemapEntry throws for URL exceeding 2048 characters")
    func urlTooLong() {
        let date = Date()
        let longPath = String(repeating: "a", count: 2040)
        let longURL = "https://21.dev/\(longPath)"
        
        #expect(longURL.count > 2048)
        #expect(throws: SitemapError.self) {
            _ = try SitemapEntry(url: longURL, lastmod: date)
        }
    }
    
    @Test("SitemapEntry accepts URL at exactly 2048 characters")
    func maxLengthURL() throws {
        let date = Date()
        let basePath = "https://21.dev/"
        let padding = String(repeating: "a", count: 2048 - basePath.count)
        let maxURL = basePath + padding
        
        #expect(maxURL.count == 2048)
        let entry = try SitemapEntry(url: maxURL, lastmod: date)
        #expect(entry.url == maxURL)
    }
    
    @Test("SitemapEntry is Equatable")
    func equatable() throws {
        let date = Date()
        let entry1 = try SitemapEntry(url: "https://21.dev/", lastmod: date)
        let entry2 = try SitemapEntry(url: "https://21.dev/", lastmod: date)
        
        #expect(entry1 == entry2)
    }
    
    @Test("SitemapEntry is Codable")
    func codable() throws {
        let date = ISO8601DateFormatter().date(from: "2025-12-15T12:00:00Z")!
        let entry = try SitemapEntry(url: "https://21.dev/", lastmod: date)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(SitemapEntry.self, from: data)
        
        #expect(decoded == entry)
    }
}

@Suite("SitemapEntry XML Output Tests")
struct SitemapEntryXMLTests {
    
    @Test("toXML produces valid sitemap URL entry")
    func xmlOutput() throws {
        let date = ISO8601DateFormatter().date(from: "2025-12-15T00:00:00Z")!
        let entry = try SitemapEntry(url: "https://21.dev/", lastmod: date)
        
        let xml = entry.toXML()
        
        #expect(xml.contains("<url>"))
        #expect(xml.contains("<loc>https://21.dev/</loc>"))
        #expect(xml.contains("<lastmod>2025-12-15"))
        #expect(xml.contains("</url>"))
    }
    
    @Test("toXML escapes special characters in URL")
    func xmlEscaping() throws {
        let date = Date()
        let entry = try SitemapEntry(url: "https://21.dev/?a=1&b=2", lastmod: date)
        
        let xml = entry.toXML()
        
        #expect(xml.contains("<loc>https://21.dev/?a=1&amp;b=2</loc>"))
    }
}

@Suite("SitemapError Tests")
struct SitemapErrorTests {
    
    @Test("SitemapError.invalidURL contains the invalid URL")
    func invalidURLError() {
        let error = SitemapError.invalidURL("bad-url")
        
        if case .invalidURL(let url) = error {
            #expect(url == "bad-url")
        } else {
            Issue.record("Expected invalidURL error")
        }
    }
    
    @Test("SitemapError has descriptive message")
    func errorDescription() {
        let error = SitemapError.invalidURL("bad-url")
        
        #expect(error.localizedDescription.contains("bad-url"))
    }
}
