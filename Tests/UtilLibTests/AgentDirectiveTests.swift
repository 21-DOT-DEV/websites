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

    @Test("Returns nil for non-documentation path")
    func extractModuleNonDoc() {
        let module = AgentDirectiveInjector.extractModule(from: "tutorials/index.html")
        #expect(module == nil)
    }

    // MARK: - buildDirective

    @Test("Builds JSON-LD directive with module")
    func buildDirectiveWithModule() throws {
        let markdownURL = URL(string: "https://docs.21.dev/data/documentation/p256k/p256k/context.md")!
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: markdownURL,
            module: "p256k",
            baseURL: baseURL
        )

        #expect(directive.hasPrefix("<script type=\"application/ld+json\">"))
        #expect(directive.hasSuffix("</script>"))
        #expect(directive.contains("text/markdown") || directive.contains("text\\/markdown"))
        #expect(directive.contains("context.md"))
        #expect(directive.contains("p256k"))
        #expect(directive.contains("llms.txt"))
        #expect(directive.contains("schema.org"))
        #expect(directive.contains("WebPage"))
    }

    @Test("Builds JSON-LD directive without module falls back to root llms.txt")
    func buildDirectiveWithoutModule() throws {
        let markdownURL = URL(string: "https://docs.21.dev/data/documentation/overview.md")!
        let directive = try AgentDirectiveInjector.buildDirective(
            markdownURL: markdownURL,
            module: nil,
            baseURL: baseURL
        )

        // Both isPartOf and mainEntity should point to root llms.txt
        let llmsCount = directive.components(separatedBy: "llms.txt").count - 1
        #expect(llmsCount >= 2)
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
        <html><head><script type="application/ld+json">{"encodingFormat":"text/markdown"}</script></head><body></body></html>
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

    @Test("Force replaces existing JSON-LD directive")
    func forceReplaceExisting() {
        let html = """
        <html><head><script type="application/ld+json">{"encodingFormat":"text/markdown","old":true}</script>
        </head><body></body></html>
        """
        let newDirective = "<script type=\"application/ld+json\">{\"encodingFormat\":\"text/markdown\",\"new\":true}</script>"

        let (result, action) = AgentDirectiveInjector.inject(html: html, directive: newDirective, force: true)

        #expect(action == .injected)
        #expect(result.contains("\"new\":true"))
        // Old content should be removed
        #expect(!result.contains("\"old\":true"))
    }

    @Test("Force replaces legacy <p> directive with JSON-LD")
    func forceReplaceLegacy() {
        let html = """
        <html><head></head><body><p class="agent-directive" aria-hidden="true">STOP! Old verbose directive</p></body></html>
        """
        let newDirective = "<script type=\"application/ld+json\">{\"encodingFormat\":\"text/markdown\"}</script>"

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
}
