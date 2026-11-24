//
//  ObservatoryEdgeParserTests.swift
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

/// `ObservatoryService` GraphQL parsers and `DatasetSettings` window
/// logic — settings probes, plan-gated and edge-quantile fixtures
/// mapped without touching the network (T009).
@Suite("Vitals — ObservatoryService edge parsers")
struct VitalsObservatoryEdgeParserTests {

    // MARK: Dataset settings (FR-004 clamp inputs)

    @Test("settings parses enabled, availableFields, and the plan's window limits")
    func parsesDatasetSettings() throws {
        let data = Data(#"""
        {"data": {"viewer": {"zones": [{"settings": {"httpRequestsAdaptiveGroups": {
          "enabled": true,
          "availableFields": [
            "quantiles_edgeTimeToFirstByteMsP50", "quantiles_edgeTimeToFirstByteMsP95",
            "quantiles_edgeTimeToFirstByteMsP99",
            "quantiles_originResponseDurationMsP50", "quantiles_originResponseDurationMsP95",
            "quantiles_originResponseDurationMsP99"
          ],
          "maxDuration": 259200, "maxPageSize": 10000, "notOlderThan": 2678400
        }}}]}}}
        """#.utf8)
        let settings = try ObservatoryService.parseDatasetSettings(data: data)
        #expect(settings.enabled == true)
        #expect(settings.maxDurationSeconds == 259200)
        #expect(settings.notOlderThanSeconds == 2678400)
        #expect(settings.planWindowDays == 3)
        #expect(settings.availableFields.count == 6)
    }

    @Test("a fractional plan limit floors to the tighter clamp, never drops it")
    func parsesSettingsFractionalLimit() throws {
        let data = Data(#"""
        {"data": {"viewer": {"zones": [{"settings": {"httpRequestsAdaptiveGroups": {
          "enabled": true,
          "availableFields": [
            "quantiles_edgeTimeToFirstByteMsP50", "quantiles_edgeTimeToFirstByteMsP95",
            "quantiles_edgeTimeToFirstByteMsP99",
            "quantiles_originResponseDurationMsP50", "quantiles_originResponseDurationMsP95",
            "quantiles_originResponseDurationMsP99"
          ],
          "maxDuration": 259200.9, "notOlderThan": 2678400.5
        }}}]}}}
        """#.utf8)
        let settings = try ObservatoryService.parseDatasetSettings(data: data)
        #expect(settings.maxDurationSeconds == 259200)
        #expect(settings.notOlderThanSeconds == 2678400)
        #expect(settings.planWindowDays == 3)
    }

    @Test("settings throws the GraphQL error message on an errors envelope")
    func parsesDatasetSettingsError() throws {
        let data = Data(#"""
        {"data": null, "errors": [{"message": "request not allowed for this zone"}]}
        """#.utf8)
        #expect(throws: ObservatoryError.self) {
            try ObservatoryService.parseDatasetSettings(data: data)
        }
    }

    @Test("settings throws when the adaptive-groups node is absent")
    func parsesDatasetSettingsAbsent() throws {
        let data = Data(#"{"data": {"viewer": {"zones": [{"settings": {}}]}}}"#.utf8)
        #expect(throws: ObservatoryError.self) {
            try ObservatoryService.parseDatasetSettings(data: data)
        }
    }

    @Test("the window clamps to the tighter of maxDuration and notOlderThan")
    func clampsWindowToLimits() {
        let settings = DatasetSettings(
            enabled: true, availableFields: [],
            maxDurationSeconds: 2_678_400, notOlderThanSeconds: 1_209_600)
        #expect(settings.planWindowDays == 14)
        #expect(settings.resolvedWindowDays(requested: 28) == 14)
        #expect(settings.resolvedWindowDays(requested: 7) == 7)
    }

    @Test("only a disabled dataset or sub-day plan resolves to no query")
    func resolvesUnavailable() {
        #expect(DatasetSettings(enabled: false).resolvedWindowDays(requested: 28) == nil)
        #expect(DatasetSettings(enabled: true, availableFields: [], maxDurationSeconds: 43_200)
            .resolvedWindowDays(requested: 28) == nil)
        // A reported field list never gates — even one visibly lacking
        // the timing names — so the data query answers for itself.
        #expect(DatasetSettings(enabled: true, availableFields: ["sum_requests"])
            .resolvedWindowDays(requested: 28) == 28)
        #expect(DatasetSettings(
            enabled: true,
            availableFields: ["avg_edgeTimeToFirstByteMs", "avg_originResponseDurationMs"])
            .resolvedWindowDays(requested: 28) == 28)
        // Unreported flag/fields can't disprove availability — proceed.
        #expect(DatasetSettings(enabled: nil, availableFields: [])
            .resolvedWindowDays(requested: 28) == 28)
        // A non-positive requested window can't produce a query.
        #expect(DatasetSettings(enabled: true).resolvedWindowDays(requested: 0) == nil)
        #expect(DatasetSettings(enabled: true).resolvedWindowDays(requested: -5) == nil)
        #expect(DatasetSettings(enabled: true).resolvedWindowDays(requested: .min) == nil)
        #expect(DatasetSettings(enabled: true)
            .unavailabilityReason(requested: 0)?.contains("requested window") == true)
    }

    // MARK: Edge-TTFB parsing (FR-004)

    @Test("edge TTFB maps the quantiles group into an available result")
    func parsesEdgeTtfb() {
        let data = Data(#"""
        {"data": {"viewer": {"zones": [{"httpRequestsAdaptiveGroups": [{
          "count": 12480,
          "quantiles": {
            "edgeTimeToFirstByteMsP50": 120.5, "edgeTimeToFirstByteMsP95": 380.0, "edgeTimeToFirstByteMsP99": 910.0,
            "originResponseDurationMsP50": 40.0, "originResponseDurationMsP95": 160.0, "originResponseDurationMsP99": 500.0
          }}]}]}}}
        """#.utf8)
        let result = ObservatoryService.parseEdgeTtfb(data: data, host: "21.dev", windowDays: 28)
        #expect(result.status == .available)
        #expect(result.sampleCount == 12480)
        #expect(result.p50Ms == 120.5)
        #expect(result.p99Ms == 910)
        #expect(result.originP95Ms == 160)
        #expect(result.windowDays == 28)
    }

    @Test("a uint64 count keeps full precision past 2^53")
    func parsesEdgeTtfbLargeCount() {
        // `count` is `uint64` on the wire — a `Double` decode would
        // round 9007199254740993 to ...992 and `Int(exactly:)` then
        // reports nil.
        let data = Data(#"""
        {"data": {"viewer": {"zones": [{"httpRequestsAdaptiveGroups": [{
          "count": 9007199254740993,
          "quantiles": {"edgeTimeToFirstByteMsP50": 120.5}}]}]}}}
        """#.utf8)
        let result = ObservatoryService.parseEdgeTtfb(data: data, host: "21.dev", windowDays: 28)
        #expect(result.status == .available)
        #expect(result.sampleCount == 9_007_199_254_740_993)
    }

    @Test("plan-gated GraphQL errors record unavailable with the error text")
    func parsesEdgeTtfbPlanGated() {
        let data = Data(#"""
        {"data": null, "errors": [{"message": "field 'edgeTimeToFirstByteMsP50' is not available for this plan"}]}
        """#.utf8)
        let result = ObservatoryService.parseEdgeTtfb(data: data, host: "21.dev", windowDays: 28)
        #expect(result.status == .unavailable)
        #expect(result.detail?.contains("not available") == true)
        #expect(result.p50Ms == nil)
        // An errors array carrying only blank messages falls back to
        // the explicit "no message" wording rather than empty detail.
        let blank = Data(#"{"data": null, "errors": [{"message": ""}]}"#.utf8)
        let blankResult = ObservatoryService.parseEdgeTtfb(data: blank, host: "21.dev", windowDays: 28)
        #expect(blankResult.status == .unavailable)
        #expect(blankResult.detail?.contains("no message") == true)
    }

    @Test("malformed and empty responses record unavailable, never a hard failure")
    func parsesEdgeTtfbFailures() {
        let malformed = ObservatoryService.parseEdgeTtfb(
            data: Data("not json".utf8), host: "21.dev", windowDays: 28)
        #expect(malformed.status == .unavailable)
        #expect(malformed.detail == "malformed JSON")

        let noData = Data(#"{"data": {"viewer": {"zones": [{"httpRequestsAdaptiveGroups": []}]}}}"#.utf8)
        let empty = ObservatoryService.parseEdgeTtfb(data: noData, host: "21.dev", windowDays: 28)
        #expect(empty.status == .unavailable)
    }

    @Test("empty quantiles or a zero-sample group records unavailable, not an empty available")
    func parsesEdgeTtfbNoUsableData() {
        let nilQuantiles = Data(#"""
        {"data": {"viewer": {"zones": [{"httpRequestsAdaptiveGroups":
          [{"count": 300, "quantiles": {}}]}]}}}
        """#.utf8)
        let nilResult = ObservatoryService.parseEdgeTtfb(data: nilQuantiles, host: "21.dev", windowDays: 28)
        #expect(nilResult.status == .unavailable)
        #expect(nilResult.detail?.contains("no usable timing data") == true)

        let zeroCount = Data(#"""
        {"data": {"viewer": {"zones": [{"httpRequestsAdaptiveGroups":
          [{"count": 0, "quantiles": {"edgeTimeToFirstByteMsP50": 20.1}}]}]}}}
        """#.utf8)
        #expect(ObservatoryService.parseEdgeTtfb(
            data: zeroCount, host: "21.dev", windowDays: 28).status == .unavailable)
    }

    @Test("origin-only quantiles are not an edge-TTFB measurement")
    func parsesEdgeTtfbOriginOnly() {
        let data = Data(#"""
        {"data": {"viewer": {"zones": [{"httpRequestsAdaptiveGroups":
          [{"count": 40, "quantiles": {"originResponseDurationMsP50": 12.0}}]}]}}}
        """#.utf8)
        let result = ObservatoryService.parseEdgeTtfb(data: data, host: "21.dev", windowDays: 28)
        #expect(result.status == .unavailable)
        #expect(result.originP50Ms == nil)
    }

    @Test("a non-2xx HTTP status prefixes the recorded detail")
    func parsesEdgeTtfbHTTPStatus() {
        let malformed = ObservatoryService.parseEdgeTtfb(
            data: Data("bad gateway".utf8), host: "21.dev", windowDays: 28, httpStatus: 502)
        #expect(malformed.detail?.hasPrefix("HTTP 502:") == true)
        let gated = ObservatoryService.parseEdgeTtfb(
            data: Data(#"{"errors": [{"message": "denied"}]}"#.utf8),
            host: "21.dev", windowDays: 28, httpStatus: 403)
        #expect(gated.detail == "HTTP 403: denied")
    }
}
