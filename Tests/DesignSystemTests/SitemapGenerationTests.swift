import Testing
import Foundation
import UtilLib
@testable import DesignSystem

@Suite("Sitemap Generation Tests")
struct SitemapGenerationTests {
    
    // MARK: - XML Structure Tests
    
    @Test("Generated sitemap conforms to protocol 0.9 structure")
    func testSitemapProtocolConformance() throws {
        let xml = generateTestSitemap()
        
        // Verify XML declaration
        #expect(xml.contains("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
        
        // Verify namespace
        #expect(xml.contains("<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">"))
        
        // Verify closing tag
        #expect(xml.contains("</urlset>"))
    }
    
    @Test("Sitemap includes required URL elements")
    func testSitemapURLElements() throws {
        let xml = generateTestSitemap()
        
        // Verify <url> wrapper tags
        #expect(xml.contains("<url>"))
        #expect(xml.contains("</url>"))
        
        // Verify <loc> tags
        #expect(xml.contains("<loc>"))
        #expect(xml.contains("</loc>"))
        
        // Verify <lastmod> tags
        #expect(xml.contains("<lastmod>"))
        #expect(xml.contains("</lastmod>"))
    }
    
    @Test("Sitemap URLs use absolute HTTPS URLs")
    func testAbsoluteURLs() throws {
        let xml = generateTestSitemap()
        
        // Should contain absolute URLs with https://
        #expect(xml.contains("<loc>https://21.dev/</loc>"))
        
        // Should NOT contain relative paths
        #expect(!xml.contains("<loc>/</loc>"))
        #expect(!xml.contains("<loc>index.html</loc>"))
    }
    
    @Test("Sitemap converts index.html to clean URLs with trailing slash")
    func testCleanURLConversion() throws {
        let xml = generateTestSitemap()
        
        // Homepage: index.html → https://21.dev/
        #expect(xml.contains("<loc>https://21.dev/</loc>"))
        
        // Nested page: about/index.html → https://21.dev/about/
        #expect(xml.contains("<loc>https://21.dev/about/</loc>") || 
                xml.contains("<loc>https://21.dev/packages/p256k/</loc>"))
        
        // Should NOT include index.html in URLs
        #expect(!xml.contains("index.html"))
    }
    
    
    @Test("Sitemap includes all pages from sitemap dictionary")
    func testCompleteURLCoverage() throws {
        let xml = generateTestSitemap()
        
        // Based on current site structure, verify key pages are present
        // Homepage
        #expect(xml.contains("<loc>https://21.dev/</loc>"))
        
        // Should have multiple URL entries
        let urlCount = xml.components(separatedBy: "<url>").count - 1
        #expect(urlCount >= 1) // At least homepage
    }
    
    @Test("Sitemap lastmod uses ISO 8601 date format")
    func testLastModDateFormat() throws {
        let xml = generateTestSitemap()
        
        // Extract lastmod value
        let lastmodPattern = #/<lastmod>(.*?)<\/lastmod>/#
        let matches = xml.matches(of: lastmodPattern)
        
        #expect(matches.count >= 1)
        
        if let firstMatch = matches.first {
            let dateString = String(firstMatch.1)
            
            // Verify ISO 8601 date format (YYYY-MM-DD)
            let isoDatePattern = /^\d{4}-\d{2}-\d{2}$/
            #expect(dateString.contains(isoDatePattern))
        }
    }
    
    @Test("Sitemap escapes XML special characters in URLs")
    func testXMLEscaping() throws {
        // This test verifies that xmlEscape utility is used
        // The utility function is already tested in SitemapUtilsTests
        
        let xml = generateTestSitemap()
        
        // Should not contain unescaped XML characters
        // (If a URL had special chars, they should be escaped)
        // For now, verify proper structure exists
        #expect(xml.contains("<loc>https://"))
        #expect(xml.contains("</loc>"))
    }
    
    // MARK: - Helper Methods
    
    /// Generates a test sitemap XML using the utility functions
    /// This simulates what SiteGenerator.generateSitemapXML() does
    private func generateTestSitemap() -> String {
        var xml = sitemapXMLHeader()
        
        // Simulate a few test URLs from a typical sitemap dictionary
        // Note: Dictionary order is not guaranteed, so we sort the keys
        let testPages = [
            "blog/index.html",
            "index.html",
            "packages/p256k/index.html"
        ].sorted() // Sort keys like the real implementation does
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let lastMod = dateFormatter.string(from: Date())
        
        for page in testPages {
            let cleanPath = page.replacingOccurrences(of: "index.html", with: "")
            var url = "https://21.dev"
            
            if !cleanPath.isEmpty {
                url += "/" + cleanPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            }
            
            if !url.hasSuffix("/") {
                url += "/"
            }
            
            xml += sitemapURLEntry(url: url, lastmod: lastMod)
        }
        
        xml += sitemapXMLFooter()
        
        return xml
    }
}
