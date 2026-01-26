//
//  FixResult.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Action taken during a fix operation.
public enum FixAction: String, Sendable {
    /// Canonical tag was inserted (file was missing canonical)
    case added
    
    /// Existing canonical tag was replaced (--force flag used)
    case updated
    
    /// File already has canonical tag and was not modified (no --force)
    case skipped
    
    /// Error occurred during fix operation
    case failed
}

/// Represents the result of a fix operation on a single file.
public struct FixResult: Sendable {
    /// Path to the file
    public let filePath: String
    
    /// Action taken
    public let action: FixAction
    
    /// Error message if action is .failed
    public let errorMessage: String?
    
    /// Creates a new fix result.
    /// - Parameters:
    ///   - filePath: Path to the file
    ///   - action: Action taken
    ///   - errorMessage: Error message if action is .failed
    public init(filePath: String, action: FixAction, errorMessage: String?) {
        self.filePath = filePath
        self.action = action
        self.errorMessage = errorMessage
    }
}
