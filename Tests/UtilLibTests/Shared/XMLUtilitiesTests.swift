//
//  XMLUtilitiesTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
@testable import UtilLib

@Suite("XML Escape Tests")
struct XMLEscapeTests {
    
    @Test("xmlEscape handles ampersand")
    func escapeAmpersand() {
        #expect(xmlEscape("foo & bar") == "foo &amp; bar")
    }
    
    @Test("xmlEscape handles less than")
    func escapeLessThan() {
        #expect(xmlEscape("a < b") == "a &lt; b")
    }
    
    @Test("xmlEscape handles greater than")
    func escapeGreaterThan() {
        #expect(xmlEscape("a > b") == "a &gt; b")
    }
    
    @Test("xmlEscape handles single quote")
    func escapeSingleQuote() {
        #expect(xmlEscape("it's") == "it&apos;s")
    }
    
    @Test("xmlEscape handles double quote")
    func escapeDoubleQuote() {
        #expect(xmlEscape("say \"hello\"") == "say &quot;hello&quot;")
    }
    
    @Test("xmlEscape handles multiple special characters")
    func escapeMultiple() {
        let input = "<tag attr=\"value\">A & B's</tag>"
        let expected = "&lt;tag attr=&quot;value&quot;&gt;A &amp; B&apos;s&lt;/tag&gt;"
        #expect(xmlEscape(input) == expected)
    }
    
    @Test("xmlEscape returns unchanged string when no special chars")
    func noEscapeNeeded() {
        #expect(xmlEscape("hello world") == "hello world")
    }
    
    @Test("xmlEscape handles empty string")
    func emptyString() {
        #expect(xmlEscape("") == "")
    }
    
    @Test("xmlEscape handles URL with ampersand")
    func urlWithAmpersand() {
        let url = "https://example.com?a=1&b=2"
        let expected = "https://example.com?a=1&amp;b=2"
        #expect(xmlEscape(url) == expected)
    }
}

@Suite("Sitemap XML Header/Footer Tests")
struct SitemapXMLTests {
    
    @Test("sitemapXMLHeader returns valid XML header")
    func xmlHeader() {
        let header = sitemapXMLHeader()
        
        #expect(header.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
        #expect(header.contains("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">"))
    }
    
    @Test("sitemapXMLFooter returns closing tag")
    func xmlFooter() {
        let footer = sitemapXMLFooter()
        
        #expect(footer == "</urlset>")
    }
    
    @Test("sitemapURLEntry formats URL entry correctly")
    func urlEntry() {
        let entry = sitemapURLEntry(url: "https://21.dev/", lastmod: "2025-12-15")
        
        #expect(entry.contains("<url>"))
        #expect(entry.contains("<loc>https://21.dev/</loc>"))
        #expect(entry.contains("<lastmod>2025-12-15</lastmod>"))
        #expect(entry.contains("</url>"))
    }
    
    @Test("sitemapURLEntry escapes special characters in URL")
    func urlEntryWithSpecialChars() {
        let entry = sitemapURLEntry(url: "https://21.dev/?a=1&b=2", lastmod: "2025-12-15")
        
        #expect(entry.contains("<loc>https://21.dev/?a=1&amp;b=2</loc>"))
    }
}

@Suite("URL Validation Tests")
struct URLValidationTests {
    
    @Test("isValidSitemapURL accepts valid HTTPS URL")
    func validHttpsURL() {
        #expect(isValidSitemapURL("https://21.dev/") == true)
    }
    
    @Test("isValidSitemapURL accepts valid HTTP URL")
    func validHttpURL() {
        #expect(isValidSitemapURL("http://example.com/page") == true)
    }
    
    @Test("isValidSitemapURL rejects URL without scheme")
    func noScheme() {
        #expect(isValidSitemapURL("21.dev/page") == false)
    }
    
    @Test("isValidSitemapURL rejects non-HTTP scheme")
    func nonHttpScheme() {
        #expect(isValidSitemapURL("ftp://files.example.com") == false)
        #expect(isValidSitemapURL("mailto:test@example.com") == false)
    }
    
    @Test("isValidSitemapURL rejects URL without host")
    func noHost() {
        #expect(isValidSitemapURL("https:///path") == false)
    }
    
    @Test("isValidSitemapURL rejects URL exceeding 2048 characters")
    func tooLongURL() {
        let longPath = String(repeating: "a", count: 2040)
        let longURL = "https://21.dev/\(longPath)"
        #expect(longURL.count > 2048)
        #expect(isValidSitemapURL(longURL) == false)
    }
    
    @Test("isValidSitemapURL accepts URL at exactly 2048 characters")
    func maxLengthURL() {
        let basePath = "https://21.dev/"
        let padding = String(repeating: "a", count: 2048 - basePath.count)
        let maxURL = basePath + padding
        #expect(maxURL.count == 2048)
        #expect(isValidSitemapURL(maxURL) == true)
    }
    
    @Test("isValidSitemapURL rejects empty string")
    func emptyURL() {
        #expect(isValidSitemapURL("") == false)
    }
    
    @Test("isValidSitemapURL rejects malformed URL")
    func malformedURL() {
        #expect(isValidSitemapURL("not a url") == false)
    }
}
