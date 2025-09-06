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

@Suite("SocialLinkView Component Tests")
struct SocialLinkViewTests {
    
    @Test("SocialLinkView renders SVG-based social link (GitHub)")
    func testSocialLinkViewRendersGitHubSVG() async throws {
        let socialLink = SocialLink(
            url: "https://github.com/test",
            ariaLabel: "GitHub",
            platform: .github
        )
        let view = SocialLinkView(socialLink: socialLink)
        
        let html = try TestUtils.renderHTML(view)
        
        // Check link structure
        #expect(html.contains("href=\"https://github.com/test\""))
        #expect(html.contains("target=\"_blank\""))
        #expect(html.contains("alt=\"GitHub\""))
        
        // Check SVG content
        #expect(html.contains("viewBox=\"0 0 24 24\""))
        #expect(html.contains("M12 0c-6.626 0-12 5.373-12 12")) // GitHub SVG path start
        #expect(html.contains("fill-current h-6 w-6"))
        
        // Check common styling
        #expect(html.contains("text-gray-400"))
        #expect(html.contains("hover:text-white"))
        #expect(html.contains("transition-colors"))
        #expect(html.contains("mb-3"))
        #expect(html.contains("block"))
    }
    
    @Test("SocialLinkView renders SVG-based social link (Twitter)")
    func testSocialLinkViewRendersTwitterSVG() async throws {
        let socialLink = SocialLink(
            url: "https://x.com/test",
            ariaLabel: "X (Twitter)",
            platform: .twitter
        )
        let view = SocialLinkView(socialLink: socialLink)
        
        let html = try TestUtils.renderHTML(view)
        
        // Check link structure
        #expect(html.contains("href=\"https://x.com/test\""))
        #expect(html.contains("alt=\"X (Twitter)\""))
        
        // Check Twitter SVG content
        #expect(html.contains("M18.244 2.25h3.308l-7.227 8.26")) // Twitter SVG path start
        #expect(html.contains("viewBox=\"0 0 24 24\""))
    }
    
    @Test("SocialLinkView renders text-based social link (Nostr)")
    func testSocialLinkViewRendersNostrText() async throws {
        let socialLink = SocialLink(
            url: "https://njump.me/test",
            ariaLabel: "Nostr Profile",
            platform: .nostr
        )
        let view = SocialLinkView(socialLink: socialLink)
        
        let html = try TestUtils.renderHTML(view)
        
        // Check link structure
        #expect(html.contains("href=\"https://njump.me/test\""))
        #expect(html.contains("alt=\"Nostr Profile\""))
        
        // Check text content and styling
        #expect(html.contains("nostr"))
        #expect(html.contains("font-mono"))
        #expect(html.contains("text-sm"))
        
        // Should not contain SVG elements
        #expect(!html.contains("<svg"))
        #expect(!html.contains("viewBox"))
    }
    
    
    @Test("SocialLinkView handles external links correctly")
    func testSocialLinkViewExternalLinkBehavior() async throws {
        let socialLink = SocialLink(
            url: "https://external-site.com",
            ariaLabel: "External Site",
            platform: .github
        )
        let view = SocialLinkView(socialLink: socialLink)
        
        let html = try TestUtils.renderHTML(view)
        
        // All social links should open in new tab
        #expect(html.contains("target=\"_blank\""))
        // Note: Slipstream may handle rel="noopener" automatically
    }
    
    @Test("SocialLinkView applies consistent styling across all variants")
    func testSocialLinkViewConsistentStyling() async throws {
        let svgLink = SocialLink(url: "https://github.com", ariaLabel: "GitHub", platform: .github)
        let textLink = SocialLink(url: "https://nostr.com", ariaLabel: "Nostr", platform: .nostr)
        let twitterLink = SocialLink(url: "https://x.com", ariaLabel: "Twitter", platform: .twitter)
        
        let svgHtml = try TestUtils.renderHTML(SocialLinkView(socialLink: svgLink))
        let textHtml = try TestUtils.renderHTML(SocialLinkView(socialLink: textLink))
        let twitterHtml = try TestUtils.renderHTML(SocialLinkView(socialLink: twitterLink))
        
        let expectedClasses = ["text-gray-400", "hover:text-white", "transition-colors", "mb-3", "block"]
        
        for className in expectedClasses {
            #expect(svgHtml.contains(className))
            #expect(textHtml.contains(className))
            #expect(twitterHtml.contains(className))
        }
    }
    
    @Test("SocialLinkView handles accessibility labels correctly")
    func testSocialLinkViewAccessibilityLabels() async throws {
        let testCases = [
            ("GitHub Profile", SocialLink(url: "https://github.com", ariaLabel: "GitHub Profile", platform: .github)),
            ("Twitter Account", SocialLink(url: "https://x.com", ariaLabel: "Twitter Account", platform: .twitter)),
            ("Nostr Identity", SocialLink(url: "https://nostr.com", ariaLabel: "Nostr Identity", platform: .nostr))
        ]
        
        for (expectedLabel, socialLink) in testCases {
            let html = try TestUtils.renderHTML(SocialLinkView(socialLink: socialLink))
            #expect(html.contains("alt=\"\(expectedLabel)\""))
        }
    }
}
