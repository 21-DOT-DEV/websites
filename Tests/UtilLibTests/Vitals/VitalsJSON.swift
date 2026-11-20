//
//  VitalsJSON.swift
//  UtilLibTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing

/// JSON-shape helpers for the vitals contract: every declared key is
/// always present and `null` marks an absent value.
enum VitalsJSON {
    /// Encoder matching the writer's wire config (ISO8601 dates).
    static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    /// Decoder matching the writer's wire config (ISO8601 dates).
    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Encodes `value` and parses the result back to a JSON object for
    /// key-shape assertions.
    static func object<T: Encodable>(of value: T) throws -> [String: Any] {
        let data = try encoder.encode(value)
        let parsed = try JSONSerialization.jsonObject(with: data)
        return try #require(parsed as? [String: Any])
    }

    /// The keys of `object` holding explicit `null` values.
    static func nullKeys(of object: [String: Any]) -> Set<String> {
        Set(object.filter { $0.value is NSNull }.map(\.key))
    }
}
