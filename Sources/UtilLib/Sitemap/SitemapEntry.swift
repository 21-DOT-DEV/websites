//
//  SitemapEntry.swift
//  Utilities
//
//  Copyright (c) 2025 21.dev
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
    /// Failed to determine lastmod date.
    case lastmodFailed(String)
    /// Failed to write sitemap file.
    case writeFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid sitemap URL: \(url)"
        case .discoveryFailed(let reason):
            return "URL discovery failed: \(reason)"
        case .lastmodFailed(let reason):
            return "Failed to determine lastmod: \(reason)"
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
public struct SitemapEntry: Codable, Equatable, Sendable {
    /// The absolute URL for this sitemap entry.
    public let url: String
    
    /// The last modification date for this URL.
    public let lastmod: Date
    
    /// Creates a new sitemap entry with validation.
    ///
    /// - Parameters:
    ///   - url: The absolute URL (must be valid HTTP/HTTPS, max 2048 chars)
    ///   - lastmod: The last modification date
    /// - Throws: `SitemapError.invalidURL` if the URL is not valid for sitemap inclusion
    public init(url: String, lastmod: Date) throws {
        guard isValidSitemapURL(url) else {
            throw SitemapError.invalidURL(url)
        }
        self.url = url
        self.lastmod = lastmod
    }
    
    /// Generates the XML representation of this entry for sitemap inclusion.
    ///
    /// - Returns: A complete `<url>` XML element with escaped content
    public func toXML() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let dateString = formatter.string(from: lastmod)
        return sitemapURLEntry(url: url, lastmod: dateString)
    }
}
