//
//  CanonicalURLDeriver.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Utility for deriving canonical URLs from file paths.
public enum CanonicalURLDeriver {
    
    /// Derives a canonical URL from a base URL and relative file path.
    ///
    /// Normalization rules:
    /// - `index.html` at any level is converted to a trailing slash
    /// - `.html` extension is removed from non-index files
    /// - Base URL trailing slash handling is normalized
    ///
    /// - Parameters:
    ///   - baseURL: The base URL (e.g., `https://21.dev`)
    ///   - relativePath: The relative file path (e.g., `about/index.html`)
    /// - Returns: The derived canonical URL
    public static func deriveURL(baseURL: URL, relativePath: String) -> URL {
        var path = relativePath
        var isDirectory = false
        
        // Normalize index.html to directory with trailing slash
        if path == "index.html" {
            path = ""
            isDirectory = true
        } else if path.hasSuffix("/index.html") {
            // Remove "/index.html" (11 chars) to get directory path
            path = String(path.dropLast(11))
            isDirectory = true
        } else if path.hasSuffix(".html") {
            // Remove .html extension for non-index files
            path = String(path.dropLast(5))
        }
        
        // Build the URL
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        
        // Normalize base URL path - remove trailing slash if present
        var basePath = components.path
        if basePath.hasSuffix("/") {
            basePath = String(basePath.dropLast())
        }
        
        // Build final path
        if path.isEmpty {
            components.path = basePath + "/"
        } else {
            components.path = basePath + "/" + path + (isDirectory ? "/" : "")
        }
        
        return components.url!
    }
}
