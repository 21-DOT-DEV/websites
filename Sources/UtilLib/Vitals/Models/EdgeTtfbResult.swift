//
//  EdgeTtfbResult.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

/// Edge-observed timing percentiles for one host (server-side field data).
public struct EdgeTtfbResult: Codable, Equatable, Sendable {
    /// The measured host.
    public let host: String
    /// The window actually queried — less than 28 when plan limits
    /// clamp it; `0` when the query was skipped.
    public let windowDays: Int
    /// Requests contributing to the quantiles; `null` when unreported.
    public let sampleCount: Int?
    /// Whether a usable measurement was recorded.
    public let status: Status
    /// Edge-observed TTFB, 50th percentile, milliseconds.
    public let p50Ms: Double?
    /// Edge-observed TTFB, 95th percentile, milliseconds.
    public let p95Ms: Double?
    /// Edge-observed TTFB, 99th percentile, milliseconds.
    public let p99Ms: Double?
    /// Origin-server TTFB, 50th percentile, milliseconds.
    public let originP50Ms: Double?
    /// Origin-server TTFB, 95th percentile, milliseconds.
    public let originP95Ms: Double?
    /// Origin-server TTFB, 99th percentile, milliseconds.
    public let originP99Ms: Double?
    /// The recorded finding (plan gate, token scope) or failure detail.
    public let detail: String?

    /// Whether a usable measurement was recorded.
    public enum Status: String, Codable, Sendable {
        /// A usable measurement was recorded.
        case available
        /// No usable measurement — plan gate, token scope, or a
        /// refused, empty, or malformed response.
        case unavailable
    }

    /// Creates an edge result; quantiles the plan or token didn't expose
    /// encode as `null`.
    public init(
        host: String,
        windowDays: Int = 28,
        sampleCount: Int? = nil,
        status: Status,
        p50Ms: Double? = nil,
        p95Ms: Double? = nil,
        p99Ms: Double? = nil,
        originP50Ms: Double? = nil,
        originP95Ms: Double? = nil,
        originP99Ms: Double? = nil,
        detail: String? = nil
    ) {
        self.host = host
        self.windowDays = windowDays
        self.sampleCount = sampleCount
        self.status = status
        self.p50Ms = p50Ms
        self.p95Ms = p95Ms
        self.p99Ms = p99Ms
        self.originP50Ms = originP50Ms
        self.originP95Ms = originP95Ms
        self.originP99Ms = originP99Ms
        self.detail = detail
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(host, forKey: .host)
        try container.encode(windowDays, forKey: .windowDays)
        try container.encode(sampleCount, forKey: .sampleCount)
        try container.encode(status, forKey: .status)
        try container.encode(p50Ms, forKey: .p50Ms)
        try container.encode(p95Ms, forKey: .p95Ms)
        try container.encode(p99Ms, forKey: .p99Ms)
        try container.encode(originP50Ms, forKey: .originP50Ms)
        try container.encode(originP95Ms, forKey: .originP95Ms)
        try container.encode(originP99Ms, forKey: .originP99Ms)
        try container.encode(detail, forKey: .detail)
    }
}
