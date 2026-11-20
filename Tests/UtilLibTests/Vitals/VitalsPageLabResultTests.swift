//
//  VitalsPageLabResultTests.swift
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

/// `PageLabResult` — a PageSpeed Insights page: `url` plus one
/// `{metrics, error}` object per form factor.
@Suite("Vitals — PageLabResult")
struct VitalsPageLabResultTests {

    @Test("encodes url and both form-factor objects")
    func encodesShape() throws {
        let result = PageLabResult(
            url: "https://21.dev/",
            mobile: .metrics(LabMetrics(lcpMs: 900)),
            desktop: .failure("HTTP 500")
        )
        let object = try VitalsJSON.object(of: result)

        #expect(Set(object.keys) == ["url", "mobile", "desktop"])
        #expect(object["url"] as? String == "https://21.dev/")
        let desktop = try #require(object["desktop"] as? [String: Any])
        #expect(desktop["metrics"] is NSNull)
        #expect(desktop["error"] as? String == "HTTP 500")
    }

    @Test("a missing form-factor object is a contract violation")
    func missingFormFactorThrows() throws {
        // The schema always shows mobile/desktop present — a payload
        // missing one is malformed, not an empty state.
        let data = Data(#"{"url": "https://21.dev/", "mobile": {"metrics": null, "error": "x"}}"#.utf8)

        #expect(throws: DecodingError.self) {
            _ = try VitalsJSON.decoder.decode(PageLabResult.self, from: data)
        }
    }

    @Test("round-trips a mixed outcome page")
    func roundTrip() throws {
        let result = PageLabResult(
            url: "https://docs.21.dev/",
            mobile: .failure("quota exhausted"),
            desktop: .metrics(LabMetrics(ttfbMs: 300))
        )
        let data = try VitalsJSON.encoder.encode(result)
        let decoded = try VitalsJSON.decoder.decode(PageLabResult.self, from: data)

        #expect(decoded == result)
    }
}
