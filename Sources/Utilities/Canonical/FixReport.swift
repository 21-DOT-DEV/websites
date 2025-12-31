//
//  FixReport.swift
//  Utilities
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Aggregate container for fix operation results.
public struct FixReport: Sendable {
    /// All individual fix results
    public let results: [FixResult]
    
    /// Count of files where canonical was added
    public var addedCount: Int {
        results.filter { $0.action == .added }.count
    }
    
    /// Count of files where canonical was updated
    public var updatedCount: Int {
        results.filter { $0.action == .updated }.count
    }
    
    /// Count of files that were skipped
    public var skippedCount: Int {
        results.filter { $0.action == .skipped }.count
    }
    
    /// Count of files that failed to fix
    public var failedCount: Int {
        results.filter { $0.action == .failed }.count
    }
    
    /// Whether all operations succeeded (no failures)
    public var isSuccess: Bool {
        failedCount == 0
    }
    
    /// Creates a new fix report.
    /// - Parameter results: All individual fix results
    public init(results: [FixResult]) {
        self.results = results
    }
}
