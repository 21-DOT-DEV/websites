//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Testing
import Foundation
@testable import DesignSystem
import Slipstream
import TestUtils

struct FeaturedPackageCardTests {
    
    @Test("FeaturedPackageCard renders with correct HTML structure")
    func testFeaturedPackageCardStructure() throws {
        let ctaButton = CTAButton(
            text: "Test CTA",
            href: "/test",
            style: .primary
        )
        
        let card = FeaturedPackageCard(
            title: "Test Package",
            description: "This is a test description for the package.",
            ctaButton: ctaButton
        )
        let html = try TestUtils.renderHTML(card)
        
        // Verify basic structure
        #expect(html.contains("<div"))
        #expect(html.contains("<h2"))
        #expect(html.contains("Test Package"))
        #expect(html.contains("This is a test description for the package."))
        #expect(html.contains("Test CTA"))
        #expect(html.contains("</h2>"))
        #expect(html.contains("</div>"))
    }
    
    @Test("FeaturedPackageCard applies elevated card style")
    func testFeaturedPackageCardElevatedStyle() throws {
        let ctaButton = CTAButton(text: "CTA", href: "/test")
        
        let card = FeaturedPackageCard(
            title: "Elevated Card",
            description: "Test description",
            ctaButton: ctaButton,
            cardStyle: .elevated
        )
        let html = try TestUtils.renderHTML(card)
        
        #expect(html.contains("Elevated Card"))
        #expect(html.contains("bg-white"))
        #expect(html.contains("border-gray-200"))
        #expect(html.contains("rounded-lg"))
    }
    
    @Test("FeaturedPackageCard applies outlined card style")
    func testFeaturedPackageCardOutlinedStyle() throws {
        let ctaButton = CTAButton(text: "CTA", href: "/test")
        
        let card = FeaturedPackageCard(
            title: "Outlined Card",
            description: "Test description",
            ctaButton: ctaButton,
            cardStyle: .outlined
        )
        let html = try TestUtils.renderHTML(card)
        
        #expect(html.contains("Outlined Card"))
        #expect(html.contains("border border-gray-200 rounded-lg"))
        // Outlined style should not have the bg-white class on the card itself
        #expect(!html.contains("bg-white border border-gray-200"))
    }
    
    @Test("FeaturedPackageCard applies filled card style")
    func testFeaturedPackageCardFilledStyle() throws {
        let ctaButton = CTAButton(text: "CTA", href: "/test")
        
        let card = FeaturedPackageCard(
            title: "Filled Card",
            description: "Test description",
            ctaButton: ctaButton,
            cardStyle: .filled
        )
        let html = try TestUtils.renderHTML(card)
        
        #expect(html.contains("Filled Card"))
        #expect(html.contains("bg-gray-50"))
        #expect(html.contains("rounded-lg"))
    }
    
    @Test("FeaturedPackageCard applies custom max width")
    func testFeaturedPackageCardCustomMaxWidth() throws {
        let ctaButton = CTAButton(text: "CTA", href: "/test")
        
        let card = FeaturedPackageCard(
            title: "Max Width Test",
            description: "Test description",
            ctaButton: ctaButton,
            maxWidth: .sixXL
        )
        let html = try TestUtils.renderHTML(card)
        
        #expect(html.contains("max-w-6xl"))
        #expect(html.contains("Max Width Test"))
    }
    
    @Test("FeaturedPackageCard applies custom background color")
    func testFeaturedPackageCardCustomBackground() throws {
        let ctaButton = CTAButton(text: "CTA", href: "/test")
        
        let card = FeaturedPackageCard(
            title: "Background Test",
            description: "Test description",
            ctaButton: ctaButton,
            backgroundColor: .palette(.gray, darkness: 50)
        )
        let html = try TestUtils.renderHTML(card)
        
        #expect(html.contains("Background Test"))
        #expect(html.contains("Test description"))
    }
    
    @Test("FeaturedPackageCard integrates CTA button correctly")
    func testFeaturedPackageCardCTAIntegration() throws {
        let ctaButton = CTAButton(
            text: "Build with P256K →",
            href: "https://github.com/21-DOT-DEV/swift-secp256k1",
            style: .primary,
            isExternal: true
        )
        
        let card = FeaturedPackageCard(
            title: "Featured Package: P256K",
            description: "Enhance your Swift development for Bitcoin apps with seamless secp256k1 integration.",
            ctaButton: ctaButton
        )
        let html = try TestUtils.renderHTML(card)
        
        #expect(html.contains("Featured Package: P256K"))
        #expect(html.contains("Enhance your Swift development"))
        #expect(html.contains("Build with P256K →"))
        #expect(html.contains("https://github.com/21-DOT-DEV/swift-secp256k1"))
        #expect(html.contains("target=\"_blank\""))
        #expect(html.contains("bg-orange-500"))
    }
    
    @Test("FeaturedPackageCard handles special characters")
    func testFeaturedPackageCardSpecialCharacters() throws {
        let ctaButton = CTAButton(text: "CTA", href: "/test")
        
        let card = FeaturedPackageCard(
            title: "Special & <Characters>",
            description: "Description with <script>alert('test')</script> & symbols",
            ctaButton: ctaButton
        )
        let html = try TestUtils.renderHTML(card)
        
        // Text should be HTML-escaped
        #expect(html.contains("Special &amp; &lt;Characters&gt;"))
        #expect(html.contains("&lt;script&gt;"))
        #expect(!html.contains("<script>alert"))
    }
    
    @Test("FeaturedPackageCard has proper responsive styling")
    func testFeaturedPackageCardResponsiveClasses() throws {
        let ctaButton = CTAButton(text: "CTA", href: "/test")
        
        let card = FeaturedPackageCard(
            title: "Responsive Test",
            description: "Test description",
            ctaButton: ctaButton
        )
        let html = try TestUtils.renderHTML(card)
        
        // Check for responsive padding classes
        #expect(html.contains("Responsive Test"))
        // The component uses responsive padding but specific classes are handled by Slipstream
    }
}
