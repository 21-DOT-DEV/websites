//
//  LinkRewriteResult.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Action taken on a single HTML file during a link-rewrite pass.
public enum LinkRewriteAction: String, Sendable {
    /// File contained one or more rewritable anchors and was updated
    /// (or would be updated, in dry-run / check mode).
    case rewritten

    /// File contained no rewritable anchors; left untouched.
    case unchanged

    /// Error occurred during read, parse, or write.
    case failed
}

/// Result of the link-rewrite pass on a single file.
public struct LinkRewriteResult: Sendable {
    /// Absolute path to the file
    public let filePath: String

    /// Action taken
    public let action: LinkRewriteAction

    /// Number of `<a href>` values rewritten in this file
    public let rewriteCount: Int

    /// Error message if action is .failed
    public let errorMessage: String?

    public init(
        filePath: String,
        action: LinkRewriteAction,
        rewriteCount: Int,
        errorMessage: String?
    ) {
        self.filePath = filePath
        self.action = action
        self.rewriteCount = rewriteCount
        self.errorMessage = errorMessage
    }
}
