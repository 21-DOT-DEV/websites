import Testing
import Foundation
@testable import DesignSystem
import Slipstream
import TestUtils

/// Tests for CSS collection during site generation.
///
/// These tests verify that component CSS is correctly collected and written
/// to the generated stylesheet when using `renderSitemap` with CSS collection.
struct CSSCollectionTests {
    
    // MARK: - Test Pages
    
    /// A page with Tabs component (nested in AttributeModifierView via .language())
    private var pageWithTabs: some View {
        BasePage(title: "Test Page") {
            Tabs(id: "test-tabs") {
                Tab("First") { Text("Content 1") }
                Tab("Second") { Text("Content 2") }
            }
        }
    }
    
    /// A page with SiteHeader component
    private var pageWithHeader: some View {
        BasePage(title: "Test Page") {
            SiteHeader(
                logoText: "Test",
                navigationLinks: [NavigationLink(title: "Link", href: "/")]
            )
        }
    }
    
    /// A page with multiple StyleModifier components
    private var pageWithMultipleComponents: some View {
        BasePage(title: "Test Page") {
            SiteHeader(
                logoText: "Test",
                navigationLinks: [NavigationLink(title: "Link", href: "/")]
            )
            Tabs(id: "multi-tabs") {
                Tab("Tab 1") { Text("Content 1") }
                Tab("Tab 2") { Text("Content 2") }
            }
        }
    }
    
    // MARK: - Tests
    
    @Test("CSS collection generates Tabs component CSS")
    func testTabsCSSCollection() async throws {
        let tempURL = TestUtils.createTempDirectory(suffix: "-css-tabs")
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        let baseCSSURL = tempURL.appendingPathComponent("style.base.css")
        let outputCSSURL = tempURL.appendingPathComponent("style.input.css")
        
        // Create minimal base CSS file
        try "@tailwind base;\n@tailwind components;\n@tailwind utilities;\n".write(
            to: baseCSSURL,
            atomically: true,
            encoding: .utf8
        )
        
        let sitemap: Sitemap = ["index.html": pageWithTabs]
        
        // Run CSS collection via renderSitemap
        try await renderSitemap(
            sitemap,
            to: tempURL,
            baseCSS: baseCSSURL,
            stylesheet: "style.input.css"
        )
        
        // Verify CSS file was generated
        #expect(FileManager.default.fileExists(atPath: outputCSSURL.path))
        
        let css = try String(contentsOf: outputCSSURL, encoding: .utf8)
        
        // Verify Tabs component CSS is present
        #expect(css.contains("Tabs[test-tabs]"), "Should contain Tabs component comment")
        #expect(css.contains(".tab-content"), "Should contain .tab-content class")
        #expect(css.contains("#test-tabs-content-0"), "Should contain tab content ID")
        #expect(css.contains("#test-tabs-tab-0:checked"), "Should contain checked selector")
        
        TestUtils.cleanupDirectory(tempURL)
    }
    
    @Test("CSS collection generates SiteHeader component CSS")
    func testSiteHeaderCSSCollection() async throws {
        let tempURL = TestUtils.createTempDirectory(suffix: "-css-header")
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        let baseCSSURL = tempURL.appendingPathComponent("style.base.css")
        let outputCSSURL = tempURL.appendingPathComponent("style.input.css")
        
        // Create minimal base CSS file
        try "@tailwind base;\n@tailwind components;\n@tailwind utilities;\n".write(
            to: baseCSSURL,
            atomically: true,
            encoding: .utf8
        )
        
        let sitemap: Sitemap = ["index.html": pageWithHeader]
        
        // Run CSS collection via renderSitemap
        try await renderSitemap(
            sitemap,
            to: tempURL,
            baseCSS: baseCSSURL,
            stylesheet: "style.input.css"
        )
        
        // Verify CSS file was generated
        #expect(FileManager.default.fileExists(atPath: outputCSSURL.path))
        
        let css = try String(contentsOf: outputCSSURL, encoding: .utf8)
        
        // Verify SiteHeader component CSS is present
        #expect(css.contains("SiteHeader"), "Should contain SiteHeader component comment")
        #expect(css.contains(".menu-button") || css.contains(".menu-items"), "Should contain menu styles")
        
        TestUtils.cleanupDirectory(tempURL)
    }
    
    @Test("CSS collection finds components nested in AttributeModifierView")
    func testCSSCollectionThroughAttributeModifier() async throws {
        // This is a regression test for the bug where AttributeModifierView
        // was missing a style() method, causing CSS collection to fail
        // for any component nested inside a view with attributes like .language()
        
        let tempURL = TestUtils.createTempDirectory(suffix: "-css-attr")
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        let baseCSSURL = tempURL.appendingPathComponent("style.base.css")
        let outputCSSURL = tempURL.appendingPathComponent("style.input.css")
        
        // Create minimal base CSS file
        try "@tailwind base;\n@tailwind components;\n@tailwind utilities;\n".write(
            to: baseCSSURL,
            atomically: true,
            encoding: .utf8
        )
        
        // BasePage uses .language("en") which wraps content in AttributeModifierView
        let sitemap: Sitemap = ["index.html": pageWithTabs]
        
        try await renderSitemap(
            sitemap,
            to: tempURL,
            baseCSS: baseCSSURL,
            stylesheet: "style.input.css"
        )
        
        let css = try String(contentsOf: outputCSSURL, encoding: .utf8)
        
        // Tabs component should be found even though it's nested inside
        // BasePage's body which is wrapped in AttributeModifierView via .language()
        #expect(css.contains("Tabs[test-tabs]"), 
                "Tabs CSS should be collected through AttributeModifierView wrapper")
        
        TestUtils.cleanupDirectory(tempURL)
    }
    
    @Test("CSS collection handles multiple components on same page")
    func testMultipleComponentsCSSCollection() async throws {
        let tempURL = TestUtils.createTempDirectory(suffix: "-css-multi")
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        let baseCSSURL = tempURL.appendingPathComponent("style.base.css")
        let outputCSSURL = tempURL.appendingPathComponent("style.input.css")
        
        // Create minimal base CSS file
        try "@tailwind base;\n@tailwind components;\n@tailwind utilities;\n".write(
            to: baseCSSURL,
            atomically: true,
            encoding: .utf8
        )
        
        let sitemap: Sitemap = ["index.html": pageWithMultipleComponents]
        
        try await renderSitemap(
            sitemap,
            to: tempURL,
            baseCSS: baseCSSURL,
            stylesheet: "style.input.css"
        )
        
        let css = try String(contentsOf: outputCSSURL, encoding: .utf8)
        
        // Both SiteHeader and Tabs CSS should be present
        #expect(css.contains("SiteHeader"), "Should contain SiteHeader CSS")
        #expect(css.contains("Tabs[multi-tabs]"), "Should contain Tabs CSS")
        
        TestUtils.cleanupDirectory(tempURL)
    }
    
    @Test("CSS collection wraps styles in @layer components")
    func testCSSLayerWrapping() async throws {
        let tempURL = TestUtils.createTempDirectory(suffix: "-css-layer")
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        let baseCSSURL = tempURL.appendingPathComponent("style.base.css")
        let outputCSSURL = tempURL.appendingPathComponent("style.input.css")
        
        // Create minimal base CSS file
        try "@tailwind base;\n@tailwind components;\n@tailwind utilities;\n".write(
            to: baseCSSURL,
            atomically: true,
            encoding: .utf8
        )
        
        let sitemap: Sitemap = ["index.html": pageWithTabs]
        
        try await renderSitemap(
            sitemap,
            to: tempURL,
            baseCSS: baseCSSURL,
            stylesheet: "style.input.css"
        )
        
        let css = try String(contentsOf: outputCSSURL, encoding: .utf8)
        
        // Component styles should be wrapped in @layer components for Tailwind v3
        #expect(css.contains("@layer components"), 
                "Component CSS should be wrapped in @layer components")
        
        TestUtils.cleanupDirectory(tempURL)
    }
}
