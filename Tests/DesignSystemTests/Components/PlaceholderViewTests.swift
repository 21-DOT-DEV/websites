import Testing
import Foundation
@testable import DesignSystem
import Slipstream
import TestUtils

struct PlaceholderViewTests {
    
    @Test("PlaceholderView renders with correct HTML structure")
    func testPlaceholderViewStructure() throws {
        let view = PlaceholderView(text: "Welcome to the site")
        let html = try TestUtils.renderHTML(view)
        
        // Verify basic structure
        #expect(html.contains("<div"))
        #expect(html.contains("Welcome to the site"))
        #expect(html.contains("</div>"))
        
        // Verify Tailwind classes for centering and typography
        TestUtils.assertContainsTailwindClasses(html, classes: TestUtils.placeholderViewClasses)
    }
    
    @Test("PlaceholderView handles text parameter correctly")
    func testPlaceholderViewTextParameter() throws {
        let customText = "Custom placeholder message"
        let view = PlaceholderView(text: customText)
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains(customText))
    }
    
    @Test("PlaceholderView handles empty text")
    func testPlaceholderViewEmptyText() throws {
        let view = PlaceholderView(text: "")
        let html = try TestUtils.renderHTML(view)
        
        // Should still render structure even with empty text
        #expect(html.contains("<div"))
        #expect(html.contains("h-screen"))
        #expect(html.contains("</div>"))
    }
    
    @Test("PlaceholderView handles special characters in text")
    func testPlaceholderViewSpecialCharacters() throws {
        let specialText = "Welcome! 🚀 <script>alert('test')</script>"
        let view = PlaceholderView(text: specialText)
        let html = try TestUtils.renderHTML(view)
        
        // Text should be HTML-escaped
        #expect(html.contains("Welcome! 🚀"))
        #expect(html.contains("&lt;script&gt;"))
        #expect(!html.contains("<script>alert"))
    }
    
    @Test("PlaceholderView generates complete snapshot")
    func testPlaceholderViewSnapshot() throws {
        let view = PlaceholderView(text: "Snapshot Test Content")
        let html = try TestUtils.renderHTML(view)
        
        // Full HTML snapshot for regression protection
        let expectedSnapshot = """
<div class="h-screen flex items-center justify-center text-7xl text-center font-sans"> <p>Snapshot Test Content</p> </div>
"""
        
        #expect(TestUtils.normalizeHTML(html) == TestUtils.normalizeHTML(expectedSnapshot))
    }
}
