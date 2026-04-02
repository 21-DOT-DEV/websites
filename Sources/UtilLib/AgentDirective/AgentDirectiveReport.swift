//
//  AgentDirectiveReport.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Action taken during an agent directive injection operation.
public enum InjectionAction: String, Sendable {
    /// Directive was injected into the file
    case injected

    /// File already has directive and was not modified (no --force)
    case skipped

    /// Error occurred during injection
    case failed
}

/// Represents the result of an injection operation on a single file.
public struct InjectionResult: Sendable {
    /// Absolute path to the HTML file
    public let filePath: String

    /// Relative path from scan directory
    public let relativePath: String

    /// Action taken
    public let action: InjectionAction

    /// Error message if action is .failed
    public let errorMessage: String?

    /// Creates a new injection result.
    /// - Parameters:
    ///   - filePath: Absolute path to the HTML file
    ///   - relativePath: Relative path from scan directory
    ///   - action: Action taken
    ///   - errorMessage: Error message if action is .failed
    public init(
        filePath: String,
        relativePath: String,
        action: InjectionAction,
        errorMessage: String?
    ) {
        self.filePath = filePath
        self.relativePath = relativePath
        self.action = action
        self.errorMessage = errorMessage
    }
}

/// Aggregate container for injection operation results.
public struct InjectionReport: Sendable {
    /// All individual injection results
    public let results: [InjectionResult]

    /// Count of files where directive was injected
    public var injectedCount: Int {
        results.filter { $0.action == .injected }.count
    }

    /// Count of files that were skipped
    public var skippedCount: Int {
        results.filter { $0.action == .skipped }.count
    }

    /// Count of files that failed
    public var failedCount: Int {
        results.filter { $0.action == .failed }.count
    }

    /// Whether all operations succeeded (no failures)
    public var isSuccess: Bool {
        failedCount == 0
    }

    /// Creates a new injection report.
    /// - Parameter results: All individual injection results
    public init(results: [InjectionResult]) {
        self.results = results
    }
}
