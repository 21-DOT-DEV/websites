//
//  CruxOriginResult.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

/// CrUX probe result for one origin.
public struct CruxOriginResult: Codable, Equatable, Sendable {
    /// The probed origin, e.g. `https://21.dev`.
    public let origin: String
    /// The probe outcome.
    public let status: Status
    /// p75 field metrics when `status == .available`; `null` otherwise.
    public let p75: P75?
    /// The recorded finding or failure detail.
    public let detail: String?

    /// Outcome of a CrUX origin probe.
    public enum Status: String, Codable, Sendable {
        /// Origin not in the dataset — expected below the eligibility threshold.
        case insufficient
        /// Origin data was returned.
        case available
        /// The query itself failed.
        case error
    }

    /// Creates a probe result; `p75` is populated only on `.available`.
    public init(origin: String, status: Status, p75: P75? = nil, detail: String? = nil) {
        self.origin = origin
        self.status = status
        self.p75 = p75
        self.detail = detail
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(origin, forKey: .origin)
        try container.encode(status, forKey: .status)
        try container.encode(p75, forKey: .p75)
        try container.encode(detail, forKey: .detail)
    }
}

extension CruxOriginResult {
    /// The field-metric percentile block for one origin — the five
    /// metrics CrUX reports at p75, including INP, which has no lab
    /// equivalent in `LabMetrics`.
    public struct P75: Codable, Equatable, Sendable {
        /// Largest Contentful Paint at p75, milliseconds.
        public let lcpMs: Double?
        /// Interaction to Next Paint — field data only.
        public let inpMs: Double?
        /// Cumulative Layout Shift at p75 — unitless.
        public let cls: Double?
        /// First Contentful Paint at p75, milliseconds.
        public let fcpMs: Double?
        /// Time to First Byte at p75, milliseconds.
        public let ttfbMs: Double?

        /// Creates a p75 block; unreported metrics encode as `null`.
        public init(
            lcpMs: Double? = nil,
            inpMs: Double? = nil,
            cls: Double? = nil,
            fcpMs: Double? = nil,
            ttfbMs: Double? = nil
        ) {
            self.lcpMs = lcpMs
            self.inpMs = inpMs
            self.cls = cls
            self.fcpMs = fcpMs
            self.ttfbMs = ttfbMs
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(lcpMs, forKey: .lcpMs)
            try container.encode(inpMs, forKey: .inpMs)
            try container.encode(cls, forKey: .cls)
            try container.encode(fcpMs, forKey: .fcpMs)
            try container.encode(ttfbMs, forKey: .ttfbMs)
        }
    }
}
