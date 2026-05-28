//
//  LinkRewriterTests.swift
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

@Suite("LinkRewriter Tests")
struct LinkRewriterTests {

    @Test("Strip trailing /index.html from simple relative href")
    func stripsSimpleRelative() throws {
        let html = #"<html><body><a href="foo/index.html">x</a></body></html>"#
        let (rewritten, count) = try LinkRewriter.rewrite(html: html)
        #expect(count == 1)
        #expect(rewritten.contains(#"href="foo/""#))
        #expect(!rewritten.contains("index.html"))
    }

    @Test("Strip trailing /index.html from parent-directory href")
    func stripsParentDirectory() throws {
        let html = #"<html><body><a href="../../../foo/index.html">x</a></body></html>"#
        let (rewritten, count) = try LinkRewriter.rewrite(html: html)
        #expect(count == 1)
        #expect(rewritten.contains(#"href="../../../foo/""#))
    }

    @Test("Rewrite all anchors on a multi-link page")
    func rewritesAllAnchorsOnPage() throws {
        let html = """
        <html><body>
        <a href="alpha/index.html">a</a>
        <a href="../beta/index.html">b</a>
        <a href="../../gamma/index.html">c</a>
        </body></html>
        """
        let (rewritten, count) = try LinkRewriter.rewrite(html: html)
        #expect(count == 3)
        #expect(!rewritten.contains("index.html"))
    }

    @Test("Idempotent: rewriting an already-clean page is a no-op")
    func idempotent() throws {
        let html = #"<html><body><a href="foo/">x</a></body></html>"#
        let (_, count) = try LinkRewriter.rewrite(html: html)
        #expect(count == 0)
    }

    @Test("Bare 'index.html' (no leading slash) is NOT rewritten")
    func skipsBareIndexHtml() throws {
        // href="index.html" → must be skipped, else we'd produce href=""
        let html = #"<html><body><a href="index.html">x</a></body></html>"#
        let (rewritten, count) = try LinkRewriter.rewrite(html: html)
        #expect(count == 0)
        #expect(rewritten.contains(#"href="index.html""#))
    }

    @Test("Non-anchor href values are left untouched")
    func skipsNonAnchorHrefs() throws {
        // <link rel="stylesheet">, <area>, etc. carry href= but aren't anchors.
        let html = """
        <html><head>
        <link rel="alternate" href="foo/index.html">
        </head><body>
        <a href="bar/index.html">x</a>
        </body></html>
        """
        let (rewritten, count) = try LinkRewriter.rewrite(html: html)
        #expect(count == 1)  // only the <a> is rewritten
        #expect(rewritten.contains(#"<a href="bar/""#))
        // <link> href stays as-is
        #expect(rewritten.contains(#"<link rel="alternate" href="foo/index.html""#))
    }

    @Test("Href values that contain 'index.html' mid-path are not rewritten")
    func skipsMidPath() throws {
        // The suffix selector requires the literal /index.html at end.
        // Hypothetical mid-path occurrence must not be touched.
        let html = #"<html><body><a href="foo/index.html/bar/">x</a></body></html>"#
        let (rewritten, count) = try LinkRewriter.rewrite(html: html)
        #expect(count == 0)
        #expect(rewritten.contains("index.html/bar/"))
    }

    @Test("Href values ending in similar-but-different suffixes are not rewritten")
    func skipsSimilarSuffixes() throws {
        // /index.html.bak or /myindex.html must not match
        let html = """
        <html><body>
        <a href="foo/index.html.bak">a</a>
        <a href="bar/myindex.html">b</a>
        </body></html>
        """
        let (_, count) = try LinkRewriter.rewrite(html: html)
        #expect(count == 0)
    }

    @Test("Anchors with no href attribute don't crash the rewriter")
    func handlesAnchorsWithoutHref() throws {
        let html = #"<html><body><a name="top">anchor</a><a href="foo/index.html">x</a></body></html>"#
        let (_, count) = try LinkRewriter.rewrite(html: html)
        #expect(count == 1)
    }

    @Test("Empty body produces no rewrites and doesn't crash")
    func handlesEmptyBody() throws {
        let html = "<html><body></body></html>"
        let (_, count) = try LinkRewriter.rewrite(html: html)
        #expect(count == 0)
    }

    // MARK: - Directory pass

    @Test("rewriteDirectory updates a single file in dry-run mode without writing")
    func directoryDryRunDoesNotWrite() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let original = #"<html><body><a href="foo/index.html">x</a></body></html>"#
        let filePath = tempDir.appendingPathComponent("page.html")
        try original.write(to: filePath, atomically: true, encoding: .utf8)

        let report = try LinkRewriter.rewriteDirectory(at: tempDir.path, dryRun: true)
        #expect(report.rewrittenCount == 1)
        #expect(report.totalLinksRewritten == 1)

        let onDisk = try String(contentsOf: filePath, encoding: .utf8)
        #expect(onDisk == original, "dry-run must not modify the file on disk")
    }

    @Test("rewriteDirectory persists changes when dry-run is false")
    func directoryActuallyWrites() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let original = #"<html><body><a href="foo/index.html">x</a></body></html>"#
        let filePath = tempDir.appendingPathComponent("page.html")
        try original.write(to: filePath, atomically: true, encoding: .utf8)

        let report = try LinkRewriter.rewriteDirectory(at: tempDir.path, dryRun: false)
        #expect(report.rewrittenCount == 1)

        let onDisk = try String(contentsOf: filePath, encoding: .utf8)
        #expect(!onDisk.contains("index.html"))
        #expect(onDisk.contains(#"href="foo/""#))
    }

    @Test("rewriteDirectory reports unchanged files when nothing to do")
    func directoryReportsUnchanged() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let original = #"<html><body><a href="foo/">x</a></body></html>"#
        try original.write(to: tempDir.appendingPathComponent("page.html"), atomically: true, encoding: .utf8)

        let report = try LinkRewriter.rewriteDirectory(at: tempDir.path, dryRun: false)
        #expect(report.rewrittenCount == 0)
        #expect(report.unchangedCount == 1)
        #expect(report.totalLinksRewritten == 0)
        #expect(report.isSuccess)
    }
}
