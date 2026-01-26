//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import Foundation
import UtilLib
@testable import DesignSystem

@Suite("Sitemap Utility Tests")
struct SitemapUtilsTests {
    
    // MARK: - XML Escaping Tests
    
    @Test("XML escaping handles ampersands")
    func testXMLEscapingAmpersand() throws {
        let input = "Search & Replace"
        let expected = "Search &amp; Replace"
        
        #expect(xmlEscape(input) == expected)
    }
    
    @Test("XML escaping handles less than")
    func testXMLEscapingLessThan() throws {
        let input = "5 < 10"
        let expected = "5 &lt; 10"
        
        #expect(xmlEscape(input) == expected)
    }
    
    @Test("XML escaping handles greater than")
    func testXMLEscapingGreaterThan() throws {
        let input = "10 > 5"
        let expected = "10 &gt; 5"
        
        #expect(xmlEscape(input) == expected)
    }
    
    @Test("XML escaping handles double quotes")
    func testXMLEscapingQuotes() throws {
        let input = #"The "quoted" text"#
        let expected = #"The &quot;quoted&quot; text"#
        
        #expect(xmlEscape(input) == expected)
    }
    
    @Test("XML escaping handles apostrophes")
    func testXMLEscapingApostrophes() throws {
        let input = "It's working"
        let expected = "It&apos;s working"
        
        #expect(xmlEscape(input) == expected)
    }
    
    @Test("XML escaping handles multiple special characters")
    func testXMLEscapingMultiple() throws {
        let input = #"<tag attr="value">Text & "more" text</tag>"#
        let expected = #"&lt;tag attr=&quot;value&quot;&gt;Text &amp; &quot;more&quot; text&lt;/tag&gt;"#
        
        #expect(xmlEscape(input) == expected)
    }
    
    @Test("XML escaping handles empty string")
    func testXMLEscapingEmptyString() throws {
        let input = ""
        let expected = ""
        
        #expect(xmlEscape(input) == expected)
    }
    
    @Test("XML escaping preserves regular text")
    func testXMLEscapingRegularText() throws {
        let input = "Hello World 123"
        let expected = "Hello World 123"
        
        #expect(xmlEscape(input) == expected)
    }
    
    // MARK: - URL Validation Tests
    
    @Test("URL validation accepts valid HTTPS URL")
    func testURLValidationHTTPS() throws {
        let url = "https://21.dev/about"
        
        #expect(isValidSitemapURL(url) == true)
    }
    
    @Test("URL validation accepts valid HTTP URL")
    func testURLValidationHTTP() throws {
        let url = "http://21.dev/contact"
        
        #expect(isValidSitemapURL(url) == true)
    }
    
    @Test("URL validation rejects non-HTTPS/HTTP schemes")
    func testURLValidationInvalidScheme() throws {
        let url = "ftp://21.dev/file"
        
        #expect(isValidSitemapURL(url) == false)
    }
    
    @Test("URL validation rejects relative URLs")
    func testURLValidationRelative() throws {
        let url = "/about/team"
        
        #expect(isValidSitemapURL(url) == false)
    }
    
    @Test("URL validation rejects URLs without scheme")
    func testURLValidationNoScheme() throws {
        let url = "21.dev/about"
        
        #expect(isValidSitemapURL(url) == false)
    }
    
    @Test("URL validation enforces maximum length (2048 chars)")
    func testURLValidationMaxLength() throws {
        // Sitemap protocol 0.9 max URL length is 2048 characters
        let longPath = String(repeating: "a", count: 2000)
        let validURL = "https://21.dev/\(longPath)"
        let invalidURL = "https://21.dev/" + String(repeating: "a", count: 2049)
        
        #expect(isValidSitemapURL(validURL) == true)
        #expect(isValidSitemapURL(invalidURL) == false)
    }
    
    @Test("URL validation accepts URLs with query parameters")
    func testURLValidationQueryParams() throws {
        let url = "https://21.dev/search?q=swift&lang=en"
        
        #expect(isValidSitemapURL(url) == true)
    }
    
    @Test("URL validation accepts URLs with fragments")
    func testURLValidationFragment() throws {
        let url = "https://21.dev/docs#installation"
        
        #expect(isValidSitemapURL(url) == true)
    }
    
    @Test("URL validation rejects malformed URLs")
    func testURLValidationMalformed() throws {
        let url = "https://21 .dev/about"  // Space in domain
        
        #expect(isValidSitemapURL(url) == false)
    }
    
    @Test("URL validation accepts international domains")
    func testURLValidationIDN() throws {
        let url = "https://münchen.de/page"
        
        #expect(isValidSitemapURL(url) == true)
    }
}
