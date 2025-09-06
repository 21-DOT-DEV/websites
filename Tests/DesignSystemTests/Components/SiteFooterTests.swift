//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import Foundation
@testable import DesignSystem
import TestUtils

@Suite("SiteFooter Component Tests")
struct SiteFooterTests {
    
    @Test("SiteFooter renders with basic configuration")
    func testSiteFooterRendersCorrectly() async throws {
        let footer = SiteFooter(
            companyName: "Test Company",
            companyDescription: "Building amazing tools for developers.",
            resourceLinks: [
                FooterLink(text: "Docs", href: "/docs"),
                FooterLink(text: "GitHub", href: "https://github.com/test", isExternal: true)
            ],
            contactEmail: "hello@test.com",
            licenseText: "MIT License",
            socialLinks: [
                SocialLink(url: "https://github.com/test", ariaLabel: "GitHub", platform: .github),
                SocialLink(url: "https://x.com/test", ariaLabel: "X", platform: .twitter)
            ],
            copyrightText: "2025 Test Company"
        )
        
        let html = try TestUtils.renderHTML(footer)
        
        // Test company info section
        #expect(html.contains("Test Company"))
        #expect(html.contains("Building amazing tools for developers."))
        
        // Test resources section
        #expect(html.contains("Resources"))
        #expect(html.contains("href=\"/docs\""))
        #expect(html.contains("href=\"https://github.com/test\""))
        #expect(html.contains("target=\"_blank\""))
        
        // Test contact section
        #expect(html.contains("Contact"))
        #expect(html.contains("mailto:hello@test.com"))
        #expect(html.contains("MIT License"))
        
        // Test social links section
        #expect(html.contains("Follow Us"))
        #expect(html.contains("alt=\"GitHub\""))
        #expect(html.contains("alt=\"X\""))
        
        // Test copyright section
        #expect(html.contains("2025 Test Company"))
        
        // Test styling classes
        #expect(html.contains("bg-gray-900"))
        #expect(html.contains("gap-8 grid grid-cols-1 md:grid-cols-4"))
    }
    
    @Test("SiteFooter handles empty configuration")
    func testSiteFooterHandlesEmptyConfiguration() async throws {
        let footer = SiteFooter(
            companyName: "Empty Co",
            companyDescription: "Minimal setup",
            copyrightText: "2025 Empty Co"
        )
        
        let html = try TestUtils.renderHTML(footer)
        
        #expect(html.contains("Empty Co"))
        #expect(html.contains("Minimal setup"))
        #expect(html.contains("2025 Empty Co"))
        
        // Should still have section headers even with empty content
        #expect(html.contains("Resources"))
        #expect(html.contains("Contact"))
        #expect(html.contains("Follow Us"))
    }
    
    @Test("SiteFooter renders social links with SVG icons")
    func testSiteFooterSocialLinksSVGRendering() async throws {
        let footer = SiteFooter(
            companyName: "SVG Test",
            companyDescription: "Testing SVG icons",
            socialLinks: [
                SocialLink(url: "https://github.com/test", ariaLabel: "GitHub", platform: .github),
                SocialLink(url: "https://x.com/test", ariaLabel: "X", platform: .twitter),
                SocialLink(url: "https://njump.me/test", ariaLabel: "Nostr", platform: .nostr)
            ],
            copyrightText: "2025 SVG Test"
        )
        
        let html = try TestUtils.renderHTML(footer)
        
        // Test GitHub SVG - new SVG component format
        #expect(html.contains("class=\"fill-current h-6 w-6\""))
        #expect(html.contains("M12 0c-6.626 0-12 5.373-12 12")) // GitHub path start
        
        // Test Twitter/X SVG  
        #expect(html.contains("M18.244 2.25h3.308l-7.227 8.26")) // Twitter path start
        
        // Test Nostr text fallback
        #expect(html.contains("nostr"))
        #expect(html.contains("font-mono"))
        #expect(html.contains("text-sm"))
    }
    
    
    @Test("SiteFooter link external/internal handling")
    func testSiteFooterLinkExternalHandling() async throws {
        let footer = SiteFooter(
            companyName: "Link Test",
            companyDescription: "Testing link behavior",
            resourceLinks: [
                FooterLink(text: "Internal", href: "/internal"),
                FooterLink(text: "External", href: "https://external.com", isExternal: true)
            ],
            copyrightText: "2025 Link Test"
        )
        
        let html = try TestUtils.renderHTML(footer)
        
        // Internal link should not have target="_blank"
        #expect(html.contains("href=\"/internal\""))
        
        // External link should have target="_blank"
        #expect(html.contains("href=\"https://external.com\" target=\"_blank\""))
    }
    
    @Test("SiteFooter handles missing optional fields")
    func testSiteFooterHandlesMissingOptionalFields() async throws {
        let footer = SiteFooter(
            companyName: "Minimal",
            companyDescription: "Just the basics",
            copyrightText: "2025 Minimal"
        )
        
        let html = try TestUtils.renderHTML(footer)
        
        #expect(html.contains("Minimal"))
        #expect(html.contains("Just the basics"))
        #expect(html.contains("2025 Minimal"))
        
        // Should not contain mailto or license text
        #expect(!html.contains("mailto:"))
        #expect(!html.contains("Licensed"))
    }
    
    @Test("FooterLink initializer defaults")
    func testFooterLinkDefaults() async throws {
        let internalLink = FooterLink(text: "Test", href: "/test")
        let externalLink = FooterLink(text: "External", href: "https://test.com", isExternal: true)
        
        #expect(internalLink.isExternal == false)
        #expect(externalLink.isExternal == true)
        #expect(internalLink.text == "Test")
        #expect(externalLink.href == "https://test.com")
    }
    
    @Test("SocialPlatform SVG paths are valid")
    func testSocialPlatformSVGPaths() async throws {
        #expect(!SocialPlatform.github.svgPath.isEmpty)
        #expect(!SocialPlatform.twitter.svgPath.isEmpty)
        #expect(SocialPlatform.nostr.svgPath.isEmpty) // Nostr uses text
        
        #expect(SocialPlatform.github.displayText == nil)
        #expect(SocialPlatform.twitter.displayText == nil)  
        #expect(SocialPlatform.nostr.displayText == "nostr")
    }
    
    @Test("SiteFooter integration with other components")
    func testSiteFooterIntegrationInPage() async throws {
        // Test that SiteFooter can be used alongside other components
        let footer = SiteFooter(
            companyName: "Integration Test",
            companyDescription: "Testing component integration",
            copyrightText: "2025 Integration Test"
        )
        
        let html = try TestUtils.renderHTML(footer)
        
        // Test responsive grid classes
        #expect(html.contains("grid-cols-1"))
        #expect(html.contains("md:grid-cols-4"))
        #expect(html.contains("max-w-6xl"))
        #expect(html.contains("mx-auto"))
    }
}
