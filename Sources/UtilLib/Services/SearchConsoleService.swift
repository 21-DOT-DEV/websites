//
//  SearchConsoleService.swift
//  UtilLib
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

// MARK: - SearchConsoleError

/// Errors that can occur during Search Console operations.
public enum SearchConsoleError: Error, Equatable, Sendable {
    /// The sitemap URL is invalid.
    case invalidSitemapURL(String)
    
    /// The sitemap submission failed.
    case submissionFailed(Int, String)
}

extension SearchConsoleError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidSitemapURL(let url):
            return "Invalid sitemap URL: \(url)"
        case .submissionFailed(let statusCode, let message):
            return "Submission failed with HTTP \(statusCode): \(message)"
        }
    }
}

// MARK: - SubmitResult

/// Result of a sitemap submission.
public struct SubmitResult: Sendable {
    public let success: Bool
    public let errorMessage: String?
    
    public init(success: Bool, errorMessage: String? = nil) {
        self.success = success
        self.errorMessage = errorMessage
    }
}

// MARK: - SearchConsoleService

/// Service for Google Search Console sitemap submission.
public enum SearchConsoleService {
    
    /// Google Search Console API base URL.
    public static let apiBaseURL = "https://www.googleapis.com/webmasters/v3"
    
    // MARK: - Site URL Formatting
    
    /// Formats a sitemap URL into the sc-domain format required by Search Console.
    /// Example: "https://21.dev/sitemap.xml" -> "sc-domain:21.dev"
    public static func formatSiteURL(from sitemapURL: String) -> String {
        guard let url = URL(string: sitemapURL),
              let host = url.host else {
            return "sc-domain:\(sitemapURL)"
        }
        return "sc-domain:\(host)"
    }
    
    // MARK: - Sitemap URL Derivation
    
    /// Derives the sitemap URL for a known site.
    public static func deriveSitemapURL(for site: SiteName) -> String {
        switch site {
        case .dev21:
            return "https://21.dev/sitemap.xml"
        case .docs21dev:
            return "https://docs.21.dev/sitemap.xml"
        case .md21dev:
            return "https://md.21.dev/sitemap.xml"
        }
    }
    
    // MARK: - API Request Building
    
    /// Builds a URLRequest for submitting a sitemap to Search Console.
    public static func buildSubmitRequest(
        sitemapURL: String,
        accessToken: String
    ) throws -> URLRequest {
        let siteURL = formatSiteURL(from: sitemapURL)
        
        // URL-encode for Google API path segments (must encode : and /)
        // Google requires full percent-encoding of special characters in path
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        
        guard let siteEncoded = siteURL.addingPercentEncoding(withAllowedCharacters: allowed),
              let sitemapEncoded = sitemapURL.addingPercentEncoding(withAllowedCharacters: allowed) else {
            throw SearchConsoleError.invalidSitemapURL(sitemapURL)
        }
        
        let urlString = "\(apiBaseURL)/sites/\(siteEncoded)/sitemaps/\(sitemapEncoded)"
        
        guard let url = URL(string: urlString) else {
            throw SearchConsoleError.invalidSitemapURL(sitemapURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    // MARK: - Response Parsing
    
    /// Parses the response from a sitemap submission.
    public static func parseSubmitResponse(statusCode: Int, body: Data?) -> SubmitResult {
        // 200 or 204 indicates success
        if statusCode == 200 || statusCode == 204 {
            return SubmitResult(success: true)
        }
        
        // Try to extract error message from response body
        var errorMessage = "HTTP \(statusCode)"
        if let body = body,
           let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            errorMessage = "HTTP \(statusCode): \(message)"
        }
        
        return SubmitResult(success: false, errorMessage: errorMessage)
    }
    
    // MARK: - Sitemap Submission
    
    /// Submits a sitemap to Google Search Console.
    public static func submitSitemap(
        sitemapURL: String,
        accessToken: String
    ) async throws -> SubmitResult {
        let request = try buildSubmitRequest(sitemapURL: sitemapURL, accessToken: accessToken)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            return SubmitResult(success: false, errorMessage: "Invalid response")
        }
        
        return parseSubmitResponse(statusCode: httpResponse.statusCode, body: data)
    }
    
    // MARK: - Output Formatting
    
    /// Formats a success message for human-readable output.
    public static func formatSuccessOutput(sitemapURL: String) -> String {
        return "✅ Sitemap submitted to Google Search Console\n   URL: \(sitemapURL)"
    }
    
    /// Formats an error message for human-readable output.
    public static func formatErrorOutput(sitemapURL: String, error: String) -> String {
        return "❌ Failed to submit sitemap to Google Search Console\n   URL: \(sitemapURL)\n   Error: \(error)"
    }
    
    /// Formats output as JSON for machine parsing.
    public static func formatJSONOutput(
        success: Bool,
        sitemapURL: String,
        error: String?
    ) -> String {
        var json: [String: Any] = [
            "success": success,
            "sitemapUrl": sitemapURL,
            "provider": "google",
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let error = error {
            json["error"] = error
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return #"{"success":false,"error":"Failed to serialize JSON"}"#
        }
        
        return string
    }
}
