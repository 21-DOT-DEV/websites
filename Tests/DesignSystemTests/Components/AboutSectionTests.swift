import Testing
import Foundation
@testable import DesignSystem
import Slipstream
import TestUtils

struct AboutSectionTests {
    
    @Test("AboutSection renders with correct HTML structure")
    func testAboutSectionStructure() throws {
        let view = AboutSection(
            title: "Test Title",
            paragraphs: ["First paragraph", "Second paragraph"]
        )
        let html = try TestUtils.renderHTML(view)
        
        // Verify basic structure
        #expect(html.contains("<div"))
        #expect(html.contains("<h2"))
        #expect(html.contains("Test Title"))
        #expect(html.contains("First paragraph"))
        #expect(html.contains("Second paragraph"))
        #expect(html.contains("</div>"))
        #expect(html.contains("</h2>"))
    }
    
    @Test("AboutSection handles single paragraph")
    func testAboutSectionSingleParagraph() throws {
        let view = AboutSection(
            title: "Single Paragraph Test",
            paragraphs: ["Only one paragraph here"]
        )
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("Single Paragraph Test"))
        #expect(html.contains("Only one paragraph here"))
    }
    
    @Test("AboutSection handles three paragraphs")
    func testAboutSectionThreeParagraphs() throws {
        let view = AboutSection(
            title: "Three Paragraph Test",
            paragraphs: [
                "First paragraph content",
                "Second paragraph content", 
                "Third paragraph content"
            ]
        )
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("Three Paragraph Test"))
        #expect(html.contains("First paragraph content"))
        #expect(html.contains("Second paragraph content"))
        #expect(html.contains("Third paragraph content"))
    }
    
    @Test("AboutSection applies custom background color")
    func testAboutSectionCustomBackground() throws {
        let view = AboutSection(
            title: "Background Test",
            paragraphs: ["Test content"],
            backgroundColor: .palette(.gray, darkness: 50)
        )
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("Background Test"))
        #expect(html.contains("Test content"))
    }
    
    @Test("AboutSection applies custom max width")
    func testAboutSectionCustomMaxWidth() throws {
        let view = AboutSection(
            title: "Max Width Test",
            paragraphs: ["Test content"],
            maxWidth: .sixXL
        )
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("max-w-6xl"))
        #expect(html.contains("Max Width Test"))
    }
    
    @Test("AboutSection handles empty paragraphs array")
    func testAboutSectionEmptyParagraphs() throws {
        let view = AboutSection(
            title: "Empty Test",
            paragraphs: []
        )
        let html = try TestUtils.renderHTML(view)
        
        // Should still render title and structure
        #expect(html.contains("Empty Test"))
        #expect(html.contains("<h2"))
        #expect(html.contains("</h2>"))
    }
    
    @Test("AboutSection handles special characters")
    func testAboutSectionSpecialCharacters() throws {
        let view = AboutSection(
            title: "Special & <Characters>",
            paragraphs: ["Content with <script>alert('test')</script> & symbols"]
        )
        let html = try TestUtils.renderHTML(view)
        
        // Text should be HTML-escaped
        #expect(html.contains("Special &amp; &lt;Characters&gt;"))
        #expect(html.contains("&lt;script&gt;"))
        #expect(!html.contains("<script>alert"))
    }
}
