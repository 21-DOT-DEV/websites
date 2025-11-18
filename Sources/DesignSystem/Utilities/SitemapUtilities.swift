//
//  SitemapUtilities.swift
//  DesignSystem
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

// MARK: - Sitemap XML Generation

/// Generates the standard XML header for a sitemap conforming to protocol 0.9
/// - Returns: XML header string with namespace declaration
public func sitemapXMLHeader() -> String {
    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    
    """
}

/// Generates the closing tag for a sitemap XML file
/// - Returns: XML footer string
public func sitemapXMLFooter() -> String {
    return "</urlset>"
}

/// Generates a complete URL entry for a sitemap
/// - Parameters:
///   - url: The absolute URL for the page
///   - lastmod: ISO 8601 formatted last modification date
/// - Returns: Complete `<url>` XML element
public func sitemapURLEntry(url: String, lastmod: String) -> String {
    let escapedURL = xmlEscape(url)
    return """
    <url>
      <loc>\(escapedURL)</loc>
      <lastmod>\(lastmod)</lastmod>
    </url>
    
    """
}

// MARK: - Sitemap Utility Functions

/// Escapes special XML characters in a string to ensure valid XML output
/// - Parameter text: The input string to escape
/// - Returns: XML-safe string with escaped characters (&, <, >, ', ")
public func xmlEscape(_ text: String) -> String {
    return text
        .replacingOccurrences(of: "&", with: "&amp;")
        .replacingOccurrences(of: "<", with: "&lt;")
        .replacingOccurrences(of: ">", with: "&gt;")
        .replacingOccurrences(of: "'", with: "&apos;")
        .replacingOccurrences(of: "\"", with: "&quot;")
}

/// Validates a URL for inclusion in a sitemap according to protocol 0.9 specifications
/// - Parameter url: The URL string to validate
/// - Returns: true if the URL is valid for sitemap inclusion, false otherwise
///
/// Validation rules:
/// - Must use HTTP or HTTPS scheme
/// - Must be a valid, well-formed URL
/// - Maximum length of 2048 characters (sitemap protocol limit)
/// - Must be an absolute URL (not relative)
public func isValidSitemapURL(_ url: String) -> Bool {
    // Check length limit (sitemap protocol 0.9 max)
    guard url.count <= 2048 else {
        return false
    }
    
    // Parse URL
    guard let parsedURL = URL(string: url) else {
        return false
    }
    
    // Validate scheme (must be http or https)
    guard let scheme = parsedURL.scheme,
          scheme == "http" || scheme == "https" else {
        return false
    }
    
    // Ensure it's an absolute URL (has a host)
    guard parsedURL.host != nil else {
        return false
    }
    
    return true
}
