//
//  CanonicalChecker.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import SwiftSoup

/// Checks HTML files for canonical URL tags and compares them to expected values.
public enum CanonicalChecker {
    
    /// Checks a single HTML string for canonical tag status.
    /// - Parameters:
    ///   - html: The HTML content to check
    ///   - filePath: Absolute path to the file (for reporting)
    ///   - relativePath: Relative path from scan directory (for URL derivation)
    ///   - baseURL: Base URL for deriving expected canonical
    /// - Returns: The check result for this file
    public static func checkHTML(
        html: String,
        filePath: String,
        relativePath: String,
        baseURL: URL
    ) throws -> CanonicalResult {
        let expectedURL = CanonicalURLDeriver.deriveURL(baseURL: baseURL, relativePath: relativePath)
        
        do {
            let document = try SwiftSoup.parse(html)
            
            // Check for head element - SwiftSoup auto-creates head, so check if original HTML has <head>
            let hasExplicitHead = html.lowercased().contains("<head")
            guard hasExplicitHead, let head = document.head() else {
                return CanonicalResult(
                    filePath: filePath,
                    relativePath: relativePath,
                    status: .error,
                    existingURL: nil,
                    expectedURL: expectedURL,
                    errorMessage: "No <head> section found"
                )
            }
            
            // Find all canonical link elements
            let canonicalLinks = try head.select("link[rel=canonical]")
            
            // Check for multiple canonical tags
            if canonicalLinks.size() > 1 {
                return CanonicalResult(
                    filePath: filePath,
                    relativePath: relativePath,
                    status: .error,
                    existingURL: nil,
                    expectedURL: expectedURL,
                    errorMessage: "Found multiple canonical tags (\(canonicalLinks.size()))"
                )
            }
            
            // No canonical tag found
            if canonicalLinks.isEmpty() {
                return CanonicalResult(
                    filePath: filePath,
                    relativePath: relativePath,
                    status: .missing,
                    existingURL: nil,
                    expectedURL: expectedURL,
                    errorMessage: nil
                )
            }
            
            // Extract href from canonical tag
            guard let canonicalLink = canonicalLinks.first(),
                  let href = try? canonicalLink.attr("href"),
                  !href.isEmpty,
                  let existingURL = URL(string: href) else {
                return CanonicalResult(
                    filePath: filePath,
                    relativePath: relativePath,
                    status: .error,
                    existingURL: nil,
                    expectedURL: expectedURL,
                    errorMessage: "Invalid or empty canonical href"
                )
            }
            
            // Compare existing to expected
            let status: CanonicalStatus = (existingURL.absoluteString == expectedURL.absoluteString) ? .valid : .mismatch
            
            return CanonicalResult(
                filePath: filePath,
                relativePath: relativePath,
                status: status,
                existingURL: existingURL,
                expectedURL: expectedURL,
                errorMessage: nil
            )
            
        } catch {
            return CanonicalResult(
                filePath: filePath,
                relativePath: relativePath,
                status: .error,
                existingURL: nil,
                expectedURL: expectedURL,
                errorMessage: "Parse error: \(error.localizedDescription)"
            )
        }
    }
    
    /// Scans a directory for HTML files and checks each one.
    /// - Parameters:
    ///   - directoryPath: Path to the directory to scan
    ///   - baseURL: Base URL for deriving expected canonicals
    /// - Returns: A report containing results for all files
    public static func checkDirectory(
        at directoryPath: String,
        baseURL: URL
    ) throws -> CheckReport {
        let fileManager = FileManager.default
        // Resolve symlinks to get consistent paths (e.g., /tmp -> /private/tmp on macOS)
        let resolvedDirPath = URL(fileURLWithPath: directoryPath).resolvingSymlinksInPath().path
        let directoryURL = URL(fileURLWithPath: resolvedDirPath)
        
        var results: [CanonicalResult] = []
        
        // Get all HTML files recursively
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw CanonicalCheckerError.cannotEnumerateDirectory(directoryPath)
        }
        
        // Normalize directory path for relative path calculation
        let normalizedDirPath = resolvedDirPath.hasSuffix("/") 
            ? resolvedDirPath 
            : resolvedDirPath + "/"
        
        for case let fileURL as URL in enumerator {
            // Only process .html files
            guard fileURL.pathExtension.lowercased() == "html" else {
                continue
            }
            
            let filePath = fileURL.resolvingSymlinksInPath().path
            let relativePath = String(filePath.dropFirst(normalizedDirPath.count))
            
            do {
                let html = try String(contentsOf: fileURL, encoding: .utf8)
                let result = try checkHTML(
                    html: html,
                    filePath: filePath,
                    relativePath: relativePath,
                    baseURL: baseURL
                )
                results.append(result)
            } catch {
                // File read error
                let expectedURL = CanonicalURLDeriver.deriveURL(baseURL: baseURL, relativePath: relativePath)
                results.append(CanonicalResult(
                    filePath: filePath,
                    relativePath: relativePath,
                    status: .error,
                    existingURL: nil,
                    expectedURL: expectedURL,
                    errorMessage: "Cannot read file: \(error.localizedDescription)"
                ))
            }
        }
        
        return CheckReport(
            results: results,
            baseURL: baseURL,
            scanDirectory: directoryPath
        )
    }
}

/// Errors that can occur during canonical checking.
public enum CanonicalCheckerError: Error, LocalizedError {
    case cannotEnumerateDirectory(String)
    
    public var errorDescription: String? {
        switch self {
        case .cannotEnumerateDirectory(let path):
            return "Cannot enumerate directory: \(path)"
        }
    }
}
