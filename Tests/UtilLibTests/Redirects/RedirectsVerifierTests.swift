//
//  RedirectsVerifierTests.swift
//  UtilitiesTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import UtilLib

@Suite("RedirectsVerifier Tests")
struct RedirectsVerifierTests {

    /// A canned transport: records (method, url) calls and answers each URL
    /// path from a lookup table — 404 when unlisted — or a scripted error.
    final class StubTransport: @unchecked Sendable {
        struct Response {
            let status: Int
            let location: String?
        }

        var calls: [(RedirectsVerifier.ProbeMethod, String)] = []
        var responses: [String: Response] = [:]
        var error: Error?
        var handler: ((RedirectsVerifier.ProbeMethod, URL) -> RedirectsVerifier.ProbeResponse)?

        func transport(
            _ method: RedirectsVerifier.ProbeMethod, _ url: URL
        ) async throws -> RedirectsVerifier.ProbeResponse {
            calls.append((method, url.absoluteString))
            if let error { throw error }
            if let handler { return handler(method, url) }
            guard let response = responses[url.path] else {
                return RedirectsVerifier.ProbeResponse(status: 404, location: nil)
            }
            return RedirectsVerifier.ProbeResponse(
                status: response.status, location: response.location)
        }
    }

    private let baseURL = URL(string: "https://abc123.example.pages.dev")!

    private func makeVerifier(_ stub: StubTransport) -> RedirectsVerifier {
        RedirectsVerifier(transport: { [stub] method, url in
            try await stub.transport(method, url)
        })
    }

    private func makeRoot() throws -> String {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("redirects-verify-\(UUID().uuidString)").path
        try FileManager.default.createDirectory(atPath: root, withIntermediateDirectories: true)
        return root
    }

    private func write(_ contents: String, to path: String) throws {
        try FileManager.default.createDirectory(
            atPath: (path as NSString).deletingLastPathComponent,
            withIntermediateDirectories: true
        )
        try contents.write(toFile: path, atomically: true, encoding: .utf8)
    }

    // MARK: - Literal rules (FR-002)

    @Test("Literal rule passes when status and Location match")
    func literalPasses() async throws {
        let stub = StubTransport()
        stub.responses["/docs"] = .init(status: 301, location: "https://docs.21.dev/documentation/")
        let rules = RedirectsParser.parse("/docs https://docs.21.dev/documentation/ 301")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome) == [.passed])
        #expect(stub.calls.map(\.0) == [.head])
        #expect(stub.calls.map(\.1) == ["https://abc123.example.pages.dev/docs"])
        #expect(report.isSuccess)
    }

    @Test("Relative Location is asserted verbatim")
    func literalRelativeLocation() async throws {
        let stub = StubTransport()
        stub.responses["/"] = .init(status: 301, location: "/documentation/")
        let rules = RedirectsParser.parse("/ /documentation/ 301")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome) == [.passed])
    }

    @Test("Wrong status fails naming expected and observed")
    func wrongStatusFails() async throws {
        let stub = StubTransport()
        stub.responses["/docs"] = .init(status: 404, location: nil)
        let rules = RedirectsParser.parse("/docs /documentation/ 301")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome)
            == [.failed(.statusMismatch(expected: 301, observed: 404))])
        #expect(!report.isSuccess)
    }

    @Test("Wrong Location fails naming expected and observed")
    func wrongLocationFails() async throws {
        let stub = StubTransport()
        stub.responses["/docs"] = .init(status: 301, location: "/elsewhere/")
        let rules = RedirectsParser.parse("/docs /documentation/ 301")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome)
            == [.failed(.locationMismatch(expected: "/documentation/", observed: "/elsewhere/"))])
    }

    @Test("Transport failure fails the rule")
    func transportErrorFails() async throws {
        let stub = StubTransport()
        stub.error = URLError(.cannotConnectToHost)
        let rules = RedirectsParser.parse("/docs /documentation/ 301")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        guard case .failed(.transportError) = report.results[0].outcome else {
            Issue.record("expected transportError, got \(report.results[0].outcome)")
            return
        }
        #expect(!report.isSuccess)
    }

    @Test("Literal 200 rewrite asserts status only")
    func literalRewrite() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("", to: "\(root)/404.html")

        let stub = StubTransport()
        stub.responses["/alias"] = .init(status: 200, location: nil)
        let rules = RedirectsParser.parse("/alias /real 200")

        let report = await makeVerifier(stub).verify(
            rules: rules, baseURL: baseURL, deployedRoot: root)

        #expect(report.results.map(\.outcome) == [.passed])
    }

    // MARK: - Edge refusals (FR-005)

    @Test("Unsupported status fails with named refusal — no request fires")
    func unsupportedStatus() async throws {
        let stub = StubTransport()
        let rules = RedirectsParser.parse("/gone /elsewhere 404")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome)
            == [.failed(.edgeRefused(.unsupportedStatus(404)))])
        #expect(stub.calls.isEmpty)
    }

    @Test("External 200 proxy target fails with named refusal")
    func externalProxyTarget() async throws {
        let stub = StubTransport()
        let rules = RedirectsParser.parse("/post https://example.com/x 200")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome)
            == [.failed(.edgeRefused(.externalProxyTarget))])
        #expect(stub.calls.isEmpty)
    }

    @Test("Uncompilable source fails with named refusal")
    func uncompilableSource() async throws {
        let stub = StubTransport()
        let rules = RedirectsParser.parse("/a/*/b/* /x 301")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome)
            == [.failed(.edgeRefused(.uncompilableSource))])
        #expect(stub.calls.isEmpty)
    }

    @Test("Self-referencing redirect fails with named refusal")
    func selfReferencingTarget() async throws {
        let stub = StubTransport()
        let rules = RedirectsParser.parse("/a/* /a/x 301")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome)
            == [.failed(.edgeRefused(.selfReferencingTarget))])
        #expect(stub.calls.isEmpty)
    }

    @Test("Self-reference detected through the canonical target form")
    func canonicalSelfReferencingTarget() async throws {
        let stub = StubTransport()
        // Literal /a/x.html does not match /*/x; the canonicalized /a/x does.
        let rules = RedirectsParser.parse("/*/x /a/x.html 301")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome)
            == [.failed(.edgeRefused(.selfReferencingTarget))])
        #expect(stub.calls.isEmpty)
    }

    @Test("Edge refusal reporting keeps checker policy separate")
    func checkerSemanticsUnchanged() {
        // The link checker's flag must keep refusing masking 200 proxies even
        // though the verifier's edgeRefusal does not.
        #expect(!RedirectsParser.parse("/* /index.html 200")[0].isAppliedByEdge)
        #expect(!RedirectsParser.parse("/* / 200")[0].isAppliedByEdge)
        #expect(!RedirectsParser.parse("/a/* /a/x.html 200")[0].isAppliedByEdge)
        #expect(RedirectsParser.parse("/* /post 200")[0].isAppliedByEdge)
        // While edgeRefusal reports nil for every edge-served 200 proxy.
        #expect(RedirectsParser.parse("/* /index.html 200")[0].edgeRefusal == nil)
        #expect(RedirectsParser.parse("/* / 200")[0].edgeRefusal == nil)
        #expect(RedirectsParser.parse("/a/* /a/x.html 200")[0].edgeRefusal == nil)
        // And keeps naming real refusals.
        #expect(RedirectsParser.parse("/a/* /a/:splat 301")[0].edgeRefusal
            == .selfReferencingTarget)
    }

    // MARK: - Wildcard redirects (FR-003)

    @Test("Wildcard 3xx probes with the fixed token and asserts Location")
    func wildcardRedirectProbe() async throws {
        let stub = StubTransport()
        stub.responses["/p256k/redirects-verify-probe"] = .init(
            status: 301, location: "/documentation/p256k/redirects-verify-probe/")
        let rules = RedirectsParser.parse("/p256k/* /documentation/p256k/:splat/ 301")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome) == [.passed])
        #expect(stub.calls.map(\.1)
            == ["https://abc123.example.pages.dev/p256k/redirects-verify-probe"])
        #expect(report.probeToken == "redirects-verify-probe")
    }

    @Test("Placeholder source substitutes token per segment")
    func placeholderProbe() async throws {
        let stub = StubTransport()
        stub.responses["/old/redirects-verify-probe"] = .init(
            status: 302, location: "/new/redirects-verify-probe")
        let rules = RedirectsParser.parse("/old/:slug /new/:slug 302")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome) == [.passed])
    }

    @Test("Wildcard probe asserting wrong Location fails")
    func wildcardProbeMismatch() async throws {
        let stub = StubTransport()
        stub.responses["/p256k/redirects-verify-probe"] = .init(
            status: 301, location: "/documentation/p256k/")
        let rules = RedirectsParser.parse("/p256k/* /documentation/p256k/:splat/ 301")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome) == [.failed(
            .locationMismatch(
                expected: "/documentation/p256k/redirects-verify-probe/",
                observed: "/documentation/p256k/"))])
    }

    // MARK: - Wildcard rewrites (FR-004)

    @Test("Splat rewrite probes through a real deployed target")
    func rewriteRealTargetProbe() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("{}", to: "\(root)/well-known/nostr.json")
        try write("", to: "\(root)/404.html")

        let stub = StubTransport()
        stub.responses["/.well-known/nostr.json"] = .init(status: 200, location: nil)
        let rules = RedirectsParser.parse("/.well-known/* /well-known/:splat 200")

        let report = await makeVerifier(stub).verify(
            rules: rules, baseURL: baseURL, deployedRoot: root)

        #expect(report.results.map(\.outcome) == [.passed])
        #expect(stub.calls.map(\.1)
            == ["https://abc123.example.pages.dev/.well-known/nostr.json"])
    }

    @Test("Splat rewrite picks the first sorted matching deployed file")
    func rewritePicksFirstSortedTarget() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("{}", to: "\(root)/well-known/aaa.json")
        try write("{}", to: "\(root)/well-known/zzz.json")
        try write("", to: "\(root)/404.html")

        let stub = StubTransport()
        stub.responses["/.well-known/aaa.json"] = .init(status: 200, location: nil)
        let rules = RedirectsParser.parse("/.well-known/* /well-known/:splat 200")

        let report = await makeVerifier(stub).verify(
            rules: rules, baseURL: baseURL, deployedRoot: root)

        #expect(report.results.map(\.outcome) == [.passed])
        #expect(stub.calls.map(\.1)
            == ["https://abc123.example.pages.dev/.well-known/aaa.json"])
    }

    @Test("Splat rewrite skips when no deployed file matches the target")
    func rewriteNoDerivableTarget() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }

        let stub = StubTransport()
        let rules = RedirectsParser.parse("/.well-known/* /well-known/:splat 200")

        let report = await makeVerifier(stub).verify(
            rules: rules, baseURL: baseURL, deployedRoot: root)

        #expect(report.results.map(\.outcome) == [.skipped(.noDerivableTarget)])
        #expect(stub.calls.isEmpty)
        #expect(report.isSuccess) // skips are honest coverage, not failures
    }

    @Test("Splat rewrite skips when no deployed root is present")
    func rewriteNoDeployedRoot() async throws {
        let stub = StubTransport()
        let rules = RedirectsParser.parse("/.well-known/* /well-known/:splat 200")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome) == [.skipped(.noDeployedRoot)])
        #expect(stub.calls.isEmpty)
    }

    @Test("SPA-shell catch-all is probed, not refused")
    func spaShellProbed() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("<html>shell</html>", to: "\(root)/index.html")
        try write("", to: "\(root)/404.html")

        let stub = StubTransport()
        stub.responses["/redirects-verify-probe"] = .init(status: 200, location: nil)
        let rules = RedirectsParser.parse("/* /index.html 200")

        let report = await makeVerifier(stub).verify(
            rules: rules, baseURL: baseURL, deployedRoot: root)

        #expect(report.results.map(\.outcome) == [.passed])
        #expect(stub.calls.map(\.1)
            == ["https://abc123.example.pages.dev/redirects-verify-probe"])
    }

    @Test("SPA shell skips when the literal target is absent")
    func spaShellMissingTarget() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }

        let stub = StubTransport()
        let rules = RedirectsParser.parse("/* /index.html 200")

        let report = await makeVerifier(stub).verify(
            rules: rules, baseURL: baseURL, deployedRoot: root)

        #expect(report.results.map(\.outcome) == [.skipped(.noDerivableTarget)])
        #expect(stub.calls.isEmpty)
    }

    @Test("Rewrite skips when the probe source is itself a deployed asset")
    func rewriteProbeSourceIsDeployedAsset() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("{}", to: "\(root)/well-known/nostr.json")
        // The probe source lands on a real file — a 200 there proves nothing.
        try write("{}", to: "\(root)/.well-known/nostr.json")

        let stub = StubTransport()
        let rules = RedirectsParser.parse("/.well-known/* /well-known/:splat 200")

        let report = await makeVerifier(stub).verify(
            rules: rules, baseURL: baseURL, deployedRoot: root)

        #expect(report.results.map(\.outcome) == [.skipped(.probeSourceIsDeployedAsset)])
        #expect(stub.calls.isEmpty)
    }

    @Test("Wildcard 3xx probe is shadowed by an earlier edge-served 200 catch-all")
    func redirectProbeShadowedByMaskingProxy() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("<html>shell</html>", to: "\(root)/index.html")
        try write("", to: "\(root)/404.html")

        let stub = StubTransport()
        stub.responses["/redirects-verify-probe"] = .init(status: 200, location: nil)
        let rules = RedirectsParser.parse("""
        /* /index.html 200
        /x/* /y/:splat 301
        """)

        let report = await makeVerifier(stub).verify(
            rules: rules, baseURL: baseURL, deployedRoot: root)

        #expect(report.results[0].outcome == .passed)
        // The catch-all proxy is checker-masked but edge-served: it governs
        // /x/redirects-verify-probe, so the 301 cannot be probed there.
        #expect(report.results[1].outcome == .skipped(.probeSourceShadowed))
        #expect(stub.calls.map(\.1)
            == ["https://abc123.example.pages.dev/redirects-verify-probe"])
    }

    @Test("Rewrite skips when an earlier applied rule shadows the probe source")
    func rewriteProbeShadowed() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("{}", to: "\(root)/well-known/nostr.json")

        let stub = StubTransport()
        // The literal rule passes its own check, then shadows the derived
        // probe source /.well-known/nostr.json for the wildcard rule.
        stub.responses["/.well-known/nostr.json"] = .init(status: 301, location: "/elsewhere")
        let rules = RedirectsParser.parse("""
        /.well-known/nostr.json /elsewhere 301
        /.well-known/* /well-known/:splat 200
        """)

        let report = await makeVerifier(stub).verify(
            rules: rules, baseURL: baseURL, deployedRoot: root)

        #expect(report.results[0].outcome == .passed)
        #expect(report.results[1].outcome == .skipped(.probeSourceShadowed))
        #expect(stub.calls.map(\.1)
            == ["https://abc123.example.pages.dev/.well-known/nostr.json"])
    }

    @Test("A probe token containing a slash skips the rule as unmatchable")
    func probeTokenWithSlashSkips() async throws {
        let stub = StubTransport()
        let verifier = RedirectsVerifier(probeToken: "a/b") { method, url in
            try await stub.transport(method, url)
        }
        // :placeholder compiles to [^/]+, so /old/a/b can never self-match.
        let rules = RedirectsParser.parse("/old/:slug /new/:slug 302")

        let report = await verifier.verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome) == [.skipped(.probeSourceUnmatchable)])
        #expect(stub.calls.isEmpty)
    }

    @Test("rewrite skips when the deployment can SPA-fallback — no 404.html")
    func rewriteSkipsWhenDeploymentCanSpaFallback() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("{}", to: "\(root)/well-known/nostr.json")

        let stub = StubTransport()
        let rules = RedirectsParser.parse("/.well-known/* /well-known/:splat 200")

        let report = await makeVerifier(stub).verify(
            rules: rules, baseURL: baseURL, deployedRoot: root)

        #expect(report.results.map(\.outcome) == [.skipped(.spaFallbackUnprovable)])
        #expect(stub.calls.isEmpty)
    }

    @Test("literal 200 skips when the deployment can SPA-fallback, probes otherwise")
    func literalRewriteSpaFallbackGate() async throws {
        let noProof = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: noProof) }
        let withProof = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: withProof) }
        try write("", to: "\(withProof)/404.html")

        let stub = StubTransport()
        stub.responses["/alias"] = .init(status: 200, location: nil)
        let rules = RedirectsParser.parse("/alias /real 200")
        let verifier = makeVerifier(stub)

        let skipped = await verifier.verify(
            rules: rules, baseURL: baseURL, deployedRoot: noProof)
        #expect(skipped.results.map(\.outcome) == [.skipped(.spaFallbackUnprovable)])

        let noRoot = await verifier.verify(rules: rules, baseURL: baseURL)
        #expect(noRoot.results.map(\.outcome) == [.skipped(.noDeployedRoot)])

        let proven = await verifier.verify(
            rules: rules, baseURL: baseURL, deployedRoot: withProof)
        #expect(proven.results.map(\.outcome) == [.passed])
        #expect(stub.calls.map(\.1) == ["https://abc123.example.pages.dev/alias"])
    }

    @Test("literal rule skips when an earlier applied rule shadows its source")
    func literalProbeShadowedByCatchAll() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("<html>shell</html>", to: "\(root)/index.html")
        try write("", to: "\(root)/404.html")

        let stub = StubTransport()
        stub.responses["/redirects-verify-probe"] = .init(status: 200, location: nil)
        let rules = RedirectsParser.parse("""
        /* /index.html 200
        /docs /y 301
        """)

        let report = await makeVerifier(stub).verify(
            rules: rules, baseURL: baseURL, deployedRoot: root)

        #expect(report.results.map(\.outcome) == [.passed, .skipped(.probeSourceShadowed)])
        #expect(stub.calls.count == 1)
    }

    @Test("unservable and hidden files are never probe targets")
    func deployedFileEnumerationFilters() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("x", to: "\(root)/.DS_Store")
        try write("x", to: "\(root)/_redirects")
        try write("", to: "\(root)/404.html")
        try write("x", to: "\(root)/real-asset.html")

        let stub = StubTransport()
        stub.responses["/x/404.html"] = .init(status: 200, location: nil)
        stub.responses["/x/real-asset.html"] = .init(status: 200, location: nil)
        let rules = RedirectsParser.parse("/x/* /:splat 200")

        let report = await makeVerifier(stub).verify(
            rules: rules, baseURL: baseURL, deployedRoot: root)

        // Sorted servable candidates: /404.html, /real-asset.html — the dot
        // file and _redirects must not win (nor appear at all).
        #expect(report.results.map(\.outcome) == [.passed])
        #expect(stub.calls.map(\.1) == ["https://abc123.example.pages.dev/x/404.html"])
    }

    @Test("non-ASCII and raw characters in a source probe without crashing")
    func rawPathProbeDoesNotCrash() async throws {
        let stub = StubTransport()
        let rules = RedirectsParser.parse("""
        /café /x 301
        /a%20b /y 301
        """)

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.count == 2)
        #expect(report.results.allSatisfy {
            if case .failed(.statusMismatch(301, 404)) = $0.outcome { return true }
            return false
        })
        // The raw source is encoded by URLComponents — non-ASCII and a bare
        // `%` must not crash; the bytes on the wire are percent-encoded.
        #expect(stub.calls.map(\.1) == [
            "https://abc123.example.pages.dev/caf%C3%A9",
            "https://abc123.example.pages.dev/a%2520b",
        ])
    }

    @Test("probe URL percent-encodes a splat filename containing a space")
    func splatFilenameWithSpaceEncodes() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("{}", to: "\(root)/well-known/my file.json")
        try write("", to: "\(root)/404.html")

        let stub = StubTransport()
        stub.responses["/.well-known/my file.json"] = .init(status: 200, location: nil)
        let rules = RedirectsParser.parse("/.well-known/* /well-known/:splat 200")

        let report = await makeVerifier(stub).verify(
            rules: rules, baseURL: baseURL, deployedRoot: root)

        #expect(report.results.map(\.outcome) == [.passed])
        #expect(stub.calls.map(\.1)
            == ["https://abc123.example.pages.dev/.well-known/my%20file.json"])
    }

    // MARK: - HTTP behavior (FR-006)

    @Test("HEAD gets a GET fallback on 405")
    func getFallbackOn405() async throws {
        let stub = StubTransport()
        stub.handler = { method, _ in
            method == .head
                ? .init(status: 405, location: nil)
                : .init(status: 301, location: "/documentation/")
        }
        let rules = RedirectsParser.parse("/docs /documentation/ 301")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome) == [.passed])
        #expect(stub.calls.map(\.0) == [.head, .get])
    }

    @Test("HEAD gets a GET fallback on 501")
    func getFallbackOn501() async throws {
        let stub = StubTransport()
        stub.handler = { method, _ in
            method == .head
                ? .init(status: 501, location: nil)
                : .init(status: 301, location: "/documentation/")
        }
        let rules = RedirectsParser.parse("/docs /documentation/ 301")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome) == [.passed])
        #expect(stub.calls.map(\.0) == [.head, .get])
    }

    @Test("HEAD 200 does not fall back to GET")
    func noFallbackOnSuccess() async throws {
        let stub = StubTransport()
        stub.responses["/docs"] = .init(status: 301, location: "/documentation/")
        let rules = RedirectsParser.parse("/docs /documentation/ 301")

        let report = await makeVerifier(stub).verify(rules: rules, baseURL: baseURL)

        #expect(report.results.map(\.outcome) == [.passed])
        #expect(stub.calls.map(\.0) == [.head])
    }

    // MARK: - Whole-file coverage

    @Test("docs-21-dev's real rules verify end-to-end on a stubbed edge")
    func realFileEndToEnd() async throws {
        // The real file: literals, splat redirects, the index.html catch-all.
        let docsRules = RedirectsParser.parse(try String(
            contentsOfFile: repositoryPath("Resources/docs-21-dev/_redirects"),
            encoding: .utf8))

        // Answer each probe the way the edge does: first applied match wins,
        // Location echoed with the captured values substituted.
        let matcher = RedirectsParser.compiledMatcher(rules: docsRules)
        let verifier = RedirectsVerifier { _, url in
            if let (rule, match) = matcher.firstAppliedMatch(sitePath: url.path) {
                let location = RedirectsParser.substitute(rule.target, with: match)
                return RedirectsVerifier.ProbeResponse(
                    status: rule.status,
                    location: RedirectRule.redirectStatuses.contains(rule.status) ? location : nil)
            }
            return RedirectsVerifier.ProbeResponse(status: 404, location: nil)
        }

        let report = await verifier.verify(rules: docsRules, baseURL: baseURL)

        #expect(report.isSuccess)
        #expect(report.results.count == docsRules.count)
        #expect(report.results.allSatisfy { $0.outcome == .passed })
    }

    @Test("21-dev's real file verifies — rewrite probed through a real file")
    func real21DevEndToEnd() async throws {
        let root = try makeRoot()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try write("{}", to: "\(root)/well-known/nostr.json")
        try write("", to: "\(root)/404.html")

        let rules = RedirectsParser.parse(try String(
            contentsOfFile: repositoryPath("Resources/21-dev/_redirects"),
            encoding: .utf8))

        let matcher = RedirectsParser.compiledMatcher(rules: rules)
        let verifier = RedirectsVerifier { _, url in
            if let (rule, match) = matcher.firstAppliedMatch(sitePath: url.path) {
                let location = RedirectsParser.substitute(rule.target, with: match)
                return RedirectsVerifier.ProbeResponse(
                    status: rule.status,
                    location: RedirectRule.redirectStatuses.contains(rule.status) ? location : nil)
            }
            return RedirectsVerifier.ProbeResponse(status: 404, location: nil)
        }

        let report = await verifier.verify(rules: rules, baseURL: baseURL, deployedRoot: root)

        #expect(report.isSuccess)
        #expect(report.results.count == rules.count)
        #expect(report.results.allSatisfy { $0.outcome == .passed })
    }

    /// Repository-relative path resolved from this file's location —
    /// `Tests/UtilLibTests/Redirects/<file>` is four levels under the root.
    private func repositoryPath(_ relative: String) -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(relative)
            .path
    }
}
