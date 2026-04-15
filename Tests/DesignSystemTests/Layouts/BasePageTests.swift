//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import Foundation
@testable import DesignSystem
import SchemaLib
import Slipstream
import TestUtils

struct BasePageTests {
    
    @Test("BasePage generates complete HTML document structure")
    func testBasePageCompleteStructure() throws {
        let page = BasePage(title: "Test Page") {
            PlaceholderView(text: "Test Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        // Verify HTML document structure using TestUtils
        TestUtils.assertValidHTMLDocument(html)
        TestUtils.assertValidTitle(html, expectedTitle: "Test Page")
        TestUtils.assertContainsText(html, texts: ["Test Content"])
    }
    
    @Test("BasePage includes default stylesheet link")
    func testBasePageDefaultStylesheet() throws {
        let page = BasePage(title: "Styled Page") {
            Text("Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        // Verify default stylesheet is linked using TestUtils
        TestUtils.assertContainsStylesheet(html)
    }
    
    @Test("BasePage includes mobile-friendly viewport meta tag")
    func testBasePageViewportMetaTag() throws {
        let page = BasePage(title: "Mobile Page") {
            Text("Mobile Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        // Verify viewport meta tag is present with correct mobile-friendly attributes
        TestUtils.assertContainsText(html, texts: [
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />"
        ])
    }
    
    @Test("BasePage accepts custom stylesheet parameter")
    func testBasePageCustomStylesheet() throws {
        let customStylesheet = "custom/styles.css"
        let page = BasePage(
            title: "Custom Styled Page",
            stylesheet: customStylesheet
        ) {
            Text("Custom Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        TestUtils.assertContainsStylesheet(html, stylesheetPath: customStylesheet)
        TestUtils.assertDoesNotContainText(html, texts: ["static/style.css"])
    }
    
    @Test("BasePage handles complex body content")
    func testBasePageComplexBodyContent() throws {
        let page = BasePage(title: "Complex Page") {
            Div {
                Text("Header")
                PlaceholderView(text: "Main Content")
                Text("Footer")
            }
        }
        let html = try TestUtils.renderHTML(page)
        
        #expect(html.contains("Header"))
        #expect(html.contains("Main Content"))
        #expect(html.contains("Footer"))
        #expect(html.contains("<div"))
    }
    
    @Test("BasePage handles empty body content")
    func testBasePageEmptyBodyContent() throws {
        let page = BasePage(title: "Empty Page") {
            EmptyView()
        }
        let html = try TestUtils.renderHTML(page)
        
        // Should still render complete structure using TestUtils
        TestUtils.assertValidTitle(html, expectedTitle: "Empty Page")
        TestUtils.assertValidHTMLDocument(html)
    }
    
    @Test("BasePage title is properly HTML-escaped")
    func testBasePageTitleEscaping() throws {
        let title = "Test & <Script> Title"
        let page = BasePage(title: title) {
            Text("Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        // Title should be HTML-escaped in the title tag using TestUtils
        TestUtils.assertContainsText(html, texts: ["&amp;", "&lt;Script&gt;"])
        TestUtils.assertDoesNotContainText(html, texts: ["<Script>"])
    }
    
    @Test("BasePage with PlaceholderView integration")
    func testBasePagePlaceholderViewIntegration() throws {
        let page = BasePage(title: "21.dev - Bitcoin Development Tools") {
            PlaceholderView(text: "Equipping developers with tools 🚀")
        }
        let html = try TestUtils.renderHTML(page)
        
        // Verify integration works correctly using TestUtils
        TestUtils.assertValidTitle(html, expectedTitle: "21.dev - Bitcoin Development Tools")
        TestUtils.assertContainsText(html, texts: ["Equipping developers with tools 🚀"])
        TestUtils.assertContainsTailwindClasses(html, classes: ["h-screen", "text-7xl"])
        TestUtils.assertContainsStylesheet(html)
        
        // Ensure proper nesting
        let bodyStartRange = html.range(of: "<body>")
        let bodyEndRange = html.range(of: "</body>")
        #expect(bodyStartRange != nil && bodyEndRange != nil)
        
        if let bodyStart = bodyStartRange?.lowerBound, let bodyEnd = bodyEndRange?.lowerBound {
            let bodyContent = String(html[bodyStart..<bodyEnd])
            #expect(bodyContent.contains("h-screen"))
        }
    }
    
    @Test("BasePage renders llms-txt link when llmsTxtURL provided")
    func testBasePageLLMsTxtLink() throws {
        let page = BasePage(
            title: "Test",
            llmsTxtURL: URL(string: "https://21.dev/llms.txt")
        ) {
            Text("Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        #expect(html.contains("rel=\"llms-txt\""))
        #expect(html.contains("href=\"https://21.dev/llms.txt\""))
    }
    
    @Test("BasePage omits llms-txt link when llmsTxtURL is nil")
    func testBasePageNoLLMsTxtLink() throws {
        let page = BasePage(title: "Test") {
            Text("Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        #expect(!html.contains("llms-txt"))
    }
    
    @Test("BasePage renders alternate markdown link when alternateMarkdownURL provided")
    func testBasePageAlternateMarkdown() throws {
        let page = BasePage(
            title: "Test",
            alternateMarkdownURL: URL(string: "https://21.dev/data/blog/hello.md")
        ) {
            Text("Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        #expect(html.contains("rel=\"alternate\""))
        #expect(html.contains("type=\"text/markdown\""))
        #expect(html.contains("href=\"https://21.dev/data/blog/hello.md\""))
    }
    
    @Test("BasePage omits alternate link when alternateMarkdownURL is nil")
    func testBasePageNoAlternateMarkdown() throws {
        let page = BasePage(title: "Test") {
            Text("Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        #expect(!html.contains("text/markdown"))
    }
    
    @Test("BasePage renders both llms-txt and alternate markdown links together")
    func testBasePageBothLinks() throws {
        let page = BasePage(
            title: "Blog Post",
            llmsTxtURL: URL(string: "https://21.dev/llms.txt"),
            alternateMarkdownURL: URL(string: "https://21.dev/data/blog/post.md")
        ) {
            Text("Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        #expect(html.contains("rel=\"llms-txt\""))
        #expect(html.contains("rel=\"alternate\""))
        #expect(html.contains("text/markdown"))
    }
    
    @Test("BasePage renders article:* meta tags with property attribute")
    func testBasePageArticleMetaPropertyAttribute() throws {
        let article = ArticleMetadata(
            publishedTime: "2025-10-15T00:00:00Z",
            modifiedTime: "2025-10-16T00:00:00Z",
            author: "21.dev",
            tags: ["swift", "bitcoin"]
        )
        let page = BasePage(
            title: "Test Article",
            articleMetadata: article
        ) {
            Text("Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        // Verify property attribute is used (not name) for OG compliance
        #expect(html.contains("property=\"article:published_time\""))
        #expect(html.contains("content=\"2025-10-15T00:00:00Z\""))
        #expect(html.contains("property=\"article:modified_time\""))
        #expect(html.contains("content=\"2025-10-16T00:00:00Z\""))
        #expect(html.contains("property=\"article:author\""))
        #expect(html.contains("content=\"21.dev\""))
        #expect(html.contains("property=\"article:tag\""))
        #expect(html.contains("content=\"swift\""))
        #expect(html.contains("content=\"bitcoin\""))
        
        // Ensure name attribute is NOT used for article:* tags
        #expect(!html.contains("name=\"article:"))
    }
    
    @Test("BasePage omits article metadata when nil")
    func testBasePageNoArticleMetadata() throws {
        let page = BasePage(title: "Test") {
            Text("Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        #expect(!html.contains("article:published_time"))
        #expect(!html.contains("article:author"))
        #expect(!html.contains("article:tag"))
    }
    
    @Test("BasePage renders favicon links when FaviconConfig provided")
    func testBasePageFaviconRendered() throws {
        let page = BasePage(
            title: "Favicon Test",
            favicon: FaviconConfig(version: "20260413")
        ) {
            Text("Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        // ICO icon (modernized: rel="icon" with sizes="32x32")
        #expect(html.contains("rel=\"icon\""))
        #expect(html.contains("href=\"/favicon.ico?v=20260413\""))
        #expect(html.contains("sizes=\"32x32\""))
        #expect(html.contains("type=\"image/x-icon\""))
        
        // PNG icon (96x96)
        #expect(html.contains("href=\"/favicon-96x96.png?v=20260413\""))
        #expect(html.contains("sizes=\"96x96\""))
        #expect(html.contains("type=\"image/png\""))
        
        // Apple touch icon
        #expect(html.contains("rel=\"apple-touch-icon\""))
        #expect(html.contains("href=\"/apple-touch-icon.png?v=20260413\""))
        #expect(html.contains("sizes=\"180x180\""))
        
        // Web manifest
        #expect(html.contains("rel=\"manifest\""))
        #expect(html.contains("href=\"/site.webmanifest?v=20260413\""))
    }
    
    @Test("BasePage omits favicon links when FaviconConfig is nil")
    func testBasePageNoFavicon() throws {
        let page = BasePage(title: "No Favicon") {
            Text("Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        #expect(!html.contains("favicon"))
        #expect(!html.contains("apple-touch-icon"))
        #expect(!html.contains("webmanifest"))
    }
    
    @Test("BasePage complete HTML snapshot")
    func testBasePageSnapshot() throws {
        let page = BasePage(title: "Snapshot Test") {
            PlaceholderView(text: "Content")
        }
        let html = try TestUtils.renderHTML(page)
        
        // Verify essential structure exists for snapshot
        #expect(html.hasPrefix("<!doctype html>") || html.hasPrefix("<html"))
        #expect(html.contains("<head>"))
        #expect(html.contains("<title>Snapshot Test</title>"))
        TestUtils.assertContainsStylesheet(html)
        #expect(html.contains("<body>"))
        #expect(html.contains("flex flex-col items-center h-screen justify-center"))
        #expect(html.contains("Content"))
        #expect(html.contains("</body>"))
        #expect(html.contains("</html>"))
    }
}
