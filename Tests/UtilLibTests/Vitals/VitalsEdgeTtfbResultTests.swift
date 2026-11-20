//
//  VitalsEdgeTtfbResultTests.swift
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

/// `EdgeTtfbResult` — edge-observed TTFB quantiles per host; `null`
/// marks quantiles the plan or token scope didn't expose.
@Suite("Vitals — EdgeTtfbResult")
struct VitalsEdgeTtfbResultTests {

    @Test("windowDays defaults to the 28-day contract window")
    func windowDaysDefault() {
        let result = EdgeTtfbResult(host: "21.dev", status: .available)

        #expect(result.windowDays == 28)
    }

    @Test("an unavailable host emits null quantiles with the reason in detail")
    func unavailableHost() throws {
        let result = EdgeTtfbResult(
            host: "docs.21.dev",
            sampleCount: nil,
            status: .unavailable,
            detail: "edgeTimeToFirstByteMs not exposed by plan"
        )
        let object = try VitalsJSON.object(of: result)

        #expect(object["status"] as? String == "unavailable")
        #expect(VitalsJSON.nullKeys(of: object) == [
            "sampleCount", "p50Ms", "p95Ms", "p99Ms",
            "originP50Ms", "originP95Ms", "originP99Ms",
        ])
        #expect(object["detail"] as? String == "edgeTimeToFirstByteMs not exposed by plan")
    }

    @Test("status encodes its wire value")
    func statusRawValues() throws {
        for (status, wire) in [
            (EdgeTtfbResult.Status.available, "available"),
            (.unavailable, "unavailable"),
        ] {
            let object = try VitalsJSON.object(of: EdgeTtfbResult(host: "21.dev", status: status))
            #expect(object["status"] as? String == wire)
        }
    }

    @Test("a plan-clamped window records the days actually used")
    func clampedWindow() throws {
        let result = EdgeTtfbResult(host: "21.dev", windowDays: 7, status: .available)
        let object = try VitalsJSON.object(of: result)

        #expect(object["windowDays"] as? Int == 7)
    }

    @Test("round-trips a populated result")
    func roundTrip() throws {
        let result = EdgeTtfbResult(
            host: "21.dev",
            windowDays: 28,
            sampleCount: 12_000,
            status: .available,
            p50Ms: 210, p95Ms: 480, p99Ms: 900,
            originP50Ms: 140, originP95Ms: 390, originP99Ms: 720,
            detail: nil
        )
        let data = try VitalsJSON.encoder.encode(result)
        let decoded = try VitalsJSON.decoder.decode(EdgeTtfbResult.self, from: data)

        #expect(decoded == result)
    }
}
