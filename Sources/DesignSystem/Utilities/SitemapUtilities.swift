//
//  SitemapUtilities.swift
//  DesignSystem
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//
/// DEPRECATED: These utilities have moved to the `Utilities` library.
/// Import `Utilities` directly and use the `util` CLI for sitemap operations.
/// This file re-exports the APIs for backward compatibility.

@_exported import Utilities

import Foundation
import Subprocess

// MARK: - Deprecated Re-exports

/// Get the last modification date for a file from git history
/// - Parameter filePath: Relative path to the file in the repository
/// - Returns: ISO8601 formatted date string from git, or current date if git history unavailable
@available(*, deprecated, message: "Use SitemapGenerator.getGitLastmod(for:) from the Utilities library")
public func getGitLastModDate(filePath: String) async throws -> String {
    // Inline implementation to avoid cross-module visibility issues
    do {
        let result = try await Subprocess.run(
            .name("git"),
            arguments: .init([
                "log",
                "-1",
                "--format=%cI",
                "--",
                filePath
            ]),
            output: .string(limit: 4096),
            error: .string(limit: 1024)
        )
        
        guard case .exited(0) = result.terminationStatus else {
            return ISO8601DateFormatter().string(from: Date())
        }
        
        guard let dateString = result.standardOutput?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !dateString.isEmpty else {
            return ISO8601DateFormatter().string(from: Date())
        }
        
        return dateString
    } catch {
        return ISO8601DateFormatter().string(from: Date())
    }
}

// MARK: - Sitemap XML Generation

/// Generates the standard XML header for a sitemap conforming to protocol 0.9
/// - Returns: XML header string with namespace declaration
@available(*, deprecated, message: "Use SitemapGenerator from the Utilities library")
public func sitemapXMLHeader() -> String {
    return """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    
    """
}

/// Generates the closing tag for a sitemap XML file
/// - Returns: XML footer string
@available(*, deprecated, message: "Use SitemapGenerator from the Utilities library")
public func sitemapXMLFooter() -> String {
    return "</urlset>"
}

/// Generates a complete URL entry for a sitemap
/// - Parameters:
///   - url: The absolute URL for the page
///   - lastmod: ISO 8601 formatted last modification date
/// - Returns: Complete `<url>` XML element
@available(*, deprecated, message: "Use SitemapEntry from the Utilities library")
public func sitemapURLEntry(url: String, lastmod: String) -> String {
    let escapedURL = xmlEscape(url)
    return """
    <url>
      <loc>\(escapedURL)</loc>
      <lastmod>\(lastmod)</lastmod>
    </url>
    
    """
}

/// Escapes special XML characters in a string to ensure valid XML output
/// - Parameter text: The input string to escape
/// - Returns: XML-safe string with escaped characters (&, <, >, ', ")
@available(*, deprecated, message: "Use xmlEscape from the Utilities library")
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
@available(*, deprecated, message: "Use isValidSitemapURL from the Utilities library")
public func isValidSitemapURL(_ url: String) -> Bool {
    guard url.count <= 2048 else { return false }
    guard let parsedURL = URL(string: url) else { return false }
    guard let scheme = parsedURL.scheme,
          scheme == "http" || scheme == "https" else { return false }
    guard parsedURL.host != nil else { return false }
    return true
}
