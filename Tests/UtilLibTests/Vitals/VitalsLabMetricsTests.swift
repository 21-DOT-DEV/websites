//
//  VitalsLabMetricsTests.swift
//  UtilLibTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
import UtilLib

/// `LabMetrics` — the seven-field lab vocabulary; `null` marks a metric
/// the run could not produce, never zero.
@Suite("Vitals — LabMetrics")
struct VitalsLabMetricsTests {

    @Test("encodes exactly the seven contract keys when empty")
    func encodesAllKeysAsNull() throws {
        let object = try VitalsJSON.object(of: LabMetrics())

        #expect(Set(object.keys) == [
            "lcpMs", "cls", "tbtMs", "fcpMs",
            "speedIndexMs", "ttfbMs", "performanceScore",
        ])
        #expect(VitalsJSON.nullKeys(of: object).count == 7)
    }

    @Test("encodes provided values")
    func encodesValues() throws {
        let metrics = LabMetrics(
            lcpMs: 1840, cls: 0.02, tbtMs: 120, fcpMs: 910,
            speedIndexMs: 1450, ttfbMs: 380, performanceScore: 92
        )
        let object = try VitalsJSON.object(of: metrics)

        #expect(object["lcpMs"] as? Double == 1840)
        #expect(object["cls"] as? Double == 0.02)
        #expect(object["performanceScore"] as? Int == 92)
        #expect(VitalsJSON.nullKeys(of: object).isEmpty)
    }

    @Test("a partially populated metric still emits null keys")
    func partialMetricsEmitNulls() throws {
        let object = try VitalsJSON.object(of: LabMetrics(lcpMs: 1200))

        #expect(object["lcpMs"] as? Double == 1200)
        #expect(VitalsJSON.nullKeys(of: object) == [
            "cls", "tbtMs", "fcpMs", "speedIndexMs", "ttfbMs", "performanceScore",
        ])
    }

    @Test("decodes a sparse object tolerantly")
    func decodesSparseObject() throws {
        let data = Data(#"{"lcpMs": 1840}"#.utf8)
        let decoded = try VitalsJSON.decoder.decode(LabMetrics.self, from: data)

        #expect(decoded.lcpMs == 1840)
        #expect(decoded.cls == nil)
    }

    @Test("round-trips through encode/decode")
    func roundTrip() throws {
        let metrics = LabMetrics(lcpMs: 1840, cls: 0.02, performanceScore: 92)
        let data = try VitalsJSON.encoder.encode(metrics)
        let decoded = try VitalsJSON.decoder.decode(LabMetrics.self, from: data)

        #expect(decoded == metrics)
    }
}
