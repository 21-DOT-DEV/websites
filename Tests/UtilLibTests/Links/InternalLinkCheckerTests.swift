//
//  InternalLinkCheckerTests.swift
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

@Suite("InternalLinkChecker Tests")
struct InternalLinkCheckerTests {

    // MARK: - srcset parsing

    @Test("srcset splits into candidate URLs")
    func srcsetCandidates() {
        let urls = InternalLinkChecker.parseSrcset("a.png 1x, b.png 2x")
        #expect(urls == ["a.png", "b.png"])
    }

    @Test("srcset data URI stays one candidate — commas inside it are not separators")
    func srcsetDataURI() {
        let urls = InternalLinkChecker.parseSrcset("data:image/png;base64,iVBORw0KGgo 1x, b.png 2x")
        #expect(urls == ["data:image/png;base64,iVBORw0KGgo", "b.png"])
    }

    @Test("srcset data URI with several commas still yields one candidate")
    func srcsetDataURIMultipleCommas() {
        let urls = InternalLinkChecker.parseSrcset("data:image/svg+xml,a,b 1x, c.png 2x")
        #expect(urls == ["data:image/svg+xml,a,b", "c.png"])
    }

    @Test("srcset comma inside a plain URL token is not a separator")
    func srcsetCommaInURL() {
        #expect(InternalLinkChecker.parseSrcset("a,b.png 1x") == ["a,b.png"])
    }

    @Test("srcset comma inside a descriptor still ends the candidate")
    func srcsetCommaInDescriptor() {
        #expect(InternalLinkChecker.parseSrcset("a.png 1x,b.png 2x") == ["a.png", "b.png"])
        #expect(InternalLinkChecker.parseSrcset("a.png 1x,b.png") == ["a.png", "b.png"])
    }

    @Test("srcset commas inside descriptor parentheses do not split")
    func srcsetCommaInParens() {
        #expect(InternalLinkChecker.parseSrcset("a.png 1x(foo,bar), b.png") == ["a.png", "b.png"])
    }

    @Test("srcset URL trailing commas collapse into one candidate")
    func srcsetTrailingCommas() {
        #expect(InternalLinkChecker.parseSrcset("a.png,, b.png") == ["a.png", "b.png"])
    }

    // MARK: - Resolution: skipped references

    @Test("External https URL is skipped")
    func skipsExternal() {
        #expect(InternalLinkChecker.resolve("https://example.com/x", from: "index.html") == .skipped)
        #expect(InternalLinkChecker.resolve("//cdn.example.com/x", from: "index.html") == .skipped)
    }

    @Test("Non-HTTP schemes are skipped")
    func skipsSchemes() {
        #expect(InternalLinkChecker.resolve("mailto:a@b.c", from: "index.html") == .skipped)
        #expect(InternalLinkChecker.resolve("tel:+15551234", from: "index.html") == .skipped)
        #expect(InternalLinkChecker.resolve("javascript:void(0)", from: "index.html") == .skipped)
        #expect(InternalLinkChecker.resolve("data:image/png;base64,x", from: "index.html") == .skipped)
    }

    @Test("Fragment-only and empty values are skipped")
    func skipsFragments() {
        #expect(InternalLinkChecker.resolve("#section", from: "index.html") == .skipped)
        #expect(InternalLinkChecker.resolve("", from: "index.html") == .skipped)
        #expect(InternalLinkChecker.resolve("  ", from: "index.html") == .skipped)
    }

    // MARK: - Resolution: internal paths

    @Test("Root-relative href resolves against site root")
    func resolvesRootRelative() {
        #expect(InternalLinkChecker.resolve("/blog/", from: "docs/a/index.html") == .sitePath("/blog/"))
    }

    @Test("Relative href resolves against containing directory")
    func resolvesRelative() {
        #expect(InternalLinkChecker.resolve("foo", from: "a/b/index.html") == .sitePath("/a/b/foo"))
        #expect(InternalLinkChecker.resolve("../x", from: "a/b/index.html") == .sitePath("/a/x"))
        #expect(InternalLinkChecker.resolve("../../x", from: "a/b/index.html") == .sitePath("/x"))
    }

    @Test("Reference escaping above site root is flagged")
    func escapesRoot() {
        #expect(InternalLinkChecker.resolve("../x", from: "index.html") == .outOfRoot)
        #expect(InternalLinkChecker.resolve("../../x", from: "a/index.html") == .outOfRoot)
    }

    @Test("Query and fragment are stripped before resolution")
    func stripsQueryFragment() {
        #expect(InternalLinkChecker.resolve("/a/b?x=1#y", from: "index.html") == .sitePath("/a/b"))
        #expect(InternalLinkChecker.resolve("/a/b#y", from: "index.html") == .sitePath("/a/b"))
    }

    @Test("Percent-encoded paths are decoded")
    func decodesPercent() {
        #expect(InternalLinkChecker.resolve("/my%20page", from: "index.html") == .sitePath("/my page"))
    }

    @Test("Dot-segments are normalized on absolute paths too")
    func normalizesDotSegments() {
        #expect(InternalLinkChecker.resolve("/a/./b", from: "index.html") == .sitePath("/a/b"))
        #expect(InternalLinkChecker.resolve("/a/b/../c", from: "index.html") == .sitePath("/a/c"))
    }

    @Test("Root-relative reference escaping above site root is flagged")
    func escapesRootAbsolute() {
        #expect(InternalLinkChecker.resolve("/../x", from: "index.html") == .outOfRoot)
        #expect(InternalLinkChecker.resolve("/a/../../x", from: "index.html") == .outOfRoot)
        // Percent-encoded traversal reaches the same check.
        #expect(InternalLinkChecker.resolve("/%2e%2e/x", from: "index.html") == .outOfRoot)
    }

    // MARK: - Existence checks against a fixture tree

    /// Builds a temporary site root: `index.html`, `about/index.html`, `post.html`,
    /// `img/logo.png`, `well-known/nostr.json`, plus a `_redirects` file.
    private func makeFixtureSite() throws -> String {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("linkcheck-\(UUID().uuidString)")
        let fm = FileManager.default
        try fm.createDirectory(at: root.appendingPathComponent("about"), withIntermediateDirectories: true)
        try fm.createDirectory(at: root.appendingPathComponent("img"), withIntermediateDirectories: true)
        try fm.createDirectory(at: root.appendingPathComponent("well-known"), withIntermediateDirectories: true)
        try "<html></html>".write(to: root.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        try "<html></html>".write(to: root.appendingPathComponent("about/index.html"), atomically: true, encoding: .utf8)
        try "<html></html>".write(to: root.appendingPathComponent("post.html"), atomically: true, encoding: .utf8)
        try "x".write(to: root.appendingPathComponent("img/logo.png"), atomically: true, encoding: .utf8)
        try "{}".write(to: root.appendingPathComponent("well-known/nostr.json"), atomically: true, encoding: .utf8)
        try """
        # comment line
        /docs https://docs.21.dev/documentation/ 301
        /.well-known/* /well-known/:splat 200
        """.write(to: root.appendingPathComponent("_redirects"), atomically: true, encoding: .utf8)
        return root.path
    }

    @Test("Exact file, directory index, and clean-URL forms all resolve")
    func existenceVariants() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        let rules = RedirectsParser.loadRules(from: root).rules

        #expect(InternalLinkChecker.exists(sitePath: "/index.html", inRoot: root, redirects: rules))
        #expect(InternalLinkChecker.exists(sitePath: "/about", inRoot: root, redirects: rules))
        #expect(InternalLinkChecker.exists(sitePath: "/about/", inRoot: root, redirects: rules))
        #expect(InternalLinkChecker.exists(sitePath: "/post", inRoot: root, redirects: rules))
        #expect(InternalLinkChecker.exists(sitePath: "/img/logo.png", inRoot: root, redirects: rules))
        #expect(!InternalLinkChecker.exists(sitePath: "/missing", inRoot: root, redirects: rules))
    }

    @Test("Redirect rule sources count as valid targets")
    func redirectExemption() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        let rules = RedirectsParser.loadRules(from: root).rules

        #expect(InternalLinkChecker.exists(sitePath: "/docs", inRoot: root, redirects: rules))
        #expect(InternalLinkChecker.exists(sitePath: "/.well-known/nostr.json", inRoot: root, redirects: rules))
        // The 200 proxy applies but its substituted target does not exist —
        // the edge serves the proxied miss, not a passing response.
        #expect(!InternalLinkChecker.exists(sitePath: "/.well-known/other.json", inRoot: root, redirects: rules))
        #expect(!InternalLinkChecker.exists(sitePath: "/not-redirected", inRoot: root, redirects: rules))
    }

    // MARK: - Status-aware, first-applied-match exemption

    @Test("An absent status column exempts like the default 302")
    func absentStatusExempts() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        let rules = RedirectsParser.parse("/gone /elsewhere")

        #expect(InternalLinkChecker.exists(sitePath: "/gone", inRoot: root, redirects: rules))
    }

    @Test("A 200 proxy shadows a real file when its target is missing")
    func twoHundredShadowsFile() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        // /post resolves on disk via post.html, but the edge applies the 200
        // rule first and serves the missing target — the link is broken.
        let rules = RedirectsParser.parse("/post /gone 200")

        #expect(!InternalLinkChecker.exists(sitePath: "/post", inRoot: root, redirects: rules))
    }

    @Test("A rule the edge ignores does not consume the first match")
    func ignoredStatusFallsThrough() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        let rules = RedirectsParser.parse("""
        /x /somewhere 404
        /x /elsewhere 301
        """)

        #expect(InternalLinkChecker.exists(sitePath: "/x", inRoot: root, redirects: rules))
    }

    @Test("An ignored rule leaves the file check in charge")
    func ignoredStatusFallsToDisk() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        let rules = RedirectsParser.parse("/post /somewhere 404")

        #expect(InternalLinkChecker.exists(sitePath: "/post", inRoot: root, redirects: rules))
    }

    @Test("A 200 rule with an external target is ignored")
    func externalProxyTargetIgnored() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        let rules = RedirectsParser.parse("/post https://example.com/x 200")

        // External proxying is unsupported — the edge ignores the rule, so the
        // real file at /post decides.
        #expect(InternalLinkChecker.exists(sitePath: "/post", inRoot: root, redirects: rules))
    }

    @Test("First applied match governs over later rules")
    func firstMatchGoverns() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        let rules = RedirectsParser.parse("""
        /a/*/index.html /missing 200
        /*/index.html /landing 301
        """)

        // Both sources match /a/b/index.html; the top-most applied rule (the
        // 200 proxy to a missing target) governs — the 301 never sees it.
        #expect(!InternalLinkChecker.exists(sitePath: "/a/b/index.html", inRoot: root, redirects: rules))
    }

    @Test("A refused loop rule applies to nothing — the file check decides")
    func refusedLoopRule() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        // `/* /index.html 200` and `/* / 200` are edge-served but
        // checker-masked — policy refuses to honor their exemption — so a
        // missing path is broken even though index.html exists: the
        // SPA-fallback the spec forbids.
        let refused = RedirectsParser.parse("/* /index.html 200")
        let refusedToRoot = RedirectsParser.parse("/* / 200")
        let splatSelfLoop = RedirectsParser.parse("/a/* /a/:splat 301")

        #expect(!InternalLinkChecker.exists(sitePath: "/nothing-here", inRoot: root, redirects: refused))
        #expect(!InternalLinkChecker.exists(sitePath: "/nothing-here", inRoot: root, redirects: refusedToRoot))
        #expect(!InternalLinkChecker.exists(sitePath: "/a/x", inRoot: root, redirects: splatSelfLoop))
        // And a real file still resolves through the normal disk check.
        #expect(InternalLinkChecker.exists(sitePath: "/post", inRoot: root, redirects: refused))
    }

    @Test("The site root resolves only through a real index.html")
    func rootResolvesThroughIndex() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        #expect(InternalLinkChecker.exists(sitePath: "/", inRoot: root, redirects: []))

        // An index-less empty directory never satisfies `/` — the directory
        // itself is not a servable file.
        let empty = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: empty, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: empty) }
        #expect(!InternalLinkChecker.exists(sitePath: "/", inRoot: empty, redirects: []))
    }

    @Test("The root path never resolves through a file named `.html`")
    func rootDoesNotResolveThroughDotHtmlFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: root) }
        try "<html></html>".write(toFile: "\(root)/.html", atomically: true, encoding: .utf8)

        #expect(!InternalLinkChecker.exists(sitePath: "/", inRoot: root, redirects: []))
    }

    @Test("Backslashes resolve as path separators and `\\\\` is protocol-relative")
    func backslashNormalization() {
        // WHATWG URL parsing treats `\` as `/` in special schemes.
        #expect(InternalLinkChecker.resolve("about\\", from: "index.html")
            == .sitePath("/about/"))
        #expect(InternalLinkChecker.resolve("img\\logo.png", from: "index.html")
            == .sitePath("/img/logo.png"))
        // `\\host/path` is protocol-relative like `//host/path` — skipped.
        #expect(InternalLinkChecker.resolve("\\\\evil.example/x", from: "index.html")
            == .skipped)
        // An *encoded* separator is not a separator — `%5C`/`%2F` inside a
        // segment can't denote a servable file.
        #expect(InternalLinkChecker.resolve("img%5Clogo.png", from: "index.html")
            == .unservable)
        #expect(InternalLinkChecker.resolve("/a%2Fb", from: "index.html")
            == .unservable)
        // Encoded dot-segments still normalize like literal dots.
        #expect(InternalLinkChecker.resolve("/%2e%2e/x", from: "index.html")
            == .outOfRoot)
    }

    @Test("A query-only `?x` reference resolves to the containing page")
    func queryOnlyResolvesToSelf() {
        #expect(InternalLinkChecker.resolve("?page=2", from: "index.html")
            == .sitePath("/index.html"))
        #expect(InternalLinkChecker.resolve("?page=2", from: "about/index.html")
            == .sitePath("/about/index.html"))
        // `#x` remains fragment-only — skipped, never resolved.
        #expect(InternalLinkChecker.resolve("#section", from: "index.html") == .skipped)
    }

    @Test("Tabs and newlines embedded in attribute values are stripped")
    func controlCharactersStripped() {
        #expect(InternalLinkChecker.resolve("a\tb", from: "index.html")
            == .sitePath("/ab"))
        #expect(InternalLinkChecker.resolve("img/\nlogo.png", from: "index.html")
            == .sitePath("/img/logo.png"))
    }

    @Test("Root config files exist on disk but are never served by the edge")
    func unservedRootConfigFilesAreBroken() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        // `_redirects` exists in the fixture — a link to it still fails.
        #expect(!InternalLinkChecker.exists(sitePath: "/_redirects", inRoot: root, redirects: []))
        #expect(!InternalLinkChecker.exists(sitePath: "/_headers", inRoot: root, redirects: []))

        // The same name under a subdirectory is an ordinary file — served.
        try FileManager.default.createDirectory(
            atPath: "\(root)/sub", withIntermediateDirectories: true)
        try "<html></html>".write(toFile: "\(root)/sub/_redirects", atomically: true, encoding: .utf8)
        #expect(InternalLinkChecker.exists(sitePath: "/sub/_redirects", inRoot: root, redirects: []))

        // Trailing-slash spellings reach the same unservable config.
        #expect(!InternalLinkChecker.exists(sitePath: "/_redirects/", inRoot: root, redirects: []))
    }

    @Test("A catch-all 200 proxy emits a scan warning — a masked gate is never silent")
    func catchAllProxyWarns() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        // Every catch-all 200 the edge would serve masks the gate — whether
        // checker policy honors the exemption (`/post`) or masks it
        // (`/index.html`, `/` — edge-served canonical-rematch shells).
        for shell in ["/* /post 200", "/* /index.html 200", "/* / 200"] {
            try shell.write(
                toFile: "\(root)/_redirects", atomically: true, encoding: .utf8)
            let report = try InternalLinkChecker.checkDirectory(at: root)
            #expect(report.scanWarnings.contains { $0.contains("catch-all") })
        }
        // And it really does mask: every internal link resolves through it.
        #expect(InternalLinkChecker.exists(sitePath: "/anything", inRoot: root,
            redirects: RedirectsParser.parse("/* /post 200")))
    }

    @Test("isSuccess stays false when nothing was actually checked")
    func isSuccessRequiresACheckedFile() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        try FileManager.default.createDirectory(atPath: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: root) }
        try Data([0xFF, 0xFE, 0x3C]).write(to: URL(fileURLWithPath: "\(root)/a.html"))

        let report = try InternalLinkChecker.checkDirectory(at: root)
        #expect(report.totalBroken == 0)
        #expect(!report.isSuccess)
    }

    @Test("A sub-tree splat proxying the site root is applied, not refused")
    func subTreeSplatProxyingRootIsApplied() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        // `/sub/*` is not a site-wide catch-all — the edge applies the rule and
        // proxies `/` (which resolves through index.html).
        let rules = RedirectsParser.parse("/sub/* / 200")
        #expect(InternalLinkChecker.exists(sitePath: "/sub/anything", inRoot: root, redirects: rules))
    }

    @Test("A 200 target with dot-segments normalizes before the loop check — /a/../b can't re-match /a/*")
    func dotSegmentTargetNotRefused() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        // The target normalizes to `/post`, which never re-matches `/a/*` — the
        // edge applies the rule and proxies to the normalized path.
        let rules = RedirectsParser.parse("/a/* /a/../post 200")
        #expect(InternalLinkChecker.exists(sitePath: "/a/x", inRoot: root, redirects: rules))

        // A missing normalized target still reports broken — applied, not refused.
        let missing = RedirectsParser.parse("/a/* /a/../nope 200")
        #expect(!InternalLinkChecker.exists(sitePath: "/a/x", inRoot: root, redirects: missing))
    }

    @Test("A 200 proxy into its own scope is NOT refused — proxy fetches never re-run routing")
    func proxyIntoOwnScopeApplied() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        // `/a/* /a/post 200` serves `a/post.html` content under `/a/*` — the
        // internal fetch does not re-match, so the edge applies the rule.
        try FileManager.default.createDirectory(atPath: root + "/a", withIntermediateDirectories: true)
        try "<html></html>".write(toFile: root + "/a/post.html", atomically: true, encoding: .utf8)
        let rules = RedirectsParser.parse("/a/* /a/post 200")
        #expect(InternalLinkChecker.exists(sitePath: "/a/x", inRoot: root, redirects: rules))
    }

    @Test("A 200 proxy to an .html target under its own scope IS refused — it canonicalizes into a loop")
    func proxyToHtmlTargetRefused() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        // `/a/* /a/post.html 200` — fetching `/a/post.html` canonical-redirects
        // to `/a/post`, which re-matches `/a/*` and proxies again forever.
        let rules = RedirectsParser.parse("/a/* /a/post.html 200")
        #expect(!InternalLinkChecker.exists(sitePath: "/a/x", inRoot: root, redirects: rules))
    }

    @Test("A 3xx into its own scope IS refused — the client re-requests the literal target")
    func redirectIntoOwnScopeRefused() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        let rules = RedirectsParser.parse("/a/* /a/post 301")
        #expect(!InternalLinkChecker.exists(sitePath: "/a/x", inRoot: root, redirects: rules))
    }

    @Test("A slash-ending literal source is NOT refused when its target can't re-match it")
    func literalSlashSourceApplied() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        // `/old-docs/` serves its `/docs/index.html` target at `/docs/`, which
        // never re-matches `/old-docs/` — the edge applies this rule normally.
        let rules = RedirectsParser.parse("/old-docs/ /docs/index.html 301")

        #expect(InternalLinkChecker.exists(sitePath: "/old-docs/", inRoot: root, redirects: rules))
    }

    @Test("A 200 rule with a protocol-relative target is ignored")
    func protocolRelativeProxyIgnored() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        let rules = RedirectsParser.parse("/post //example.com/x 200")

        #expect(InternalLinkChecker.exists(sitePath: "/post", inRoot: root, redirects: rules))
    }

    @Test("Tab-separated fields parse like space-separated ones")
    func tabSeparatedFields() {
        let rules = RedirectsParser.parse("/a\t/b\t301")
        #expect(rules == [RedirectRule(source: "/a", target: "/b", status: 301)])
    }

    @Test("Non-ASCII characters after a colon are literal, not placeholders")
    func nonASCIIPlaceholder() {
        // Placeholder names are `:[A-Za-z]\w*` — a colon before a non-ASCII
        // letter stays literal and never makes the rule a wildcard.
        let rule = RedirectRule(source: "/a/:é", target: "/b", status: 301)
        #expect(!rule.isWildcard)
        #expect(RedirectsParser.matches(rule, sitePath: "/a/:é"))
        #expect(!RedirectsParser.matches(rule, sitePath: "/a/x"))
    }

    @Test("A slash-ending path still tries the clean-URL file form")
    func slashEndingCleanURL() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        // `/post/` resolves through `post.html` — Pages redirects the
        // non-canonical spelling rather than 404ing.
        #expect(InternalLinkChecker.exists(sitePath: "/post/", inRoot: root, redirects: []))
        // `/post` resolves through the same file and through directory forms.
        #expect(InternalLinkChecker.exists(sitePath: "/post", inRoot: root, redirects: []))
        #expect(InternalLinkChecker.exists(sitePath: "/about/", inRoot: root, redirects: []))
    }

    @Test("A 200 proxy target ending in / resolves through the clean-URL form")
    func slashEndingProxyTarget() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        let rules = RedirectsParser.parse("/a/* /post/ 200")

        #expect(InternalLinkChecker.exists(sitePath: "/a/x", inRoot: root, redirects: rules))
    }

    @Test("A multi-splat source is not applied — it can never match")
    func multiSplatNotApplied() {
        let rule = RedirectRule(source: "/a/*/b/*", target: "/x", status: 301)
        #expect(!rule.isAppliedByEdge)
        #expect(!InternalLinkChecker.exists(sitePath: "/a/x/b/y", inRoot: "/", redirects: [rule]))
    }

    @Test("A digit-leading colon stays a path — schemes start with a letter")
    func digitLeadingColon() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        try "<html></html>".write(
            toFile: root + "/2024:recap.html",
            atomically: true,
            encoding: .utf8
        )
        #expect(InternalLinkChecker.resolve("2024:recap.html", from: "index.html") == .sitePath("/2024:recap.html"))
        #expect(InternalLinkChecker.exists(sitePath: "/2024:recap.html", inRoot: root, redirects: []))
    }

    @Test("A 200 proxy target resolves through the same disk forms")
    func twoHundredTargetForms() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }
        let rules = RedirectsParser.parse("""
        /proxy-post /post 200
        /proxy-dir /about/ 200
        """)

        #expect(InternalLinkChecker.exists(sitePath: "/proxy-post", inRoot: root, redirects: rules))
        #expect(InternalLinkChecker.exists(sitePath: "/proxy-dir", inRoot: root, redirects: rules))
    }

    // MARK: - checkDirectory end-to-end

    @Test("checkDirectory reports broken links with source file and href")
    func directoryCheck() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }

        let html = """
        <html><head>
        <link rel="stylesheet" href="/static/style.css">
        </head><body>
        <a href="/about">ok index</a>
        <a href="/post">ok clean url</a>
        <a href="/docs">ok redirect</a>
        <a href="https://example.com">skipped external</a>
        <a href="#top">skipped fragment</a>
        <a href="/missing-page">broken</a>
        <img src="/img/logo.png">
        <img srcset="/img/logo.png 1x, /missing-img.png 2x">
        </body></html>
        """
        try html.write(toFile: root + "/index.html", atomically: true, encoding: .utf8)

        let report = try InternalLinkChecker.checkDirectory(at: root)
        let index = report.results.first { $0.relativePath == "index.html" }

        #expect(report.totalBroken == 3) // missing-page link + missing style.css + missing srcset candidate
        #expect(index?.brokenLinks.contains { $0.rawValue == "/missing-page" } == true)
        #expect(index?.brokenLinks.contains { $0.attribute == "srcset" && $0.rawValue == "/missing-img.png" } == true)
        #expect(index?.skippedCount == 2)
        #expect(report.isSuccess == false)
    }

    @Test("An unreadable _redirects surfaces a scan warning, not silent zero rules")
    func unreadableRedirectsWarned() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }

        try Data([0xFF, 0xFE]).write(to: URL(fileURLWithPath: root + "/_redirects"))

        let loaded = RedirectsParser.loadRules(from: root)
        #expect(loaded.rules.isEmpty)
        #expect(loaded.warning != nil)

        let report = try InternalLinkChecker.checkDirectory(at: root)
        #expect(report.warnings.contains { $0.contains("_redirects") })
    }

    @Test("checkDirectory counts an unparseable file as skipped and names it")
    func unparseableFileWarned() throws {
        let root = try makeFixtureSite()
        defer { try? FileManager.default.removeItem(atPath: root) }

        let invalidUTF8 = Data([0xFF, 0xFE, 0x3C, 0x62])
        try invalidUTF8.write(to: URL(fileURLWithPath: root + "/garbage.html"))

        let report = try InternalLinkChecker.checkDirectory(at: root)

        #expect(report.skippedFiles.map(\.relativePath) == ["garbage.html"])
        #expect(report.warnings.count == 1)
        #expect(report.warnings.first?.contains("garbage.html") == true)
        #expect(report.isSuccess)
    }

    // MARK: - _redirects parsing

    @Test("Redirects parser skips comments and defaults status to 302")
    func redirectsParsing() {
        let rules = RedirectsParser.parse("""
        # comment
        /a /b 301

        /c /d
        """)
        #expect(rules.count == 2)
        #expect(rules[0] == RedirectRule(source: "/a", target: "/b", status: 301))
        #expect(rules[1] == RedirectRule(source: "/c", target: "/d", status: 302))
    }

    @Test("Redirects parser ignores malformed lines like the edge does")
    func malformedLinesDropped() {
        let rules = RedirectsParser.parse("""
        /a /b extra fields
        /c /d nonsense
        /lonely
        /ok /target 301
        """)
        #expect(rules == [RedirectRule(source: "/ok", target: "/target", status: 301)])
    }

    @Test("Parses both real site _redirects files without dropping rules")
    func realSiteFiles() throws {
        // 21-dev: 3 rules — one 200 splat proxy, two external 301s.
        // docs-21-dev: 15 rules — mid-path splats and a catch-all.
        let resources = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Tests/UtilLibTests/Links/
            .deletingLastPathComponent() // Tests/UtilLibTests/
            .deletingLastPathComponent() // Tests/
            .deletingLastPathComponent() // repo root
            .appendingPathComponent("Resources")
            .path
        let dev = RedirectsParser.loadRules(from: resources + "/21-dev").rules
        let docs = RedirectsParser.loadRules(from: resources + "/docs-21-dev").rules

        // Canary: every non-comment, non-blank line parsed — no silent drops.
        for site in ["21-dev", "docs-21-dev"] {
            let contents = try String(contentsOfFile: resources + "/\(site)/_redirects", encoding: .utf8)
            let ruleLines = contents.split(separator: "\n").count {
                !$0.trimmingCharacters(in: .whitespaces).isEmpty
                    && !$0.trimmingCharacters(in: .whitespaces).hasPrefix("#")
            }
            #expect(RedirectsParser.loadRules(from: resources + "/\(site)").rules.count == ruleLines)
        }
        #expect(dev.contains(RedirectRule(source: "/.well-known/*", target: "/well-known/:splat", status: 200)))
        #expect(docs.first == RedirectRule(source: "/", target: "/documentation/", status: 301))
        #expect(docs.last == RedirectRule(source: "/*/index.html", target: "/:splat/", status: 301))
    }

    // MARK: - _redirects matching

    @Test("Matcher handles exact, suffix-splat, and placeholder sources")
    func redirectsMatching() {
        #expect(RedirectsParser.matches(RedirectRule(source: "/a", target: "/b", status: 301), sitePath: "/a"))
        #expect(RedirectsParser.matches(RedirectRule(source: "/w/*", target: "/x/:splat", status: 200), sitePath: "/w/deep/path"))
        #expect(RedirectsParser.matches(RedirectRule(source: "/p/:slug", target: "/x", status: 301), sitePath: "/p/abc"))
        #expect(!RedirectsParser.matches(RedirectRule(source: "/p/:slug", target: "/x", status: 301), sitePath: "/p/a/b"))
        #expect(!RedirectsParser.matches(RedirectRule(source: "/p/:slug", target: "/x", status: 301), sitePath: "/p/"))
        #expect(!RedirectsParser.matches(RedirectRule(source: "/a", target: "/b", status: 301), sitePath: "/ab"))
    }

    @Test("Splat matches greedily mid-path, not only at the end")
    func midPathSplat() {
        let rule = RedirectRule(source: "/p256k/*/index.html", target: "/documentation/p256k/:splat/", status: 301)

        #expect(RedirectsParser.matches(rule, sitePath: "/p256k/x/index.html"))
        #expect(RedirectsParser.matches(rule, sitePath: "/p256k/a/b/index.html"))
        #expect(!RedirectsParser.matches(rule, sitePath: "/p256k/x/other.html"))

        let match = RedirectsParser.match(rule, sitePath: "/p256k/a/b/index.html")
        #expect(match?.splat == "a/b")
    }

    @Test("Sources can mix a splat with placeholders")
    func mixedSplatAndPlaceholder() {
        let rule = RedirectRule(source: "/m/:year/*/index.html", target: "/t/:year/:splat/", status: 301)
        let match = RedirectsParser.match(rule, sitePath: "/m/2024/a/b/index.html")

        #expect(match?.splat == "a/b")
        #expect(match?.placeholders["year"] == "2024")
        #expect(RedirectsParser.substitute(rule.target, with: match!) == "/t/2024/a/b/")
    }

    @Test("A source with more than one splat never matches")
    func multiSplatInvalid() {
        let rule = RedirectRule(source: "/a/*/b/*", target: "/t", status: 301)
        #expect(!RedirectsParser.matches(rule, sitePath: "/a/x/b/y"))
    }

    @Test("Splat may match empty when the path still fits")
    func splatMatchesEmpty() {
        let rule = RedirectRule(source: "/p256k/*", target: "/documentation/p256k/:splat/", status: 301)
        let match = RedirectsParser.match(rule, sitePath: "/p256k/")

        #expect(match?.splat == "")
    }

    @Test("Placeholder captures exactly one segment")
    func placeholderCaptures() {
        let rule = RedirectRule(source: "/m/:title", target: "/media/:title", status: 301)
        let match = RedirectsParser.match(rule, sitePath: "/m/dune")

        #expect(match?.placeholders["title"] == "dune")
        #expect(RedirectsParser.substitute(rule.target, with: match!) == "/media/dune")
    }

    @Test("isWildcard and isAppliedByEdge classify rules for consumers")
    func ruleClassification() {
        #expect(RedirectRule(source: "/a/*", target: "/b/:splat", status: 301).isWildcard)
        #expect(RedirectRule(source: "/a/:slug", target: "/b", status: 301).isWildcard)
        #expect(!RedirectRule(source: "/a", target: "/b", status: 301).isWildcard)

        #expect(RedirectRule(source: "/a", target: "/b", status: 301).isAppliedByEdge)
        #expect(RedirectRule(source: "/a", target: "/b", status: 200).isAppliedByEdge)
        #expect(RedirectRule(source: "/a", target: "https://x.dev", status: 200).isAppliedByEdge == false)
        #expect(RedirectRule(source: "/a", target: "/b", status: 404).isAppliedByEdge == false)
        #expect(RedirectRule(source: "/a", target: "/b", status: 300).isAppliedByEdge == false)
    }
}
