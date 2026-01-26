//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
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
            url: "https://github.com/example",
            ariaLabel: "GitHub",
            icon: GitHubIcon()
        )
        let view = SocialLinkView(socialLink: socialLink)
        
        let html = try TestUtils.renderHTML(view)
        
        // Check link structure
        #expect(html.contains("href=\"https://github.com/example\""))
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
    }
    
    @Test("SocialLinkView renders SVG-based social link (Twitter)")
    func testSocialLinkViewRendersTwitterSVG() async throws {
        let socialLink = SocialLink(
            url: "https://x.com/test",
            ariaLabel: "Twitter",
            icon: TwitterIcon()
        )
        let view = SocialLinkView(socialLink: socialLink)
        
        let html = try TestUtils.renderHTML(view)
        
        // Check link structure
        #expect(html.contains("href=\"https://x.com/test\""))
        #expect(html.contains("alt=\"Twitter\""))
        
        // Check Twitter SVG content
        #expect(html.contains("M18.244 2.25h3.308l-7.227 8.26")) // Twitter SVG path start
        #expect(html.contains("viewBox=\"0 0 24 24\""))
    }
    
    @Test("SocialLinkView renders SVG-based social link (Nostr)")
    func testSocialLinkViewRendersNostrSVG() async throws {
        let socialLink = SocialLink(
            url: "https://nostr.com/test",
            ariaLabel: "Nostr",
            icon: NostrIcon()
        )
        let view = SocialLinkView(socialLink: socialLink)
        
        let html = try TestUtils.renderHTML(view)
        
        // Check link structure
        #expect(html.contains("href=\"https://nostr.com/test\""))
        #expect(html.contains("alt=\"Nostr\""))
        
        // Check Nostr SVG content
        #expect(html.contains("viewBox=\"0 0 24 24\""))
        #expect(html.contains("transform=\"scale(1.4) translate(-3.2, -3.2)\"")) // Nostr SVG specific
        
        // Should contain SVG elements now
        #expect(html.contains("<svg"))
        #expect(html.contains("fill-current h-6 w-6"))
    }
    
    
    @Test("SocialLinkView handles external links correctly")
    func testSocialLinkViewExternalLinkBehavior() async throws {
        let socialLink = SocialLink(
            url: "https://external-site.com",
            ariaLabel: "External Site",
            icon: GitHubIcon()
        )
        let view = SocialLinkView(socialLink: socialLink)
        
        let html = try TestUtils.renderHTML(view)
        
        // All social links should open in new tab
        #expect(html.contains("target=\"_blank\""))
        // Note: Slipstream may handle rel="noopener" automatically
    }
    
    @Test("SocialLinkView applies consistent styling across all variants")
    func testSocialLinkViewConsistentStyling() async throws {
        let svgLink = SocialLink(url: "https://github.com", ariaLabel: "GitHub", icon: GitHubIcon())
        let textLink = SocialLink(url: "https://nostr.com", ariaLabel: "Nostr", icon: NostrIcon())
        let twitterLink = SocialLink(url: "https://x.com", ariaLabel: "Twitter", icon: TwitterIcon())
        
        let svgHtml = try TestUtils.renderHTML(SocialLinkView(socialLink: svgLink))
        let textHtml = try TestUtils.renderHTML(SocialLinkView(socialLink: textLink))
        let twitterHtml = try TestUtils.renderHTML(SocialLinkView(socialLink: twitterLink))
        
        let expectedClasses = ["text-gray-400", "hover:text-white", "transition-colors"]
        
        for className in expectedClasses {
            #expect(svgHtml.contains(className))
            #expect(textHtml.contains(className))
            #expect(twitterHtml.contains(className))
        }
    }
    
    @Test("SocialLinkView handles accessibility labels correctly")
    func testSocialLinkViewAccessibilityLabels() async throws {
        let testCases = [
            ("GitHub Profile", SocialLink(url: "https://github.com", ariaLabel: "GitHub Profile", icon: GitHubIcon())),
            ("Twitter Account", SocialLink(url: "https://x.com", ariaLabel: "Twitter Account", icon: TwitterIcon())),
            ("Nostr Identity", SocialLink(url: "https://nostr.com", ariaLabel: "Nostr Identity", icon: NostrIcon()))
        ]
        
        for (expectedLabel, socialLink) in testCases {
            let html = try TestUtils.renderHTML(SocialLinkView(socialLink: socialLink))
            #expect(html.contains("alt=\"\(expectedLabel)\""))
        }
    }
}
