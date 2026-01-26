//
//  CanonicalResult.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Represents the check result for a single HTML file.
public struct CanonicalResult: Sendable {
    /// Absolute path to the HTML file
    public let filePath: String
    
    /// Relative path from scan directory (used for URL derivation)
    public let relativePath: String
    
    /// Check result status
    public let status: CanonicalStatus
    
    /// Existing canonical URL found in file (nil if missing)
    public let existingURL: URL?
    
    /// Expected canonical URL derived from base URL + path
    public let expectedURL: URL
    
    /// Error message if status is .error
    public let errorMessage: String?
    
    /// Creates a new canonical result.
    /// - Parameters:
    ///   - filePath: Absolute path to the HTML file
    ///   - relativePath: Relative path from scan directory
    ///   - status: Check result status
    ///   - existingURL: Existing canonical URL found in file (nil if missing)
    ///   - expectedURL: Expected canonical URL derived from base URL + path
    ///   - errorMessage: Error message if status is .error
    public init(
        filePath: String,
        relativePath: String,
        status: CanonicalStatus,
        existingURL: URL?,
        expectedURL: URL,
        errorMessage: String?
    ) {
        self.filePath = filePath
        self.relativePath = relativePath
        self.status = status
        self.existingURL = existingURL
        self.expectedURL = expectedURL
        self.errorMessage = errorMessage
    }
}
