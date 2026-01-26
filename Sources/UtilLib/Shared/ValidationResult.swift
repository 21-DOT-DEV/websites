//
//  ValidationResult.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Represents an error found during validation.
public struct ValidationError: Error, CustomStringConvertible, Sendable {
    /// Error code (e.g., "INVALID_URL", "MISSING_HEADER")
    public let code: String
    
    /// Human-readable error message
    public let message: String
    
    /// Optional location (file path, line number, etc.)
    public let location: String?
    
    /// Creates a validation error.
    public init(code: String, message: String, location: String? = nil) {
        self.code = code
        self.message = message
        self.location = location
    }
    
    /// Formatted description of the error.
    public var description: String {
        if let location = location {
            return "[\(code)] \(message) at \(location)"
        }
        return "[\(code)] \(message)"
    }
}

/// Result of a validation operation (sitemap, headers, state).
public struct ValidationResult: Sendable {
    /// Overall pass/fail status
    public let isValid: Bool
    
    /// List of errors (empty if valid)
    public let errors: [ValidationError]
    
    /// Non-fatal warnings
    public let warnings: [String]
    
    /// Creates a validation result.
    public init(isValid: Bool, errors: [ValidationError], warnings: [String]) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
    }
    
    /// Creates a successful validation result.
    /// - Parameter warnings: Optional warnings to include
    /// - Returns: A valid result with no errors
    public static func success(warnings: [String] = []) -> ValidationResult {
        ValidationResult(isValid: true, errors: [], warnings: warnings)
    }
    
    /// Creates a failed validation result.
    /// - Parameter errors: The errors that caused the failure
    /// - Returns: An invalid result with the specified errors
    public static func failure(_ errors: [ValidationError]) -> ValidationResult {
        ValidationResult(isValid: false, errors: errors, warnings: [])
    }
}
