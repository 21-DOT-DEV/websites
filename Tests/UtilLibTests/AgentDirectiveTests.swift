//
//  AgentDirectiveTests.swift
//  UtilLibTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import UtilLib

@Suite("Agent Directive Injector Tests")
struct AgentDirectiveTests {

    let baseURL = URL(string: "https://docs.21.dev")!

    // MARK: - deriveMarkdownRelativePath

    @Test("Derives markdown relative path from index.html")
    func deriveMarkdownRelativePathFromIndex() {
        let path = AgentDirectiveInjector.deriveMarkdownRelativePath(
            from: "documentation/p256k/p256k/context/index.html"
        )
        #expect(path == "data/documentation/p256k/p256k/context.md")
    }

    @Test("Derives markdown relative path from .html")
    func deriveMarkdownRelativePathFromHTML() {
        let path = AgentDirectiveInjector.deriveMarkdownRelativePath(
            from: "documentation/p256k/p256k/signing.html"
        )
        #expect(path == "data/documentation/p256k/p256k/signing.md")
    }

    // MARK: - deriveMarkdownURL

    @Test("Derives markdown URL from index.html path")
    func deriveMarkdownURLFromIndex() {
        let url = AgentDirectiveInjector.deriveMarkdownURL(
            baseURL: baseURL,
            relativePath: "documentation/p256k/p256k/context/index.html"
        )
        #expect(url.absoluteString == "https://docs.21.dev/data/documentation/p256k/p256k/context.md")
    }

    @Test("Derives markdown URL from .html path")
    func deriveMarkdownURLFromHTML() {
        let url = AgentDirectiveInjector.deriveMarkdownURL(
            baseURL: baseURL,
            relativePath: "documentation/p256k/p256k/signing.html"
        )
        #expect(url.absoluteString == "https://docs.21.dev/data/documentation/p256k/p256k/signing.md")
    }

    // MARK: - extractModule

    @Test("Extracts module from documentation path")
    func extractModuleFromPath() {
        let module = AgentDirectiveInjector.extractModule(
            from: "documentation/p256k/p256k/context/index.html"
        )
        #expect(module == "p256k")
    }

    @Test("Extracts zkp module")
    func extractZKPModule() {
        let module = AgentDirectiveInjector.extractModule(
            from: "documentation/zkp/zkp/signing/index.html"
        )
        #expect(module == "zkp")
    }

    @Test("Returns nil for top-level documentation page")
    func extractModuleTopLevel() {
        let module = AgentDirectiveInjector.extractModule(from: "documentation/index.html")
        #expect(module == nil)
    }

    @Test("Returns nil for non-documentation path")
    func extractModuleNonDoc() {
        let module = AgentDirectiveInjector.extractModule(from: "tutorials/index.html")
        #expect(module == nil)
    }

    // MARK: - deriveBreadcrumbs

    @Test("Top-level documentation/index.html produces zero breadcrumbs and API Reference name")
    func breadcrumbsTopLevel() {
        let result = AgentDirectiveInjector.deriveBreadcrumbs(
            from: "documentation/index.html",
            baseURL: baseURL
        )
        #expect(result.items.isEmpty)
        #expect(result.pageName == "API Reference")
    }

    @Test("Module root produces zero breadcrumbs")
    func breadcrumbsModuleRoot() {
        let result = AgentDirectiveInjector.deriveBreadcrumbs(
            from: "documentation/p256k/index.html",
            baseURL: baseURL
        )
        #expect(result.items.isEmpty)
        #expect(result.pageName == "P256K")
    }

    @Test("Non-doubled direct child produces 1 breadcrumb")
    func breadcrumbsDirectChild() {
        let result = AgentDirectiveInjector.deriveBreadcrumbs(
            from: "documentation/p256k/int256/index.html",
            baseURL: baseURL
        )
        #expect(result.items.count == 1)
        #expect(result.items[0].name == "P256K")
        #expect(result.items[0].item?.contains("/documentation/p256k/") == true)
        #expect(result.pageName == "Int256")
    }

    @Test("Article path produces 1 breadcrumb")
    func breadcrumbsArticle() {
        let result = AgentDirectiveInjector.deriveBreadcrumbs(
            from: "documentation/p256k/gettingstarted/index.html",
            baseURL: baseURL
        )
        #expect(result.items.count == 1)
        #expect(result.items[0].name == "P256K")
        #expect(result.pageName == "GettingStarted")
    }

    @Test("Doubled one level deduplicates correctly")
    func breadcrumbsDoubledOneLevel() {
        let result = AgentDirectiveInjector.deriveBreadcrumbs(
            from: "documentation/p256k/p256k/signing/index.html",
            baseURL: baseURL
        )
        #expect(result.items.count == 1)
        #expect(result.items[0].name == "P256K")
        // Breadcrumb URL points to /documentation/p256k/ (canonical path)
        #expect(result.items[0].item?.contains("/documentation/p256k/") == true)
        #expect(result.pageName == "Signing")
    }

    @Test("Doubled two levels produces correct breadcrumbs with canonical URLs")
    func breadcrumbsDoubledTwoLevels() {
        let result = AgentDirectiveInjector.deriveBreadcrumbs(
            from: "documentation/p256k/p256k/signing/privatekey/index.html",
            baseURL: baseURL
        )
        #expect(result.items.count == 2)
        #expect(result.items[0].name == "P256K")
        #expect(result.items[0].item?.contains("/documentation/p256k/") == true)
        #expect(result.items[1].name == "Signing")
        // Signing URL uses canonical DocC path with doubled p256k
        #expect(result.items[1].item?.contains("/documentation/p256k/p256k/signing/") == true)
        #expect(result.pageName == "PrivateKey")
    }

    @Test("Cross-module ZKP path produces correct breadcrumbs")
    func breadcrumbsCrossModule() {
        let result = AgentDirectiveInjector.deriveBreadcrumbs(
            from: "documentation/zkp/p256k/signing/privatekey/index.html",
            baseURL: baseURL
        )
        #expect(result.items.count == 3)
        #expect(result.items[0].name == "ZKP")
        #expect(result.items[1].name == "P256K")
        #expect(result.items[2].name == "Signing")
        #expect(result.pageName == "PrivateKey")
    }

    @Test("Known compound name resolves correctly")
    func breadcrumbsKnownName() {
        let result = AgentDirectiveInjector.deriveBreadcrumbs(
            from: "documentation/p256k/p256k/keyagreement/index.html",
            baseURL: baseURL
        )
        #expect(result.items.count == 1)
        #expect(result.items[0].name == "P256K")
        #expect(result.pageName == "KeyAgreement")
    }

    @Test("Swift symbol with parentheses kept as-is")
    func breadcrumbsParentheses() {
        let result = AgentDirectiveInjector.deriveBreadcrumbs(
            from: "documentation/p256k/p256k/init(rawrepresentation:)/index.html",
            baseURL: baseURL
        )
        #expect(result.items.count == 1)
        #expect(result.items[0].name == "P256K")
        #expect(result.pageName == "init(rawrepresentation:)")
    }

    @Test("Unknown single-word segment uses capitalize-first fallback")
    func breadcrumbsCapitalizeFallback() {
        let result = AgentDirectiveInjector.deriveBreadcrumbs(
            from: "documentation/p256k/p256k/context/index.html",
            baseURL: baseURL
        )
        #expect(result.items.count == 1)
        #expect(result.pageName == "Context")
    }

    @Test("Extended module page swift uses capitalize-first")
    func breadcrumbsExtendedModuleSwift() {
        let result = AgentDirectiveInjector.deriveBreadcrumbs(
            from: "documentation/p256k/swift/index.html",
            baseURL: baseURL
        )
        #expect(result.items.count == 1)
        #expect(result.items[0].name == "P256K")
        #expect(result.pageName == "Swift")
    }

    @Test("Extended module page foundation uses capitalize-first")
    func breadcrumbsExtendedModuleFoundation() {
        let result = AgentDirectiveInjector.deriveBreadcrumbs(
            from: "documentation/p256k/foundation/index.html",
            baseURL: baseURL
        )
        #expect(result.items.count == 1)
        #expect(result.items[0].name == "P256K")
        #expect(result.pageName == "Foundation")
    }

    // MARK: - buildDirective

    @Test("Builds directive with @graph containing WebSite, Organization, and WebPage")
    func buildDirectiveWithGraph() throws {
        let markdownURL = URL(string: "https://docs.21.dev/data/documentation/p256k/p256k/context.md")!
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: markdownURL,
            relativePath: "documentation/p256k/p256k/context/index.html",
            baseURL: baseURL
        )

        // <link rel="llms-txt"> always present
        #expect(directive.contains("rel=\"llms-txt\""))
        #expect(directive.contains("llms.txt"))
        // <link rel="alternate"> for markdown
        #expect(directive.contains("rel=\"alternate\""))
        #expect(directive.contains("type=\"text/markdown\""))
        #expect(directive.contains("context.md"))
        // JSON-LD @graph
        #expect(directive.contains("application/ld+json"))
        #expect(directive.contains("@graph"))
        #expect(directive.contains("WebSite"))
        #expect(directive.contains("WebPage"))
        #expect(directive.contains("docs.21.dev"))
        #expect(directive.contains("isPartOf"))
        // Organization publisher node — anchored to the marketing-site
        // canonical @id so docs and 21.dev resolve to the same entity.
        #expect(directive.contains("Organization"))
        #expect(directive.contains("21.dev\\/#organization"))
        // No mainEntity when no DocC sidecar is supplied
        #expect(!directive.contains("mainEntity"))
        // No MediaObject
        #expect(!directive.contains("MediaObject"))
    }

    @Test("WebSite @id and url use trailing slash before fragment")
    func buildDirectiveWebSiteTrailingSlash() throws {
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/index.html",
            baseURL: baseURL
        )

        // @id must be https://docs.21.dev/#website (trailing slash before fragment)
        #expect(directive.contains("docs.21.dev\\/#website"))
        // url must be https://docs.21.dev/ (with trailing slash)
        #expect(directive.contains("\"url\":\"https:\\/\\/docs.21.dev\\/\""))
    }

    @Test("Builds directive with breadcrumbs when path has depth")
    func buildDirectiveWithBreadcrumbs() throws {
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/p256k/signing/privatekey/index.html",
            baseURL: baseURL
        )

        #expect(directive.contains("BreadcrumbList"))
        #expect(directive.contains("#breadcrumb"))
        #expect(directive.contains("breadcrumb"))
    }

    @Test("Builds directive without breadcrumbs for module root")
    func buildDirectiveNoBreadcrumbs() throws {
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/index.html",
            baseURL: baseURL
        )

        #expect(!directive.contains("BreadcrumbList"))
        // WebSite always present
        #expect(directive.contains("WebSite"))
        #expect(directive.contains("WebPage"))
    }

    @Test("Builds directive with llms-txt link but no alternate when markdown nil")
    func buildDirectiveNoMarkdown() throws {
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/index.html",
            baseURL: baseURL
        )

        // llms-txt always present
        #expect(directive.contains("rel=\"llms-txt\""))
        // No alternate link
        #expect(!directive.contains("rel=\"alternate\""))
        #expect(!directive.contains("text/markdown"))
    }

    @Test("llms-txt link points to module-specific llms.txt for P256K pages")
    func buildDirectiveLlmsTxtP256K() throws {
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/p256k/signing/index.html",
            baseURL: baseURL
        )

        #expect(directive.contains("href=\"https://docs.21.dev/data/documentation/p256k/llms.txt\""))
    }

    @Test("llms-txt link points to module-specific llms.txt for ZKP pages")
    func buildDirectiveLlmsTxtZKP() throws {
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/zkp/p256k/signing/index.html",
            baseURL: baseURL
        )

        #expect(directive.contains("href=\"https://docs.21.dev/data/documentation/zkp/llms.txt\""))
    }

    @Test("llms-txt link points to root llms.txt for documentation/index.html")
    func buildDirectiveLlmsTxtRoot() throws {
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/index.html",
            baseURL: baseURL
        )

        #expect(directive.contains("href=\"https://docs.21.dev/llms.txt\""))
    }

    @Test("WebSite node always present in @graph regardless of breadcrumb count")
    func buildDirectiveWebSiteAlwaysPresent() throws {
        // Module root (0 breadcrumbs)
        let d1 = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/index.html",
            baseURL: baseURL
        )
        #expect(d1.contains("WebSite"))

        // Deep page (2 breadcrumbs)
        let d2 = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/p256k/signing/privatekey/index.html",
            baseURL: baseURL
        )
        #expect(d2.contains("WebSite"))

        // Top-level (0 breadcrumbs)
        let d3 = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/index.html",
            baseURL: baseURL
        )
        #expect(d3.contains("WebSite"))
    }

    // MARK: - inject

    @Test("Injects directive before </head>")
    func injectBeforeHead() {
        let html = "<html><head><title>Test</title></head><body>Content</body></html>"
        let directive = "<script type=\"application/ld+json\">{\"test\":true}</script>"

        let (result, action) = AgentDirectiveInjector.inject(html: html, directive: directive, force: false)

        #expect(action == .injected)
        #expect(result.contains(directive))
        // Verify inserted before </head>
        let directiveIndex = result.range(of: directive)!.lowerBound
        let headEndIndex = result.range(of: "</head>")!.lowerBound
        #expect(directiveIndex < headEndIndex)
    }

    @Test("Skips when JSON-LD directive already exists")
    func skipExistingDirective() {
        let html = """
        <html><head><script type="application/ld+json">{"isPartOf":{"url":"https://docs.21.dev/llms.txt"}}</script></head><body></body></html>
        """
        let directive = "<script type=\"application/ld+json\">{\"new\":true}</script>"

        let (_, action) = AgentDirectiveInjector.inject(html: html, directive: directive, force: false)
        #expect(action == .skipped)
    }

    @Test("Skips when <link rel=alternate> already exists")
    func skipExistingAlternate() {
        let html = """
        <html><head><link rel="alternate" type="text/markdown" href="/docs/page.md" /></head><body></body></html>
        """
        let directive = "<script type=\"application/ld+json\">{\"new\":true}</script>"

        let (_, action) = AgentDirectiveInjector.inject(html: html, directive: directive, force: false)
        #expect(action == .skipped)
    }

    @Test("Skips when legacy <p> directive exists")
    func skipLegacyDirective() {
        let html = """
        <html><head></head><body><p class="agent-directive" aria-hidden="true">Old directive</p></body></html>
        """
        let directive = "<script type=\"application/ld+json\">{\"new\":true}</script>"

        let (_, action) = AgentDirectiveInjector.inject(html: html, directive: directive, force: false)
        #expect(action == .skipped)
    }

    @Test("Skips when llms-txt link already exists")
    func skipExistingLlmsTxt() {
        let html = """
        <html><head><link rel="llms-txt" href="https://docs.21.dev/llms.txt" /></head><body></body></html>
        """
        let directive = "<script type=\"application/ld+json\">{\"new\":true}</script>"

        let (_, action) = AgentDirectiveInjector.inject(html: html, directive: directive, force: false)
        #expect(action == .skipped)
    }

    @Test("Force replaces existing JSON-LD directive")
    func forceReplaceExisting() {
        let html = """
        <html><head><script type="application/ld+json">{"isPartOf":{"url":"old"},"old":true}</script>
        </head><body></body></html>
        """
        let newDirective = "<script type=\"application/ld+json\">{\"isPartOf\":{\"url\":\"new\"},\"new\":true}</script>"

        let (result, action) = AgentDirectiveInjector.inject(html: html, directive: newDirective, force: true)

        #expect(action == .injected)
        #expect(result.contains("\"new\":true"))
        // Old content should be removed
        #expect(!result.contains("\"old\":true"))
    }

    @Test("Force replaces existing <link rel=alternate>, llms-txt, and JSON-LD")
    func forceReplaceAllMarkers() {
        let html = """
        <html><head>
        <link rel="llms-txt" href="https://docs.21.dev/llms.txt" />
        <link rel="alternate" type="text/markdown" href="/old.md" />
        <script type="application/ld+json">{"isPartOf":{"url":"old"}}</script>
        </head><body></body></html>
        """
        let newDirective = "<link rel=\"llms-txt\" href=\"https://docs.21.dev/llms.txt\" />\n<link rel=\"alternate\" type=\"text/markdown\" href=\"/new.md\" />\n<script type=\"application/ld+json\">{\"isPartOf\":{\"url\":\"new\"}}</script>"

        let (result, action) = AgentDirectiveInjector.inject(html: html, directive: newDirective, force: true)

        #expect(action == .injected)
        #expect(result.contains("new.md"))
        #expect(!result.contains("old.md"))
        #expect(result.contains("\"url\":\"new\""))
    }

    @Test("Force on old AgentDirectiveWebPage format removes mainEntity and adds llms-txt")
    func forceReplaceOldFormat() {
        // Real old format output has isPartOf AND mainEntity, but no <link rel="llms-txt">
        let oldJsonLd = "{\"@context\":\"https://schema.org\",\"@type\":\"WebPage\",\"isPartOf\":{\"@type\":\"WebSite\",\"name\":\"P256K Module\",\"url\":\"https://docs.21.dev/data/documentation/p256k/llms.txt\"},\"mainEntity\":{\"@type\":\"WebSite\",\"url\":\"https://docs.21.dev/llms.txt\"}}"
        let html = """
        <html><head>
        <link rel="alternate" type="text/markdown" href="/old.md" />
        <script type="application/ld+json">\(oldJsonLd)</script>
        </head><body></body></html>
        """
        let newDirective = "<link rel=\"llms-txt\" href=\"https://docs.21.dev/llms.txt\" />\n<script type=\"application/ld+json\">{\"@graph\":[{\"isPartOf\":{}}]}</script>"

        let (result, action) = AgentDirectiveInjector.inject(html: html, directive: newDirective, force: true)

        #expect(action == .injected)
        // Old mainEntity removed
        #expect(!result.contains("mainEntity"))
        // New llms-txt link added
        #expect(result.contains("rel=\"llms-txt\""))
        // New format has @graph
        #expect(result.contains("@graph"))
    }

    @Test("Force replaces legacy <p> directive with JSON-LD")
    func forceReplaceLegacy() {
        let html = """
        <html><head></head><body><p class="agent-directive" aria-hidden="true">STOP! Old verbose directive</p></body></html>
        """
        let newDirective = "<script type=\"application/ld+json\">{\"isPartOf\":{\"url\":\"test\"}}</script>"

        let (result, action) = AgentDirectiveInjector.inject(html: html, directive: newDirective, force: true)

        #expect(action == .injected)
        #expect(result.contains("application/ld+json"))
        #expect(!result.contains("agent-directive"))
        #expect(!result.contains("STOP!"))
    }

    @Test("Fails when no </head> tag present")
    func failsWithoutHead() {
        let html = "<html><body>No head tag</body></html>"
        let directive = "<script type=\"application/ld+json\">{}</script>"

        let (_, action) = AgentDirectiveInjector.inject(html: html, directive: directive, force: false)
        #expect(action == .failed)
    }

    // MARK: - knownNames snapshot validation

    // MARK: - noindex allowlist

    @Test("normalizePathForAllowlist strips index.html")
    func normalizePathIndex() {
        let result = AgentDirectiveInjector.normalizePathForAllowlist(
            "documentation/p256k/p256k/signing/index.html"
        )
        #expect(result == "documentation/p256k/p256k/signing")
    }

    @Test("normalizePathForAllowlist strips .html extension")
    func normalizePathExtension() {
        let result = AgentDirectiveInjector.normalizePathForAllowlist(
            "documentation/p256k/int256.html"
        )
        #expect(result == "documentation/p256k/int256")
    }

    @Test("normalizePathForAllowlist lowercases path")
    func normalizePathLowercase() {
        let result = AgentDirectiveInjector.normalizePathForAllowlist(
            "Documentation/P256K/Int256.html"
        )
        #expect(result == "documentation/p256k/int256")
    }

    @Test("shouldIndex returns true for allowlisted page")
    func shouldIndexAllowlisted() {
        #expect(AgentDirectiveInjector.shouldIndex(
            relativePath: "documentation/p256k/p256k/signing/index.html"
        ))
    }

    @Test("shouldIndex returns false for non-allowlisted page")
    func shouldIndexNonAllowlisted() {
        #expect(!AgentDirectiveInjector.shouldIndex(
            relativePath: "documentation/p256k/p256k/signing/xonlykey/index.html"
        ))
    }

    @Test("shouldIndex returns true for documentation root (docs.21.dev landing)")
    func shouldIndexDocumentationRoot() {
        #expect(AgentDirectiveInjector.shouldIndex(
            relativePath: "documentation/index.html"
        ))
    }

    @Test("shouldIndex returns true for P256K namespace-enum Topics hub")
    func shouldIndexP256KNamespaceHub() {
        #expect(AgentDirectiveInjector.shouldIndex(
            relativePath: "documentation/p256k/p256k/index.html"
        ))
    }

    @Test("shouldIndex returns false for operator pages")
    func shouldIndexOperatorPage() {
        #expect(!AgentDirectiveInjector.shouldIndex(
            relativePath: "documentation/p256k/p256k/signing/publickey/==(_:_:)/index.html"
        ))
    }

    @Test("buildDirective includes noindex tag when shouldIndex is false")
    func buildDirectiveNoindex() throws {
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/p256k/signing/xonlykey/index.html",
            baseURL: baseURL,
            shouldIndex: false
        )
        #expect(directive.contains("name=\"robots\""))
        #expect(directive.contains("noindex, follow"))
    }

    @Test("buildDirective omits noindex tag when shouldIndex is true")
    func buildDirectiveIndexable() throws {
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: nil,
            relativePath: "documentation/p256k/p256k/signing/index.html",
            baseURL: baseURL,
            shouldIndex: true
        )
        #expect(!directive.contains("name=\"robots\""))
    }

    @Test("inject with force removes existing noindex tag via exact match")
    func forceReplacesNoindex() {
        let html = """
        <html><head>
        <meta name="robots" content="noindex, follow">
        <link rel="llms-txt" href="https://docs.21.dev/llms.txt" />
        </head><body></body></html>
        """
        let (result, action) = AgentDirectiveInjector.inject(
            html: html, directive: "<link rel=\"llms-txt\" href=\"test\" />", force: true
        )
        #expect(action == .injected)
        let noindexCount = result.components(separatedBy: "name=\"robots\"").count - 1
        #expect(noindexCount == 0)
    }

    @Test("inject skips file with existing noindex when not forcing")
    func skipsExistingNoindex() {
        let html = """
        <html><head>
        <meta name="robots" content="noindex, follow">
        </head><body></body></html>
        """
        let (_, action) = AgentDirectiveInjector.inject(
            html: html, directive: "test", force: false
        )
        #expect(action == .skipped)
    }

    @Test("Allowlist has exactly 130 entries (2 hub + 23 P256K llms.txt + 52 Discussion + 29 authored + 10 Event llms.txt + 12 OpenSSL llms.txt + 2 ZKP authored)")
    func allowlistCompleteness() {
        #expect(AgentDirectiveInjector.indexablePages.count == 130)

        // Spot-check hub pages
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/p256k"))

        // Spot-check P256K llms.txt entries
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/gettingstarted"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/p256k/signing"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/p256k/signing/privatekey"))

        // Spot-check newly-added authored articles (added in PR fb0c08)
        // ellipticcurvediffiehellman + silentpayments are first shipped in
        // swift-secp256k1 0.23.1-prerelease-3.
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/ellipticcurvediffiehellman"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/silentpayments"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/tweakingkeys"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/musig2multisignatures"))

        // Spot-check Discussion audit entries
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/p256k/context/rawrepresentation"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/p256k/schnorr/privatekey/signature(for:)"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/sha256/taggedhash(tag:data:)"))

        // Spot-check authored Parameters/Return Value/aside entries
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/p256k/signing/publickey/isvalidsignature(_:for:)-7sttb"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/p256k/recovery/publickey/init(_:signature:format:)-4311g"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/p256k/sha256/hash(data:)"))

        // Spot-check Event llms.txt entries
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/event"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/event/gettingstarted"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/event/eventloop"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/event/socketerror"))

        // Spot-check OpenSSL llms.txt entries
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/openssl"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/openssl/gettingstarted"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/openssl/sha256"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/openssl/rsa/privatekey"))

        // ZKP-unique authored articles allowlisted (module overview + product-selection guide)
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/zkp"))
        #expect(AgentDirectiveInjector.indexablePages.contains("documentation/zkp/choosingp256kvszkp"))

        // ZKP symbol pages still excluded — they re-export P256K and would be SEO dupes
        #expect(!AgentDirectiveInjector.indexablePages.contains("documentation/zkp/p256k/signing"))
        #expect(!AgentDirectiveInjector.indexablePages.contains("documentation/zkp/p256k/schnorr/privatekey"))

        // Protocol conformance stubs excluded (no authored content)
        #expect(!AgentDirectiveInjector.indexablePages.contains("documentation/p256k/p256k/signing/privatekey/==(_:_:)"))
        #expect(!AgentDirectiveInjector.indexablePages.contains("documentation/p256k/p256k/signing/ecdsasignature/withunsafebytes(_:)"))
    }

    @Test("force-reinject removes existing noindex without over-deleting adjacent tags")
    func forceReinjectPreservesAdjacentTags() {
        let html = """
        <html><head>
        <meta name="robots" content="noindex, follow">
        <link rel="llms-txt" href="https://docs.21.dev/llms.txt" />
        </head><body></body></html>
        """
        let newDirective = "<link rel=\"llms-txt\" href=\"https://docs.21.dev/llms.txt\" />"
        let (result, action) = AgentDirectiveInjector.inject(
            html: html, directive: newDirective, force: true
        )
        #expect(action == .injected)
        #expect(!result.contains("name=\"robots\""))
        #expect(result.contains("rel=\"llms-txt\""))
    }

    // MARK: - knownNames snapshot validation

    @Test("Every multi-word compound segment in snapshot has a knownNames entry")
    func knownNamesSnapshotCompleteness() throws {
        // Load the checked-in snapshot of all DocC URL segments
        let snapshotPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Tests/UtilLibTests/
            .appendingPathComponent("Fixtures/known-segments.txt")
            .path

        let content = try String(contentsOfFile: snapshotPath, encoding: .utf8)
        let segments = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }

        // A segment is "multi-word compound" if it contains more than one
        // logical word — detected by having a lowercase letter followed by
        // an uppercase letter (camelCase when properly cased) or by being
        // a known compound in the knownNames map.
        // Simple heuristic: if capitalize-first would NOT produce the correct
        // name, the segment MUST be in knownNames.
        let knownNames = AgentDirectiveInjector.knownNames
        var missing: [String] = []

        for segment in segments {
            if knownNames[segment] != nil {
                // Entry exists in knownNames — correctly mapped
            } else {
                // Not in knownNames. Check if it's a multi-word compound where
                // capitalize-first fallback would produce wrong casing.
                // Use known word-boundary patterns that indicate compound names.
                let compoundSuffixes = ["key", "secret", "digest", "error", "signature",
                                        "proof", "started", "only", "kit"]
                let isLikelyCompound = compoundSuffixes.contains(where: { suffix in
                    segment.hasSuffix(suffix) && segment != suffix
                })

                if isLikelyCompound {
                    missing.append(segment)
                }
            }
        }

        #expect(missing.isEmpty, "Segments missing from knownNames: \(missing). Add entries to AgentDirectiveInjector.knownNames.")
    }
}
