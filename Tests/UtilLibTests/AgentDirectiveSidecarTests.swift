//
//  AgentDirectiveSidecarTests.swift
//  websitesPackageTests
//
//  Sidecar-driven JSON-LD enrichment + report aggregation coverage for
//  `AgentDirectiveInjector`. Pairs with `AgentDirectiveTests` (legacy
//  pre-sidecar behavior) and `DocCSidecarTests` (loader / decoding).
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import SchemaLib
import Testing
@testable import UtilLib

// MARK: - Helpers

private let docsBaseURL = URL(string: "https://docs.21.dev")!

private func makeSidecar(
    title: String,
    role: String,
    abstract: String? = nil,
    module: String? = nil,
    symbolKind: String? = nil
) throws -> DocCSidecar {
    var json: [String: Any] = [
        "metadata": [
            "title": title,
            "role": role
        ]
    ]
    var metadata = json["metadata"] as! [String: Any]
    if let module {
        metadata["modules"] = [["name": module]]
    }
    if let symbolKind {
        metadata["symbolKind"] = symbolKind
    }
    json["metadata"] = metadata
    if let abstract {
        json["abstract"] = [["type": "text", "text": abstract]]
    }
    let data = try JSONSerialization.data(withJSONObject: json)
    return try JSONDecoder().decode(DocCSidecar.self, from: data)
}

// MARK: - buildDirective(sidecar:) — Article role

@Suite("AgentDirectiveInjector — TechArticle wiring")
struct AgentDirectiveTechArticleTests {

    @Test("Article sidecar emits TechArticle node with articleSection=Guides and bidirectional refs")
    func articleEmitsTechArticle() throws {
        let sidecar = try makeSidecar(
            title: "Choosing Between P256K and ZKP",
            role: "article",
            abstract: "Pick the right product for the job.",
            module: "ZKP"
        )

        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/zkp/choosingp256kvszkp/index.html",
            baseURL: docsBaseURL,
            sidecar: sidecar
        )

        // Article-class node is present, uniformly typed as TechArticle.
        #expect(directive.contains("\"TechArticle\""))
        // WebPage gets a back-reference to the TechArticle.
        #expect(directive.contains("mainEntity"))
        #expect(directive.contains("#techarticle"))
        // Article carries the canonical publisher @id pointer.
        #expect(directive.contains("21.dev\\/#organization"))
        // Title is sourced from the sidecar, not the slug fallback.
        #expect(directive.contains("Choosing Between P256K and ZKP"))
        #expect(directive.contains("Pick the right product"))
        // articleSection is "Guides" for prose articles.
        #expect(directive.contains("\"articleSection\":\"Guides\""))
        // Authored articles do not get an `about` (no single subject).
        #expect(!directive.contains("\"about\""))
        // No APIReference legacy type/fragment for an authored article.
        #expect(!directive.contains("\"APIReference\""))
        #expect(!directive.contains("#apireference"))
    }

    @Test("Article WebPage.name equals sidecar.metadata.title (not slug)")
    func articleWebPageNameFromSidecar() throws {
        let sidecar = try makeSidecar(
            title: "Choosing Between P256K and ZKP",
            role: "article"
        )

        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/zkp/choosingp256kvszkp/index.html",
            baseURL: docsBaseURL,
            sidecar: sidecar
        )

        // Sidecar title appears verbatim. The slug-cased fallback
        // ("Choosingp256kvszkp" or similar) must not.
        #expect(directive.contains("Choosing Between P256K and ZKP"))
        #expect(!directive.contains("Choosingp256kvszkp"))
    }

    @Test("Article-role @id uses TechArticleSchema.canonicalID helper")
    func articleIDMatchesCanonicalHelper() throws {
        let sidecar = try makeSidecar(
            title: "Choosing Between P256K and ZKP",
            role: "article"
        )

        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/zkp/choosingp256kvszkp/index.html",
            baseURL: docsBaseURL,
            sidecar: sidecar
        )

        let expectedID = TechArticleSchema.canonicalID(
            forPageURL: "https://docs.21.dev/documentation/zkp/choosingp256kvszkp/"
        )
        // Match against the JSON-LD escaped form (`/` -> `\/`) the renderer emits.
        let escapedID = expectedID.replacingOccurrences(of: "/", with: "\\/")
        #expect(directive.contains(escapedID))
    }
}

// MARK: - buildDirective(sidecar:) — Symbol / Collection roles

@Suite("AgentDirectiveInjector — TechArticle (symbol/collection) wiring")
struct AgentDirectiveSymbolCollectionTests {

    @Test("Symbol sidecar emits TechArticle with articleSection=API Reference and about=<module>")
    func symbolEmitsTechArticle() throws {
        let sidecar = try makeSidecar(
            title: "PrivateKey",
            role: "symbol",
            abstract: "A secp256k1 private key.",
            module: "P256K",
            symbolKind: "struct"
        )

        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/p256k/signing/privatekey/index.html",
            baseURL: docsBaseURL,
            sidecar: sidecar
        )

        // Uniform TechArticle @type for both prose and reference pages.
        #expect(directive.contains("\"TechArticle\""))
        // Reference pages carry articleSection: "API Reference".
        #expect(directive.contains("\"articleSection\":\"API Reference\""))
        // Reference pages carry the module name in `about`.
        #expect(directive.contains("\"about\":\"P256K\""))
        // Canonical fragment is uniformly #techarticle.
        #expect(directive.contains("#techarticle"))
        // WebPage has a mainEntity ref to the TechArticle node.
        #expect(directive.contains("mainEntity"))
        // Dropped properties must NOT appear.
        #expect(!directive.contains("\"programmingLanguage\""))
        #expect(!directive.contains("\"codeRepository\""))
        // Legacy APIReference type/fragment must NOT appear.
        #expect(!directive.contains("\"APIReference\""))
        #expect(!directive.contains("#apireference"))
    }

    @Test("Collection (module overview) sidecar emits TechArticle with API Reference section")
    func collectionEmitsTechArticle() throws {
        let sidecar = try makeSidecar(
            title: "P256K",
            role: "collection",
            module: "P256K"
        )

        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/index.html",
            baseURL: docsBaseURL,
            sidecar: sidecar
        )

        #expect(directive.contains("\"TechArticle\""))
        #expect(directive.contains("\"articleSection\":\"API Reference\""))
        #expect(directive.contains("\"about\":\"P256K\""))
        #expect(!directive.contains("\"APIReference\""))
    }

    @Test("Symbol-role @id uses TechArticleSchema.canonicalID helper")
    func symbolIDMatchesCanonicalHelper() throws {
        let sidecar = try makeSidecar(
            title: "PrivateKey",
            role: "symbol",
            module: "P256K"
        )

        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/p256k/signing/privatekey/index.html",
            baseURL: docsBaseURL,
            sidecar: sidecar
        )

        let expectedID = TechArticleSchema.canonicalID(
            forPageURL: "https://docs.21.dev/documentation/p256k/p256k/signing/privatekey/"
        )
        let escapedID = expectedID.replacingOccurrences(of: "/", with: "\\/")
        #expect(directive.contains(escapedID))
    }

    @Test("`about` falls back to path-derived module when sidecar.moduleName is nil")
    func aboutFallsBackToPath() throws {
        // Sidecar without a module field— forces extractModule(from:) fallback.
        let sidecar = try makeSidecar(
            title: "Event",
            role: "collection"
        )

        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/event/index.html",
            baseURL: docsBaseURL,
            sidecar: sidecar
        )

        // extractModule returns lowercase "event"; the injector uppercases it
        // to match DocC's bundle-name convention.
        #expect(directive.contains("\"about\":\"EVENT\""))
    }
}

// MARK: - buildDirective(sidecar:) — Roles that should NOT add Article-class

@Suite("AgentDirectiveInjector — sidecar role fallthrough")
struct AgentDirectiveRoleFallthroughTests {

    @Test("Landing page role keeps WebPage-only @graph")
    func landingPageNoArticleNode() throws {
        let sidecar = try makeSidecar(title: "Documentation", role: "landingPage")

        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/index.html",
            baseURL: docsBaseURL,
            sidecar: sidecar
        )

        #expect(!directive.contains("\"TechArticle\""))
        #expect(!directive.contains("\"APIReference\""))
        #expect(!directive.contains("mainEntity"))
    }

    @Test("Unknown DocC role keeps WebPage-only @graph")
    func unknownRoleNoArticleNode() throws {
        let sidecar = try makeSidecar(title: "X", role: "futureRole42")
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/x/index.html",
            baseURL: docsBaseURL,
            sidecar: sidecar
        )

        #expect(!directive.contains("\"TechArticle\""))
        #expect(!directive.contains("\"APIReference\""))
    }

    @Test("nil sidecar still emits Organization + WebPage with slug name")
    func nilSidecarFallsBackToSlug() throws {
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/p256k/context/index.html",
            baseURL: docsBaseURL,
            sidecar: nil
        )

        #expect(directive.contains("Organization"))
        #expect(directive.contains("WebPage"))
        // Slug-derived page name still appears (capitalized last segment).
        #expect(directive.contains("\"name\":\"Context\""))
        #expect(!directive.contains("\"TechArticle\""))
        #expect(!directive.contains("\"APIReference\""))
    }
}

// MARK: - Regression: APIReference / #apireference must never re-appear

@Suite("AgentDirectiveInjector — APIReference legacy regression")
struct AgentDirectiveAPIReferenceRegressionTests {

    /// Walks the cross-product of representative roles × paths and confirms
    /// that the deprecated `"APIReference"` `@type` and `#apireference`
    /// fragment never leak back into the rendered JSON-LD. Pinning these
    /// strings as forbidden defends against accidental reintroduction
    /// (e.g., copy-paste from older docs / specs).
    @Test("No representative role+path combination ever emits 'APIReference' or '#apireference'")
    func neverEmitsLegacyAPIReferenceTokens() throws {
        struct Case { let title: String; let role: String; let module: String?; let path: String }
        let cases: [Case] = [
            .init(title: "Choosing P256K vs ZKP", role: "article", module: "ZKP",
                  path: "documentation/zkp/choosingp256kvszkp/index.html"),
            .init(title: "PrivateKey", role: "symbol", module: "P256K",
                  path: "documentation/p256k/p256k/signing/privatekey/index.html"),
            .init(title: "P256K", role: "collection", module: "P256K",
                  path: "documentation/p256k/index.html"),
            .init(title: "Event", role: "collection", module: "Event",
                  path: "documentation/event/index.html"),
            .init(title: "Documentation", role: "landingPage", module: nil,
                  path: "documentation/index.html"),
        ]

        for c in cases {
            let sidecar = try makeSidecar(title: c.title, role: c.role, module: c.module)
            let directive = try AgentDirectiveInjector.buildDirective(
                markdownURL: nil,
                relativePath: c.path,
                baseURL: docsBaseURL,
                sidecar: sidecar
            )
            #expect(
                !directive.contains("\"APIReference\""),
                "role=\(c.role) path=\(c.path) leaked legacy @type 'APIReference'"
            )
            #expect(
                !directive.contains("#apireference"),
                "role=\(c.role) path=\(c.path) leaked legacy fragment '#apireference'"
            )
        }
    }

    @Test("nil sidecar path also never emits the legacy tokens")
    func nilSidecarPathHasNoLegacyTokens() throws {
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/p256k/context/index.html",
            baseURL: docsBaseURL,
            sidecar: nil
        )
        #expect(!directive.contains("\"APIReference\""))
        #expect(!directive.contains("#apireference"))
    }
}

// MARK: - InjectionReport sidecar aggregates

@Suite("InjectionReport sidecar aggregates")
struct InjectionReportSidecarAggregateTests {

    private func makeResult(
        path: String,
        sidecar: SidecarStatus
    ) -> InjectionResult {
        InjectionResult(
            filePath: "/tmp/\(path)",
            relativePath: path,
            action: .injected,
            noindexed: false,
            errorMessage: nil,
            sidecarStatus: sidecar,
            sidecarFailureMessage: sidecar == .failed ? "boom" : nil
        )
    }

    @Test("Aggregate counts split loaded / missing / failed correctly")
    func aggregateCounts() {
        let report = InjectionReport(results: [
            makeResult(path: "a.html", sidecar: .loaded),
            makeResult(path: "b.html", sidecar: .loaded),
            makeResult(path: "c.html", sidecar: .missing),
            makeResult(path: "d.html", sidecar: .failed),
        ])

        #expect(report.sidecarLoadedCount == 2)
        #expect(report.sidecarMissingCount == 1)
        #expect(report.sidecarFailedCount == 1)
    }

    @Test("Failure rate excludes .missing from the denominator")
    func failureRateExcludesMissing() {
        let report = InjectionReport(results: [
            makeResult(path: "a.html", sidecar: .loaded),
            makeResult(path: "b.html", sidecar: .loaded),
            makeResult(path: "c.html", sidecar: .loaded),
            makeResult(path: "d.html", sidecar: .failed),
            makeResult(path: "e.html", sidecar: .missing),
            makeResult(path: "f.html", sidecar: .missing),
        ])

        // 1 failed / (3 loaded + 1 failed) = 0.25
        #expect(abs(report.sidecarFailureRate - 0.25) < 1e-9)
    }

    @Test("Failure rate is zero when no sidecar attempts resolved")
    func failureRateZeroWithOnlyMissing() {
        let report = InjectionReport(results: [
            makeResult(path: "a.html", sidecar: .missing),
        ])
        #expect(report.sidecarFailureRate == 0.0)
        #expect(report.exceedsSidecarFailureThreshold(0.0) == false)
    }

    @Test("exceedsSidecarFailureThreshold uses strict greater-than")
    func thresholdComparisonIsStrict() {
        let report = InjectionReport(results: [
            makeResult(path: "a.html", sidecar: .loaded),
            makeResult(path: "b.html", sidecar: .failed), // 50% failure rate
        ])
        #expect(report.sidecarFailureRate == 0.5)
        // Equal rate is allowed (strict >).
        #expect(report.exceedsSidecarFailureThreshold(0.5) == false)
        // Just below trips the gate.
        #expect(report.exceedsSidecarFailureThreshold(0.49) == true)
    }
}
