//
//  VitalsBaseline.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// The committed baseline artifact — `baseline.json` schema v1
/// (`Development/Specs/009-cwv-baseline/contracts/baseline-schema.md`).
/// Holds measured values, not budget thresholds.
public struct VitalsBaseline: Codable, Equatable, Sendable {
    /// Schema version — bumps only on a breaking change.
    public let schemaVersion: Int
    /// When the credentialed run produced the data; `null` while pending.
    public let generatedAt: Date?
    /// The artifact's overall state.
    public let status: Status
    /// The origins this baseline covers.
    public let origins: [String]
    /// Real-user (CrUX) and edge-observed results.
    public let fieldData: FieldData
    /// Observatory and PageSpeed lab results.
    public let lab: Lab
    /// The resolved URL list actually measured.
    public let pageSet: [String]
    /// Recorded gaps by stable id — findings, not failures.
    public let gaps: [String]
    /// Free-text findings.
    public let notes: [String]

    /// Whether every requested section has data or a recorded reason.
    public enum Status: String, Codable, Sendable {
        /// No credentialed run yet.
        case pending
        /// Some pages or sections errored.
        case partial
        /// Every section has data or a recorded unavailability reason.
        case complete
    }

    /// Field-data section — real-user and edge-observed results.
    public struct FieldData: Codable, Equatable, Sendable {
        /// One CrUX probe per origin.
        public let crux: [CruxOriginResult]
        /// One edge-TTFB result per host.
        public let edgeTtfb: [EdgeTtfbResult]

        /// Creates field data; empty until the run reports.
        public init(crux: [CruxOriginResult] = [], edgeTtfb: [EdgeTtfbResult] = []) {
            self.crux = crux
            self.edgeTtfb = edgeTtfb
        }
    }

    /// Lab section — both instruments, side by side per page.
    public struct Lab: Codable, Equatable, Sendable {
        /// One Observatory result per page.
        public let observatory: [ObservatoryPageResult]
        /// One PageSpeed Insights result per page.
        public let pagespeed: [PageLabResult]

        /// Creates a lab section; empty until the run reports.
        public init(observatory: [ObservatoryPageResult] = [], pagespeed: [PageLabResult] = []) {
            self.observatory = observatory
            self.pagespeed = pagespeed
        }
    }

    /// Creates a baseline; `schemaVersion` is fixed at 1. `status` is
    /// required so a populated artifact can't silently claim to be
    /// pending; `gaps` defaults to none — recorded gaps are supplied by
    /// the run that observed them, or by ``pending(origins:)``.
    /// `generatedAt` is normalized to whole seconds — the wire format
    /// carries no sub-second component, so the in-memory value equals
    /// what a round-trip through `baseline.json` produces.
    public init(
        generatedAt: Date? = nil,
        status: Status,
        origins: [String] = [],
        fieldData: FieldData = FieldData(),
        lab: Lab = Lab(),
        pageSet: [String] = [],
        gaps: [String] = [],
        notes: [String] = []
    ) {
        self.schemaVersion = 1
        self.generatedAt = generatedAt.map {
            Date(timeIntervalSince1970: $0.timeIntervalSince1970.rounded(.down))
        }
        self.status = status
        self.origins = origins
        self.fieldData = fieldData
        self.lab = lab
        self.pageSet = pageSet
        self.gaps = gaps
        self.notes = notes
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, generatedAt, status, origins, fieldData, lab, pageSet, gaps, notes
    }

    /// Decodes only schema v1 — any other `schemaVersion` is a different
    /// artifact shape and fails loudly rather than reading plausible-looking
    /// fields from a format this type can't represent. When a v2 schema is
    /// designed, it gets its own type and version dispatch happens at the
    /// reader boundary.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .schemaVersion)
        guard version == 1 else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unsupported baseline schema version \(version); this model reads v1."
            )
        }
        schemaVersion = version
        if let string = try container.decodeIfPresent(String.self, forKey: .generatedAt) {
            guard let date = ISO8601DateFormatter().date(from: string) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .generatedAt,
                    in: container,
                    debugDescription: "generatedAt must be an ISO8601 string, got '\(string)'"
                )
            }
            generatedAt = date
        } else {
            generatedAt = nil
        }
        status = try container.decode(Status.self, forKey: .status)
        origins = try container.decode([String].self, forKey: .origins)
        fieldData = try container.decode(FieldData.self, forKey: .fieldData)
        lab = try container.decode(Lab.self, forKey: .lab)
        pageSet = try container.decode([String].self, forKey: .pageSet)
        gaps = try container.decode([String].self, forKey: .gaps)
        notes = try container.decode([String].self, forKey: .notes)
    }

    /// A pending baseline for `--dry-run` and the committed placeholder —
    /// `.pending`, no measurements, the recorded gaps.
    public static func pending(origins: [String]) -> VitalsBaseline {
        VitalsBaseline(
            status: .pending,
            origins: origins,
            gaps: ["crux", "gsc-cwv", "inp-field"],
            notes: ["Pending first credentialed run — see Development/Specs/009-cwv-baseline/plan.md"]
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        if let generatedAt {
            try container.encode(ISO8601DateFormatter().string(from: generatedAt), forKey: .generatedAt)
        } else {
            try container.encodeNil(forKey: .generatedAt)
        }
        try container.encode(status, forKey: .status)
        try container.encode(origins, forKey: .origins)
        try container.encode(fieldData, forKey: .fieldData)
        try container.encode(lab, forKey: .lab)
        try container.encode(pageSet, forKey: .pageSet)
        try container.encode(gaps, forKey: .gaps)
        try container.encode(notes, forKey: .notes)
    }
}
