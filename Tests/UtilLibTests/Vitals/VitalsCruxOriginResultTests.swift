//
//  VitalsCruxOriginResultTests.swift
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

/// `CruxOriginResult` — one origin's field-data probe plus its nested
/// `P75` block, the only place INP exists in the schema.
@Suite("Vitals — CruxOriginResult")
struct VitalsCruxOriginResultTests {

    @Test("status encodes its wire value")
    func statusRawValues() throws {
        for (status, wire) in [
            (CruxOriginResult.Status.insufficient, "insufficient"),
            (.available, "available"),
            (.error, "error"),
        ] {
            let result = CruxOriginResult(origin: "https://21.dev", status: status)
            let object = try VitalsJSON.object(of: result)
            #expect(object["status"] as? String == wire)
        }
    }

    @Test("an insufficient probe emits null p75 with the finding in detail")
    func insufficientProbe() throws {
        let result = CruxOriginResult(
            origin: "https://21.dev",
            status: .insufficient,
            detail: "record not found — origin below CrUX eligibility"
        )
        let object = try VitalsJSON.object(of: result)

        #expect(object["p75"] is NSNull)
        #expect(object["detail"] as? String == "record not found — origin below CrUX eligibility")
    }

    @Test("P75 carries inpMs — the field-only metric absent from LabMetrics")
    func p75CarriesInp() throws {
        let p75 = CruxOriginResult.P75(lcpMs: 2100, inpMs: 180, cls: 0.05, fcpMs: 900, ttfbMs: 600)
        let object = try VitalsJSON.object(of: p75)

        #expect(Set(object.keys) == ["lcpMs", "inpMs", "cls", "fcpMs", "ttfbMs"])
        #expect(object["inpMs"] as? Double == 180)
    }

    @Test("P75 emits null keys for unreported metrics")
    func p75EmitsNulls() throws {
        let object = try VitalsJSON.object(of: CruxOriginResult.P75())

        #expect(VitalsJSON.nullKeys(of: object).count == 5)
    }

    @Test("decodes when optional keys are absent, not just null")
    func decodesAbsentOptionalKeys() throws {
        let data = Data(#"{"origin": "https://21.dev", "status": "insufficient"}"#.utf8)
        let decoded = try VitalsJSON.decoder.decode(CruxOriginResult.self, from: data)

        #expect(decoded.p75 == nil)
        #expect(decoded.detail == nil)
    }

    @Test("round-trips an available probe")
    func roundTrip() throws {
        let result = CruxOriginResult(
            origin: "https://docs.21.dev",
            status: .available,
            p75: CruxOriginResult.P75(lcpMs: 1500, inpMs: 120, cls: 0.01, fcpMs: 700, ttfbMs: 300),
            detail: "origin-level data"
        )
        let data = try VitalsJSON.encoder.encode(result)
        let decoded = try VitalsJSON.decoder.decode(CruxOriginResult.self, from: data)

        #expect(decoded == result)
    }
}
