import Testing
import Foundation
@testable import DesignSystem
import Slipstream
import TestUtils

struct Site21DEVTests {
    
    // Recreate the 21-dev sitemap for testing (since executable targets can't be imported)
    private var homepage: BasePage {
        BasePage(title: "21.dev - Bitcoin Development Tools") {
            PlaceholderView(text: "Equipping developers with the tools they need today to build the Bitcoin apps of tomorrow. 📱")
        }
    }
    
    private var sitemap: Sitemap {
        ["index.html": homepage]
    }
    
    @Test("21-dev site generates index.html with correct content")
    func testSiteGeneration() throws {
        // Create temporary output directory
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("test-21-dev-\(UUID())")
        
        // Test complete site generation pipeline
        try renderSitemap(sitemap, to: tempURL)
        
        // Verify index.html was created
        let indexPath = tempURL.appendingPathComponent("index.html")
        #expect(FileManager.default.fileExists(atPath: indexPath.path))
        
        // Verify HTML content is correct
        let html = try String(contentsOf: indexPath, encoding: .utf8)
        
        // Check title using TestUtils
        TestUtils.assertValidTitle(html, expectedTitle: "21.dev - Bitcoin Development Tools")
        
        // Check placeholder content using TestUtils
        TestUtils.assertContainsText(html, texts: [
            "Equipping developers with the tools they need today",
            "Bitcoin apps of tomorrow",
            "📱"
        ])
        
        // Check HTML structure using TestUtils
        TestUtils.assertValidHTMLDocument(html)
        
        // Check UTF-8 charset meta tag for emoji support using TestUtils
        TestUtils.assertContainsUTF8Charset(html)
        
        // Check stylesheet link using TestUtils
        TestUtils.assertContainsStylesheet(html)
        
        // Check PlaceholderView classes are applied using TestUtils
        TestUtils.assertContainsTailwindClasses(html, classes: TestUtils.placeholderViewClasses)
        
        // Cleanup using TestUtils
        TestUtils.cleanupDirectory(tempURL)
    }
    
    @Test("21-dev homepage uses correct DesignSystem components")
    func testHomepageComponentComposition() throws {
        // Test that homepage correctly combines DesignSystem components
        let homepageHTML = try TestUtils.renderHTML(homepage)
        
        // Verify BasePage structure using TestUtils
        TestUtils.assertValidHTMLDocument(homepageHTML)
        TestUtils.assertValidTitle(homepageHTML, expectedTitle: "21.dev - Bitcoin Development Tools")
        TestUtils.assertContainsUTF8Charset(homepageHTML)
        TestUtils.assertContainsStylesheet(homepageHTML)
        
        // Verify PlaceholderView structure using TestUtils
        TestUtils.assertContainsTailwindClasses(homepageHTML, classes: TestUtils.placeholderViewClasses)
        
        // Verify actual content using TestUtils
        TestUtils.assertContainsText(homepageHTML, texts: [
            "Equipping developers with the tools they need today",
            "build the Bitcoin apps of tomorrow",
            "📱"
        ])
    }
    
    @Test("21-dev sitemap structure is correct")
    func testSitemapStructure() throws {
        // Verify sitemap contains expected pages
        #expect(sitemap.count == 1)
        #expect(sitemap.keys.contains("index.html"))
        
        // Verify homepage can be rendered without errors
        let indexPage = sitemap["index.html"]
        #expect(indexPage != nil)
        
        if let indexPage = indexPage {
            let html = try TestUtils.renderHTML(indexPage)
            #expect(!html.isEmpty)
            TestUtils.assertContainsText(html, texts: ["21.dev"])
        }
    }
    
    @Test("21-dev site generates with proper file permissions")
    func testSiteFilePermissions() throws {
        // Create temporary output directory using TestUtils
        let tempURL = TestUtils.createTempDirectory(suffix: "-permissions")
        
        // Test complete site generation pipeline
        try renderSitemap(sitemap, to: tempURL)
        
        // Verify index.html has correct permissions (readable)
        let indexPath = tempURL.appendingPathComponent("index.html")
        let attributes = try FileManager.default.attributesOfItem(atPath: indexPath.path)
        let permissions = attributes[.posixPermissions] as? Int
        
        // Should be readable (at minimum)
        #expect(permissions != nil)
        
        // Verify file is readable
        let html = try String(contentsOf: indexPath, encoding: .utf8)
        #expect(!html.isEmpty)
        
        // Cleanup using TestUtils
        TestUtils.cleanupDirectory(tempURL)
    }
    
    @Test("21-dev site handles output directory creation")
    func testOutputDirectoryCreation() throws {
        // Create nested temporary output directory that doesn't exist using TestUtils
        let tempURL = TestUtils.createTempDirectory(suffix: "-nested")
            .appendingPathComponent("21-dev-output")
        
        // Ensure directory doesn't exist initially
        #expect(!FileManager.default.fileExists(atPath: tempURL.path))
        
        // Test complete site generation pipeline
        try renderSitemap(sitemap, to: tempURL)
        
        // Verify directory was created
        #expect(FileManager.default.fileExists(atPath: tempURL.path))
        
        // Verify index.html was created in the new directory
        let indexPath = tempURL.appendingPathComponent("index.html")
        #expect(FileManager.default.fileExists(atPath: indexPath.path))
        
        // Cleanup using TestUtils
        TestUtils.cleanupDirectory(tempURL.deletingLastPathComponent())
    }
    
    @Test("21-dev site content is deterministic")
    func testSiteDeterministicOutput() throws {
        // Generate the same site twice to ensure deterministic output using TestUtils
        let tempURL1 = TestUtils.createTempDirectory(suffix: "-deterministic-1")
        let tempURL2 = TestUtils.createTempDirectory(suffix: "-deterministic-2")
        
        // Generate site twice
        try renderSitemap(sitemap, to: tempURL1)
        try renderSitemap(sitemap, to: tempURL2)
        
        // Read both outputs
        let html1 = try String(contentsOf: tempURL1.appendingPathComponent("index.html"), encoding: .utf8)
        let html2 = try String(contentsOf: tempURL2.appendingPathComponent("index.html"), encoding: .utf8)
        
        // Should be identical
        #expect(html1 == html2)
        
        // Cleanup using TestUtils
        TestUtils.cleanupDirectory(tempURL1)
        TestUtils.cleanupDirectory(tempURL2)
    }
    
    @Test("21-dev complete HTML document validation")
    func testCompleteHTMLDocumentStructure() throws {
        let tempURL = TestUtils.createTempDirectory(suffix: "-validation")
        
        try renderSitemap(sitemap, to: tempURL)
        let html = try String(contentsOf: tempURL.appendingPathComponent("index.html"), encoding: .utf8)
        
        // Verify complete HTML document structure using TestUtils
        TestUtils.assertValidHTMLDocument(html)
        
        // Additional integration-specific validations
        TestUtils.assertValidTitle(html, expectedTitle: "21.dev - Bitcoin Development Tools")
        TestUtils.assertContainsUTF8Charset(html)
        TestUtils.assertContainsStylesheet(html)
        
        // Cleanup using TestUtils
        TestUtils.cleanupDirectory(tempURL)
    }
}
