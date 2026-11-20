//
//  FormFactorResult.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

/// The outcome of one lab measurement attempt on one form factor
/// (mobile or desktop).
///
/// Encodes as `{"metrics": …, "error": …}` — the two-key shape the
/// baseline schema pins per form factor so a failed call or report is
/// attributable rather than indistinguishable from absent data. Exactly
/// one case holds: measured values, or the recorded reason none exist.
/// Decoding rejects a payload carrying both or neither — the contract
/// permits exactly one.
public enum FormFactorResult: Codable, Equatable, Sendable {
    /// The instrument produced metrics.
    case metrics(LabMetrics)
    /// The call or report failed; the payload records why.
    case failure(String)

    /// The measured metrics, when this attempt succeeded.
    public var metrics: LabMetrics? {
        if case .metrics(let metrics) = self { metrics } else { nil }
    }

    /// The failure reason, when the attempt produced no metrics.
    public var error: String? {
        if case .failure(let error) = self { error } else { nil }
    }

    private enum CodingKeys: String, CodingKey {
        case metrics, error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch (
            try container.decodeIfPresent(LabMetrics.self, forKey: .metrics),
            try container.decodeIfPresent(String.self, forKey: .error)
        ) {
        case (.some(let metrics), .none):
            self = .metrics(metrics)
        case (.none, .some(let error)):
            self = .failure(error)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "FormFactorResult requires exactly one of 'metrics' or 'error'"
                )
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .metrics(let metrics):
            try container.encode(metrics, forKey: .metrics)
            try container.encodeNil(forKey: .error)
        case .failure(let error):
            try container.encodeNil(forKey: .metrics)
            try container.encode(error, forKey: .error)
        }
    }
}
