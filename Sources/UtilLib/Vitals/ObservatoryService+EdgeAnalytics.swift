//
//  ObservatoryService+EdgeAnalytics.swift
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

// MARK: - DatasetSettings

/// The GraphQL `settings` node for `httpRequestsAdaptiveGroups` — the
/// dataset's per-plan limits plus its reported field list, as the
/// requesting token/plan sees them (FR-004's clamp inputs).
public struct DatasetSettings: Sendable, Equatable {
    /// Whether the dataset is enabled; `nil` when the node didn't report
    /// one — only an explicit `false` gates, so an unreported flag can't
    /// remove a measurement.
    public var enabled: Bool?
    /// Field paths the plan/token reports (`"quantiles_…"`-style
    /// names) — kept for diagnostics; it never gates a query.
    public var availableFields: [String]
    /// `maxDuration` — the widest query window the plan allows, seconds.
    public var maxDurationSeconds: Int?
    /// `notOlderThan` — the furthest lookback the plan allows, seconds.
    public var notOlderThanSeconds: Int?

    /// Creates a settings snapshot; every property is optional so an
    /// unreported value can't fabricate a gate or a limit.
    public init(
        enabled: Bool? = nil,
        availableFields: [String] = [],
        maxDurationSeconds: Int? = nil,
        notOlderThanSeconds: Int? = nil
    ) {
        self.enabled = enabled
        self.availableFields = availableFields
        self.maxDurationSeconds = maxDurationSeconds
        self.notOlderThanSeconds = notOlderThanSeconds
    }

    /// The plan's maximum query window in whole days — the smaller of
    /// `maxDuration` and `notOlderThan`; unreported limits don't constrain.
    public var planWindowDays: Int {
        let limits = [maxDurationSeconds, notOlderThanSeconds].compactMap { $0 }
        return (limits.min() ?? .max) / 86_400
    }

    /// The window to actually query — `requested` clamped to the plan's
    /// limits — or `nil` when the query can't succeed (dataset disabled,
    /// a sub-day request, or a sub-day plan window below `date_geq`'s
    /// whole-day granularity). `availableFields` deliberately does not gate: a
    /// reported field list is unverified spelling, while a refused data
    /// query answers with Cloudflare's own error. Quantiles can't merge
    /// across window chunks, so clamping — not splitting — is the only
    /// correct move.
    public func resolvedWindowDays(requested: Int) -> Int? {
        guard enabled != false, requested >= 1, planWindowDays >= 1 else { return nil }
        return min(requested, planWindowDays)
    }

    /// The recorded reason when a request asks for a sub-day window —
    /// shared by `unavailabilityReason` and `fetchEdgeTtfb`'s entry
    /// guard so both verdicts read identically.
    fileprivate static let subDayWindowReason = "the requested window is below one day"

    /// The `unavailable` detail when `resolvedWindowDays` returns `nil`.
    public func unavailabilityReason(requested: Int) -> String? {
        if enabled == false { return "httpRequestsAdaptiveGroups is not enabled for this plan/token" }
        if requested < 1 { return Self.subDayWindowReason }
        if planWindowDays < 1 { return "the plan's allowed query window is below one day" }
        return nil
    }
}

// MARK: - ObservatoryService + EdgeAnalytics

extension ObservatoryService {
    /// Cloudflare GraphQL endpoint.
    public static let graphqlEndpoint = "https://api.cloudflare.com/client/v4/graphql"

    // MARK: Request builders

    /// GraphQL `settings` probe for `httpRequestsAdaptiveGroups` — the
    /// per-plan `enabled`/`maxDuration`/`notOlderThan` limits FR-004
    /// clamps against (`availableFields` rides along for diagnostics
    /// only). Values ride in `variables`, never the query text.
    public static func buildDatasetSettingsRequest(zoneID: String, token: String) throws -> URLRequest {
        try buildGraphQLRequest(
            query: datasetSettingsQuery,
            variables: ["zone": zoneID],
            token: token
        )
    }

    /// GraphQL `httpRequestsAdaptiveGroups` edge-TTFB quantiles query —
    /// the contract's parameterized text verbatim; `since` is a `Date`
    /// scalar (`YYYY-MM-DD`, UTC) aligned so the query stays inside a
    /// `sinceDays`-long window ending at `referenceDate`.
    public static func buildEdgeTtfbRequest(
        zoneID: String, host: String, sinceDays: Int, token: String,
        referenceDate: Date = Date()
    ) throws -> URLRequest {
        // `date_geq` starts at the UTC midnight of `since` and runs to
        // "now", so the real span is the day count plus today's elapsed
        // fraction — `startOfDay − (days − 1)` keeps the query inside a
        // `sinceDays` budget (plan limits are second-accurate) while
        // still covering `sinceDays` whole date labels ending today.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let startOfToday = calendar.startOfDay(for: referenceDate)
        let daysBack = sinceDays > 1 ? sinceDays - 1 : 0
        let sinceDay = startOfToday.addingTimeInterval(-Double(daysBack) * 86_400)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return try buildGraphQLRequest(
            query: edgeTtfbQuery,
            variables: ["zone": zoneID, "since": formatter.string(from: sinceDay), "host": host],
            token: token
        )
    }

    // MARK: Response parsing

    /// Parse a `settings`-node response; throws the GraphQL error text on
    /// an `errors` envelope or an absent node.
    public static func parseDatasetSettings(data: Data, httpStatus: Int = 200) throws -> DatasetSettings {
        let envelope = try graphqlEnvelope(
            ZonesViewer<SettingsZone>.self, in: data, status: httpStatus)
        if let errors = envelope.errors, !errors.isEmpty {
            throw ObservatoryError.apiError(
                httpStatus,
                errors.compactMap(\.message).first(where: { !$0.isEmpty })
                    ?? "GraphQL errors present (no message)")
        }
        guard let group = envelope.data?.viewer?.zones?.first?.settings?.httpRequestsAdaptiveGroups else {
            throw ObservatoryError.apiError(httpStatus, "no httpRequestsAdaptiveGroups settings in response")
        }
        return DatasetSettings(
            enabled: group.enabled,
            availableFields: group.availableFields ?? [],
            maxDurationSeconds: int(group.maxDuration),
            notOlderThanSeconds: int(group.notOlderThan)
        )
    }

    /// Parse the edge-TTFB response into the recorded result. Never
    /// throws — `errors`, plan-gated fields, empty groups, and malformed
    /// payloads all land as `unavailable` + detail (FR-004). A non-2xx
    /// `httpStatus` prefixes the recorded detail so a 429-with-HTML
    /// doesn't masquerade as a plain parse failure.
    public static func parseEdgeTtfb(
        data: Data, host: String, windowDays: Int, httpStatus: Int = 200
    ) -> EdgeTtfbResult {
        // JSON decode and `errors` check stay separate here — an errors
        // envelope carries the plan-gate reason the result must record,
        // so it can't ride the throwing `graphqlEnvelope` path.
        let statusNote = (200...299).contains(httpStatus) ? "" : "HTTP \(httpStatus): "
        let envelope: GraphQLEnvelope<ZonesViewer<EdgeTtfbZone>>
        do {
            envelope = try JSONDecoder().decode(
                GraphQLEnvelope<ZonesViewer<EdgeTtfbZone>>.self, from: data)
        } catch {
            return EdgeTtfbResult(host: host, windowDays: windowDays, status: .unavailable, detail: "\(statusNote)malformed JSON")
        }
        if let errors = envelope.errors, !errors.isEmpty {
            let message = errors.compactMap(\.message).first(where: { !$0.isEmpty })
                ?? "GraphQL errors present (no message)"
            return EdgeTtfbResult(host: host, windowDays: windowDays, status: .unavailable, detail: "\(statusNote)\(message)")
        }
        guard let group = envelope.data?.viewer?.zones?.first?.httpRequestsAdaptiveGroups?.first else {
            return EdgeTtfbResult(host: host, windowDays: windowDays, status: .unavailable, detail: "\(statusNote)no data")
        }
        let count = group.count
        let q = group.quantiles
        let quantiles: [Double?] = [
            q?.edgeTimeToFirstByteMsP50, q?.edgeTimeToFirstByteMsP95, q?.edgeTimeToFirstByteMsP99,
            q?.originResponseDurationMsP50, q?.originResponseDurationMsP95, q?.originResponseDurationMsP99,
        ]
        // A group with zero samples or no edge-TTFB quantile measured
        // nothing this result exists to record — `.available` requires
        // at least one `edgeTimeToFirstByteMs*` value, not merely any
        // quantile (origin-only data isn't an edge-TTFB measurement).
        guard count ?? 1 > 0, quantiles.prefix(3).contains(where: { $0 != nil }) else {
            return EdgeTtfbResult(
                host: host, windowDays: windowDays, sampleCount: count,
                status: .unavailable, detail: "\(statusNote)no usable timing data"
            )
        }
        return EdgeTtfbResult(
            host: host,
            windowDays: windowDays,
            sampleCount: count,
            status: .available,
            p50Ms: quantiles[0],
            p95Ms: quantiles[1],
            p99Ms: quantiles[2],
            originP50Ms: quantiles[3],
            originP95Ms: quantiles[4],
            originP99Ms: quantiles[5]
        )
    }

    // MARK: Async runners

    /// Fetch the dataset's settings node for this zone.
    public static func fetchDatasetSettings(
        zoneID: String, token: String, session: URLSession = .shared
    ) async throws -> DatasetSettings {
        let request = try buildDatasetSettingsRequest(zoneID: zoneID, token: token)
        let (data, response) = try await session.data(for: request)
        return try parseDatasetSettings(
            data: data, httpStatus: (response as? HTTPURLResponse)?.statusCode ?? 0)
    }

    /// The two-shot edge query (FR-004): read the dataset's `settings`
    /// node, clamp the window to the plan's `maxDuration`/`notOlderThan`,
    /// then run the quantiles query. Disabled datasets and sub-day
    /// windows — requested or plan-allowed — skip the query and record
    /// `unavailable`, as do refused, empty, or malformed responses. A
    /// settings call that can't answer proceeds at the requested window
    /// rather than removing the measurement, with the probe failure
    /// recorded in the result's `detail`.
    ///
    /// `referenceDate` overrides "now" for the data query's `since`
    /// alignment (tests); when nil it's taken at query-build time —
    /// after the settings probe — so probe latency can't smuggle the
    /// window past an exact whole-day plan limit across UTC midnight.
    ///
    /// - Throws: `CancellationError` when the task is cancelled or a
    ///   request is aborted; every other failure is recorded, not thrown.
    public static func fetchEdgeTtfb(
        zoneID: String, host: String, windowDays: Int = 28, token: String,
        session: URLSession = .shared, referenceDate: Date? = nil
    ) async throws -> EdgeTtfbResult {
        guard windowDays >= 1 else {
            return EdgeTtfbResult(
                host: host, windowDays: 0, status: .unavailable,
                detail: DatasetSettings.subDayWindowReason
            )
        }
        var days = windowDays
        var probeDetail: String?
        var reportedFields: [String] = []
        do {
            let settings = try await fetchDatasetSettings(zoneID: zoneID, token: token, session: session)
            reportedFields = settings.availableFields
            guard let resolved = settings.resolvedWindowDays(requested: windowDays) else {
                return EdgeTtfbResult(
                    host: host, windowDays: 0, status: .unavailable,
                    detail: settings.unavailabilityReason(requested: windowDays)
                        ?? "dataset limits not met"
                )
            }
            days = resolved
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            probeDetail = "settings probe failed: \(error.localizedDescription)"
        }
        try Task.checkCancellation()
        // `availableFields` never gates; on a refused/empty query the
        // note carries only the plan's timing fields — the names this
        // query actually needs — appended after the reason.
        let timingFields = reportedFields.filter {
            $0.contains("edgeTimeToFirstByteMs") || $0.contains("originResponseDurationMs")
        }
        let fieldsNote: String? = reportedFields.isEmpty
            ? nil
            : timingFields.isEmpty
                ? "plan reports none of the queried timing fields"
                : "plan reports timing fields: \(timingFields.joined(separator: ", "))"
        do {
            let request = try buildEdgeTtfbRequest(
                zoneID: zoneID, host: host, sinceDays: days, token: token,
                referenceDate: referenceDate ?? Date()
            )
            let (data, response) = try await session.data(for: request)
            let parsed = parseEdgeTtfb(
                data: data, host: host, windowDays: days,
                httpStatus: (response as? HTTPURLResponse)?.statusCode ?? 0
            ).recordingProbe(probeDetail)
            return parsed.status == .unavailable ? parsed.appendingNote(fieldsNote) : parsed
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch {
            let detail = [probeDetail, error.localizedDescription, fieldsNote]
                .compactMap { $0 }.joined(separator: "; ")
            return EdgeTtfbResult(host: host, windowDays: days, status: .unavailable, detail: detail)
        }
    }

    // MARK: Internals

    /// POST `{query, variables}` to the GraphQL endpoint.
    private static func buildGraphQLRequest(
        query: String, variables: [String: String], token: String
    ) throws -> URLRequest {
        guard let url = URL(string: graphqlEndpoint) else {
            throw ObservatoryError.invalidURL(graphqlEndpoint)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            GraphQLRequestBody(query: query, variables: variables))
        return request
    }

    /// Decode a GraphQL envelope — any decode failure surfaces as
    /// `apiError(status, "malformed JSON")` rather than a raw
    /// `DecodingError`.
    private static func graphqlEnvelope<Payload: Decodable>(
        _ type: Payload.Type, in data: Data, status: Int
    ) throws -> GraphQLEnvelope<Payload> {
        do {
            return try JSONDecoder().decode(GraphQLEnvelope<Payload>.self, from: data)
        } catch {
            throw ObservatoryError.apiError(status, "malformed JSON")
        }
    }

    /// The contract's parameterized edge-TTFB query — emitted verbatim.
    static let edgeTtfbQuery = """
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
            } }
          }
        }
        """

    /// The `settings`-node probe — the dataset's per-plan limits and
    /// exposed fields as the requesting token sees them.
    static let datasetSettingsQuery = """
        query($zone: string!) {
          viewer { zones(filter: {zoneTag: $zone}) {
            settings { httpRequestsAdaptiveGroups {
              enabled availableFields maxDuration notOlderThan
            } }
          } }
        }
        """
}

// MARK: - GraphQL wire shapes

/// `{query, variables}` — the POST body both GraphQL calls share.
private struct GraphQLRequestBody: Encodable {
    var query: String
    var variables: [String: String]
}

/// `{data, errors[]}` — the shared GraphQL envelope, generic over the
/// `data` payload the specific query asks for.
private struct GraphQLEnvelope<Payload: Decodable>: Decodable {
    var data: Payload?
    var errors: [Entry]?

    /// An `errors[]` entry — `try?` keeps a non-string message from
    /// voiding the envelope's other errors.
    struct Entry: Decodable {
        var message: String?
        enum CodingKeys: String, CodingKey { case message }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            message = try? c.decodeIfPresent(String.self, forKey: .message)
        }
    }
}

/// `{"viewer":{"zones":[Zone]}}` — generic over the zone payload the
/// specific query asks for.
private struct ZonesViewer<Zone: Decodable>: Decodable {
    var viewer: Holder?

    struct Holder: Decodable { var zones: [Zone]? }
}

/// Zone payload for the `settings` probe.
private struct SettingsZone: Decodable {
    var settings: Wrap?

    struct Wrap: Decodable { var httpRequestsAdaptiveGroups: Group? }

    /// Per-field `try?` keeps a mistyped member from voiding the group
    /// (e.g. a string `enabled` reads nil, and an unreported flag can't
    /// gate).
    struct Group: Decodable {
        var enabled: Bool?
        var availableFields: [String]?
        var maxDuration: Double?
        var notOlderThan: Double?

        enum CodingKeys: String, CodingKey {
            case enabled, availableFields, maxDuration, notOlderThan
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            enabled = try? c.decodeIfPresent(Bool.self, forKey: .enabled)
            availableFields = try? c.decodeIfPresent([String].self, forKey: .availableFields)
            maxDuration = try? c.decodeIfPresent(Double.self, forKey: .maxDuration)
            notOlderThan = try? c.decodeIfPresent(Double.self, forKey: .notOlderThan)
        }
    }
}

/// Zone payload for the edge-TTFB quantiles query.
private struct EdgeTtfbZone: Decodable {
    var httpRequestsAdaptiveGroups: [Group]?

    /// Per-field `try?` keeps a mistyped member from voiding the group.
    struct Group: Decodable {
        var count: Int?
        var quantiles: Quantiles?

        enum CodingKeys: String, CodingKey { case count, quantiles }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            // `count` is `uint64` on the wire — decode `Int` first so
            // counts past 2^53 keep full precision, falling back to the
            // range-checked `Double` path for float-serialized values.
            count = (try? c.decodeIfPresent(Int.self, forKey: .count))
                ?? ObservatoryService.int(try? c.decodeIfPresent(Double.self, forKey: .count))
            quantiles = try? c.decodeIfPresent(Quantiles.self, forKey: .quantiles)
        }
    }

    struct Quantiles: Decodable {
        var edgeTimeToFirstByteMsP50, edgeTimeToFirstByteMsP95, edgeTimeToFirstByteMsP99: Double?
        var originResponseDurationMsP50, originResponseDurationMsP95, originResponseDurationMsP99: Double?

        enum CodingKeys: String, CodingKey {
            case edgeTimeToFirstByteMsP50, edgeTimeToFirstByteMsP95, edgeTimeToFirstByteMsP99
            case originResponseDurationMsP50, originResponseDurationMsP95, originResponseDurationMsP99
        }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            edgeTimeToFirstByteMsP50 = try? c.decodeIfPresent(Double.self, forKey: .edgeTimeToFirstByteMsP50)
            edgeTimeToFirstByteMsP95 = try? c.decodeIfPresent(Double.self, forKey: .edgeTimeToFirstByteMsP95)
            edgeTimeToFirstByteMsP99 = try? c.decodeIfPresent(Double.self, forKey: .edgeTimeToFirstByteMsP99)
            originResponseDurationMsP50 = try? c.decodeIfPresent(Double.self, forKey: .originResponseDurationMsP50)
            originResponseDurationMsP95 = try? c.decodeIfPresent(Double.self, forKey: .originResponseDurationMsP95)
            originResponseDurationMsP99 = try? c.decodeIfPresent(Double.self, forKey: .originResponseDurationMsP99)
        }
    }
}

private extension EdgeTtfbResult {
    /// A copy with the settings-probe note merged ahead of `detail` —
    /// `EdgeTtfbResult`'s fields are `let`, so the merge rebuilds.
    func recordingProbe(_ note: String?) -> EdgeTtfbResult {
        guard let note else { return self }
        return EdgeTtfbResult(
            host: host, windowDays: windowDays, sampleCount: sampleCount, status: status,
            p50Ms: p50Ms, p95Ms: p95Ms, p99Ms: p99Ms,
            originP50Ms: originP50Ms, originP95Ms: originP95Ms, originP99Ms: originP99Ms,
            detail: [note, detail].compactMap { $0 }.joined(separator: "; ")
        )
    }

    /// A copy with `note` appended after any existing `detail` —
    /// supporting evidence follows the primary reason.
    func appendingNote(_ note: String?) -> EdgeTtfbResult {
        guard let note else { return self }
        return EdgeTtfbResult(
            host: host, windowDays: windowDays, sampleCount: sampleCount, status: status,
            p50Ms: p50Ms, p95Ms: p95Ms, p99Ms: p99Ms,
            originP50Ms: originP50Ms, originP95Ms: originP95Ms, originP99Ms: originP99Ms,
            detail: [detail, note].compactMap { $0 }.joined(separator: "; ")
        )
    }
}
