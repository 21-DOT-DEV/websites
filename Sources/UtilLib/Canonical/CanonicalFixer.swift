//
//  CanonicalFixer.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import SwiftSoup

/// Fixes canonical URL tags in HTML files.
public enum CanonicalFixer {
    
    /// Inserts a canonical tag into HTML that doesn't have one.
    /// - Parameters:
    ///   - html: The HTML content
    ///   - canonicalURL: The canonical URL to insert
    /// - Returns: The modified HTML with canonical tag inserted
    public static func insertCanonical(html: String, canonicalURL: URL) throws -> String {
        let document = try SwiftSoup.parse(html)
        
        guard let head = document.head() else {
            throw CanonicalFixerError.noHeadSection
        }
        
        // Append canonical link to end of head
        let canonicalElement = try head.appendElement("link")
        try canonicalElement.attr("rel", "canonical")
        try canonicalElement.attr("href", canonicalURL.absoluteString)
        
        return try document.html()
    }
    
    /// Replaces an existing canonical tag with a new URL.
    /// - Parameters:
    ///   - html: The HTML content
    ///   - newCanonicalURL: The new canonical URL
    /// - Returns: The modified HTML with updated canonical tag
    public static func replaceCanonical(html: String, newCanonicalURL: URL) throws -> String {
        let document = try SwiftSoup.parse(html)
        
        guard let head = document.head() else {
            throw CanonicalFixerError.noHeadSection
        }
        
        // Find and update existing canonical
        let canonicalLinks = try head.select("link[rel=canonical]")
        
        if let existing = canonicalLinks.first() {
            try existing.attr("href", newCanonicalURL.absoluteString)
        } else {
            // No existing canonical, insert new one
            let canonicalElement = try head.appendElement("link")
            try canonicalElement.attr("rel", "canonical")
            try canonicalElement.attr("href", newCanonicalURL.absoluteString)
        }
        
        return try document.html()
    }
    
    /// Fixes a single file based on its check result.
    /// - Parameters:
    ///   - html: The HTML content
    ///   - checkResult: The result from checking this file
    ///   - force: Whether to overwrite existing canonical tags
    /// - Returns: Tuple of (fixed HTML, action taken)
    public static func fix(
        html: String,
        checkResult: CanonicalResult,
        force: Bool
    ) throws -> (String, FixAction) {
        switch checkResult.status {
        case .missing:
            let fixedHTML = try insertCanonical(html: html, canonicalURL: checkResult.expectedURL)
            return (fixedHTML, .added)
            
        case .mismatch:
            if force {
                let fixedHTML = try replaceCanonical(html: html, newCanonicalURL: checkResult.expectedURL)
                return (fixedHTML, .updated)
            } else {
                return (html, .skipped)
            }
            
        case .valid:
            return (html, .skipped)
            
        case .error:
            return (html, .failed)
        }
    }
    
    /// Fixes all files in a directory based on check results.
    /// - Parameters:
    ///   - checkReport: The report from checking the directory
    ///   - force: Whether to overwrite existing canonical tags
    ///   - dryRun: If true, don't actually modify files
    /// - Returns: A fix report with results for all files
    public static func fixDirectory(
        checkReport: CheckReport,
        force: Bool,
        dryRun: Bool
    ) throws -> FixReport {
        var fixResults: [FixResult] = []
        
        for checkResult in checkReport.results {
            do {
                let html = try String(contentsOfFile: checkResult.filePath, encoding: .utf8)
                let (fixedHTML, action) = try fix(html: html, checkResult: checkResult, force: force)
                
                // Write file if not dry run and action requires write
                if !dryRun && (action == .added || action == .updated) {
                    try fixedHTML.write(toFile: checkResult.filePath, atomically: true, encoding: .utf8)
                }
                
                fixResults.append(FixResult(
                    filePath: checkResult.filePath,
                    action: action,
                    errorMessage: nil
                ))
            } catch {
                fixResults.append(FixResult(
                    filePath: checkResult.filePath,
                    action: .failed,
                    errorMessage: error.localizedDescription
                ))
            }
        }
        
        return FixReport(results: fixResults)
    }
}

/// Errors that can occur during canonical fixing.
public enum CanonicalFixerError: Error, LocalizedError {
    case noHeadSection
    
    public var errorDescription: String? {
        switch self {
        case .noHeadSection:
            return "No <head> section found in HTML"
        }
    }
}
