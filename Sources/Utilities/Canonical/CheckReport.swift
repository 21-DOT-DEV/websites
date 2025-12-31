//
//  CheckReport.swift
//  Utilities
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Aggregate container for all check results with summary statistics.
public struct CheckReport: Sendable {
    /// All individual file results
    public let results: [CanonicalResult]
    
    /// Base URL used for derivation
    public let baseURL: URL
    
    /// Directory that was scanned
    public let scanDirectory: String
    
    /// Count of files with valid canonical tags
    public var validCount: Int {
        results.filter { $0.status == .valid }.count
    }
    
    /// Count of files with mismatched canonical tags
    public var mismatchCount: Int {
        results.filter { $0.status == .mismatch }.count
    }
    
    /// Count of files missing canonical tags
    public var missingCount: Int {
        results.filter { $0.status == .missing }.count
    }
    
    /// Count of files with errors
    public var errorCount: Int {
        results.filter { $0.status == .error }.count
    }
    
    /// Total number of files processed
    public var totalCount: Int {
        results.count
    }
    
    /// Whether all files are valid (no issues found)
    public var isAllValid: Bool {
        mismatchCount == 0 && missingCount == 0 && errorCount == 0
    }
    
    /// Creates a new check report.
    /// - Parameters:
    ///   - results: All individual file results
    ///   - baseURL: Base URL used for derivation
    ///   - scanDirectory: Directory that was scanned
    public init(results: [CanonicalResult], baseURL: URL, scanDirectory: String) {
        self.results = results
        self.baseURL = baseURL
        self.scanDirectory = scanDirectory
    }
}
