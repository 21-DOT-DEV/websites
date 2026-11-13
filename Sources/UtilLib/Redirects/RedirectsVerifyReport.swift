//
//  RedirectsVerifyReport.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// The verification outcome for a single `_redirects` rule.
public struct RedirectRuleVerification: Sendable, Equatable {
    /// The rule as declared in the file.
    public let rule: RedirectRule

    /// What verification found.
    public let outcome: Outcome

    public init(rule: RedirectRule, outcome: Outcome) {
        self.rule = rule
        self.outcome = outcome
    }

    /// The per-rule result classes (FR-005).
    public enum Outcome: Sendable, Equatable {
        /// The deployment's observed behavior matches the declaration.
        case passed

        /// The declaration and the observed behavior disagree, or the edge
        /// refuses the rule outright — blocks the deploy (exit non-zero).
        case failed(Failure)

        /// The rule could not be proven — reported with a reason, neither
        /// passed nor failed.
        case skipped(Skip)
    }

    /// Why a rule failed verification.
    public enum Failure: Sendable, Equatable {
        /// The edge refuses the rule outright — named, before any request
        /// fired. A declaration the platform ignores is broken configuration.
        case edgeRefused(RedirectEdgeRefusal)

        /// The observed status differs from the declared status.
        case statusMismatch(expected: Int, observed: Int)

        /// The observed `Location` differs from the declared target —
        /// compared verbatim, the edge echoes targets as written.
        case locationMismatch(expected: String, observed: String?)

        /// The request itself failed — unreachable host, timeout, or a
        /// non-HTTP response.
        case transportError(String)
    }

    /// Why a rule could not be verified — honest coverage, never a false pass.
    public enum Skip: Sendable, Equatable {
        /// No deployed output root was available — neither a real target to
        /// probe nor a `404.html` check to rule out SPA fallback.
        case noDeployedRoot

        /// No deployed file matched the rule's target, so no probe path could
        /// be derived.
        case noDerivableTarget

        /// The probed source path is itself a deployed asset — a `200` there
        /// would come from the file, not the rule, and proves nothing.
        case probeSourceIsDeployedAsset

        /// An earlier edge-applied rule governs the probe source, so the rule
        /// under test cannot be observed at that path.
        case probeSourceShadowed

        /// The constructed probe path does not match the rule's own source —
        /// defensive; impossible for sane probe tokens.
        case probeSourceUnmatchable

        /// The deployment has no top-level `404.html`, so Pages' SPA
        /// fallback can answer `200` for any unmatched path — a status-only
        /// `200` probe cannot distinguish the rule from the fallback. (Also
        /// a finding in itself: the site soft-404s missing URLs.)
        case spaFallbackUnprovable
    }
}

/// The aggregate result of verifying a site's `_redirects` against a deployment.
public struct RedirectsVerifyReport: Sendable {
    /// The deployment origin the rules were verified against.
    public let baseURL: URL

    /// The fixed token substituted for wildcards in verifier-chosen probe
    /// paths — conspicuous by design and surfaced in output.
    public let probeToken: String

    /// Per-rule results in `_redirects` file order.
    public let results: [RedirectRuleVerification]

    public init(baseURL: URL, probeToken: String, results: [RedirectRuleVerification]) {
        self.baseURL = baseURL
        self.probeToken = probeToken
        self.results = results
    }

    /// Rules whose observed behavior matched the declaration.
    public var passed: [RedirectRuleVerification] {
        results.filter { $0.outcome == .passed }
    }

    /// Rules that failed — edge-refused, mismatched, or unreachable.
    public var failed: [RedirectRuleVerification] {
        results.filter {
            if case .failed = $0.outcome { return true }
            return false
        }
    }

    /// Rules that could not be proven — skipped with reasons.
    public var skipped: [RedirectRuleVerification] {
        results.filter {
            if case .skipped = $0.outcome { return true }
            return false
        }
    }

    /// `true` when no rule failed *and* at least one rule was actually
    /// proven — an all-skipped report verifies nothing, matching
    /// `LinkCheckReport.isSuccess`'s nothing-checked guard.
    public var isSuccess: Bool {
        failed.isEmpty && !passed.isEmpty
    }
}

extension RedirectRuleVerification.Failure: CustomStringConvertible {
    /// A human-readable sentence naming the failure — printed per rule by
    /// `util redirects verify`.
    public var description: String {
        switch self {
        case .edgeRefused(let refusal):
            return "edge would not apply this rule: \(refusal)"
        case .statusMismatch(let expected, let observed):
            return "expected status \(expected), got \(observed)"
        case .locationMismatch(let expected, let observed):
            return "expected Location \"\(expected)\", got \(observed.map { "\"\($0)\"" } ?? "none")"
        case .transportError(let message):
            return "probe request failed: \(message)"
        }
    }
}

extension RedirectRuleVerification.Skip: CustomStringConvertible {
    /// A human-readable sentence naming why the rule could not be proven —
    /// printed per rule by `util redirects verify`.
    public var description: String {
        switch self {
        case .noDeployedRoot:
            return "no deployed output root — cannot derive a real target or rule out SPA fallback"
        case .noDerivableTarget:
            return "no deployed file matches the rule's target"
        case .probeSourceIsDeployedAsset:
            return "probe source is itself a deployed asset — a 200 there proves nothing"
        case .probeSourceShadowed:
            return "an earlier rule matches the probe source first"
        case .probeSourceUnmatchable:
            return "the constructed probe source does not match this rule"
        case .spaFallbackUnprovable:
            return "no top-level 404.html — SPA fallback could answer any 200"
        }
    }
}
