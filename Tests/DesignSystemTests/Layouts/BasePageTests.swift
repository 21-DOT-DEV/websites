import Testing
import Foundation
@testable import DesignSystem
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
        TestUtils.assertDoesNotContainText(html, texts: ["static/style.output.css"])
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
        #expect(html.contains("h-screen flex items-center justify-center"))
        #expect(html.contains("Content"))
        #expect(html.contains("</body>"))
        #expect(html.contains("</html>"))
    }
}
