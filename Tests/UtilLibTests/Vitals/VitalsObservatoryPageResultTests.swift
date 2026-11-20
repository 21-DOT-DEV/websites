//
//  VitalsObservatoryPageResultTests.swift
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

/// `ObservatoryPageResult` — adds test-level attribution (`testId`,
/// `region`, `error`) to the per-form-factor shape.
@Suite("Vitals — ObservatoryPageResult")
struct VitalsObservatoryPageResultTests {

    @Test("encodes null testId and error when unset")
    func explicitNulls() throws {
        let result = ObservatoryPageResult(
            url: "https://21.dev/",
            testId: nil,
            region: "us-west1",
            error: nil,
            mobile: .metrics(LabMetrics()),
            desktop: .metrics(LabMetrics())
        )
        let object = try VitalsJSON.object(of: result)

        #expect(object["testId"] is NSNull)
        #expect(object["error"] is NSNull)
        #expect(object["region"] as? String == "us-west1")
    }

    @Test("a refused trigger records testId null, page error, and failed form factors")
    func refusedTriggerShape() throws {
        let result = ObservatoryPageResult(
            url: "https://21.dev/blog/",
            testId: nil,
            region: "us-east1",
            error: "quota exhausted",
            mobile: .failure("quota exhausted"),
            desktop: .failure("quota exhausted")
        )
        let object = try VitalsJSON.object(of: result)

        #expect(object["testId"] is NSNull)
        #expect(object["error"] as? String == "quota exhausted")
        let data = try VitalsJSON.encoder.encode(result)
        let decoded = try VitalsJSON.decoder.decode(ObservatoryPageResult.self, from: data)
        #expect(decoded == result)
    }

    @Test("a never-completing poll keeps its testId and records the failure in error")
    func pollTimeoutShape() throws {
        // A refused trigger has no testId; a poll timeout does — the POST
        // succeeded, only the report never arrived. Per contract the id
        // is retained and the failure moves to the page-level error.
        let result = ObservatoryPageResult(
            url: "https://21.dev/",
            testId: "abc123",
            region: "us-west1",
            error: "poll timed out before report",
            mobile: .failure("no report"),
            desktop: .failure("no report")
        )
        let object = try VitalsJSON.object(of: result)

        #expect(object["testId"] as? String == "abc123")
        #expect(object["error"] as? String == "poll timed out before report")
    }

    @Test("round-trips a completed test")
    func roundTrip() throws {
        let result = ObservatoryPageResult(
            url: "https://21.dev/",
            testId: "abc123",
            region: "eu-west1",
            error: nil,
            mobile: .metrics(LabMetrics(lcpMs: 1840, performanceScore: 92)),
            desktop: .metrics(LabMetrics(lcpMs: 700, performanceScore: 99))
        )
        let data = try VitalsJSON.encoder.encode(result)
        let decoded = try VitalsJSON.decoder.decode(ObservatoryPageResult.self, from: data)

        #expect(decoded == result)
    }
}
