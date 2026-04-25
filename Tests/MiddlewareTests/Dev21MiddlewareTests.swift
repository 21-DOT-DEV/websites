//
//  Dev21MiddlewareTests.swift
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

@Suite("21-dev Middleware Tests")
struct Dev21MiddlewareTests {
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
            .appendingPathComponent("Resources/21-dev/functions/logic.js")
            .path
        guard FileManager.default.fileExists(atPath: jsPath) else {
            Issue.record("logic.js not found at \(jsPath) — did the test file move?")
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

    @Test("Redirects pages.dev to custom domain")
    func redirectPagesDev() {
        let result = ctx.evaluateScript("resolveRedirect('21-dev.pages.dev')")!
        let dict = result.toDictionary() as! [String: Any]
        #expect(dict["redirect"] as? Bool == true)
        #expect(dict["target"] as? String == "21.dev")
    }

    @Test("Passes through non-pages.dev hostname")
    func passthroughCustomDomain() {
        let result = ctx.evaluateScript("resolveRedirect('21.dev')")!
        let dict = result.toDictionary() as! [String: Any]
        #expect(dict["redirect"] as? Bool == false)
        #expect(dict["target"] as? String == "21.dev")
    }

    @Test("Passes through arbitrary hostname")
    func passthroughArbitrary() {
        let result = ctx.evaluateScript("resolveRedirect('example.com')")!
        let dict = result.toDictionary() as! [String: Any]
        #expect(dict["redirect"] as? Bool == false)
        #expect(dict["target"] as? String == "example.com")
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
}
