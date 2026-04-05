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

@Suite("Breadcrumb Component Tests")
struct BreadcrumbTests {
    
    @Test("Breadcrumb renders nav element with aria-label")
    func testBreadcrumbRendersNavWithAriaLabel() throws {
        let view = Breadcrumb(levels: [
            BreadcrumbLevel(name: "Home", href: "/"),
            BreadcrumbLevel(name: "Blog")
        ])
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("<nav"))
        #expect(html.contains("aria-label=\"Breadcrumb\""))
    }
    
    @Test("Breadcrumb renders linked levels as anchor tags")
    func testBreadcrumbRendersLinks() throws {
        let view = Breadcrumb(levels: [
            BreadcrumbLevel(name: "Home", href: "/"),
            BreadcrumbLevel(name: "Packages", href: "/packages/"),
            BreadcrumbLevel(name: "P256K")
        ])
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("href=\"/\""))
        #expect(html.contains("Home"))
        #expect(html.contains("href=\"/packages/\""))
        #expect(html.contains("Packages"))
    }
    
    @Test("Breadcrumb renders last item as plain text (not a link)")
    func testBreadcrumbRendersLastItemAsText() throws {
        let view = Breadcrumb(levels: [
            BreadcrumbLevel(name: "Home", href: "/"),
            BreadcrumbLevel(name: "Blog")
        ])
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("Blog"))
        // Last item should be a span, not a link
        #expect(html.contains("<span class=\"text-gray-700\">Blog</span>"))
    }
    
    @Test("Breadcrumb renders separator between items")
    func testBreadcrumbRendersSeparator() throws {
        let view = Breadcrumb(levels: [
            BreadcrumbLevel(name: "Home", href: "/"),
            BreadcrumbLevel(name: "Blog")
        ])
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("›"))
    }
    
    @Test("Breadcrumb three-level trail renders correctly")
    func testBreadcrumbThreeLevels() throws {
        let view = Breadcrumb(levels: [
            BreadcrumbLevel(name: "Home", href: "/"),
            BreadcrumbLevel(name: "Blog", href: "/blog/"),
            BreadcrumbLevel(name: "Hello World")
        ])
        let html = try TestUtils.renderHTML(view)
        
        #expect(html.contains("href=\"/\""))
        #expect(html.contains("href=\"/blog/\""))
        #expect(html.contains("<span class=\"text-gray-700\">Hello World</span>"))
    }
}
