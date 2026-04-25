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

    @Test("Article sidecar emits TechArticle node and bidirectional refs")
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

        // Article-class node is present.
        #expect(directive.contains("TechArticle"))
        // WebPage gets a back-reference to the TechArticle.
        #expect(directive.contains("mainEntity"))
        #expect(directive.contains("#techarticle"))
        // Article carries the canonical publisher @id pointer.
        #expect(directive.contains("21.dev\\/#organization"))
        // Title is sourced from the sidecar, not the slug fallback.
        #expect(directive.contains("Choosing Between P256K and ZKP"))
        #expect(directive.contains("Pick the right product"))
        // No APIReference for an authored article.
        #expect(!directive.contains("APIReference"))
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
}

// MARK: - buildDirective(sidecar:) — Symbol / Collection roles

@Suite("AgentDirectiveInjector — APIReference wiring")
struct AgentDirectiveAPIReferenceTests {

    @Test("Symbol sidecar emits APIReference with Swift / repo / module")
    func symbolEmitsAPIReference() throws {
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

        #expect(directive.contains("APIReference"))
        #expect(directive.contains("#apireference"))
        #expect(directive.contains("\"programmingLanguage\":\"Swift\""))
        #expect(directive.contains("21-DOT-DEV\\/swift-secp256k1"))
        #expect(directive.contains("\"about\":\"P256K\""))
        // WebPage has a mainEntity ref to the APIReference node.
        #expect(directive.contains("mainEntity"))
        // No TechArticle for a symbol page.
        #expect(!directive.contains("TechArticle"))
    }

    @Test("Collection (module overview) sidecar also emits APIReference")
    func collectionEmitsAPIReference() throws {
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

        #expect(directive.contains("APIReference"))
        #expect(directive.contains("21-DOT-DEV\\/swift-secp256k1"))
    }

    @Test("APIReference for ZKP module routes to swift-secp256k1 repo")
    func zkpRepoMapping() throws {
        let sidecar = try makeSidecar(
            title: "ZKP",
            role: "collection",
            module: "ZKP"
        )

        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/zkp/index.html",
            baseURL: docsBaseURL,
            sidecar: sidecar
        )
        #expect(directive.contains("21-DOT-DEV\\/swift-secp256k1"))
    }

    @Test("APIReference for Event module routes to swift-event repo")
    func eventRepoMapping() throws {
        let sidecar = try makeSidecar(
            title: "Event",
            role: "collection",
            module: "Event"
        )

        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/event/index.html",
            baseURL: docsBaseURL,
            sidecar: sidecar
        )
        #expect(directive.contains("21-DOT-DEV\\/swift-event"))
    }

    @Test("Unknown module yields no codeRepository field")
    func unknownModuleHasNoRepository() throws {
        let sidecar = try makeSidecar(
            title: "Mystery",
            role: "collection",
            module: "Mystery"
        )

        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/mystery/index.html",
            baseURL: docsBaseURL,
            sidecar: sidecar
        )
        #expect(directive.contains("APIReference"))
        // codeRepository is omitted (encodeIfPresent) — no swift-* token.
        #expect(!directive.contains("\"codeRepository\""))
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

        #expect(!directive.contains("TechArticle"))
        #expect(!directive.contains("APIReference"))
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

        #expect(!directive.contains("TechArticle"))
        #expect(!directive.contains("APIReference"))
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
        #expect(!directive.contains("TechArticle"))
        #expect(!directive.contains("APIReference"))
    }
}

// MARK: - codeRepository(forModule:) helper

@Suite("AgentDirectiveInjector.codeRepository helper")
struct AgentDirectiveCodeRepositoryTests {

    @Test("Maps p256k and zkp to swift-secp256k1 (case-insensitive)")
    func p256kAndZkpMapToSecp256k1() {
        #expect(AgentDirectiveInjector.codeRepository(forModule: "P256K")?.hasSuffix("swift-secp256k1") == true)
        #expect(AgentDirectiveInjector.codeRepository(forModule: "p256k")?.hasSuffix("swift-secp256k1") == true)
        #expect(AgentDirectiveInjector.codeRepository(forModule: "ZKP")?.hasSuffix("swift-secp256k1") == true)
    }

    @Test("Maps event to swift-event")
    func eventMapping() {
        #expect(AgentDirectiveInjector.codeRepository(forModule: "Event")?.hasSuffix("swift-event") == true)
    }

    @Test("Maps openssl to swift-openssl")
    func opensslMapping() {
        #expect(AgentDirectiveInjector.codeRepository(forModule: "OpenSSL")?.hasSuffix("swift-openssl") == true)
    }

    @Test("Returns nil for unknown / nil module")
    func unknownReturnsNil() {
        #expect(AgentDirectiveInjector.codeRepository(forModule: nil) == nil)
        #expect(AgentDirectiveInjector.codeRepository(forModule: "Unknown") == nil)
        #expect(AgentDirectiveInjector.codeRepository(forModule: "") == nil)
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
