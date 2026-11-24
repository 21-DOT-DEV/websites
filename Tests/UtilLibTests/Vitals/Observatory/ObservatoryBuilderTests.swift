//
//  ObservatoryBuilderTests.swift
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

/// `ObservatoryService` request builders — the wire shapes pinned in
/// `contracts/api.md`: methods, paths, percent-encoded page URLs,
/// auth headers, and the parameterized GraphQL bodies (T008/T009).
@Suite("Vitals — ObservatoryService builders")
struct VitalsObservatoryBuilderTests {

    private let zone = "023e105f4ecef8ad9ca31a8372d0c353"
    private let token = "cf-token"
    private let page = "https://21.dev/packages/"

    // MARK: REST

    @Test("availabilities GETs the zone's speed_api quota endpoint with Bearer auth")
    func buildsAvailabilitiesRequest() throws {
        let request = try ObservatoryService.buildAvailabilitiesRequest(zoneID: zone, token: token)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString ==
            "https://api.cloudflare.com/client/v4/zones/\(zone)/speed_api/availabilities")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(token)")
        #expect(request.httpBody == nil)
    }

    @Test("the availabilities path percent-encodes the zone id like the page paths")
    func encodesAvailabilitiesZoneID() throws {
        let request = try ObservatoryService.buildAvailabilitiesRequest(
            zoneID: "abc/def", token: token)
        #expect(request.url?.absoluteString.contains("abc%2Fdef") == true)
    }

    @Test("start-test POSTs the page URL percent-encoded into the path with a pinned region body")
    func buildsStartTestRequest() throws {
        let request = try ObservatoryService.buildStartTestRequest(
            zoneID: zone, pageURL: page, region: "us-east4", token: token)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString ==
            "https://api.cloudflare.com/client/v4/zones/\(zone)/speed_api/pages/https%3A%2F%2F21.dev%2Fpackages%2F/tests")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(token)")
        let body = try #require(request.httpBody)
        let json = try JSONDecoder().decode(EmittedBody.self, from: body)
        #expect(json.region == "us-east4")
    }

    @Test("poll GETs the encoded page URL plus the test id")
    func buildsGetTestRequest() throws {
        let request = try ObservatoryService.buildGetTestRequest(
            zoneID: zone, pageURL: page, testID: "abc-123", token: token)
        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString ==
            "https://api.cloudflare.com/client/v4/zones/\(zone)/speed_api/pages/https%3A%2F%2F21.dev%2Fpackages%2F/tests/abc-123")
    }

    // MARK: GraphQL

    @Test("settings request POSTs the parameterized query with the zone in variables")
    func buildsDatasetSettingsRequest() throws {
        let request = try ObservatoryService.buildDatasetSettingsRequest(zoneID: zone, token: token)
        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://api.cloudflare.com/client/v4/graphql")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(token)")
        let body = try #require(request.httpBody)
        let json = try JSONDecoder().decode(EmittedBody.self, from: body)
        let query = try #require(json.query)
        // Whitespace-normalized token equality with the contract text —
        // a dropped field or a renamed filter fails even when the
        // remaining substrings still appear.
        let pinned = """
            query($zone: string!) {
              viewer { zones(filter: {zoneTag: $zone}) {
                settings { httpRequestsAdaptiveGroups {
                  enabled availableFields maxDuration notOlderThan
                } }
              } }
            }
            """
        #expect(query.tokens == pinned.tokens)
        #expect(json.variables?["zone"] == zone)
    }

    @Test("edge-TTFB request emits the contract's query verbatim plus zone/since/host variables")
    func buildsEdgeTtfbRequest() throws {
        let reference = try #require(ISO8601DateFormatter().date(from: "2026-11-23T00:00:00Z"))
        let request = try ObservatoryService.buildEdgeTtfbRequest(
            zoneID: zone, host: "docs.21.dev", sinceDays: 28, token: token,
            referenceDate: reference)
        let body = try #require(request.httpBody)
        let json = try JSONDecoder().decode(EmittedBody.self, from: body)
        let query = try #require(json.query)
        let pinned = """
            query($zone: string!, $since: Date!, $host: string!) {
              viewer { zones(filter: {zoneTag: $zone}) {
                httpRequestsAdaptiveGroups(limit: 1, filter: {
                  date_geq: $since,
                  clientRequestHTTPHost_in: [$host],
                  edgeResponseContentTypeName: "html",
                  requestSource: "eyeball"
                }) {
                  count
                  quantiles {
                    edgeTimeToFirstByteMsP50 edgeTimeToFirstByteMsP95 edgeTimeToFirstByteMsP99
                    originResponseDurationMsP50 originResponseDurationMsP95 originResponseDurationMsP99
                  }
                }
              } }
            }
            """
        #expect(query.tokens == pinned.tokens)
        #expect(json.variables?["zone"] == zone)
        #expect(json.variables?["host"] == "docs.21.dev")
        // 28 date labels ending today: since = startOfDay(11-23) − 27d.
        #expect(json.variables?["since"] == "2026-10-27")
    }

    @Test("a non-midnight run keeps the query inside the day budget")
    func windowEndsTodayOnNonMidnightRuns() throws {
        // 15:00 UTC, 3-day budget: since = startOfDay − 2d → the real
        // [midnight…now] span is ~2.6 days, under a 3-day plan limit.
        let reference = try #require(ISO8601DateFormatter().date(from: "2026-11-23T15:00:00Z"))
        let request = try ObservatoryService.buildEdgeTtfbRequest(
            zoneID: zone, host: "21.dev", sinceDays: 3, token: token,
            referenceDate: reference)
        let body = try #require(request.httpBody)
        let json = try JSONDecoder().decode(EmittedBody.self, from: body)
        #expect(json.variables?["since"] == "2026-11-21")
    }

    @Test("degenerate since-days clamp to today instead of trapping")
    func degenerateSinceDaysClampToToday() throws {
        let reference = try #require(ISO8601DateFormatter().date(from: "2026-11-23T15:00:00Z"))
        for days in [0, -5, Int.min] {
            let request = try ObservatoryService.buildEdgeTtfbRequest(
                zoneID: zone, host: "21.dev", sinceDays: days, token: token,
                referenceDate: reference)
            let body = try #require(request.httpBody)
            let json = try JSONDecoder().decode(EmittedBody.self, from: body)
            #expect(json.variables?["since"] == "2026-11-23")
        }
    }

    @Test("non-ASCII characters in the page URL are percent-encoded into the path")
    func encodesNonASCIIPath() throws {
        // RFC 3986 unreserved is ASCII-only; a Unicode-wide allowed set
        // would leave é raw in the path.
        let request = try ObservatoryService.buildStartTestRequest(
            zoneID: zone, pageURL: "https://21.dev/café", region: "us-central1", token: token)
        let path = try #require(request.url?.absoluteString)
        #expect(path.contains("caf%C3%A9"))
        #expect(!path.contains("café"))
    }
}

/// The JSON body the request builders emit — decoded for field-level
/// assertions.
private struct EmittedBody: Decodable {
    var query: String?
    var variables: [String: String]?
    var region: String?
}

/// Whole-string whitespace collapse — two queries equal under `.tokens`
/// contain the same GraphQL tokens in the same order regardless of
/// line breaks or indentation.
private extension String {
    var tokens: String { split(whereSeparator: \.isWhitespace).joined() }
}
