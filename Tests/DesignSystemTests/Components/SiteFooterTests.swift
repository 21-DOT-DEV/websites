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
                SocialLink(url: "https://github.com/test", ariaLabel: "GitHub", icon: GitHubIcon()),
                SocialLink(url: "https://x.com/test", ariaLabel: "X", icon: TwitterIcon())
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
                SocialLink(url: "https://github.com/test", ariaLabel: "GitHub", icon: GitHubIcon()),
                SocialLink(url: "https://x.com/test", ariaLabel: "X", icon: TwitterIcon()),
                SocialLink(url: "https://njump.me/test", ariaLabel: "Nostr", icon: NostrIcon())
            ],
            copyrightText: "2025 SVG Test"
        )
        
        let html = try TestUtils.renderHTML(footer)
        
        // Test GitHub SVG - new SVG component format
        #expect(html.contains("class=\"fill-current h-6 w-6\""))
        #expect(html.contains("M12 0c-6.626 0-12 5.373-12 12")) // GitHub path start
        
        // Test Twitter/X SVG  
        #expect(html.contains("M18.244 2.25h3.308l-7.227 8.26")) // Twitter path start
        
        // Test Nostr SVG rendering (now all icons are SVG)
        #expect(html.contains("viewBox=\"0 0 24 24\""))
        #expect(html.contains("transform=\"scale(1.4) translate(-3.2, -3.2)\"")) // Nostr icon specific
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
    
    @Test("Social icons render correctly")
    func testSocialIconsRendering() async throws {
        let githubIcon = GitHubIcon()
        let twitterIcon = TwitterIcon()
        let nostrIcon = NostrIcon()
        
        let githubHtml = try TestUtils.renderHTML(githubIcon)
        let twitterHtml = try TestUtils.renderHTML(twitterIcon)
        let nostrHtml = try TestUtils.renderHTML(nostrIcon)
        
        // Test that icons render with proper SVG structure
        #expect(githubHtml.contains("<svg"))
        #expect(twitterHtml.contains("<svg"))
        #expect(nostrHtml.contains("<svg"))
        
        // Test viewBox attributes
        #expect(githubHtml.contains("viewBox=\"0 0 24 24\""))
        #expect(twitterHtml.contains("viewBox=\"0 0 24 24\""))
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
    
    // MARK: - Email Obfuscation Tests
    
    @Test("SiteFooter obfuscates email with RTL CSS technique")
    func testSiteFooterEmailObfuscation() async throws {
        let footer = SiteFooter(
            companyName: "Obfuscation Test",
            companyDescription: "Testing email obfuscation",
            contactEmail: "hello@21.dev",
            copyrightText: "2025 Test"
        )
        
        let html = try TestUtils.renderHTML(footer)
        
        // Email should be reversed in the DOM (RTL obfuscation)
        #expect(html.contains("ved.12@olleh"))
        
        // Should have the obfuscation class
        #expect(html.contains("email-obfuscated"))
        
        // mailto: href should still contain the correct email
        #expect(html.contains("mailto:hello@21.dev"))
        
        // Should have accessibility label (Slipstream renders as alt attribute)
        #expect(html.contains("alt=\"Contact Us\""))
    }
    
    @Test("SiteFooter StyleModifier provides email obfuscation CSS")
    func testSiteFooterStyleModifierCSS() async throws {
        let footer = SiteFooter(
            companyName: "CSS Test",
            companyDescription: "Testing StyleModifier",
            copyrightText: "2025 Test"
        )
        
        // Verify the style property contains the RTL CSS
        #expect(footer.style.contains(".email-obfuscated"))
        #expect(footer.style.contains("unicode-bidi: bidi-override"))
        #expect(footer.style.contains("direction: rtl"))
        
        // Verify componentName
        #expect(footer.componentName == "SiteFooter")
    }
    
    @Test("SiteFooter email obfuscation handles various email formats")
    func testSiteFooterEmailObfuscationVariousFormats() async throws {
        let testCases: [(email: String, reversed: String)] = [
            ("test@example.com", "moc.elpmaxe@tset"),
            ("a@b.co", "oc.b@a"),
            ("contact+support@company.io", "oi.ynapmoc@troppus+tcatnoc")
        ]
        
        for testCase in testCases {
            let footer = SiteFooter(
                companyName: "Test",
                companyDescription: "Test",
                contactEmail: testCase.email,
                copyrightText: "2025"
            )
            
            let html = try TestUtils.renderHTML(footer)
            
            #expect(html.contains(testCase.reversed), "Expected reversed email '\(testCase.reversed)' for '\(testCase.email)'")
            #expect(html.contains("mailto:\(testCase.email)"), "Expected mailto href for '\(testCase.email)'")
        }
    }
}
