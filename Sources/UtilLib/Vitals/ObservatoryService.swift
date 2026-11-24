//
//  ObservatoryService.swift
//  UtilLib
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

// MARK: - ObservatoryError

/// Errors from Cloudflare Observatory and edge-analytics calls.
public enum ObservatoryError: Error, Equatable, Sendable, LocalizedError {
    /// The page URL could not be encoded for the API path.
    case invalidURL(String)
    /// The API returned an error envelope or HTTP failure.
    case apiError(Int, String)
    /// A test-level operation failed end-to-end (e.g., the caller's poll
    /// loop timed out); per-report failures ride inside `ReportSnapshot`.
    case testFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url): return "Cannot build Observatory request for URL: \(url)"
        case .apiError(let code, let msg): return "Cloudflare API error \(code): \(msg)"
        case .testFailed(let msg): return "Observatory test failed: \(msg)"
        }
    }
}

// MARK: - ObservatoryAvailability

/// The zone's Observatory quota and allowed regions — what
/// `GET speed_api/availabilities` reports for the current plan (FR-001).
public struct ObservatoryAvailability: Sendable, Equatable {
    /// The Cloudflare plan name the zone sits on (`"free"`, `"pro"`, …).
    public var plan: String?
    /// One-off tests left this month; `nil` when the API doesn't report it.
    public var remainingTests: Int?
    /// Region `value`s the zone may test from (`"us-central1"`, …).
    public var regions: [String]

    /// Creates an availability snapshot; unreported quota or regions
    /// stay `nil`/empty rather than gating.
    public init(plan: String? = nil, remainingTests: Int? = nil, regions: [String] = []) {
        self.plan = plan
        self.remainingTests = remainingTests
        self.regions = regions
    }
}

// MARK: - ReportSnapshot

/// One form factor's Lighthouse report at poll time — the per-`*Report`
/// slice of a test result, carrying `state` plus exactly what the wire
/// reported so a failed report's `error{code,detail}` stays attributable
/// (the per-form-factor `{metrics, error}` contract).
public struct ReportSnapshot: Sendable, Equatable {
    /// The wire `state` — `RUNNING`/`COMPLETE`/`FAILED`, or `PENDING`
    /// when the report object is absent from the test result.
    public var state: String
    /// Measured metrics — populated only on `COMPLETE` (any field may
    /// still be absent). `nil` while running or on failure.
    public var metrics: LabMetrics?
    /// `"CODE: detail"` from the report's `error` object when present.
    public var error: String?

    /// `true` once the report can no longer change — `COMPLETE` or `FAILED`.
    public var isTerminal: Bool { state == "COMPLETE" || state == "FAILED" }

    /// Creates a report snapshot; `metrics` and `error` are mutually
    /// exclusive on the wire but independent here.
    public init(state: String, metrics: LabMetrics? = nil, error: String? = nil) {
        self.state = state
        self.metrics = metrics
        self.error = error
    }
}

// MARK: - ObservatoryTestResult

/// Parsed state of one Observatory test at poll time.
public struct ObservatoryTestResult: Sendable, Equatable {
    /// The test's API id.
    public var testId: String
    /// The region the API reports the test ran in (`result.region.value`);
    /// `nil` while unreported.
    public var region: String?
    /// The mobile report's snapshot.
    public var mobile: ReportSnapshot
    /// The desktop report's snapshot.
    public var desktop: ReportSnapshot

    /// `true` once *both* reports reached a terminal state — the contract's
    /// poll-until (`COMPLETE`/`FAILED` on each `*Report.state`).
    public var isComplete: Bool { mobile.isTerminal && desktop.isTerminal }

    /// Creates a poll result pairing both form-factor reports.
    public init(testId: String, region: String? = nil, mobile: ReportSnapshot, desktop: ReportSnapshot) {
        self.testId = testId
        self.region = region
        self.mobile = mobile
        self.desktop = desktop
    }
}

// MARK: - ObservatoryService

/// Cloudflare Observatory (synthetic Lighthouse) REST client — the
/// availabilities/start-test/poll surface (FR-001). The GraphQL
/// edge-timing surface (FR-004) lives in
/// `ObservatoryService+EdgeAnalytics.swift`.
/// Wire shapes pinned in `Development/Specs/009-cwv-baseline/contracts/api.md`.
public enum ObservatoryService {
    /// Cloudflare REST base.
    public static let apiBase = "https://api.cloudflare.com/client/v4"
    /// The region used when `--region` isn't passed — Iowa, the first
    /// region Cloudflare's own docs table lists and present on every
    /// plan, so it also holds when the availability check can't answer.
    /// A fixed vantage keeps baseline runs comparable (and matches PSI's
    /// typical North-America vantage for the side-by-side instruments).
    public static let defaultRegion = "us-central1"

    // MARK: Request builders

    /// `GET /zones/{zone}/speed_api/availabilities` — plan quota + regions.
    public static func buildAvailabilitiesRequest(zoneID: String, token: String) throws -> URLRequest {
        guard let zone = zoneID.addingPercentEncoding(withAllowedCharacters: unreserved) else {
            throw ObservatoryError.invalidURL(zoneID)
        }
        let path = "\(apiBase)/zones/\(zone)/speed_api/availabilities"
        guard let url = URL(string: path) else { throw ObservatoryError.invalidURL(path) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    /// `POST /zones/{zone}/speed_api/pages/{url}/tests` — trigger a test.
    /// The full page URL is percent-encoded into the path; `region` is
    /// always sent (the contract's pinned body shape).
    public static func buildStartTestRequest(
        zoneID: String, pageURL: String, region: String, token: String
    ) throws -> URLRequest {
        var request = URLRequest(url: try pageTestsURL(zoneID: zoneID, pageURL: pageURL))
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["region": region])
        return request
    }

    /// `GET /zones/{zone}/speed_api/pages/{url}/tests/{id}` — poll a test.
    public static func buildGetTestRequest(
        zoneID: String, pageURL: String, testID: String, token: String
    ) throws -> URLRequest {
        var request = URLRequest(url: try pageTestsURL(zoneID: zoneID, pageURL: pageURL, testID: testID))
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    // MARK: Response parsing

    /// Parse an availabilities envelope (FR-001's quota/region check).
    /// `regionsPerPlan[plan]` back-fills when `regions` is absent.
    public static func parseAvailabilities(data: Data, httpStatus: Int = 200) throws -> ObservatoryAvailability {
        let result = try restResult(in: data, status: httpStatus, as: AvailabilitiesResult.self)
        let plan = result.quota?.plan
        var regions = (result.regions ?? []).compactMap(\.value)
        if regions.isEmpty, let plan, let entries = result.regionsPerPlan?[plan] {
            regions = entries.compactMap(\.value)
        }
        return ObservatoryAvailability(
            plan: plan,
            remainingTests: int(result.quota?.remainingTests),
            regions: regions
        )
    }

    /// Extract the new test id from a `POST …/tests` envelope.
    public static func parseTestID(data: Data, httpStatus: Int = 200) throws -> String {
        let result = try restResult(in: data, status: httpStatus, as: TestIDResult.self)
        if let id = result.id ?? result.test?.id { return id }
        throw ObservatoryError.apiError(httpStatus, "no test id in response")
    }

    /// Parse a `GET tests/{id}` envelope into a poll snapshot.
    public static func parseTestResult(data: Data, httpStatus: Int = 200) throws -> ObservatoryTestResult {
        let result = try restResult(in: data, status: httpStatus, as: PollResult.self)
        guard let testId = result.id ?? result.testId else {
            throw ObservatoryError.apiError(httpStatus, "no test id in response")
        }
        return ObservatoryTestResult(
            testId: testId,
            region: result.region?.value,
            mobile: parseReport(result.mobileReport),
            desktop: parseReport(result.desktopReport)
        )
    }

    /// Map one `LighthouseReport` object to its snapshot. An `error`
    /// object with text wins over state; `error: null` and `error: {}`
    /// are *not* errors — treating them as one would drop valid metrics.
    /// Metrics are read only on `COMPLETE`; anything else is a
    /// state-only snapshot.
    private static func parseReport(_ report: PollResult.Report?) -> ReportSnapshot {
        guard let report else { return ReportSnapshot(state: "PENDING") }
        let state = report.state ?? "PENDING"
        // An error object counts only when it carries text — a decoded
        //-but-empty `error: {}` must not drop a COMPLETE report's
        // metrics.
        if let error = report.error,
           nonEmpty(error.code) != nil || nonEmpty(error.detail) != nil {
            let text = [error.code, error.detail].compactMap { nonEmpty($0) }
                .joined(separator: ": ")
            return ReportSnapshot(state: state, error: text)
        }
        guard state == "COMPLETE" else {
            return ReportSnapshot(state: state)
        }
        // The contract pins the score at 0–100 (the API's own example
        // shows `90`) — record it verbatim, rounded to an Int; inferring
        // a scale from the value would misread a real score of `1`.
        return ReportSnapshot(state: state, metrics: LabMetrics(
            lcpMs: report.lcp,
            cls: report.cls,
            tbtMs: report.tbt,
            fcpMs: report.fcp,
            speedIndexMs: report.si,
            ttfbMs: report.ttfb,
            performanceScore: report.performanceScore.flatMap { Int(exactly: $0.rounded()) }
        ))
    }

    // MARK: Async runners

    /// Fetch the zone's Observatory availability (quota + regions).
    public static func fetchAvailability(
        zoneID: String, token: String, session: URLSession = .shared
    ) async throws -> ObservatoryAvailability {
        let request = try buildAvailabilitiesRequest(zoneID: zoneID, token: token)
        let (data, response) = try await session.data(for: request)
        return try parseAvailabilities(data: data, httpStatus: (response as? HTTPURLResponse)?.statusCode ?? 0)
    }

    /// Trigger a test; returns the new test id.
    public static func startTest(
        zoneID: String, pageURL: String, region: String, token: String,
        session: URLSession = .shared
    ) async throws -> String {
        let request = try buildStartTestRequest(zoneID: zoneID, pageURL: pageURL, region: region, token: token)
        let (data, response) = try await session.data(for: request)
        return try parseTestID(data: data, httpStatus: (response as? HTTPURLResponse)?.statusCode ?? 0)
    }

    /// Poll a test once; the caller loops until `isComplete`.
    public static func fetchTest(
        zoneID: String, pageURL: String, testID: String, token: String,
        session: URLSession = .shared
    ) async throws -> ObservatoryTestResult {
        let request = try buildGetTestRequest(zoneID: zoneID, pageURL: pageURL, testID: testID, token: token)
        let (data, response) = try await session.data(for: request)
        return try parseTestResult(data: data, httpStatus: (response as? HTTPURLResponse)?.statusCode ?? 0)
    }

    // MARK: Internals

    /// The RFC 3986 unreserved set — explicit ASCII; `CharacterSet
    /// .alphanumerics` is Unicode-wide and would leave non-ASCII
    /// characters unencoded in the path.
    private static let unreserved = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

    /// `/zones/{zone}/speed_api/pages/{url}/tests[/{id}]` — the full page
    /// URL percent-encoded into the path (RFC 3986 unreserved set).
    private static func pageTestsURL(zoneID: String, pageURL: String, testID: String? = nil) throws -> URL {
        guard let zone = zoneID.addingPercentEncoding(withAllowedCharacters: unreserved) else {
            throw ObservatoryError.invalidURL(zoneID)
        }
        guard let encoded = pageURL.addingPercentEncoding(withAllowedCharacters: unreserved) else {
            throw ObservatoryError.invalidURL(pageURL)
        }
        var path = "\(apiBase)/zones/\(zone)/speed_api/pages/\(encoded)/tests"
        if let testID {
            guard let encodedID = testID.addingPercentEncoding(withAllowedCharacters: unreserved) else {
                throw ObservatoryError.invalidURL(testID)
            }
            path += "/\(encodedID)"
        }
        guard let url = URL(string: path) else { throw ObservatoryError.invalidURL(path) }
        return url
    }

    /// Safe `Double`→`Int` — floors, then `Int(exactly:)` so
    /// out-of-range values (e.g. `1e300`) return `nil` where
    /// `Int.init(Double)` would trap; the "never throws" parsers need
    /// the nil, not a crash. Floor (not exact-match) because the
    /// callers are limits and counts: a fractional `maxDuration`
    /// clamps tighter rather than dropping the clamp, and truncation
    /// preserves integer wire values as-is.
    /// Shared with `+EdgeAnalytics` (same module).
    static func int(_ value: Double?) -> Int? {
        value.flatMap { Int(exactly: $0.rounded(.down)) }
    }

    /// Nil-normalizing for wire strings — an empty JSON string means
    /// "nothing reported", not a message with no content.
    static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    /// The `result` object of a Cloudflare REST envelope — `success:
    /// false`, a missing result, or malformed JSON all throw the
    /// envelope's error text.
    private static func restResult<Payload: Decodable>(
        in data: Data, status: Int, as type: Payload.Type
    ) throws -> Payload {
        let envelope: RESTEnvelope<Payload>
        do {
            envelope = try JSONDecoder().decode(RESTEnvelope<Payload>.self, from: data)
        } catch {
            throw ObservatoryError.apiError(status, "malformed JSON")
        }
        guard envelope.success == true, let result = envelope.result else {
            throw ObservatoryError.apiError(status, envelope.errorMessage(status: status))
        }
        return result
    }
}

// MARK: - REST wire shapes

/// `{success, result, errors[]}` — the shared Cloudflare REST envelope,
/// generic over the endpoint's `result` payload.
private struct RESTEnvelope<Payload: Decodable>: Decodable {
    var success: Bool?
    var result: Payload?
    var errors: [RESTError]?

    /// The envelope's error text — `code: message` pairs joined, HTTP
    /// status as the fallback. A code-only entry still contributes its
    /// code rather than dropping to the generic fallback.
    func errorMessage(status: Int) -> String {
        let text = (errors ?? []).compactMap { error -> String? in
            let text = [error.code, error.message]
                .compactMap { ObservatoryService.nonEmpty($0) }.joined(separator: ": ")
            return text.isEmpty ? nil : text
        }.joined(separator: "; ")
        return text.isEmpty ? "HTTP \(status)" : text
    }
}

private struct RESTError: Decodable {
    /// Stringified wire `code` — ints are documented but strings
    /// tolerated so the error text survives either serialization.
    var code: String?
    var message: String?

    enum CodingKeys: String, CodingKey { case code, message }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let numeric = try? c.decodeIfPresent(Int.self, forKey: .code) {
            code = String(numeric)
        } else {
            code = try? c.decodeIfPresent(String.self, forKey: .code)
        }
        message = try? c.decodeIfPresent(String.self, forKey: .message)
    }
}

/// `availabilities` result — quota plus the regions the plan may test
/// from (with the per-plan table as back-fill).
private struct AvailabilitiesResult: Decodable {
    var quota: Quota?
    var regions: [Region]?
    var regionsPerPlan: [String: [Region]]?

    enum CodingKeys: String, CodingKey { case quota, regions, regionsPerPlan }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        quota = try? c.decodeIfPresent(Quota.self, forKey: .quota)
        regions = try? c.decodeIfPresent([Region].self, forKey: .regions)
        regionsPerPlan = try? c.decodeIfPresent([String: [Region]].self, forKey: .regionsPerPlan)
    }

    /// Per-field `try?` keeps a mistyped member from voiding the result
    /// (a bad region entry drops, not parses).
    struct Quota: Decodable {
        var plan: String?
        var remainingTests: Double?

        enum CodingKeys: String, CodingKey { case plan, remainingTests }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            plan = try? c.decodeIfPresent(String.self, forKey: .plan)
            remainingTests = try? c.decodeIfPresent(Double.self, forKey: .remainingTests)
        }
    }
    struct Region: Decodable {
        var value: String?
        enum CodingKeys: String, CodingKey { case value }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            value = try? c.decodeIfPresent(String.self, forKey: .value)
        }
    }
}

/// `POST …/tests` result — the new test id, top-level or nested.
private struct TestIDResult: Decodable {
    var id: String?
    var test: Nested?

    enum CodingKeys: String, CodingKey { case id, test }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try? c.decodeIfPresent(String.self, forKey: .id)
        test = try? c.decodeIfPresent(Nested.self, forKey: .test)
    }

    struct Nested: Decodable {
        var id: String?
        enum CodingKeys: String, CodingKey { case id }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try? c.decodeIfPresent(String.self, forKey: .id)
        }
    }
}

/// `GET tests/{id}` result — test id, region, and both form-factor
/// reports.
private struct PollResult: Decodable {
    var id: String?
    var testId: String?
    var region: Region?
    var mobileReport: Report?
    var desktopReport: Report?

    enum CodingKeys: String, CodingKey { case id, testId, region, mobileReport, desktopReport }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try? c.decodeIfPresent(String.self, forKey: .id)
        testId = try? c.decodeIfPresent(String.self, forKey: .testId)
        region = try? c.decodeIfPresent(Region.self, forKey: .region)
        mobileReport = try? c.decodeIfPresent(Report.self, forKey: .mobileReport)
        desktopReport = try? c.decodeIfPresent(Report.self, forKey: .desktopReport)
    }

    struct Region: Decodable {
        var value: String?
        enum CodingKeys: String, CodingKey { case value }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            value = try? c.decodeIfPresent(String.self, forKey: .value)
        }
    }

    /// The report's `error` object — `code`/`detail` joined for the
    /// attributable failure text; `code` tolerates an Int like
    /// `RESTError` does, and a mistyped member degrades to nil.
    struct ReportError: Decodable {
        var code: String?
        var detail: String?

        enum CodingKeys: String, CodingKey { case code, detail }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            if let numeric = try? c.decodeIfPresent(Int.self, forKey: .code) {
                code = String(numeric)
            } else {
                code = try? c.decodeIfPresent(String.self, forKey: .code)
            }
            detail = try? c.decodeIfPresent(String.self, forKey: .detail)
        }
    }

    /// One `*Report` object — per-field `try?` keeps a mistyped metric
    /// key from voiding the whole report.
    struct Report: Decodable {
        var state: String?
        var error: ReportError?
        var lcp, cls, tbt, fcp, si, ttfb, performanceScore: Double?

        enum CodingKeys: String, CodingKey {
            case state, error, lcp, cls, tbt, fcp, si, ttfb, performanceScore
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            state = try? c.decodeIfPresent(String.self, forKey: .state)
            error = try? c.decodeIfPresent(ReportError.self, forKey: .error)
            lcp = try? c.decodeIfPresent(Double.self, forKey: .lcp)
            cls = try? c.decodeIfPresent(Double.self, forKey: .cls)
            tbt = try? c.decodeIfPresent(Double.self, forKey: .tbt)
            fcp = try? c.decodeIfPresent(Double.self, forKey: .fcp)
            si = try? c.decodeIfPresent(Double.self, forKey: .si)
            ttfb = try? c.decodeIfPresent(Double.self, forKey: .ttfb)
            performanceScore = try? c.decodeIfPresent(Double.self, forKey: .performanceScore)
        }
    }
}
