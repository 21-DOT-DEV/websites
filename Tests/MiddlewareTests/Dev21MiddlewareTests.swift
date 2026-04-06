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
}
