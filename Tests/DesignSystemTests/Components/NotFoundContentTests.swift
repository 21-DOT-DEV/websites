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

struct NotFoundContentTests {
    
    @Test("NotFoundContent renders with default values")
    func testNotFoundContentDefaults() throws {
        let content = NotFoundContent()
        let html = try TestUtils.renderHTML(content)
        
        // Verify default headline
        #expect(html.contains("404: Page not found"))
        // Verify default description
        #expect(html.contains("This URL doesn't match any content on our site."))
    }
    
    @Test("NotFoundContent renders custom headline")
    func testNotFoundContentCustomHeadline() throws {
        let content = NotFoundContent(
            headline: "404: Post not found",
            description: "This blog post doesn't exist."
        )
        let html = try TestUtils.renderHTML(content)
        
        #expect(html.contains("404: Post not found"))
        #expect(html.contains("This blog post doesn't exist."))
    }
    
    @Test("NotFoundContent renders navigation links")
    func testNotFoundContentNavigationLinks() throws {
        let content = NotFoundContent(
            headline: "404: Page not found",
            description: "Page not found.",
            navigationLinks: [
                NavigationLink(title: "Homepage", href: "/"),
                NavigationLink(title: "Blog", href: "/blog/")
            ]
        )
        let html = try TestUtils.renderHTML(content)
        
        #expect(html.contains("Homepage"))
        #expect(html.contains("href=\"/\""))
        #expect(html.contains("Blog"))
        #expect(html.contains("href=\"/blog/\""))
    }
    
    @Test("NotFoundContent applies correct styling classes")
    func testNotFoundContentStyling() throws {
        let content = NotFoundContent()
        let html = try TestUtils.renderHTML(content)
        
        // Verify headline styling
        #expect(html.contains("text-3xl"))
        #expect(html.contains("md:text-4xl"))
        #expect(html.contains("font-bold"))
        #expect(html.contains("text-gray-900"))
        
        // Verify description styling
        #expect(html.contains("text-lg"))
        #expect(html.contains("text-gray-600"))
        
        // Verify background
        #expect(html.contains("bg-gray-50"))
    }
    
    @Test("NotFoundContent renders H1 element for headline")
    func testNotFoundContentSemanticHTML() throws {
        let content = NotFoundContent(headline: "404: Test")
        let html = try TestUtils.renderHTML(content)
        
        #expect(html.contains("<h1"))
        #expect(html.contains("</h1>"))
    }
    
    @Test("NotFoundContent link styling includes orange color")
    func testNotFoundContentLinkStyling() throws {
        let content = NotFoundContent(
            navigationLinks: [
                NavigationLink(title: "Home", href: "/")
            ]
        )
        let html = try TestUtils.renderHTML(content)
        
        #expect(html.contains("text-orange-600"))
    }
    
    @Test("NotFoundContent handles empty navigation links")
    func testNotFoundContentEmptyLinks() throws {
        let content = NotFoundContent(
            headline: "404",
            description: "Not found",
            navigationLinks: []
        )
        let html = try TestUtils.renderHTML(content)
        
        // Should render without navigation section
        #expect(html.contains("404"))
        #expect(html.contains("Not found"))
    }
}
