//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import Testing

/// Shared test utilities for all test targets
public enum TestUtils {
    
    // MARK: - HTML Rendering
    
    /// Renders any Slipstream View to HTML using the official Slipstream API
    public static func renderHTML<T: View>(_ view: T) throws -> String {
        return try Slipstream.renderHTML(view)
    }
    
    // MARK: - HTML Processing
    
    /// Normalizes HTML by trimming whitespace and collapsing multiple spaces
    public static func normalizeHTML(_ html: String) -> String {
        return html
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
    // MARK: - Tailwind CSS Assertions
    
    /// Asserts that HTML contains all specified Tailwind CSS classes
    public static func assertContainsTailwindClasses(_ html: String, classes: [String]) {
        for className in classes {
            #expect(html.contains(className), "HTML should contain Tailwind class: \(className)")
        }
    }
    
    /// Common Tailwind classes for PlaceholderView components
    public static let placeholderViewClasses = [
        "h-screen",      // Full viewport height
        "flex",          // Flexbox container
        "items-center",  // Vertical centering
        "justify-center", // Horizontal centering
        "text-7xl",     // Large font size
        "text-center",  // Text alignment
        "font-sans"     // Sans-serif font
    ]
    
    // MARK: - HTML Structure Validation
    
    /// Asserts that HTML has valid HTML document structure
    public static func assertValidHTMLDocument(_ html: String) {
        #expect(html.contains("<html") || html.hasPrefix("<!doctype html>"), "HTML should start with doctype or html tag")
        #expect(html.contains("<head>"), "HTML should contain head section")
        #expect(html.contains("<body>"), "HTML should contain body section")
        #expect(html.contains("</body>"), "HTML should close body section")
        #expect(html.contains("</html>"), "HTML should close html tag")
    }
    
    /// Asserts that HTML contains a valid title tag with expected content
    public static func assertValidTitle(_ html: String, expectedTitle: String? = nil) {
        #expect(html.contains("<title>"), "HTML should contain title tag")
        #expect(html.contains("</title>"), "HTML should close title tag")
        
        if let expectedTitle = expectedTitle {
            #expect(html.contains("<title>\(expectedTitle)</title>"), "HTML should contain expected title: \(expectedTitle)")
        }
    }
    
    /// Asserts that HTML contains stylesheet link
    public static func assertContainsStylesheet(_ html: String, stylesheetPath: String = "static/style.css") {
        #expect(html.contains(stylesheetPath), "HTML should contain stylesheet: \(stylesheetPath)")
    }
    
    /// Asserts that HTML contains UTF-8 meta charset declaration
    public static func assertContainsUTF8Charset(_ html: String) {
        #expect(html.contains("<meta charset=\"UTF-8\" />"), "HTML should contain UTF-8 charset meta tag")
    }
    
    // MARK: - File System Utilities
    
    /// Creates a temporary directory for testing file operations
    public static func createTempDirectory(suffix: String = "") -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueName = "test-\(UUID().uuidString)\(suffix)"
        return tempDir.appendingPathComponent(uniqueName)
    }
    
    /// Safely removes a directory and its contents if it exists
    public static func cleanupDirectory(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Content Validation
    
    /// Asserts that HTML contains expected text content
    public static func assertContainsText(_ html: String, texts: [String]) {
        for text in texts {
            #expect(html.contains(text), "HTML should contain text: \(text)")
        }
    }
    
    /// Asserts that HTML does not contain specified text content
    public static func assertDoesNotContainText(_ html: String, texts: [String]) {
        for text in texts {
            #expect(!html.contains(text), "HTML should not contain text: \(text)")
        }
    }
}
