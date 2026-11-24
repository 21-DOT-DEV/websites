//
//  ObservatoryParserTests.swift
//  UtilLibTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
import UtilLib

/// `ObservatoryService` REST response parsers — success, `FAILED`,
/// and error-envelope fixtures mapped without touching the network
/// (T008/T009).
@Suite("Vitals — ObservatoryService parsers")
struct VitalsObservatoryParserTests {

    // MARK: Availabilities parsing (FR-001)

    @Test("availabilities parses plan, remaining tests, and region values")
    func parsesAvailabilities() throws {
        let data = Data(#"""
        {"success": true, "result": {
          "quota": {"plan": "free", "remainingTests": 5, "remainingSchedules": 1},
          "regions": [{"label": "Iowa, USA", "value": "us-central1"},
                      {"label": "South Carolina, USA", "value": "us-east1"}]
        }, "errors": [], "messages": []}
        """#.utf8)
        let availability = try ObservatoryService.parseAvailabilities(data: data)
        #expect(availability.plan == "free")
        #expect(availability.remainingTests == 5)
        #expect(availability.regions == ["us-central1", "us-east1"])
    }

    @Test("availabilities falls back to regionsPerPlan[plan] when regions is absent")
    func parsesAvailabilitiesPerPlanFallback() throws {
        let data = Data(#"""
        {"success": true, "result": {
          "quota": {"plan": "pro", "remainingTests": 40},
          "regionsPerPlan": {"pro": [{"label": "Oregon, USA", "value": "us-west1"}],
                             "free": [{"label": "Iowa, USA", "value": "us-central1"}]}
        }, "errors": []}
        """#.utf8)
        let availability = try ObservatoryService.parseAvailabilities(data: data)
        #expect(availability.regions == ["us-west1"])
    }

    @Test("availabilities error envelope throws code-plus-message")
    func parsesAvailabilitiesError() throws {
        let data = Data(#"""
        {"success": false, "errors": [{"code": 9109, "message": "Invalid access token"}], "messages": []}
        """#.utf8)
        #expect(throws: ObservatoryError.self) {
            try ObservatoryService.parseAvailabilities(data: data, httpStatus: 403)
        }
        do {
            _ = try ObservatoryService.parseAvailabilities(data: data, httpStatus: 403)
            Issue.record("expected apiError")
        } catch ObservatoryError.apiError(_, let message) {
            #expect(message.contains("9109"))
            #expect(message.contains("Invalid access token"))
        } catch {
            Issue.record("expected apiError, got \(error)")
        }
    }

    // MARK: Test trigger + poll parsing

    @Test("start-test parses the new test id from result.id")
    func parsesTestID() throws {
        let data = Data(#"{"success": true, "result": {"id": "f174e90a-fafe-4643-bbbc-4a0ed4fc8415"}, "errors": []}"#.utf8)
        #expect(try ObservatoryService.parseTestID(data: data) == "f174e90a-fafe-4643-bbbc-4a0ed4fc8415")
    }

    @Test("a complete test yields both reports' metrics, the reported region, and isComplete")
    func parsesCompleteTestResult() throws {
        let data = Data(#"""
        {"success": true, "result": {
          "id": "t1",
          "region": {"label": "Iowa, USA", "value": "us-central1"},
          "mobileReport": {"state": "COMPLETE", "lcp": 1840.0, "cls": 0.02, "tbt": 120.0,
                           "fcp": 910.0, "si": 1450.0, "ttfb": 380.0, "performanceScore": 92},
          "desktopReport": {"state": "COMPLETE", "lcp": 700.0, "cls": 0.0, "tbt": 40.0,
                            "fcp": 400.0, "si": 800.0, "ttfb": 200.0, "performanceScore": 99}
        }, "errors": []}
        """#.utf8)
        let result = try ObservatoryService.parseTestResult(data: data)
        #expect(result.testId == "t1")
        #expect(result.region == "us-central1")
        #expect(result.isComplete)
        #expect(result.mobile.metrics?.lcpMs == 1840)
        #expect(result.mobile.metrics?.performanceScore == 92)
        #expect(result.desktop.metrics?.ttfbMs == 200)
        #expect(result.mobile.error == nil)
    }

    @Test("a still-running report keeps the test incomplete without inventing metrics or errors")
    func parsesRunningTestResult() throws {
        let data = Data(#"""
        {"success": true, "result": {
          "id": "t2",
          "mobileReport": {"state": "COMPLETE", "lcp": 1840.0, "performanceScore": 92},
          "desktopReport": {"state": "RUNNING"}
        }, "errors": []}
        """#.utf8)
        let result = try ObservatoryService.parseTestResult(data: data)
        #expect(!result.isComplete)
        #expect(result.desktop.state == "RUNNING")
        #expect(result.desktop.metrics == nil)
        #expect(result.desktop.error == nil)
        #expect(result.mobile.isTerminal)
    }

    @Test("a FAILED report records code-plus-detail per form factor, never dropping the failure")
    func parsesFailedReport() throws {
        let data = Data(#"""
        {"success": true, "result": {
          "id": "t3",
          "mobileReport": {"state": "FAILED",
                           "error": {"code": "NOT_REACHABLE", "detail": "Details: net::ERR_CONNECTION_CLOSED",
                                     "finalDisplayedUrl": "21.dev"}},
          "desktopReport": {"state": "COMPLETE", "lcp": 700.0, "performanceScore": 99}
        }, "errors": []}
        """#.utf8)
        let result = try ObservatoryService.parseTestResult(data: data)
        #expect(result.isComplete)   // both terminal — COMPLETE and FAILED
        #expect(result.mobile.state == "FAILED")
        #expect(result.mobile.metrics == nil)
        #expect(result.mobile.error == "NOT_REACHABLE: Details: net::ERR_CONNECTION_CLOSED")
        #expect(result.desktop.metrics?.performanceScore == 99)
    }

    @Test("an explicit 'error': null does not void a complete report's metrics")
    func parsesNullErrorAsAbsent() throws {
        // An explicit "error": null decodes as absent — a report
        // carrying it still holds valid metrics.
        let data = Data(#"""
        {"success": true, "result": {
          "id": "t4",
          "mobileReport": {"state": "COMPLETE", "error": null, "lcp": 900.0, "performanceScore": 88},
          "desktopReport": {"state": "COMPLETE", "error": null, "lcp": 600.0, "performanceScore": 95}
        }, "errors": []}
        """#.utf8)
        let result = try ObservatoryService.parseTestResult(data: data)
        #expect(result.mobile.metrics?.lcpMs == 900)
        #expect(result.mobile.error == nil)
    }

    @Test("a success:false poll envelope throws the envelope's error text")
    func parsesPollErrorEnvelope() throws {
        let data = Data(#"""
        {"success": false, "errors": [{"code": 7003, "message": "No route for that URI"}], "messages": []}
        """#.utf8)
        #expect(throws: ObservatoryError.self) {
            try ObservatoryService.parseTestResult(data: data, httpStatus: 404)
        }
    }

    @Test("a poll result without a test id throws rather than fabricating an empty one")
    func missingTestIdThrows() {
        let data = Data(#"{"success": true, "result": {}, "errors": []}"#.utf8)
        #expect(throws: ObservatoryError.self) {
            try ObservatoryService.parseTestResult(data: data)
        }
    }

    @Test("a performanceScore of 1 records 1 — not a normalized 100")
    func parsesScoreOfOneVerbatim() throws {
        // The wire scale is a pinned 0–100; a scale heuristic that maps
        // `1` → `100` silently inverts a catastrophic score.
        let data = Data(#"""
        {"success": true, "result": {
          "id": "t5",
          "mobileReport": {"state": "COMPLETE", "lcp": 9000.0, "performanceScore": 1},
          "desktopReport": {"state": "COMPLETE", "performanceScore": 0}
        }, "errors": []}
        """#.utf8)
        let result = try ObservatoryService.parseTestResult(data: data)
        #expect(result.mobile.metrics?.performanceScore == 1)
        #expect(result.desktop.metrics?.performanceScore == 0)
    }

    @Test("an empty error object records no error text rather than the report state")
    func parsesEmptyErrorObject() throws {
        let data = Data(#"""
        {"success": true, "result": {
          "id": "t6",
          "mobileReport": {"state": "FAILED", "error": {}}
        }, "errors": []}
        """#.utf8)
        let result = try ObservatoryService.parseTestResult(data: data)
        #expect(result.mobile.state == "FAILED")
        #expect(result.mobile.error == nil)
    }

    @Test("empty-string error fields mean 'nothing reported', not an error")
    func parsesEmptyStringErrorFields() throws {
        for errorJSON in [#""code": """#, #""detail": """#] {
            let data = Data("""
            {"success": true, "result": {"id": "t8",
              "mobileReport": {"state": "COMPLETE", "performanceScore": 90,
                "lcp": 900.0, "error": {\(errorJSON)}}}, "errors": []}
            """.utf8)
            let result = try ObservatoryService.parseTestResult(data: data)
            #expect(result.mobile.error == nil)
            #expect(result.mobile.metrics?.lcpMs == 900)
        }
        // A real code beside an empty detail joins without the stray ":".
        let data = Data(#"""
        {"success": true, "result": {"id": "t9",
          "mobileReport": {"state": "FAILED", "error": {"code": "1001", "detail": ""}}}, "errors": []}
        """#.utf8)
        #expect(try ObservatoryService.parseTestResult(data: data).mobile.error == "1001")
    }

    @Test("an empty error object on a COMPLETE report keeps its metrics")
    func parsesCompleteWithEmptyError() throws {
        let data = Data(#"""
        {"success": true, "result": {
          "id": "t8",
          "mobileReport": {"state": "COMPLETE", "error": {}, "lcp": 900.0, "performanceScore": 88}
        }, "errors": []}
        """#.utf8)
        let result = try ObservatoryService.parseTestResult(data: data)
        #expect(result.mobile.metrics?.lcpMs == 900)
        #expect(result.mobile.error == nil)
    }

    @Test("a numeric report error code joins into the recorded error text")
    func parsesNumericErrorCode() throws {
        let data = Data(#"""
        {"success": true, "result": {
          "id": "t9",
          "mobileReport": {"state": "FAILED", "error": {"code": 1001, "detail": "boom"}}
        }, "errors": []}
        """#.utf8)
        let result = try ObservatoryService.parseTestResult(data: data)
        #expect(result.mobile.error == "1001: boom")
    }

    @Test("a code-only REST error contributes its code to the thrown message")
    func parsesCodeOnlyErrorEnvelope() {
        let data = Data(#"{"success": false, "errors": [{"code": 9109}], "messages": []}"#.utf8)
        do {
            _ = try ObservatoryService.parseAvailabilities(data: data, httpStatus: 403)
            Issue.record("expected apiError")
        } catch ObservatoryError.apiError(_, let message) {
            #expect(message.contains("9109"))
        } catch {
            Issue.record("expected apiError, got \(error)")
        }
        // Empty-string fields mean "nothing reported" — the generic
        // HTTP-status fallback wins over a blank code: message join.
        let emptyFields = Data(#"{"success": false, "errors": [{"code": "", "message": ""}]}"#.utf8)
        do {
            _ = try ObservatoryService.parseAvailabilities(data: emptyFields, httpStatus: 403)
            Issue.record("expected apiError")
        } catch ObservatoryError.apiError(_, let message) {
            #expect(message.contains("HTTP 403"))
        } catch {
            Issue.record("expected apiError, got \(error)")
        }
    }

    @Test("out-of-range numbers degrade to nil rather than trapping the parsers")
    func oversizedNumbers() throws {
        // 1e300 is valid JSON; `Int.init(Double)` would trap on it —
        // the "never throws" parsers must degrade instead.
        let avail = Data(#"""
        {"success": true, "result": {"quota": {"plan": "pro", "remainingTests": 1e300}}}
        """#.utf8)
        let availability = try ObservatoryService.parseAvailabilities(data: avail)
        #expect(availability.plan == "pro")
        #expect(availability.remainingTests == nil)

        let settingsData = Data(#"""
        {"data": {"viewer": {"zones": [{"settings": {"httpRequestsAdaptiveGroups":
          {"enabled": true, "availableFields": [], "maxDuration": 1e300}}}]}}}
        """#.utf8)
        let settings = try ObservatoryService.parseDatasetSettings(data: settingsData)
        #expect(settings.maxDurationSeconds == nil)
        #expect(settings.resolvedWindowDays(requested: 28) == 28)

        let edge = Data(#"""
        {"data": {"viewer": {"zones": [{"httpRequestsAdaptiveGroups":
          [{"count": 1e300, "quantiles": {"edgeTimeToFirstByteMsP50": 20.0}}]}]}}}
        """#.utf8)
        let edgeResult = ObservatoryService.parseEdgeTtfb(data: edge, host: "21.dev", windowDays: 28)
        #expect(edgeResult.status == .available)
        #expect(edgeResult.sampleCount == nil)

        let poll = Data(#"""
        {"success": true, "result": {"id": "t7",
          "mobileReport": {"state": "COMPLETE", "performanceScore": 1e300}}, "errors": []}
        """#.utf8)
        #expect(try ObservatoryService.parseTestResult(data: poll)
            .mobile.metrics?.performanceScore == nil)
    }

    @Test("malformed JSON surfaces as ObservatoryError on every throwing parser")
    func malformedJSONThrowsObservatoryError() {
        let garbage = Data(#"{"truncated":"#.utf8)
        #expect(throws: ObservatoryError.self) {
            try ObservatoryService.parseAvailabilities(data: garbage)
        }
        #expect(throws: ObservatoryError.self) {
            try ObservatoryService.parseTestID(data: garbage)
        }
        #expect(throws: ObservatoryError.self) {
            try ObservatoryService.parseTestResult(data: garbage)
        }
        #expect(throws: ObservatoryError.self) {
            try ObservatoryService.parseDatasetSettings(data: garbage)
        }
    }
}
