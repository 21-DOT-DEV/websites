//
//  SitemapEntryTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import UtilLib

@Suite("SitemapEntry Tests")
struct SitemapEntryTests {
    
    @Test("SitemapEntry initializes with valid URL")
    func validInitialization() throws {
        let entry = try SitemapEntry(url: "https://21.dev/")
        
        #expect(entry.url == "https://21.dev/")
    }
    
    @Test("SitemapEntry throws for invalid URL")
    func invalidURL() {
        #expect(throws: SitemapError.self) {
            _ = try SitemapEntry(url: "not a url")
        }
    }
    
    @Test("SitemapEntry throws for URL without scheme")
    func urlWithoutScheme() {
        #expect(throws: SitemapError.self) {
            _ = try SitemapEntry(url: "21.dev/page")
        }
    }
    
    @Test("SitemapEntry throws for non-HTTP scheme")
    func nonHttpScheme() {
        #expect(throws: SitemapError.self) {
            _ = try SitemapEntry(url: "ftp://files.example.com")
        }
    }
    
    @Test("SitemapEntry throws for URL exceeding 2048 characters")
    func urlTooLong() {
        let longPath = String(repeating: "a", count: 2040)
        let longURL = "https://21.dev/\(longPath)"
        
        #expect(longURL.count > 2048)
        #expect(throws: SitemapError.self) {
            _ = try SitemapEntry(url: longURL)
        }
    }
    
    @Test("SitemapEntry accepts URL at exactly 2048 characters")
    func maxLengthURL() throws {
        let basePath = "https://21.dev/"
        let padding = String(repeating: "a", count: 2048 - basePath.count)
        let maxURL = basePath + padding
        
        #expect(maxURL.count == 2048)
        let entry = try SitemapEntry(url: maxURL)
        #expect(entry.url == maxURL)
    }
    
    @Test("SitemapEntry is Equatable")
    func equatable() throws {
        let entry1 = try SitemapEntry(url: "https://21.dev/")
        let entry2 = try SitemapEntry(url: "https://21.dev/")
        
        #expect(entry1 == entry2)
    }
    
    @Test("SitemapEntry is Codable")
    func codable() throws {
        let entry = try SitemapEntry(url: "https://21.dev/")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(entry)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SitemapEntry.self, from: data)
        
        #expect(decoded == entry)
    }
}

@Suite("SitemapEntry XML Output Tests")
struct SitemapEntryXMLTests {
    
    @Test("toXML produces valid sitemap URL entry without <lastmod>")
    func xmlOutput() throws {
        let entry = try SitemapEntry(url: "https://21.dev/")
        
        let xml = entry.toXML()
        
        #expect(xml.contains("<url>"))
        #expect(xml.contains("<loc>https://21.dev/</loc>"))
        #expect(xml.contains("</url>"))
        // <lastmod> is intentionally never emitted (sitemap protocol 0.9 optional element)
        #expect(!xml.contains("<lastmod>"))
    }
    
    @Test("toXML escapes special characters in URL")
    func xmlEscaping() throws {
        let entry = try SitemapEntry(url: "https://21.dev/?a=1&b=2")
        
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
