import Testing
import Foundation
@testable import DesignSystem
import Slipstream
import TestUtils

struct CTAButtonTests {
    
    @Test("CTAButton renders with correct HTML structure")
    func testCTAButtonStructure() throws {
        let button = CTAButton(
            text: "Test Button",
            href: "https://example.com",
            style: .primary,
            isExternal: true
        )
        let view = CTAButtonView(button: button)
        let html = try TestUtils.renderHTML(view)
        
        // Verify basic structure
        #expect(html.contains("<a"))
        #expect(html.contains("Test Button"))
        #expect(html.contains("https://example.com"))
        #expect(html.contains("target=\"_blank\""))
        #expect(html.contains("</a>"))
    }
    
    @Test("CTAButton primary style applies correct classes")
    func testCTAButtonPrimaryStyle() throws {
        let button = CTAButton(
            text: "Primary Button",
            href: "/test",
            style: .primary
        )
        let view = CTAButtonView(button: button)
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("Primary Button"))
        #expect(html.contains("bg-orange-500"))
        #expect(html.contains("text-white"))
        #expect(html.contains("rounded-lg"))
    }
    
    @Test("CTAButton secondary style applies correct classes")
    func testCTAButtonSecondaryStyle() throws {
        let button = CTAButton(
            text: "Secondary Button",
            href: "/test",
            style: .secondary
        )
        let view = CTAButtonView(button: button)
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("Secondary Button"))
        #expect(html.contains("border-gray-300"))
        #expect(html.contains("text-gray-700"))
        #expect(html.contains("rounded-lg"))
    }
    
    @Test("CTAButton handles internal links correctly")
    func testCTAButtonInternalLink() throws {
        let button = CTAButton(
            text: "Internal Link",
            href: "/internal-page",
            isExternal: false
        )
        let view = CTAButtonView(button: button)
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("/internal-page"))
        #expect(!html.contains("target=\"_blank\""))
    }
    
    @Test("CTAButton handles external links correctly")
    func testCTAButtonExternalLink() throws {
        let button = CTAButton(
            text: "External Link",
            href: "https://github.com/21-dot-dev",
            isExternal: true
        )
        let view = CTAButtonView(button: button)
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("https://github.com/21-dot-dev"))
        #expect(html.contains("target=\"_blank\""))
    }
    
    @Test("CTAButtonGroup renders multiple buttons")
    func testCTAButtonGroup() throws {
        let primary = CTAButton(text: "Primary", href: "/primary", style: .primary)
        let secondary = CTAButton(text: "Secondary", href: "/secondary", style: .secondary)
        
        let group = CTAButtonGroup(
            primaryButton: primary,
            secondaryButton: secondary
        )
        let html = try TestUtils.renderHTML(group)
        
        #expect(html.contains("Primary"))
        #expect(html.contains("Secondary"))
        #expect(html.contains("bg-orange-500"))
        #expect(html.contains("border-gray-300"))
    }
    
    @Test("CTAButtonGroup handles single button")
    func testCTAButtonGroupSingleButton() throws {
        let primary = CTAButton(text: "Only Button", href: "/only", style: .primary)
        
        let group = CTAButtonGroup(
            primaryButton: primary,
            secondaryButton: nil
        )
        let html = try TestUtils.renderHTML(group)
        
        #expect(html.contains("Only Button"))
        #expect(html.contains("bg-orange-500"))
    }
    
    @Test("CTAButton handles special characters")
    func testCTAButtonSpecialCharacters() throws {
        let button = CTAButton(
            text: "Build with P256K →",
            href: "/test"
        )
        let view = CTAButtonView(button: button)
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("Build with P256K →"))
    }
}
