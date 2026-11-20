//
//  VitalsFormFactorResultTests.swift
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

/// `FormFactorResult` — the `{metrics, error}` outcome object each form
/// factor carries; exactly one of the two keys holds a value.
@Suite("Vitals — FormFactorResult")
struct VitalsFormFactorResultTests {

    @Test(".metrics encodes metrics with a null error")
    func metricsCase() throws {
        let object = try VitalsJSON.object(of: FormFactorResult.metrics(LabMetrics(lcpMs: 900)))

        let metrics = try #require(object["metrics"] as? [String: Any])
        #expect(metrics["lcpMs"] as? Double == 900)
        #expect(object["error"] is NSNull)
    }

    @Test(".failure encodes a null metrics with the reason")
    func failureCase() throws {
        let object = try VitalsJSON.object(of: FormFactorResult.failure("HTTP 429"))

        #expect(object["metrics"] is NSNull)
        #expect(object["error"] as? String == "HTTP 429")
    }

    @Test("decodes a metrics payload")
    func decodesMetrics() throws {
        let data = Data(#"{"metrics": {"lcpMs": 900}, "error": null}"#.utf8)
        let decoded = try VitalsJSON.decoder.decode(FormFactorResult.self, from: data)

        #expect(decoded == .metrics(LabMetrics(lcpMs: 900)))
    }

    @Test("decodes a failure payload")
    func decodesFailure() throws {
        let data = Data(#"{"metrics": null, "error": "report FAILED"}"#.utf8)
        let decoded = try VitalsJSON.decoder.decode(FormFactorResult.self, from: data)

        #expect(decoded == .failure("report FAILED"))
    }

    @Test("rejects a payload carrying both metrics and error")
    func rejectsBothPresent() throws {
        let data = Data(#"{"metrics": {"lcpMs": 900}, "error": "stale"}"#.utf8)

        #expect(throws: DecodingError.self) {
            _ = try VitalsJSON.decoder.decode(FormFactorResult.self, from: data)
        }
    }

    @Test("rejects a payload with neither metrics nor error")
    func rejectsEmptyPayload() throws {
        let data = Data(#"{"metrics": null, "error": null}"#.utf8)

        #expect(throws: DecodingError.self) {
            _ = try VitalsJSON.decoder.decode(FormFactorResult.self, from: data)
        }
    }

    @Test("accessors expose the carried value only")
    func accessors() {
        let measured = FormFactorResult.metrics(LabMetrics(lcpMs: 900))
        let failed = FormFactorResult.failure("boom")

        #expect(measured.metrics?.lcpMs == 900)
        #expect(measured.error == nil)
        #expect(failed.metrics == nil)
        #expect(failed.error == "boom")
    }

    @Test("round-trips both cases")
    func roundTrip() throws {
        for result in [FormFactorResult.metrics(LabMetrics(lcpMs: 900)), .failure("boom")] {
            let data = try VitalsJSON.encoder.encode(result)
            let decoded = try VitalsJSON.decoder.decode(FormFactorResult.self, from: data)
            #expect(decoded == result)
        }
    }
}
