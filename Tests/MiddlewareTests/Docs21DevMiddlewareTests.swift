//
//  Docs21DevMiddlewareTests.swift
//  MiddlewareTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import JavaScriptCore
import Testing

@Suite("docs-21-dev Middleware Tests")
struct Docs21DevMiddlewareTests {
    let ctx: JSContext

    init() throws {
        let context = JSContext()!
        context.exceptionHandler = { _, exception in
            Issue.record("JS exception: \(exception!)")
        }
        let jsPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Tests/MiddlewareTests/
            .deletingLastPathComponent() // Tests/
            .deletingLastPathComponent() // repo root
            .appendingPathComponent("Resources/docs-21-dev/functions/logic.js")
            .path
        guard FileManager.default.fileExists(atPath: jsPath) else {
            Issue.record("logic.js not found at \(jsPath) \u{2014} did the test file move?")
            ctx = context
            return
        }
        var source = try String(contentsOfFile: jsPath, encoding: .utf8)
        source = source.replacingOccurrences(
            of: #"(?m)^export "#,
            with: "",
            options: .regularExpression
        )
        context.evaluateScript(source)
        ctx = context
    }

    // MARK: - CACHE_TTL_SECONDS

    @Test("CACHE_TTL_SECONDS is 3600")
    func cacheTtlValue() {
        let result = ctx.evaluateScript("CACHE_TTL_SECONDS")!
        #expect(result.toInt32() == 3600)
    }

    @Test("buildMarkdownHeaders uses CACHE_TTL_SECONDS")
    func headersCacheTtlConsistency() {
        let result = ctx.evaluateScript("buildMarkdownHeaders(0)")!
        let dict = result.toDictionary() as! [String: Any]
        let cacheControl = dict["Cache-Control"] as? String ?? ""
        let ttl = ctx.evaluateScript("CACHE_TTL_SECONDS")!.toInt32()
        #expect(cacheControl.contains("max-age=\(ttl)"))
    }

    // MARK: - resolveCountry

    @Test("Resolves country from header value")
    func resolveCountryPresent() {
        let result = ctx.evaluateScript("resolveCountry('US')")!
        #expect(result.toString() == "US")
    }

    @Test("Returns unknown for null header")
    func resolveCountryNull() {
        let result = ctx.evaluateScript("resolveCountry(null)")!
        #expect(result.toString() == "unknown")
    }

    @Test("Returns unknown for empty string header")
    func resolveCountryEmpty() {
        let result = ctx.evaluateScript("resolveCountry('')")!
        #expect(result.toString() == "unknown")
    }

    @Test("Returns unknown for undefined header")
    func resolveCountryUndefined() {
        let result = ctx.evaluateScript("resolveCountry(undefined)")!
        #expect(result.toString() == "unknown")
    }

    // MARK: - resolveRedirect

    @Test("Redirects pages.dev to docs.21.dev")
    func redirectPagesDev() {
        let result = ctx.evaluateScript("resolveRedirect('docs-21-dev.pages.dev')")!
        let dict = result.toDictionary() as! [String: Any]
        #expect(dict["redirect"] as? Bool == true)
        #expect(dict["target"] as? String == "docs.21.dev")
    }

    @Test("Passes through docs.21.dev hostname")
    func passthroughCustomDomain() {
        let result = ctx.evaluateScript("resolveRedirect('docs.21.dev')")!
        let dict = result.toDictionary() as! [String: Any]
        #expect(dict["redirect"] as? Bool == false)
        #expect(dict["target"] as? String == "docs.21.dev")
    }

    // MARK: - resolveMarkdownPath

    @Test("Root path maps to llms.txt")
    func resolvePathRoot() {
        let result = ctx.evaluateScript("resolveMarkdownPath('/')")!
        #expect(result.toString() == "/llms.txt")
    }

    @Test("/documentation maps to llms.txt")
    func resolvePathDocumentation() {
        let result = ctx.evaluateScript("resolveMarkdownPath('/documentation')")!
        #expect(result.toString() == "/llms.txt")
    }

    @Test("/documentation/ maps to llms.txt")
    func resolvePathDocumentationTrailingSlash() {
        let result = ctx.evaluateScript("resolveMarkdownPath('/documentation/')")!
        #expect(result.toString() == "/llms.txt")
    }

    @Test("Module path with trailing slash maps to .md")
    func resolvePathModuleTrailingSlash() {
        let result = ctx.evaluateScript("resolveMarkdownPath('/documentation/p256k/')")!
        #expect(result.toString() == "/data/documentation/p256k.md")
    }

    @Test("Module path without trailing slash maps to .md")
    func resolvePathModuleNoSlash() {
        let result = ctx.evaluateScript("resolveMarkdownPath('/documentation/p256k')")!
        #expect(result.toString() == "/data/documentation/p256k.md")
    }

    @Test("index.html path maps to .md")
    func resolvePathIndexHtml() {
        let result = ctx.evaluateScript("resolveMarkdownPath('/documentation/p256k/index.html')")!
        #expect(result.toString() == "/data/documentation/p256k.md")
    }

    @Test(".html path maps to .md")
    func resolvePathHtml() {
        let result = ctx.evaluateScript("resolveMarkdownPath('/documentation/p256k/p256k/signing.html')")!
        #expect(result.toString() == "/data/documentation/p256k/p256k/signing.md")
    }

    @Test("Non-documentation path maps to /data prefix")
    func resolvePathFavicon() {
        let result = ctx.evaluateScript("resolveMarkdownPath('/favicon.ico')")!
        #expect(result.toString() == "/data/favicon.ico.md")
    }

    @Test("CSS path maps to /data prefix")
    func resolvePathCss() {
        let result = ctx.evaluateScript("resolveMarkdownPath('/css/index.css')")!
        #expect(result.toString() == "/data/css/index.css.md")
    }

    @Test("/llms.txt itself maps to /data prefix")
    func resolvePathLlmsTxt() {
        let result = ctx.evaluateScript("resolveMarkdownPath('/llms.txt')")!
        #expect(result.toString() == "/data/llms.txt.md")
    }

    @Test("Mixed-case path normalised to lowercase")
    func resolvePathCaseNormalization() {
        let result = ctx.evaluateScript("resolveMarkdownPath('/documentation/P256K/P256K/Signing/PublicKey')")!
        #expect(result.toString() == "/data/documentation/p256k/p256k/signing/publickey.md")
    }

    @Test("Mixed-case /Documentation maps to llms.txt")
    func resolvePathCaseNormalizationIndex() {
        let result = ctx.evaluateScript("resolveMarkdownPath('/Documentation')")!
        #expect(result.toString() == "/llms.txt")
    }

    @Test("Mixed-case .html path normalised to lowercase .md")
    func resolvePathCaseNormalizationHtml() {
        let result = ctx.evaluateScript("resolveMarkdownPath('/Documentation/P256K/Signing.html')")!
        #expect(result.toString() == "/data/documentation/p256k/signing.md")
    }

    // MARK: - isValidMarkdownResponse

    @Test("text/html is not valid markdown response")
    func invalidHtml() {
        let result = ctx.evaluateScript("isValidMarkdownResponse('text/html')")!
        #expect(result.toBool() == false)
    }

    @Test("text/html with charset is not valid markdown response")
    func invalidHtmlCharset() {
        let result = ctx.evaluateScript("isValidMarkdownResponse('text/html; charset=utf-8')")!
        #expect(result.toBool() == false)
    }

    @Test("application/octet-stream is valid markdown response")
    func validOctetStream() {
        let result = ctx.evaluateScript("isValidMarkdownResponse('application/octet-stream')")!
        #expect(result.toBool() == true)
    }

    @Test("Empty content type is valid markdown response")
    func validEmpty() {
        let result = ctx.evaluateScript("isValidMarkdownResponse('')")!
        #expect(result.toBool() == true)
    }

    @Test("text/markdown is valid markdown response")
    func validTextMarkdown() {
        let result = ctx.evaluateScript("isValidMarkdownResponse('text/markdown')")!
        #expect(result.toBool() == true)
    }

    @Test("text/markdown with charset is valid markdown response")
    func validTextMarkdownCharset() {
        let result = ctx.evaluateScript("isValidMarkdownResponse('text/markdown; charset=utf-8')")!
        #expect(result.toBool() == true)
    }

    // MARK: - wantsMarkdown

    @Test("Accept header with text/markdown returns true")
    func wantsMarkdownTrue() {
        let result = ctx.evaluateScript("wantsMarkdown('text/markdown')")!
        #expect(result.toBool() == true)
    }

    @Test("Accept header with text/markdown among others returns true")
    func wantsMarkdownMixed() {
        let result = ctx.evaluateScript("wantsMarkdown('text/html, text/markdown')")!
        #expect(result.toBool() == true)
    }

    @Test("Accept header without text/markdown returns false")
    func wantsMarkdownFalse() {
        let result = ctx.evaluateScript("wantsMarkdown('text/html, application/json')")!
        #expect(result.toBool() == false)
    }

    @Test("Empty Accept header returns false")
    func wantsMarkdownEmpty() {
        let result = ctx.evaluateScript("wantsMarkdown('')")!
        #expect(result.toBool() == false)
    }

    // MARK: - buildMarkdownHeaders

    @Test("Builds correct Content-Type header")
    func headersContentType() {
        let result = ctx.evaluateScript("buildMarkdownHeaders(42)")!
        let dict = result.toDictionary() as! [String: Any]
        #expect(dict["Content-Type"] as? String == "text/markdown; charset=utf-8")
    }

    @Test("Builds correct X-Markdown-Tokens header")
    func headersTokenCount() {
        let result = ctx.evaluateScript("buildMarkdownHeaders(42)")!
        let dict = result.toDictionary() as! [String: Any]
        #expect(dict["X-Markdown-Tokens"] as? String == "42")
    }

    @Test("Builds correct Content-Signal header")
    func headersContentSignal() {
        let result = ctx.evaluateScript("buildMarkdownHeaders(0)")!
        let dict = result.toDictionary() as! [String: Any]
        #expect(dict["Content-Signal"] as? String == "ai-input=yes, search=yes, ai-train=yes")
    }

    @Test("Builds correct Cache-Control header")
    func headersCacheControl() {
        let result = ctx.evaluateScript("buildMarkdownHeaders(0)")!
        let dict = result.toDictionary() as! [String: Any]
        #expect(dict["Cache-Control"] as? String == "public, max-age=3600")
    }

    @Test("Builds correct Vary header")
    func buildMarkdownHeadersVary() {
        let js = "buildMarkdownHeaders(100)"
        let dict = ctx.evaluateScript(js)!.toDictionary() as! [String: Any]
        #expect(dict["Vary"] as? String == "Accept")
    }

    @Test("Builds correct Link header (catalog relations only) for markdown response")
    func buildMarkdownHeadersLink() {
        let js = "buildMarkdownHeaders(100)"
        let dict = ctx.evaluateScript(js)!.toDictionary() as! [String: Any]
        let link = dict["Link"] as? String ?? ""
        #expect(link.contains(#"</llms.txt>; rel="llms-txt""#))
        #expect(link.contains(#"</llms-full.txt>; rel="llms-full-txt""#))
        // Markdown response should NOT include per-page alternate/canonical
        // (it IS the alternate, and canonical lives on the HTML response).
        #expect(!link.contains(#"rel="alternate""#))
        #expect(!link.contains(#"rel="canonical""#))
    }

    @Test("Builds correct X-Llms-Txt header for markdown response")
    func buildMarkdownHeadersXLlmsTxt() {
        let js = "buildMarkdownHeaders(100)"
        let dict = ctx.evaluateScript(js)!.toDictionary() as! [String: Any]
        #expect(dict["X-Llms-Txt"] as? String == "/llms.txt")
    }

    // MARK: - formatAnalyticsPayload

    @Test("Formats blobs with normalizedPath in position 0")
    func payloadBlobs() {
        let js = """
        JSON.stringify(formatAnalyticsPayload({
            requestedPath: '/docs/P256K',
            normalizedPath: '/docs/p256k',
            resolvedPath: '/data/docs/p256k.md',
            outcome: 'served',
            accept: 'text/markdown',
            userAgent: 'TestBot/1.0',
            country: 'US',
            tokens: 100,
            chars: 500
        }).blobs)
        """
        let result = ctx.evaluateScript(js)!.toString()!
        let expected = #"["/docs/p256k","/data/docs/p256k.md","served","text/markdown","TestBot/1.0","US"]"#
        #expect(result == expected)
    }

    @Test("Formats doubles as [1, tokens, chars]")
    func payloadDoubles() {
        let js = """
        JSON.stringify(formatAnalyticsPayload({
            requestedPath: '/', normalizedPath: '/', resolvedPath: '/llms.txt', outcome: 'served',
            accept: '', userAgent: '', country: 'DE',
            tokens: 42, chars: 200
        }).doubles)
        """
        let result = ctx.evaluateScript(js)!.toString()!
        #expect(result == "[1,42,200]")
    }

    @Test("Formats indexes as [requestedPath] preserving original case")
    func payloadIndexes() {
        let js = """
        JSON.stringify(formatAnalyticsPayload({
            requestedPath: '/docs/ZKP', normalizedPath: '/docs/zkp', resolvedPath: '/data/docs/zkp.md', outcome: 'miss',
            accept: '', userAgent: '', country: '',
            tokens: 0, chars: 0
        }).indexes)
        """
        let result = ctx.evaluateScript(js)!.toString()!
        #expect(result == #"["/docs/ZKP"]"#)
    }

    @Test("Truncates accept to 256 characters")
    func payloadAcceptTruncation() {
        let longAccept = String(repeating: "a", count: 300)
        let js = """
        formatAnalyticsPayload({
            requestedPath: '/', normalizedPath: '/', resolvedPath: '/', outcome: 'miss',
            accept: '\(longAccept)', userAgent: '', country: '',
            tokens: 0, chars: 0
        }).blobs[3].length
        """
        let result = ctx.evaluateScript(js)!.toInt32()
        #expect(result == 256)
    }

    @Test("Truncates userAgent to 512 characters")
    func payloadUserAgentTruncation() {
        let longUA = String(repeating: "b", count: 600)
        let js = """
        formatAnalyticsPayload({
            requestedPath: '/', normalizedPath: '/', resolvedPath: '/', outcome: 'miss',
            accept: '', userAgent: '\(longUA)', country: '',
            tokens: 0, chars: 0
        }).blobs[4].length
        """
        let result = ctx.evaluateScript(js)!.toInt32()
        #expect(result == 512)
    }

    // MARK: - estimateTokens

    @Test("Estimates tokens from two-word text")
    func estimateTokensTwoWords() {
        let result = ctx.evaluateScript("estimateTokens('hello world')")!
        #expect(result.toInt32() == 2)
    }

    @Test("Estimates tokens from empty string")
    func estimateTokensEmpty() {
        let result = ctx.evaluateScript("estimateTokens('')")!
        #expect(result.toInt32() == 0)
    }

    @Test("Estimates tokens from whitespace-only string")
    func estimateTokensWhitespace() {
        let result = ctx.evaluateScript("estimateTokens('   ')")!
        #expect(result.toInt32() == 0)
    }

    // MARK: - etagHeader

    @Test("etagHeader wraps hash in W/\"...\" weak format")
    func etagHeaderFormat() {
        let result = ctx.evaluateScript("etagHeader('abc123')")!
        #expect(result.toString() == "W/\"abc123\"")
    }

    @Test("etagHeader handles empty hash")
    func etagHeaderEmpty() {
        let result = ctx.evaluateScript("etagHeader('')")!
        #expect(result.toString() == "W/\"\"")
    }

    // MARK: - etagMatches

    @Test("etagMatches returns false when If-None-Match is null")
    func etagMatchesNull() {
        let result = ctx.evaluateScript("etagMatches('W/\"abc\"', null)")!
        #expect(result.toBool() == false)
    }

    @Test("etagMatches returns false when If-None-Match is empty string")
    func etagMatchesEmpty() {
        let result = ctx.evaluateScript("etagMatches('W/\"abc\"', '')")!
        #expect(result.toBool() == false)
    }

    @Test("etagMatches returns true for wildcard *")
    func etagMatchesWildcard() {
        let result = ctx.evaluateScript("etagMatches('W/\"abc\"', '*')")!
        #expect(result.toBool() == true)
    }

    @Test("etagMatches returns true for identical weak ETags")
    func etagMatchesWeakIdentical() {
        let result = ctx.evaluateScript("etagMatches('W/\"abc\"', 'W/\"abc\"')")!
        #expect(result.toBool() == true)
    }

    @Test("etagMatches uses weak comparison: weak server vs strong client")
    func etagMatchesWeakComparison() {
        // RFC 9110 §13.1.3: If-None-Match MUST use weak comparison
        let result = ctx.evaluateScript("etagMatches('W/\"abc\"', '\"abc\"')")!
        #expect(result.toBool() == true)
    }

    @Test("etagMatches finds match in comma-separated list")
    func etagMatchesList() {
        let result = ctx.evaluateScript("etagMatches('W/\"abc\"', 'W/\"xxx\", W/\"abc\", W/\"yyy\"')")!
        #expect(result.toBool() == true)
    }

    @Test("etagMatches returns false for unrelated hash")
    func etagMatchesNoMatch() {
        let result = ctx.evaluateScript("etagMatches('W/\"abc\"', 'W/\"xyz\"')")!
        #expect(result.toBool() == false)
    }

    @Test("etagMatches handles whitespace around list entries")
    func etagMatchesWhitespace() {
        let result = ctx.evaluateScript("etagMatches('W/\"abc\"', '  W/\"xxx\"  ,   W/\"abc\"   ')")!
        #expect(result.toBool() == true)
    }

    // MARK: - buildNotModifiedHeaders

    @Test("buildNotModifiedHeaders includes ETag")
    func buildNotModifiedIncludesETag() {
        let js = "buildNotModifiedHeaders('W/\"abc\"', {})"
        let dict = ctx.evaluateScript(js)!.toDictionary() as! [String: Any]
        #expect(dict["ETag"] as? String == "W/\"abc\"")
    }

    @Test("buildNotModifiedHeaders excludes Content-Type")
    func buildNotModifiedExcludesContentType() {
        let js = "buildNotModifiedHeaders('W/\"abc\"', {'Content-Type': 'text/html'})"
        let dict = ctx.evaluateScript(js)!.toDictionary() as! [String: Any]
        #expect(dict["Content-Type"] == nil)
    }

    @Test("buildNotModifiedHeaders excludes Content-Length")
    func buildNotModifiedExcludesContentLength() {
        let js = "buildNotModifiedHeaders('W/\"abc\"', {'Content-Length': '1234'})"
        let dict = ctx.evaluateScript(js)!.toDictionary() as! [String: Any]
        #expect(dict["Content-Length"] == nil)
    }

    @Test("buildNotModifiedHeaders preserves Cache-Control")
    func buildNotModifiedPreservesCacheControl() {
        let js = "buildNotModifiedHeaders('W/\"abc\"', {'Cache-Control': 'public, max-age=300'})"
        let dict = ctx.evaluateScript(js)!.toDictionary() as! [String: Any]
        #expect(dict["Cache-Control"] as? String == "public, max-age=300")
    }

    @Test("buildNotModifiedHeaders preserves Vary")
    func buildNotModifiedPreservesVary() {
        let js = "buildNotModifiedHeaders('W/\"abc\"', {'Vary': 'Accept-Encoding'})"
        let dict = ctx.evaluateScript(js)!.toDictionary() as! [String: Any]
        #expect(dict["Vary"] as? String == "Accept-Encoding")
    }

    @Test("buildNotModifiedHeaders is case-insensitive on input keys")
    func buildNotModifiedCaseInsensitive() {
        let js = "buildNotModifiedHeaders('W/\"abc\"', {'cache-control': 'public, max-age=42'})"
        let dict = ctx.evaluateScript(js)!.toDictionary() as! [String: Any]
        #expect(dict["Cache-Control"] as? String == "public, max-age=42")
    }

    // MARK: - canonicalUrl

    @Test("canonicalUrl strips trailing /index.html")
    func canonicalStripsIndexHtml() {
        let r = ctx.evaluateScript("canonicalUrl('/documentation/p256k/index.html')")!
        #expect(r.toString() == "https://docs.21.dev/documentation/p256k/")
    }

    @Test("canonicalUrl preserves clean directory paths")
    func canonicalPreservesDirectoryPaths() {
        let r = ctx.evaluateScript("canonicalUrl('/documentation/p256k/')")!
        #expect(r.toString() == "https://docs.21.dev/documentation/p256k/")
    }

    @Test("canonicalUrl preserves .html siblings (non-index)")
    func canonicalPreservesHtmlSiblings() {
        let r = ctx.evaluateScript("canonicalUrl('/documentation/p256k/signing.html')")!
        #expect(r.toString() == "https://docs.21.dev/documentation/p256k/signing.html")
    }

    @Test("canonicalUrl handles root path")
    func canonicalHandlesRoot() {
        let r = ctx.evaluateScript("canonicalUrl('/')")!
        #expect(r.toString() == "https://docs.21.dev/")
    }

    @Test("canonicalUrl always uses https://docs.21.dev origin")
    func canonicalAlwaysUsesDocsOrigin() {
        let r = ctx.evaluateScript("canonicalUrl('/llms.txt')")!
        #expect(r.toString() == "https://docs.21.dev/llms.txt")
    }

    @Test("canonicalUrl preserves nested deep paths")
    func canonicalPreservesNestedPaths() {
        let r = ctx.evaluateScript("canonicalUrl('/documentation/p256k/p256k/signing/')")!
        #expect(r.toString() == "https://docs.21.dev/documentation/p256k/p256k/signing/")
    }

    // MARK: - buildHtmlLinkHeader

    @Test("buildHtmlLinkHeader for module path includes catalog + alternate + canonical")
    func linkHeaderModulePath() {
        let r = ctx.evaluateScript("buildHtmlLinkHeader('/documentation/p256k/')")!.toString()!
        // Catalog relations
        #expect(r.contains(#"</llms.txt>; rel="llms-txt""#))
        #expect(r.contains(#"</llms-full.txt>; rel="llms-full-txt""#))
        #expect(r.contains(#"</sitemap.xml>; rel="sitemap""#))
        // Per-page relations
        #expect(r.contains(#"</data/documentation/p256k.md>; rel="alternate"; type="text/markdown""#))
        #expect(r.contains(#"<https://docs.21.dev/documentation/p256k/>; rel="canonical""#))
    }

    @Test("buildHtmlLinkHeader catalog relations are stable across paths")
    func linkHeaderCatalogStable() {
        for path in ["/", "/documentation/", "/documentation/p256k/", "/documentation/p256k/p256k/signing/"] {
            let r = ctx.evaluateScript("buildHtmlLinkHeader('\(path)')")!.toString()!
            #expect(r.contains(#"</llms.txt>; rel="llms-txt""#), "missing llms-txt at \(path)")
            #expect(r.contains(#"</llms-full.txt>; rel="llms-full-txt""#), "missing llms-full-txt at \(path)")
            #expect(r.contains(#"</sitemap.xml>; rel="sitemap""#), "missing sitemap at \(path)")
        }
    }

    @Test("buildHtmlLinkHeader emits exactly five link entries")
    func linkHeaderHasFiveEntries() {
        let r = ctx.evaluateScript("buildHtmlLinkHeader('/documentation/p256k/')")!.toString()!
        // Five link entries → four ", " separators
        let separatorCount = r.components(separatedBy: ", ").count
        #expect(separatorCount == 5, "expected 5 entries, got \(separatorCount): \(r)")
    }

    @Test("buildHtmlLinkHeader for index page uses /llms.txt as alternate")
    func linkHeaderIndexUsesLlmsTxt() {
        let r = ctx.evaluateScript("buildHtmlLinkHeader('/')")!.toString()!
        #expect(r.contains(#"</llms.txt>; rel="alternate"; type="text/markdown""#))
        #expect(r.contains(#"<https://docs.21.dev/>; rel="canonical""#))
    }

    @Test("buildHtmlLinkHeader for /documentation/ uses /llms.txt as alternate")
    func linkHeaderDocumentationIndex() {
        let r = ctx.evaluateScript("buildHtmlLinkHeader('/documentation/')")!.toString()!
        #expect(r.contains(#"</llms.txt>; rel="alternate"; type="text/markdown""#))
        #expect(r.contains(#"<https://docs.21.dev/documentation/>; rel="canonical""#))
    }

    @Test("buildHtmlLinkHeader for /index.html strips suffix in canonical only")
    func linkHeaderStripsIndexHtmlInCanonical() {
        let r = ctx.evaluateScript("buildHtmlLinkHeader('/documentation/p256k/index.html')")!.toString()!
        // Canonical is the cleaned URL
        #expect(r.contains(#"<https://docs.21.dev/documentation/p256k/>; rel="canonical""#))
        // Alternate is what resolveMarkdownPath produces for the literal pathname
        #expect(r.contains(#"</data/documentation/p256k.md>; rel="alternate""#))
    }

    @Test("buildHtmlLinkHeader produces RFC 8288 comma-separated value")
    func linkHeaderCommaSeparated() {
        let r = ctx.evaluateScript("buildHtmlLinkHeader('/documentation/p256k/')")!.toString()!
        #expect(r.contains(", "))
        #expect(!r.hasPrefix(","))
        #expect(!r.hasSuffix(","))
    }

    @Test("buildHtmlLinkHeader for .html sibling uses corresponding .md alternate")
    func linkHeaderHtmlSibling() {
        let r = ctx.evaluateScript("buildHtmlLinkHeader('/documentation/p256k/p256k/signing.html')")!.toString()!
        #expect(r.contains(#"</data/documentation/p256k/p256k/signing.md>; rel="alternate""#))
        #expect(r.contains(#"<https://docs.21.dev/documentation/p256k/p256k/signing.html>; rel="canonical""#))
    }
}
