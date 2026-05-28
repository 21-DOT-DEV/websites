//
//  LinkRewriteReport.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Aggregate container for a link-rewrite pass across a directory.
public struct LinkRewriteReport: Sendable {
    /// All individual per-file results
    public let results: [LinkRewriteResult]

    /// Count of files that had at least one anchor rewritten
    public var rewrittenCount: Int {
        results.filter { $0.action == .rewritten }.count
    }

    /// Count of files with no rewritable anchors
    public var unchangedCount: Int {
        results.filter { $0.action == .unchanged }.count
    }

    /// Count of files that failed to rewrite
    public var failedCount: Int {
        results.filter { $0.action == .failed }.count
    }

    /// Total `<a href>` values rewritten across all files
    public var totalLinksRewritten: Int {
        results.reduce(0) { $0 + $1.rewriteCount }
    }

    /// Whether all operations succeeded (no failures)
    public var isSuccess: Bool {
        failedCount == 0
    }

    public init(results: [LinkRewriteResult]) {
        self.results = results
    }
}
