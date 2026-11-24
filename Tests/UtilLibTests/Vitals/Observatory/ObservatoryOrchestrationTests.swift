//
//  ObservatoryOrchestrationTests.swift
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

/// `ObservatoryService.fetchEdgeTtfb`'s two-shot orchestration (FR-004):
/// the settings probe → window resolution → data query flow, exercised
/// through a `URLProtocol` stub so no real network is touched. The suite
/// runs serialized because the stub's response queue is shared state.
@Suite("Vitals — ObservatoryService fetchEdgeTtfb", .serialized)
struct VitalsObservatoryOrchestrationTests {

    private let zone = "023e105f4ecef8ad9ca31a8372d0c353"
    private let token = "cf-token"

    @Test("a disabled dataset short-circuits before the data query")
    func settingsDisabledSkipsDataQuery() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(200, #"""
        {"data": {"viewer": {"zones": [{"settings": {"httpRequestsAdaptiveGroups":
          {"enabled": false, "availableFields": []}}}]}}}
        """#)
        let result = try await ObservatoryService.fetchEdgeTtfb(
            zoneID: zone, host: "21.dev", token: token, session: StubURLProtocol.session())
        #expect(result.status == .unavailable)
        #expect(result.detail?.contains("not enabled") == true)
        // Nothing was queried — `windowDays` records 0, not the request.
        #expect(result.windowDays == 0)
        #expect(StubURLProtocol.requestCount == 1)
    }

    @Test("a field list lacking the timing names still sends the data query")
    func reportedFieldsDoNotGate() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(200, #"""
        {"data": {"viewer": {"zones": [{"settings": {"httpRequestsAdaptiveGroups":
          {"enabled": true, "availableFields": ["sum_requests"]}}}]}}}
        """#)
        StubURLProtocol.enqueue(200, #"""
        {"data": {"viewer": {"zones": [{"httpRequestsAdaptiveGroups":
          [{"count": 10, "quantiles": {"edgeTimeToFirstByteMsP50": 100.0}}]}]}}}
        """#)
        let result = try await ObservatoryService.fetchEdgeTtfb(
            zoneID: zone, host: "21.dev", token: token, session: StubURLProtocol.session())
        // `availableFields` is diagnostic-only — the data query's own
        // verdict stands in for any inferred field absence.
        #expect(result.status == .available)
        #expect(StubURLProtocol.requestCount == 2)
    }

    @Test("a cancelled request aborts the run rather than recording a fabricated gap")
    func cancellationPropagates() async {
        // Cancellation on the probe and on the data query alike must
        // surface as `CancellationError` — a cancelled baseline run
        // shouldn't write an `unavailable` row for a host that was
        // never given the chance to answer.
        StubURLProtocol.reset()
        StubURLProtocol.enqueueFailure(URLError(.cancelled))
        await #expect(throws: CancellationError.self) {
            _ = try await ObservatoryService.fetchEdgeTtfb(
                zoneID: zone, host: "21.dev", token: token, session: StubURLProtocol.session())
        }

        StubURLProtocol.reset()
        StubURLProtocol.enqueue(200, #"""
        {"data": {"viewer": {"zones": [{"settings": {"httpRequestsAdaptiveGroups":
          {"enabled": true, "availableFields": []}}}]}}}
        """#)
        StubURLProtocol.enqueueFailure(URLError(.cancelled))
        await #expect(throws: CancellationError.self) {
            _ = try await ObservatoryService.fetchEdgeTtfb(
                zoneID: zone, host: "21.dev", token: token, session: StubURLProtocol.session())
        }
    }

    @Test("a failed settings probe still sends the data query at the requested window")
    func settingsFailureProceedsAtRequestedWindow() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(200, #"{"data": null, "errors": [{"message": "denied"}]}"#)
        StubURLProtocol.enqueue(200, #"""
        {"data": {"viewer": {"zones": [{"httpRequestsAdaptiveGroups": [{
          "count": 10, "quantiles": {"edgeTimeToFirstByteMsP50": 100.0}}]}]}}}
        """#)
        let reference = try #require(ISO8601DateFormatter().date(from: "2026-11-23T12:00:00Z"))
        let result = try await ObservatoryService.fetchEdgeTtfb(
            zoneID: zone, host: "21.dev", token: token,
            session: StubURLProtocol.session(), referenceDate: reference)
        #expect(result.status == .available)
        #expect(result.windowDays == 28)
        #expect(StubURLProtocol.requestCount == 2)
        // The probe failure is recorded, not silently swallowed.
        #expect(result.detail?.contains("settings probe") == true)
        let since = try #require(StubURLProtocol.lastVariable("since"))
        #expect((27...29).contains(Self.wholeDays(between: since, and: reference)))
    }

    @Test("a plan limit clamps the window the data query emits")
    func clampedWindowPropagatesToDataQuery() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(200, #"""
        {"data": {"viewer": {"zones": [{"settings": {"httpRequestsAdaptiveGroups":
          {"enabled": true, "availableFields":
            ["sum_requests", "avg_edgeTimeToFirstByteMs"],
           "maxDuration": 259200, "notOlderThan": 2592000}}}]}}}
        """#)
        StubURLProtocol.enqueue(200, #"{"data": {"viewer": {"zones": [{"httpRequestsAdaptiveGroups": []}]}}}"#)
        let reference = try #require(ISO8601DateFormatter().date(from: "2026-11-23T12:00:00Z"))
        let result = try await ObservatoryService.fetchEdgeTtfb(
            zoneID: zone, host: "21.dev", token: token,
            session: StubURLProtocol.session(), referenceDate: reference)
        #expect(result.windowDays == 3)
        #expect(StubURLProtocol.requestCount == 2)
        // Only the plan's timing fields ride the detail — appended
        // after the reason, non-timing names filtered out.
        let detail = try #require(result.detail)
        #expect(detail.hasSuffix("plan reports timing fields: avg_edgeTimeToFirstByteMs"))
        #expect(!detail.contains("sum_requests"))
        // Emitted `since` sits ~3 whole days back — a slack band so the
        // test holds regardless of how day-boundary alignment is fixed.
        let since = try #require(StubURLProtocol.lastVariable("since"))
        #expect((2...4).contains(Self.wholeDays(between: since, and: reference)))
    }

    @Test("a plan field list without timing fields records a bounded note, not the names")
    func fieldsNoteReportsNoneWhenNoTimingFields() async throws {
        StubURLProtocol.reset()
        StubURLProtocol.enqueue(200, #"""
        {"data": {"viewer": {"zones": [{"settings": {"httpRequestsAdaptiveGroups":
          {"enabled": true, "availableFields": ["sum_requests"]}}}]}}}
        """#)
        StubURLProtocol.enqueue(200, #"{"data": {"viewer": {"zones": [{"httpRequestsAdaptiveGroups": []}]}}}"#)
        let result = try await ObservatoryService.fetchEdgeTtfb(
            zoneID: zone, host: "21.dev", token: token,
            session: StubURLProtocol.session())
        let detail = try #require(result.detail)
        #expect(detail.hasSuffix("plan reports none of the queried timing fields"))
        #expect(!detail.contains("sum_requests"))
    }

    @Test("a sub-day requested window skips both calls and records unavailable")
    func subDayWindowSkipsBothQueries() async throws {
        for window in [0, -1] {
            StubURLProtocol.reset()
            let result = try await ObservatoryService.fetchEdgeTtfb(
                zoneID: zone, host: "21.dev", windowDays: window,
                token: token, session: StubURLProtocol.session())
            #expect(result.status == .unavailable)
            #expect(result.windowDays == 0)
            #expect(result.detail == "the requested window is below one day")
            #expect(StubURLProtocol.requestCount == 0)
        }
    }

    /// Whole UTC days between a `yyyy-MM-dd` string and a timestamp.
    static func wholeDays(between dateString: String, and date: Date) -> Int {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        guard let day = formatter.date(from: dateString) else { return -1 }
        return Int(date.timeIntervalSince(day) / 86_400)
    }
}

/// A FIFO `URLProtocol` — replies with the queued `(status, JSON)`
/// responses and records request bodies so tests can assert call
/// count and emitted GraphQL variables with no real network.
private final class StubURLProtocol: URLProtocol {
    // `nonisolated(unsafe)` is sound here only because the suite carries
    // `.serialized` — the queue, counter, and body log are shared mutable
    // state by design, and no test may run while a stub request is live.
    private enum Stub {
        case http(status: Int, body: Data)
        case failure(Error)
    }
    nonisolated(unsafe) private static var responses: [Stub] = []
    nonisolated(unsafe) private(set) static var requestCount = 0
    nonisolated(unsafe) private(set) static var bodies: [LoggedBody] = []

    static func reset() {
        responses = []; requestCount = 0; bodies = []
    }

    static func enqueue(_ status: Int, _ json: String) {
        responses.append(.http(status: status, body: Data(json.utf8)))
    }

    /// Queue a transport-level failure instead of an HTTP response.
    static func enqueueFailure(_ error: Error) {
        responses.append(.failure(error))
    }

    /// The named GraphQL variable from the most recent request body.
    static func lastVariable(_ name: String) -> String? {
        bodies.last?.variables?[name]
    }

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let next = Self.responses.isEmpty
            ? Stub.http(status: 500, body: Data(#"{"errors":[{"message":"unstubbed"}]}"#.utf8))
            : Self.responses.removeFirst()
        Self.requestCount += 1
        if let logged = try? JSONDecoder().decode(LoggedBody.self, from: requestBody(request)) {
            Self.bodies.append(logged)
        }
        switch next {
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        case .http(let status, let body):
            if let url = request.url,
               let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil) {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}

    /// The `{variables}` slice of an emitted request body, logged per
    /// call for `lastVariable` assertions.
    struct LoggedBody: Decodable {
        var variables: [String: String]?
    }

    /// `httpBody` can migrate to `httpBodyStream` inside URLSession —
    /// read whichever carries the payload.
    private func requestBody(_ request: URLRequest) -> Data {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return Data() }
        var data = Data()
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16_384)
        defer { buffer.deallocate() }
        stream.open()
        defer { stream.close() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: 16_384)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return data
    }
}
