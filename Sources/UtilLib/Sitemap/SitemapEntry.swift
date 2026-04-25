//
//  SitemapEntry.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Errors that can occur during sitemap operations.
public enum SitemapError: Error, LocalizedError {
    /// The provided URL is not valid for sitemap inclusion.
    case invalidURL(String)
    /// Failed to discover URLs in the output directory.
    case discoveryFailed(String)
    /// Failed to write sitemap file.
    case writeFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid sitemap URL: \(url)"
        case .discoveryFailed(let reason):
            return "URL discovery failed: \(reason)"
        case .writeFailed(let reason):
            return "Failed to write sitemap: \(reason)"
        }
    }
}

/// Represents a single URL entry in a sitemap.
///
/// Conforms to sitemap protocol 0.9 specifications:
/// - URL must use HTTP or HTTPS scheme
/// - URL must have a valid host (absolute URL)
/// - URL length must not exceed 2048 characters
///
/// Sitemap entries emit only the `<loc>` element. The `<lastmod>` element is
/// optional in protocol 0.9 and is intentionally omitted across all sites in
/// this repo: aggregated docs (docs.21.dev) lack a per-URL change signal, and
/// per-URL git tracking for 21.dev was removed because uniform timestamps from
/// a single source file degraded sitemap trust. See git history for context.
public struct SitemapEntry: Codable, Equatable, Sendable {
    /// The absolute URL for this sitemap entry.
    public let url: String
    
    /// Creates a new sitemap entry with validation.
    ///
    /// - Parameter url: The absolute URL (must be valid HTTP/HTTPS, max 2048 chars)
    /// - Throws: `SitemapError.invalidURL` if the URL is not valid for sitemap inclusion
    public init(url: String) throws {
        guard isValidSitemapURL(url) else {
            throw SitemapError.invalidURL(url)
        }
        self.url = url
    }
    
    /// Generates the XML representation of this entry for sitemap inclusion.
    ///
    /// - Returns: A complete `<url>` XML element with escaped content
    public func toXML() -> String {
        return sitemapURLEntry(url: url)
    }
}
