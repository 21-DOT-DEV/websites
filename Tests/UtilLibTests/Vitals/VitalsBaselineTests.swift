//
//  VitalsBaselineTests.swift
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

/// `VitalsBaseline` — the committed artifact root; the pending state
/// encodes every key with `null` where data doesn't exist yet.
@Suite("Vitals — VitalsBaseline")
struct VitalsBaselineTests {

    /// The committed `baseline.json` in spec 009's folder.
    private var committedBaseline: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // file name
            .deletingLastPathComponent() // Vitals/
            .deletingLastPathComponent() // UtilLibTests/
            .deletingLastPathComponent() // Tests/
            .appendingPathComponent("Development/Specs/009-cwv-baseline/baseline.json")
    }

    @Test("pending factory produces the contract's pending state")
    func pendingFactory() {
        let baseline = VitalsBaseline.pending(origins: ["https://21.dev", "https://docs.21.dev"])

        #expect(baseline.schemaVersion == 1)
        #expect(baseline.status == .pending)
        #expect(baseline.generatedAt == nil)
        #expect(baseline.gaps == ["crux", "gsc-cwv", "inp-field"])
        #expect(baseline.fieldData.crux.isEmpty)
        #expect(baseline.lab.observatory.isEmpty)
    }

    @Test("pending state encodes generatedAt as an explicit null")
    func pendingEncodesNullGeneratedAt() throws {
        let object = try VitalsJSON.object(of: VitalsBaseline.pending(origins: []))

        #expect(object["generatedAt"] is NSNull)
        #expect(Set(object.keys) == [
            "schemaVersion", "generatedAt", "status", "origins",
            "fieldData", "lab", "pageSet", "gaps", "notes",
        ])
    }

    @Test("generatedAt encodes as the ISO8601 string the writer produces")
    func generatedAtWireFormat() throws {
        let date = Date(timeIntervalSince1970: 1_763_500_000)
        let object = try VitalsJSON.object(of: VitalsBaseline(generatedAt: date, status: .partial))

        #expect(object["generatedAt"] as? String == "2025-11-18T21:06:40Z")
    }

    @Test("generatedAt emits ISO8601 under a default, unconfigured encoder")
    func generatedAtOwnsItsWireFormat() throws {
        // The model formats the date itself — a caller's plain
        // JSONEncoder() (no dateEncodingStrategy) must still produce the
        // contract's ISO8601 string, not a seconds-since-2001 number.
        let date = Date(timeIntervalSince1970: 1_763_500_000)
        let data = try JSONEncoder().encode(VitalsBaseline(generatedAt: date, status: .partial))
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        #expect(object["generatedAt"] as? String == "2025-11-18T21:06:40Z")
    }

    @Test("generatedAt carries second precision — in memory and on the wire")
    func generatedAtSecondPrecision() throws {
        // Sub-second components are dropped at construction, so the
        // in-memory baseline equals what a round-trip produces.
        let baseline = VitalsBaseline(
            generatedAt: Date(timeIntervalSince1970: 1_763_500_000.5),
            status: .partial
        )
        #expect(baseline.generatedAt == Date(timeIntervalSince1970: 1_763_500_000))

        let data = try VitalsJSON.encoder.encode(baseline)
        let decoded = try VitalsJSON.decoder.decode(VitalsBaseline.self, from: data)
        #expect(decoded == baseline)
    }

    @Test("status encodes its wire value")
    func statusRawValues() throws {
        for (status, wire) in [
            (VitalsBaseline.Status.pending, "pending"),
            (.partial, "partial"),
            (.complete, "complete"),
        ] {
            let object = try VitalsJSON.object(of: VitalsBaseline(status: status))
            #expect(object["status"] as? String == wire)
        }
    }

    @Test("the committed baseline.json decodes and re-encodes losslessly")
    func committedBaselineRoundTrips() throws {
        let data = try Data(contentsOf: committedBaseline)
        let decoded = try VitalsJSON.decoder.decode(VitalsBaseline.self, from: data)

        // Structural invariants only — T018 replaces the pending
        // placeholder with the first live artifact, so this asserts what
        // survives that change: the version, and a lossless round-trip.
        // The pending shape itself is pinned by the factory tests above.
        #expect(decoded.schemaVersion == 1)

        let reencoded = try VitalsJSON.encoder.encode(decoded)
        let reparsed = try VitalsJSON.decoder.decode(VitalsBaseline.self, from: reencoded)
        #expect(reparsed == decoded)
    }

    @Test("round-trips a populated baseline")
    func roundTrip() throws {
        let baseline = VitalsBaseline(
            generatedAt: Date(timeIntervalSince1970: 1_763_500_000),
            status: .partial,
            origins: ["https://21.dev"],
            fieldData: VitalsBaseline.FieldData(
                crux: [CruxOriginResult(origin: "https://21.dev", status: .insufficient, detail: "no record")],
                edgeTtfb: [EdgeTtfbResult(host: "21.dev", status: .unavailable, detail: "plan-gated")]
            ),
            lab: VitalsBaseline.Lab(
                observatory: [],
                pagespeed: [PageLabResult(
                    url: "https://21.dev/",
                    mobile: .metrics(LabMetrics(lcpMs: 1840)),
                    desktop: .failure("HTTP 500")
                )]
            ),
            pageSet: ["https://21.dev/"],
            notes: ["edge TTFB plan-gated"]
        )
        let data = try VitalsJSON.encoder.encode(baseline)
        let decoded = try VitalsJSON.decoder.decode(VitalsBaseline.self, from: data)

        #expect(decoded == baseline)
    }

    @Test("an unparseable generatedAt is rejected, not silently dropped")
    func malformedGeneratedAtRejected() throws {
        // A timestamp that isn't ISO8601 is corruption, not "no run yet" —
        // decoding must fail rather than record generatedAt as null.
        let data = Data(#"{"schemaVersion": 1, "generatedAt": "last tuesday", "status": "pending", "origins": [], "fieldData": {"crux": [], "edgeTtfb": []}, "lab": {"observatory": [], "pagespeed": []}, "pageSet": [], "gaps": [], "notes": []}"#.utf8)
        #expect(throws: DecodingError.self) {
            _ = try VitalsJSON.decoder.decode(VitalsBaseline.self, from: data)
        }
    }

    @Test("a future schemaVersion is rejected, not silently read")
    func futureSchemaVersionRejected() throws {
        let data = Data(#"{"schemaVersion": 2, "generatedAt": null, "status": "pending", "origins": [], "fieldData": {"crux": [], "edgeTtfb": []}, "lab": {"observatory": [], "pagespeed": []}, "pageSet": [], "gaps": [], "notes": []}"#.utf8)
        #expect(throws: DecodingError.self) {
            _ = try VitalsJSON.decoder.decode(VitalsBaseline.self, from: data)
        }
    }
}
