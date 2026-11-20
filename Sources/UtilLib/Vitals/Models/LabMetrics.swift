//
//  LabMetrics.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

/// Lab (synthetic) metrics for one page load on one form factor.
///
/// The seven-field lab vocabulary shared by Cloudflare Observatory and
/// PageSpeed Insights. INP is absent by design — it requires real user
/// interaction, so it lives only in `CruxOriginResult.P75`; TBT is the lab
/// proxy. Every key is always present when encoded — `null` marks a
/// metric the run could not produce (absent is null, never zero).
public struct LabMetrics: Codable, Equatable, Sendable {
    /// Largest Contentful Paint, milliseconds.
    public let lcpMs: Double?
    /// Cumulative Layout Shift — unitless.
    public let cls: Double?
    /// Total Blocking Time — the lab proxy for INP.
    public let tbtMs: Double?
    /// First Contentful Paint, milliseconds.
    public let fcpMs: Double?
    /// Speed Index, milliseconds.
    public let speedIndexMs: Double?
    /// Time to First Byte as the lab run observed it, milliseconds.
    public let ttfbMs: Double?
    /// Lighthouse performance score, 0–100.
    public let performanceScore: Int?

    /// Creates a lab-metric set; any metric not provided encodes as `null`.
    public init(
        lcpMs: Double? = nil,
        cls: Double? = nil,
        tbtMs: Double? = nil,
        fcpMs: Double? = nil,
        speedIndexMs: Double? = nil,
        ttfbMs: Double? = nil,
        performanceScore: Int? = nil
    ) {
        self.lcpMs = lcpMs
        self.cls = cls
        self.tbtMs = tbtMs
        self.fcpMs = fcpMs
        self.speedIndexMs = speedIndexMs
        self.ttfbMs = ttfbMs
        self.performanceScore = performanceScore
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(lcpMs, forKey: .lcpMs)
        try container.encode(cls, forKey: .cls)
        try container.encode(tbtMs, forKey: .tbtMs)
        try container.encode(fcpMs, forKey: .fcpMs)
        try container.encode(speedIndexMs, forKey: .speedIndexMs)
        try container.encode(ttfbMs, forKey: .ttfbMs)
        try container.encode(performanceScore, forKey: .performanceScore)
    }
}
