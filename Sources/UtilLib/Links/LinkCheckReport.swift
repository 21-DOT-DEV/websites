//
//  LinkCheckReport.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// A single extracted reference with its check outcome.
public struct CheckedReference: Sendable, Equatable {
    /// How a reference was resolved.
    public enum Outcome: Sendable, Equatable {
        /// Internal reference resolved to this site-relative path (leading `/`).
        case resolved(sitePath: String)
        /// Not an internal path — external URL, scheme, fragment-only, or empty.
        case skipped
        /// Internal reference that resolved to nothing.
        case broken(resolvedPath: String, reason: String)
    }

    /// The HTML attribute that carried the reference (`href`, `src`, `srcset`).
    public let attribute: ExtractedLink.Attribute

    /// The URL token as written in the markup.
    public let rawValue: String

    /// What the reference resolved to.
    public let outcome: Outcome

    public init(attribute: ExtractedLink.Attribute, rawValue: String, outcome: Outcome) {
        self.attribute = attribute
        self.rawValue = rawValue
        self.outcome = outcome
    }
}

/// Per-file outcome of an internal link check.
public struct FileLinkCheck: Sendable, Equatable {
    /// Absolute path to the checked file.
    public let filePath: String

    /// Path relative to the scanned directory.
    public let relativePath: String

    /// Every extracted reference with its outcome, grouped by selector pass.
    public let references: [CheckedReference]

    /// Non-nil when the file could not be read or parsed — counted as skipped
    /// and surfaced as a warning rather than dropped silently.
    public let skippedReason: String?

    public init(filePath: String, relativePath: String, references: [CheckedReference], skippedReason: String? = nil) {
        self.filePath = filePath
        self.relativePath = relativePath
        self.references = references
        self.skippedReason = skippedReason
    }

    /// Internal references resolved against the site output.
    public var checkedCount: Int {
        references.count { if case .skipped = $0.outcome { return false }; return true }
    }

    /// References skipped without checking (external, `mailto:`, fragment-only, …).
    public var skippedCount: Int {
        references.count { if case .skipped = $0.outcome { return true }; return false }
    }

    /// Internal references that resolved to nothing.
    public var brokenLinks: [BrokenLink] {
        references.compactMap { reference in
            guard case .broken(let resolvedPath, let reason) = reference.outcome else { return nil }
            return BrokenLink(
                attribute: reference.attribute.rawValue,
                rawValue: reference.rawValue,
                resolvedPath: resolvedPath,
                reason: reason
            )
        }
    }
}

/// Aggregated result of `InternalLinkChecker.checkDirectory`.
public struct LinkCheckReport: Sendable {
    /// Per-file results, sorted by relative path.
    public let results: [FileLinkCheck]

    /// The directory that was scanned.
    public let scanDirectory: String

    /// Scan-level warnings not tied to one file (e.g. an unreadable `_redirects`).
    public let scanWarnings: [String]

    public init(results: [FileLinkCheck], scanDirectory: String, scanWarnings: [String] = []) {
        self.results = results
        self.scanDirectory = scanDirectory
        self.scanWarnings = scanWarnings
    }

    /// Total internal references resolved against the output.
    public var totalChecked: Int { results.reduce(0) { $0 + $1.checkedCount } }

    /// Total references skipped (external, scheme, fragment-only).
    public var totalSkipped: Int { results.reduce(0) { $0 + $1.skippedCount } }

    /// Total broken internal references across all files.
    public var totalBroken: Int { results.reduce(0) { $0 + $1.brokenLinks.count } }

    /// Files containing at least one broken reference.
    public var filesWithBrokenLinks: [FileLinkCheck] {
        results.filter { !$0.brokenLinks.isEmpty }
    }

    /// Files that could not be read or parsed — counted as skipped.
    public var skippedFiles: [FileLinkCheck] {
        results.filter { $0.skippedReason != nil }
    }

    /// One warning line per skipped file, naming it, plus scan-level warnings.
    public var warnings: [String] {
        scanWarnings + skippedFiles.map { "\($0.relativePath): \($0.skippedReason ?? "unreadable")" }
    }

    /// `true` when no broken internal references were found *and* at least one
    /// file was actually checked — an all-unparseable scan verifies nothing.
    public var isSuccess: Bool {
        totalBroken == 0 && results.contains { $0.skippedReason == nil }
    }
}
