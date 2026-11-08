//
//  LinksCheckCLITests.swift
//  UtilitiesCLITests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
import Subprocess
import System

@Suite("Links Check CLI Tests")
struct LinksCheckCLITests {

    @Test("links check requires path argument")
    func requiresPathArgument() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["links", "check"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
    }

    @Test("links check validates path exists")
    func validatesPathExists() async throws {
        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["links", "check", "--path", "/nonexistent/path"],
            output: .string(limit: 4096),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code != 0)
    }

    @Test("links check exits 0 on a clean site")
    func cleanSitePasses() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("linkcheck-cli-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(atPath: root.path) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try """
        <html><body><a href="/about">x</a></body></html>
        """.write(to: root.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("about"), withIntermediateDirectories: true)
        try "<html></html>".write(to: root.appendingPathComponent("about/index.html"), atomically: true, encoding: .utf8)

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["links", "check", "--path", root.path],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 0)
        #expect((result.standardOutput ?? "").contains("All internal links resolve"))
    }

    @Test("links check exits 1 and names the broken href")
    func brokenSiteFails() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("linkcheck-cli-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(atPath: root.path) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try """
        <html><body><a href="/definitely-missing">x</a></body></html>
        """.write(to: root.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["links", "check", "--path", root.path],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 1)
        #expect((result.standardOutput ?? "").contains("/definitely-missing"))
    }

    @Test("links check --verbose lists every checked reference per file")
    func verboseListsReferences() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("linkcheck-cli-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(atPath: root.path) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("about"), withIntermediateDirectories: true)
        try "<html></html>".write(to: root.appendingPathComponent("about/index.html"), atomically: true, encoding: .utf8)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("busted"), withIntermediateDirectories: true)
        try """
        <html><body>
        <a href="/about">x</a>
        <a href="https://example.com">skipped</a>
        </body></html>
        """.write(to: root.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        try """
        <html><body><a href="/missing-page">x</a></body></html>
        """.write(to: root.appendingPathComponent("busted/index.html"), atomically: true, encoding: .utf8)

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["links", "check", "--path", root.path, "--verbose"],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 1)
        let stdout = result.standardOutput ?? ""
        #expect(stdout.contains("index.html"))
        #expect(stdout.contains("✅ index.html"))
        #expect(stdout.contains("❌ busted/index.html"))
        #expect(stdout.contains("href=\"/about\" → /about"))
        #expect(!stdout.contains("example.com"))
    }

    @Test("links check exits 1 on an empty scan — a gate that checked nothing")
    func emptyScanFails() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("linkcheck-cli-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(atPath: root.path) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["links", "check", "--path", root.path],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 1)
        #expect((result.standardOutput ?? "").contains("No HTML files"))
    }

    @Test("links check exits 1 when every HTML file fails to parse")
    func allUnparseableFilesFail() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("linkcheck-cli-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(atPath: root.path) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data([0xFF, 0xFE, 0x3C]).write(to: root.appendingPathComponent("a.html"))
        try Data([0xFF, 0xFE, 0x3C]).write(to: root.appendingPathComponent("b.html"))

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["links", "check", "--path", root.path],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 1)
        #expect((result.standardOutput ?? "").contains("nothing was verified"))
    }

    @Test("links check warns on unparseable files but still exits 0")
    func unparseableFileWarns() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("linkcheck-cli-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(atPath: root.path) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try "<html></html>".write(to: root.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        try Data([0xFF, 0xFE, 0x3C]).write(to: root.appendingPathComponent("garbage.html"))

        let result = try await Subprocess.run(
            .path(FilePath(".build/debug/util")),
            arguments: ["links", "check", "--path", root.path],
            output: .string(limit: 8192),
            error: .string(limit: 4096)
        )

        guard case .exited(let code) = result.terminationStatus else {
            Issue.record("Unexpected termination")
            return
        }
        #expect(code == 0)
        #expect((result.standardOutput ?? "").contains("garbage.html"))
        #expect((result.standardOutput ?? "").contains("skipped"))
    }
}
