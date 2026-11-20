//
//  ObservatoryPageResult.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

/// Observatory result for one URL — mobile + desktop reports from a
/// single test, plus the test-level attribution the per-report shape
/// can't carry.
///
/// A refused trigger sets `testId` to `null` (a refused `POST` returns no
/// `result.id`); a test that starts but never completes keeps its `testId`
/// and records the poll failure in `error`. Either way `error` records
/// the reason and both form factors are `.failure`.
public struct ObservatoryPageResult: Codable, Equatable, Sendable {
    /// The URL the test targeted.
    public let url: String
    /// `null` when the trigger was refused.
    public let testId: String?
    /// The region the test ran (or was requested) in.
    public let region: String
    /// Test-level failure (trigger refused, poll never completed); `null`
    /// when the test itself reached a terminal state.
    public let error: String?
    /// The mobile-report outcome.
    public let mobile: FormFactorResult
    /// The desktop-report outcome.
    public let desktop: FormFactorResult

    /// Creates a result; a refused trigger passes `testId: nil`, the page-
    /// level `error`, and `.failure` for both form factors.
    public init(
        url: String,
        testId: String?,
        region: String,
        error: String?,
        mobile: FormFactorResult,
        desktop: FormFactorResult
    ) {
        self.url = url
        self.testId = testId
        self.region = region
        self.error = error
        self.mobile = mobile
        self.desktop = desktop
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(testId, forKey: .testId)
        try container.encode(region, forKey: .region)
        try container.encode(error, forKey: .error)
        try container.encode(mobile, forKey: .mobile)
        try container.encode(desktop, forKey: .desktop)
    }
}
