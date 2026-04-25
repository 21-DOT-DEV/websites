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

/// Outcome of attempting to load the DocC sidecar JSON for a page.
///
/// The injector treats sidecars as best-effort enrichment: a missing sidecar
/// (top-level / landing pages) is expected, and a malformed sidecar must not
/// abort the directory walk. Aggregate counts on `InjectionReport` let the
/// CLI gate the build at a configurable failure-rate threshold.
public enum SidecarStatus: String, Sendable {
    /// Sidecar JSON found and decoded successfully.
    case loaded

    /// No sidecar exists for this page (e.g., `documentation/index.html`).
    case missing

    /// Sidecar exists but failed to decode. The associated parse error is
    /// captured in `InjectionResult.sidecarFailureMessage`.
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

    /// Whether this page was marked noindex (not on allowlist)
    public let noindexed: Bool

    /// Error message if action is .failed
    public let errorMessage: String?

    /// Outcome of locating + decoding the DocC sidecar for this page.
    public let sidecarStatus: SidecarStatus

    /// Decoder error message when `sidecarStatus == .failed`. `nil` otherwise.
    public let sidecarFailureMessage: String?

    /// Creates a new injection result.
    /// - Parameters:
    ///   - filePath: Absolute path to the HTML file
    ///   - relativePath: Relative path from scan directory
    ///   - action: Action taken
    ///   - noindexed: Whether the page was marked noindex
    ///   - errorMessage: Error message if action is .failed
    ///   - sidecarStatus: Outcome of DocC sidecar lookup (defaults to
    ///     `.missing` so existing call sites remain source-compatible)
    ///   - sidecarFailureMessage: Decoder error when `sidecarStatus == .failed`
    public init(
        filePath: String,
        relativePath: String,
        action: InjectionAction,
        noindexed: Bool = false,
        errorMessage: String?,
        sidecarStatus: SidecarStatus = .missing,
        sidecarFailureMessage: String? = nil
    ) {
        self.filePath = filePath
        self.relativePath = relativePath
        self.action = action
        self.noindexed = noindexed
        self.errorMessage = errorMessage
        self.sidecarStatus = sidecarStatus
        self.sidecarFailureMessage = sidecarFailureMessage
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

    /// Count of files that were noindexed (not on allowlist)
    public var noindexedCount: Int {
        results.filter { $0.noindexed && $0.action == .injected }.count
    }

    /// Count of files that were indexed (on allowlist)
    public var indexedCount: Int {
        results.filter { !$0.noindexed && $0.action == .injected }.count
    }

    /// Whether all operations succeeded (no failures)
    public var isSuccess: Bool {
        failedCount == 0
    }

    // MARK: - DocC sidecar aggregate counts

    /// Count of files whose DocC sidecar was loaded successfully.
    public var sidecarLoadedCount: Int {
        results.filter { $0.sidecarStatus == .loaded }.count
    }

    /// Count of files where no DocC sidecar was found (top-level / landing
    /// pages). Treated as expected and **not** counted as a failure.
    public var sidecarMissingCount: Int {
        results.filter { $0.sidecarStatus == .missing }.count
    }

    /// Count of files whose DocC sidecar existed but failed to decode.
    public var sidecarFailedCount: Int {
        results.filter { $0.sidecarStatus == .failed }.count
    }

    /// Failure rate among pages that had a sidecar attempt resolve to
    /// either `.loaded` or `.failed` — i.e., excludes `.missing` (which is
    /// expected). Returns `0.0` when no sidecar was ever attempted.
    public var sidecarFailureRate: Double {
        let denominator = sidecarLoadedCount + sidecarFailedCount
        guard denominator > 0 else { return 0.0 }
        return Double(sidecarFailedCount) / Double(denominator)
    }

    /// Returns `true` when `sidecarFailureRate` strictly exceeds `threshold`.
    ///
    /// Used by the CLI's `--sidecar-failure-threshold` gate. A threshold of
    /// `0.05` means "fail the build if more than 5% of pages with sidecars
    /// failed to parse".
    ///
    /// - Parameter threshold: Acceptable failure rate as a fraction in `[0, 1]`.
    public func exceedsSidecarFailureThreshold(_ threshold: Double) -> Bool {
        sidecarFailureRate > threshold
    }

    /// Creates a new injection report.
    /// - Parameter results: All individual injection results
    public init(results: [InjectionResult]) {
        self.results = results
    }
}
