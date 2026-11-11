//
//  RedirectsVerifier.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Verifies every rule in a `_redirects` file against a live deployment —
/// derived from the file itself, so a new rule cannot ship unverified
/// (Specs/007, FR-002…FR-006).
///
/// Verification posture per rule, in `_redirects` file order:
///
/// 1. Edge refusal — a status Cloudflare does not support, a source that
///    cannot compile, or a redirect target looping through its own source
///    (``RedirectRule/edgeRefusal``) fails with the refusal named, before any
///    request fires. `200` masking proxies (`/* /index.html 200`) are *not*
///    refused — a deployed edge serves them (deploy-time validation may
///    refuse canonical-rematch shapes upstream; this models the runtime
///    edge); they are probed like any rewrite.
/// 2. Literal source — request `baseURL + source`, assert the observed status
///    equals the declared status and, for redirect statuses, that `Location`
///    equals the declared target verbatim (the edge echoes targets as
///    written). Shadowed sources skip; `200` sources also skip unless a
///    deployed root rules out SPA fallback.
/// 3. Wildcard + redirect status — substitute the fixed ``probeToken`` for
///    each `*`/`:placeholder`, request the probe source, apply the same
///    assertions.
/// 4. Wildcard + `200` (rewrite) — a fixed-token probe proves nothing (a 404
///    comes back either way), so a *real* target is derived: a deployed file
///    matching the splat-expanded target, or the literal target itself. When
///    the probe source is not itself a deployed asset and is not shadowed by
///    an earlier applied rule, it is requested and the declared status
///    asserted — a `200` there is reachable only through the rewrite *when
///    the deployment cannot fall back*: without a top-level `404.html` Pages
///    serves `/` with `200` for any unmatched path (a soft-404 condition),
///    so status-only `200` probes on such deployments are reported skipped
///    rather than trusted. Otherwise the rule is reported skipped with a
///    reason.
///
/// Requests are issued HEAD-first with a GET fallback on 405/501 (FR-006);
/// transport is injected so tests need no server.
public struct RedirectsVerifier: Sendable {

    /// The HTTP method a probe request is attempted with.
    public enum ProbeMethod: String, Sendable {
        case head = "HEAD"
        case get = "GET"
    }

    /// The minimum a probe needs from the edge: status code and `Location`.
    public struct ProbeResponse: Sendable, Equatable {
        public let status: Int
        public let location: String?

        public init(status: Int, location: String?) {
            self.status = status
            self.location = location
        }
    }

    /// Performs one probe request — injected so tests need no server.
    public typealias Transport = @Sendable (ProbeMethod, URL) async throws -> ProbeResponse

    /// The fixed token substituted for each `*`/`:placeholder` in
    /// verifier-chosen probe paths — conspicuous so a probe path can never
    /// be mistaken for real traffic, and named in the report.
    public let probeToken: String

    /// Performs probes against the deployment.
    public let transport: Transport

    /// Creates a verifier.
    /// - Parameters:
    ///   - probeToken: Wildcard substitution token; must be a single path
    ///     segment so `:placeholder` probes still match (`[^/]+`).
    ///   - requestTimeout: Per-request bound for the default live transport;
    ///     ignored when `transport` is injected.
    ///   - transport: Probe transport; defaults to live `URLSession` requests
    ///     that never follow redirects — only the first hop is asserted.
    public init(
        probeToken: String = "redirects-verify-probe",
        requestTimeout: TimeInterval = 15,
        transport: Transport? = nil
    ) {
        self.probeToken = probeToken
        self.transport = transport ?? Self.liveTransport(timeout: requestTimeout)
    }

    /// Verifies every rule against a deployment, in file order.
    /// - Parameters:
    ///   - rules: Parsed `_redirects` rules.
    ///   - baseURL: Deployment origin — the per-deploy `*.pages.dev` URL where
    ///     `_redirects` is the only redirect policy in play.
    ///   - deployedRoot: The generated output root (`Websites/<site>/`) used
    ///     to derive real targets for `200` rewrites and to rule out SPA
    ///     fallback for any `200` probe; when `nil` or absent those probes
    ///     degrade to skips (FR-004).
    /// - Returns: A report with one outcome per rule, in file order.
    public func verify(
        rules: [RedirectRule],
        baseURL: URL,
        deployedRoot: String? = nil
    ) async -> RedirectsVerifyReport {
        let compiledRules = rules.map(CompiledRedirectRule.init(rule:))
        let root = deployedRoot.flatMap { path in
            var isDirectory: ObjCBool = false
            return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
                && isDirectory.boolValue ? path : nil
        }
        var results: [RedirectRuleVerification] = []

        for (index, rule) in rules.enumerated() {
            let compiled = compiledRules[index]
            let outcome: RedirectRuleVerification.Outcome

            if let refusal = compiled.edgeRefusal {
                outcome = .failed(.edgeRefused(refusal))
            } else if !rule.isWildcard {
                outcome = await verifyLiteral(
                    rule, index: index, compiledRules: compiledRules,
                    baseURL: baseURL, deployedRoot: root
                )
            } else if RedirectRule.redirectStatuses.contains(rule.status) {
                outcome = await verifyRedirectWildcard(
                    rule, compiled: compiled, index: index, compiledRules: compiledRules,
                    baseURL: baseURL
                )
            } else {
                outcome = await verifyRewriteWildcard(
                    rule, compiled: compiled, index: index, compiledRules: compiledRules,
                    baseURL: baseURL, deployedRoot: root
                )
            }
            results.append(RedirectRuleVerification(rule: rule, outcome: outcome))
        }

        return RedirectsVerifyReport(baseURL: baseURL, probeToken: probeToken, results: results)
    }

    // MARK: - Rule kinds

    /// FR-002: request the literal source; assert status, and `Location`
    /// verbatim for redirect statuses. Skipped when an earlier applied rule
    /// governs the source — the probe observes that rule, not this one — and,
    /// for `200` rules, when the deployment could SPA-fallback and make a
    /// status-only `200` unprovable (see ``siteCanProve200(inRoot:)``).
    private func verifyLiteral(
        _ rule: RedirectRule,
        index: Int,
        compiledRules: [CompiledRedirectRule],
        baseURL: URL,
        deployedRoot: String?
    ) async -> RedirectRuleVerification.Outcome {
        guard !isShadowed(rule.source, before: index, in: compiledRules) else {
            return .skipped(.probeSourceShadowed)
        }
        if rule.status == 200 {
            guard let root = deployedRoot else {
                return .skipped(.noDeployedRoot)
            }
            guard siteCanProve200(inRoot: root) else {
                return .skipped(.spaFallbackUnprovable)
            }
        }
        guard let url = probeURL(baseURL: baseURL, sitePath: rule.source) else {
            return .failed(.transportError("could not construct probe URL for \(rule.source)"))
        }
        let expectedLocation = RedirectRule.redirectStatuses.contains(rule.status)
            ? rule.target : nil
        return await assertResponse(rule, on: url, expectedLocation: expectedLocation)
    }

    /// FR-003: substitute the probe token for each wildcard, then apply the
    /// FR-002 assertions to the probe response. Skipped when an earlier
    /// applied rule governs the probe source — the probe cannot observe the
    /// rule there.
    private func verifyRedirectWildcard(
        _ rule: RedirectRule,
        compiled: CompiledRedirectRule,
        index: Int,
        compiledRules: [CompiledRedirectRule],
        baseURL: URL
    ) async -> RedirectRuleVerification.Outcome {
        let probeSource = expandSource(rule.source, with: nil)
        guard let match = compiled.match(sitePath: probeSource) else {
            return .skipped(.probeSourceUnmatchable)
        }
        guard !isShadowed(probeSource, before: index, in: compiledRules) else {
            return .skipped(.probeSourceShadowed)
        }
        guard let url = probeURL(baseURL: baseURL, sitePath: probeSource) else {
            return .failed(.transportError("could not construct probe URL for \(probeSource)"))
        }
        let expectedLocation = RedirectsParser.substitute(rule.target, with: match)
        return await assertResponse(rule, on: url, expectedLocation: expectedLocation)
    }

    /// FR-004: a `200` wildcard can only be proven through a real target —
    /// a deployed file matching the splat-expanded target, or the literal
    /// target itself. The probe source (the rule's source with the captured
    /// or token values substituted back) must not itself be a deployed asset
    /// and must not be shadowed by an earlier applied rule; otherwise the
    /// rule is skipped with a stated reason.
    private func verifyRewriteWildcard(
        _ rule: RedirectRule,
        compiled: CompiledRedirectRule,
        index: Int,
        compiledRules: [CompiledRedirectRule],
        baseURL: URL,
        deployedRoot: String?
    ) async -> RedirectRuleVerification.Outcome {
        guard let root = deployedRoot else {
            return .skipped(.noDeployedRoot)
        }

        var targetPath = rule.target
        if let cut = targetPath.firstIndex(where: { $0 == "?" || $0 == "#" }) {
            targetPath = String(targetPath[..<cut])
        }
        let probeSource: String
        if let pattern = TargetPattern(targetPath) {
            guard let match = deployedFiles(under: root)
                .lazy.compactMap({ pattern.matches($0) }).first else {
                return .skipped(.noDerivableTarget)
            }
            probeSource = expandSource(rule.source, with: match)
        } else {
            guard InternalLinkChecker.fileExists(
                sitePath: rule.normalizedLiteralTarget, inRoot: root
            ) else {
                return .skipped(.noDerivableTarget)
            }
            probeSource = expandSource(rule.source, with: nil)
        }

        guard compiled.match(sitePath: probeSource) != nil else {
            return .skipped(.probeSourceUnmatchable)
        }
        guard !InternalLinkChecker.fileExists(sitePath: probeSource, inRoot: root) else {
            return .skipped(.probeSourceIsDeployedAsset)
        }
        guard !isShadowed(probeSource, before: index, in: compiledRules) else {
            return .skipped(.probeSourceShadowed)
        }
        guard siteCanProve200(inRoot: root) else {
            return .skipped(.spaFallbackUnprovable)
        }
        guard let url = probeURL(baseURL: baseURL, sitePath: probeSource) else {
            return .failed(.transportError("could not construct probe URL for \(probeSource)"))
        }
        return await assertResponse(rule, on: url)
    }

    // MARK: - Assertions

    /// Issues the probe (HEAD, GET fallback) and applies the declared-status
    /// and `Location` assertions.
    private func assertResponse(
        _ rule: RedirectRule,
        on url: URL,
        expectedLocation: String? = nil
    ) async -> RedirectRuleVerification.Outcome {
        let response: ProbeResponse
        do {
            response = try await fetch(url)
        } catch {
            return .failed(.transportError(error.localizedDescription))
        }
        guard response.status == rule.status else {
            return .failed(.statusMismatch(expected: rule.status, observed: response.status))
        }
        if let expectedLocation, response.location != expectedLocation {
            return .failed(.locationMismatch(expected: expectedLocation, observed: response.location))
        }
        return .passed
    }

    /// HEAD first; on 405/501 (methods an edge layer may not implement) retry
    /// GET — FR-006.
    private func fetch(_ url: URL) async throws -> ProbeResponse {
        let head = try await transport(.head, url)
        if head.status == 405 || head.status == 501 {
            return try await transport(.get, url)
        }
        return head
    }

    /// Builds `baseURL + sitePath` — the path is assigned raw and encoded by
    /// `URLComponents`, so the *decoded* request path always equals the
    /// declared source. (`percentEncodedPath` would require pre-encoded input
    /// and fatal-errors on spaces, non-ASCII, or a bare `%`.)
    private func probeURL(baseURL: URL, sitePath: String) -> URL? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.path = sitePath.hasPrefix("/") ? sitePath : "/" + sitePath
        components.percentEncodedQuery = nil
        components.fragment = nil
        return components.url
    }

    /// Substitutes values into a *source* pattern — captured wildcard values
    /// when a match is provided, else the probe token. `*` takes the splat
    /// (or token), each `:placeholder` its captured (or token) value.
    private func expandSource(_ source: String, with match: RedirectMatch?) -> String {
        var result = ""
        var index = source.startIndex
        while index < source.endIndex {
            let character = source[index]
            if character == "*" {
                result += match?.splat ?? probeToken
                index = source.index(after: index)
            } else if character == ":",
                      let nameStart = source.index(index, offsetBy: 1, limitedBy: source.endIndex),
                      nameStart < source.endIndex,
                      isPlaceholderStart(source[nameStart]) {
                var nameEnd = nameStart
                while nameEnd < source.endIndex, isPlaceholderCharacter(source[nameEnd]) {
                    nameEnd = source.index(after: nameEnd)
                }
                let name = String(source[nameStart..<nameEnd])
                result += match?.placeholders[name] ?? probeToken
                index = nameEnd
            } else {
                result.append(character)
                index = source.index(after: index)
            }
        }
        return result
    }

    /// Whether an earlier rule that the edge would apply governs the probe
    /// path — a probe there observes the earlier rule, not the one under test.
    /// Uses edge semantics (`edgeRefusal`), not the link checker's
    /// `isAppliedByEdge`: a `200` masking proxy does shadow requests.
    private func isShadowed(
        _ probeSource: String,
        before index: Int,
        in compiledRules: [CompiledRedirectRule]
    ) -> Bool {
        compiledRules[..<index].contains {
            $0.edgeRefusal == nil && $0.match(sitePath: probeSource) != nil
        }
    }

    /// Whether a bare `200` status at a probe path can prove anything on this
    /// deployment. Without a top-level `404.html`, Pages assumes an SPA and
    /// serves `/` with `200` for any unmatched path — a soft-404 condition —
    /// so a `200` could come from the fallback rather than the rule.
    private func siteCanProve200(inRoot root: String) -> Bool {
        InternalLinkChecker.fileExists(sitePath: "/404.html", inRoot: root)
    }

    /// Regular files under the deployed root as site paths (`/`-prefixed),
    /// sorted for deterministic probe selection. Files the edge never serves
    /// are excluded — dot-paths (Pages does not serve them; the `atPath`
    /// enumerator has no `.skipsHiddenFiles`) and root config files like
    /// `_redirects` (`InternalLinkChecker.unservedRootFiles`).
    private func deployedFiles(under root: String) -> [String] {
        guard let enumerator = FileManager.default.enumerator(atPath: root) else { return [] }
        var files: [String] = []
        var isDirectory: ObjCBool = false
        for case let path as String in enumerator {
            guard !path.components(separatedBy: "/").contains(where: { $0.hasPrefix(".") })
            else { continue }
            let sitePath = "/" + path
            guard !InternalLinkChecker.unservedRootFiles.contains(sitePath)
            else { continue }
            let absolute = (root as NSString).appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: absolute, isDirectory: &isDirectory),
               !isDirectory.boolValue {
                files.append(sitePath)
            }
        }
        return files.sorted()
    }

    // MARK: - Live transport

    /// The default transport: real `URLSession` probes that never follow
    /// redirects — only the first hop is asserted (spec: chained redirects
    /// cover themselves).
    private static func liveTransport(timeout: TimeInterval) -> Transport {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        let session = URLSession(
            configuration: configuration,
            delegate: NoRedirectDelegate(),
            delegateQueue: nil
        )
        return { method, url in
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            let (_, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            return ProbeResponse(
                status: http.statusCode,
                location: http.value(forHTTPHeaderField: "Location")
            )
        }
    }
}

/// Refuses redirect following — the verifier asserts the first hop only.
private final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(nil)
    }
}

/// A `200` rule's *target* compiled for matching deployed files — the
/// inverse of a source pattern: `:splat` compiles to `.*` (crosses slashes,
/// like the source `*`), `:placeholder` to `[^/]+`, everything else literal.
private struct TargetPattern {
    private let regex: NSRegularExpression
    private let splatGroup: Int?
    private let namedGroups: [String: Int]

    /// Compiles a wildcard target for file matching, or `nil` when the target
    /// has no wildcards — literal targets are checked by file existence
    /// instead of enumeration.
    init?(_ target: String) {
        var pattern = "\\A"
        var group = 0
        var splatGroup: Int? = nil
        var namedGroups: [String: Int] = [:]
        var sawWildcard = false

        var index = target.startIndex
        while index < target.endIndex {
            let character = target[index]
            if character == ":",
               let nameStart = target.index(index, offsetBy: 1, limitedBy: target.endIndex),
               nameStart < target.endIndex,
               isPlaceholderStart(target[nameStart]) {
                var nameEnd = nameStart
                while nameEnd < target.endIndex, isPlaceholderCharacter(target[nameEnd]) {
                    nameEnd = target.index(after: nameEnd)
                }
                let name = String(target[nameStart..<nameEnd])
                group += 1
                sawWildcard = true
                if name == "splat" {
                    splatGroup = group
                    pattern += "(.*)"
                } else {
                    namedGroups[name] = group
                    pattern += "([^/]+)"
                }
                index = nameEnd
            } else {
                pattern += NSRegularExpression.escapedPattern(for: String(character))
                index = target.index(after: index)
            }
        }
        pattern += "\\z"

        guard sawWildcard, let compiled = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        self.regex = compiled
        self.splatGroup = splatGroup
        self.namedGroups = namedGroups
    }

    /// Captures a deployed file's site path against the target pattern.
    func matches(_ sitePath: String) -> RedirectMatch? {
        let range = NSRange(sitePath.startIndex..., in: sitePath)
        guard let result = regex.firstMatch(in: sitePath, range: range) else { return nil }
        var splat: String? = nil
        if let splatGroup, let capture = Range(result.range(at: splatGroup), in: sitePath) {
            splat = String(sitePath[capture])
        }
        var placeholders: [String: String] = [:]
        for (name, group) in namedGroups {
            if let capture = Range(result.range(at: group), in: sitePath) {
                placeholders[name] = String(sitePath[capture])
            }
        }
        return RedirectMatch(splat: splat, placeholders: placeholders)
    }
}

/// Whether a character can start a placeholder name (`:[A-Za-z]…`).
private func isPlaceholderStart(_ character: Character) -> Bool {
    character.isASCII && character.isLetter
}

/// Whether a character can continue a placeholder name (`\w`).
private func isPlaceholderCharacter(_ character: Character) -> Bool {
    character.isASCII && (character.isLetter || character.isNumber || character == "_")
}
