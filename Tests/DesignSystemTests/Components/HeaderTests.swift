import Testing
import Foundation
@testable import DesignSystem
import Slipstream
import TestUtils

struct HeaderTests {
    
    @Test("Header renders with correct HTML structure and full width")
    func testHeaderBasicStructure() throws {
        let navigationLinks = [
            NavigationLink(title: "Home", href: "/"),
            NavigationLink(title: "About", href: "/about")
        ]
        let header = Header(logoText: "TestSite", navigationLinks: navigationLinks)
        let html = try TestUtils.renderHTML(header)
        
        // Verify basic HTML structure
        #expect(html.contains("<div"))
        #expect(html.contains("</div>"))
        
        // Verify full width class is applied
        TestUtils.assertContainsTailwindClasses(html, classes: ["w-full"])
        
        // Verify container structure
        TestUtils.assertContainsTailwindClasses(html, classes: ["container"])
        
        // Verify header layout classes
        TestUtils.assertContainsTailwindClasses(html, classes: ["flex", "items-center"])
    }
    
    @Test("Header logo renders correctly with proper styling")
    func testHeaderLogo() throws {
        let header = Header(logoText: "MyAwesomeSite", navigationLinks: [])
        let html = try TestUtils.renderHTML(header)
        
        // Verify logo text appears
        TestUtils.assertContainsText(html, texts: ["MyAwesomeSite"])
        
        // Verify logo is a link to homepage
        #expect(html.contains("href=\"/\""))
        
        // Verify logo typography classes
        TestUtils.assertContainsTailwindClasses(html, classes: [
            "text-2xl", // fontSize(.extraExtraLarge)
            "font-bold",
            "text-gray-900"
        ])
    }
    
    @Test("Header navigation links render with correct attributes")
    func testHeaderNavigationLinks() throws {
        let navigationLinks = [
            NavigationLink(title: "Home", href: "/"),
            NavigationLink(title: "Blog", href: "/blog"),
            NavigationLink(title: "Docs", href: "https://docs.example.com", isExternal: true)
        ]
        let header = Header(logoText: "Site", navigationLinks: navigationLinks)
        let html = try TestUtils.renderHTML(header)
        
        // Verify all navigation link texts appear
        TestUtils.assertContainsText(html, texts: ["Home", "Blog", "Docs"])
        
        // Verify all navigation link hrefs appear
        #expect(html.contains("href=\"/\""))
        #expect(html.contains("href=\"/blog\""))
        #expect(html.contains("href=\"https://docs.example.com\""))
        
        // Verify external link opens in new tab (target="_blank")
        #expect(html.contains("target=\"_blank\""))
        
        // Verify navigation link styling
        TestUtils.assertContainsTailwindClasses(html, classes: [
            "text-gray-700",
            "font-medium"
        ])
    }
    
    @Test("Header handles empty navigation links")
    func testHeaderEmptyNavigation() throws {
        let header = Header(logoText: "Site", navigationLinks: [])
        let html = try TestUtils.renderHTML(header)
        
        // Should still render basic structure
        TestUtils.assertContainsText(html, texts: ["Site"])
        TestUtils.assertContainsTailwindClasses(html, classes: ["w-full", "container"])
        
        // Should not contain any navigation links or aria-current attributes
        #expect(!html.contains("aria-current"))
    }
    
    @Test("Header handles special characters in logo text")
    func testHeaderSpecialCharacters() throws {
        let logoWithSpecialChars = "My Site™ & Co. <script>alert('test')</script>"
        let header = Header(logoText: logoWithSpecialChars, navigationLinks: [])
        let html = try TestUtils.renderHTML(header)
        
        // Should contain escaped HTML
        #expect(html.contains("My Site™ &amp; Co."))
        #expect(html.contains("&lt;script&gt;"))
        #expect(!html.contains("<script>alert"))
    }
    
    @Test("Header applies proper background and border styling")
    func testHeaderStyling() throws {
        let header = Header(logoText: "Site", navigationLinks: [])
        let html = try TestUtils.renderHTML(header)
        
        // Verify background and border classes
        TestUtils.assertContainsTailwindClasses(html, classes: [
            "bg-white",
            "border-b",
            "border-b-gray-200"
        ])
        
        // Verify sticky positioning and backdrop blur (via ClassModifier)
        #expect(html.contains("sticky"))
        #expect(html.contains("top-0"))
        #expect(html.contains("z-50"))
        #expect(html.contains("backdrop-blur-sm"))
        #expect(html.contains("bg-opacity-90"))
    }
    
    @Test("Header responsive padding classes are applied")
    func testHeaderResponsivePadding() throws {
        let header = Header(logoText: "Site", navigationLinks: [])
        let html = try TestUtils.renderHTML(header)
        
        // Verify base and responsive padding classes
        TestUtils.assertContainsTailwindClasses(html, classes: [
            "py-4", // padding(.vertical, 16)
            "px-4", // base horizontal padding
            "md:px-6", // medium breakpoint padding
            "lg:px-8"  // large breakpoint padding
        ])
    }
    
    @Test("Header first navigation link is automatically marked as active")
    func testHeaderActiveNavigation() throws {
        let navigationLinks = [
            NavigationLink(title: "Home", href: "/"),
            NavigationLink(title: "About", href: "/about")
        ]
        let header = Header(logoText: "Site", navigationLinks: navigationLinks)
        let html = try TestUtils.renderHTML(header)
        
        // Verify first link has aria-current attribute (automatic active state)
        #expect(html.contains("aria-current-page"))
    }
    
    @Test("Header handles long navigation lists")
    func testHeaderLongNavigation() throws {
        let manyLinks = (1...10).map { index in
            NavigationLink(title: "Link \(index)", href: "/link\(index)")
        }
        let header = Header(logoText: "Site", navigationLinks: manyLinks)
        let html = try TestUtils.renderHTML(header)
        
        // Should render all links
        for i in 1...10 {
            TestUtils.assertContainsText(html, texts: ["Link \(i)"])
            #expect(html.contains("href=\"/link\(i)\""))
        }
        
        // Should maintain proper structure
        TestUtils.assertContainsTailwindClasses(html, classes: ["w-full", "container"])
    }
    
    @Test("Header component integrates with BasePage properly")
    func testHeaderBasePageIntegration() throws {
        let navigationLinks = [
            NavigationLink(title: "Home", href: "/"),
            NavigationLink(title: "About", href: "/about")
        ]
        let header = Header(logoText: "Integration Test", navigationLinks: navigationLinks)
        
        let page = BasePage(title: "Test Page") {
            header
            PlaceholderView(text: "Page Content")
        }
        
        let html = try TestUtils.renderHTML(page)
        
        // Verify complete HTML document structure
        TestUtils.assertValidHTMLDocument(html)
        TestUtils.assertValidTitle(html, expectedTitle: "Test Page")
        TestUtils.assertContainsStylesheet(html)
        
        // Verify header is properly integrated
        TestUtils.assertContainsText(html, texts: ["Integration Test", "Home", "About", "Page Content"])
        TestUtils.assertContainsTailwindClasses(html, classes: ["w-full", "container"])
    }
}
