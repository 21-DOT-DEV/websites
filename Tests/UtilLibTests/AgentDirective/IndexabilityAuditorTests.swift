//
//  IndexabilityAuditorTests.swift
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

@Suite("IndexabilityAuditor — Hybrid Policy")
struct IndexabilityAuditorPolicyTests {

    // MARK: - Helpers

    /// Build a DocC sidecar with a `## Discussion` content block of `chars`
    /// length, optionally including an aside callout and/or a code listing.
    private static func sidecar(
        roleHeading: String,
        symbolKind: String = "struct",
        textLength: Int,
        includeAside: Bool = false,
        includeCodeListing: Bool = false
    ) -> Data {
        var content: [[String: Any]] = []

        // Authored prose (single text node sized to exact length).
        let prose = String(repeating: "x", count: textLength)
        content.append([
            "type": "paragraph",
            "inlineContent": [
                ["type": "text", "text": prose] as [String: Any]
            ],
        ])

        // Optional code listing — must NOT contribute to char count.
        if includeCodeListing {
            content.append([
                "type": "codeListing",
                "syntax": "swift",
                "code": ["let x = 1", "let y = 2"],
            ])
        }

        // Optional aside callout (Note/Warning/Tip/Important).
        // Use empty content so the aside contributes 0 chars to the char
        // count — keeps `textLength` the sole variable in threshold tests.
        // (Real asides carry text; their text DOES count toward the
        // threshold in production. See `flattenedText` impl.)
        if includeAside {
            content.append([
                "type": "aside",
                "style": "note",
                "content": [] as [Any],
            ])
        }

        let json: [String: Any] = [
            "metadata": [
                "roleHeading": roleHeading,
                "symbolKind": symbolKind,
                "title": "TestSymbol",
            ],
            "primaryContentSections": [
                [
                    "kind": "content",
                    "content": content,
                ] as [String: Any]
            ],
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])
    }

    // MARK: - Tests: type-page rule

    @Test("Type page with Overview ≥ 200 chars is eligible")
    func typePageMeetsThreshold() throws {
        let data = Self.sidecar(roleHeading: "Structure", textLength: 250)
        let page = try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/foo")
        try #require(page != nil)
        #expect(page!.path == "documentation/x/foo")
        #expect(page!.reason == "type:Structure:overview=250")
    }

    @Test("Type page with Overview = exactly 200 chars is eligible (lower bound)")
    func typePageAtLowerBound() throws {
        let data = Self.sidecar(roleHeading: "Class", textLength: IndexabilityAuditor.typeOverviewMinChars)
        let page = try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/c")
        #expect(page != nil)
    }

    @Test("Type page with Overview = 199 chars is NOT eligible (just under bound)")
    func typePageBelowLowerBound() throws {
        let data = Self.sidecar(roleHeading: "Structure", textLength: 199)
        let page = try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/foo")
        #expect(page == nil)
    }

    @Test("All type-role headings recognized")
    func typeRoleHeadingCoverage() throws {
        for heading in ["Structure", "Enumeration", "Class", "Protocol", "Type Alias", "Actor"] {
            let data = Self.sidecar(roleHeading: heading, textLength: 250)
            let page = try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/\(heading)")
            #expect(page != nil, "Heading '\(heading)' should classify as type page")
        }
    }

    // MARK: - Tests: method-page rule

    @Test("Method page with Discussion ≥ 300 chars is eligible")
    func methodPageMeetsThreshold() throws {
        let data = Self.sidecar(roleHeading: "Instance Method", symbolKind: "method", textLength: 350)
        let page = try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/foo()")
        try #require(page != nil)
        #expect(page!.reason == "method:Instance Method:disc=350")
    }

    @Test("Method page with Discussion = exactly 300 chars is eligible")
    func methodPageAtLowerBound() throws {
        let data = Self.sidecar(roleHeading: "Initializer", symbolKind: "init", textLength: 300)
        #expect(try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/init") != nil)
    }

    @Test("Method page with Discussion = 299 chars is NOT eligible")
    func methodPageBelowLowerBound() throws {
        let data = Self.sidecar(roleHeading: "Type Method", symbolKind: "method", textLength: 299)
        #expect(try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/foo") == nil)
    }

    @Test("Method page with Discussion = 200 chars (above type threshold) is NOT eligible — wrong role")
    func methodPageNotMisclassifiedAsType() throws {
        // 200 chars ≥ type threshold but < method threshold; method role heading
        // ⇒ must NOT be eligible. Guards against accidental fall-through where
        // a method page with a substantial-but-sub-300 discussion gets indexed.
        let data = Self.sidecar(roleHeading: "Instance Method", symbolKind: "method", textLength: 200)
        #expect(try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/foo()") == nil)
    }

    @Test("All method-role headings recognized")
    func methodRoleHeadingCoverage() throws {
        let methodHeadings = [
            "Instance Method", "Type Method", "Initializer", "Operator",
            "Subscript", "Instance Property", "Type Property", "Case",
        ]
        for heading in methodHeadings {
            let data = Self.sidecar(roleHeading: heading, symbolKind: "method", textLength: 320)
            let page = try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/\(heading)")
            #expect(page != nil, "Heading '\(heading)' should classify as method page")
        }
    }

    // MARK: - Tests: aside rule

    @Test("Aside-bearing page with Discussion ≥ 100 chars is eligible regardless of role")
    func asidePageMeetsThreshold() throws {
        // 150 chars: under both type (200) and method (300) thresholds, but
        // aside callout + ≥ 100 chars qualifies it.
        let data = Self.sidecar(
            roleHeading: "Instance Property",
            symbolKind: "property",
            textLength: 150,
            includeAside: true
        )
        let page = try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/p")
        try #require(page != nil)
        // Aside reason should win over method check (which would also have failed).
        #expect(page!.reason.hasPrefix("aside:"))
    }

    @Test("Aside-bearing page with Discussion = 99 chars is NOT eligible")
    func asidePageBelowLowerBound() throws {
        let data = Self.sidecar(
            roleHeading: "Instance Property", symbolKind: "property",
            textLength: 99, includeAside: true
        )
        #expect(try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/p") == nil)
    }

    @Test("Page without aside and short Discussion is NOT eligible")
    func nonAsidePageBelowAllThresholds() throws {
        let data = Self.sidecar(
            roleHeading: "Instance Property", symbolKind: "property",
            textLength: 150, includeAside: false
        )
        #expect(try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/p") == nil)
    }

    // MARK: - Tests: parsing edge cases

    @Test("Article (no symbolKind) returns nil — not in audit scope")
    func articlePageReturnsNil() throws {
        let json: [String: Any] = [
            "metadata": [
                "roleHeading": "Article",
                "title": "Getting Started",
            ],
            "primaryContentSections": [
                [
                    "kind": "content",
                    "content": [
                        [
                            "type": "paragraph",
                            "inlineContent": [
                                ["type": "text", "text": String(repeating: "y", count: 1000)] as [String: Any]
                            ],
                        ] as [String: Any]
                    ],
                ] as [String: Any]
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        #expect(try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/article") == nil)
    }

    @Test("Code listings are excluded from char count")
    func codeListingsExcludedFromCharCount() throws {
        // 150 chars of prose + a code listing. With code excluded, total is 150
        // (below type threshold 200, no aside, NOT eligible).
        let data = Self.sidecar(
            roleHeading: "Structure",
            textLength: 150,
            includeCodeListing: true
        )
        #expect(try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/c") == nil)

        // Bumping prose to 200 chars + code listing should pass (code still
        // excluded; only the 200 chars of prose count).
        let data2 = Self.sidecar(
            roleHeading: "Structure",
            textLength: 200,
            includeCodeListing: true
        )
        #expect(try IndexabilityAuditor.evaluate(sidecarData: data2, canonicalPath: "documentation/x/c") != nil)
    }

    @Test("Sidecar with no primaryContentSections is NOT eligible")
    func emptyContentSections() throws {
        let json: [String: Any] = [
            "metadata": [
                "roleHeading": "Structure",
                "symbolKind": "struct",
                "title": "Empty",
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        #expect(try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/empty") == nil)
    }

    @Test("Sidecar with primaryContentSections of kind != 'content' is NOT eligible")
    func nonContentSectionsIgnored() throws {
        let json: [String: Any] = [
            "metadata": [
                "roleHeading": "Structure",
                "symbolKind": "struct",
            ],
            "primaryContentSections": [
                [
                    "kind": "declarations",
                    "declarations": [],
                ] as [String: Any]
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        #expect(try IndexabilityAuditor.evaluate(sidecarData: data, canonicalPath: "documentation/x/d") == nil)
    }
}

// MARK: - Filesystem Scan Tests

@Suite("IndexabilityAuditor — auditModule")
struct IndexabilityAuditorScanTests {

    /// Create a temporary archives root populated with one or more sidecar
    /// files at the given relative paths.
    private static func makeFixtureRoot(sidecars: [String: Data]) throws -> URL {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("IndexabilityAuditorTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("documentation", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        for (relativePath, data) in sidecars {
            let url = tmp.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url)
        }
        return tmp
    }

    private static func eligibleStructSidecar(textLength: Int = 250) -> Data {
        let json: [String: Any] = [
            "metadata": ["roleHeading": "Structure", "symbolKind": "struct"],
            "primaryContentSections": [
                [
                    "kind": "content",
                    "content": [
                        [
                            "type": "paragraph",
                            "inlineContent": [
                                ["type": "text", "text": String(repeating: "z", count: textLength)] as [String: Any]
                            ],
                        ] as [String: Any]
                    ],
                ] as [String: Any]
            ],
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    @Test("auditModule discovers eligible pages and partitions against allowlist")
    func auditModulePartitionsCorrectly() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/foo.json": Self.eligibleStructSidecar(),
            "p256k/bar/baz.json": Self.eligibleStructSidecar(),
            "p256k/uneligible.json": Self.eligibleStructSidecar(textLength: 50),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let report = try IndexabilityAuditor.auditModule(
            module: "p256k",
            archivesRoot: root,
            currentAllowlist: ["documentation/p256k/foo"],
            excludedPathPrefixes: []
        )
        let eligiblePaths = report.eligible.map(\.path).sorted()
        #expect(eligiblePaths == ["documentation/p256k/bar/baz", "documentation/p256k/foo"])
        #expect(report.alreadyAllowed.map(\.path) == ["documentation/p256k/foo"])
        #expect(report.newlyDiscovered.map(\.path) == ["documentation/p256k/bar/baz"])
    }

    @Test("auditModule respects excludedPathPrefixes")
    func auditModuleAppliesExclusions() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "tor/torclient.json": Self.eligibleStructSidecar(),
            "tor/controlsocket/readline.json": Self.eligibleStructSidecar(),
            "tor/controlprotocolparser/parse.json": Self.eligibleStructSidecar(),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let report = try IndexabilityAuditor.auditModule(
            module: "tor",
            archivesRoot: root,
            currentAllowlist: [],
            excludedPathPrefixes: [
                "documentation/tor/controlsocket/",
                "documentation/tor/controlprotocolparser/",
            ]
        )
        #expect(report.eligible.map(\.path) == ["documentation/tor/torclient"])
    }

    @Test("auditModule throws when module directory is missing")
    func auditModuleMissingDirectoryThrows() throws {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("nonexistent-\(UUID().uuidString)")
        #expect(throws: IndexabilityAuditor.AuditError.self) {
            _ = try IndexabilityAuditor.auditModule(
                module: "p256k",
                archivesRoot: root,
                currentAllowlist: []
            )
        }
    }

    @Test("auditModule skips non-JSON files silently")
    func auditModuleSkipsNonJSONFiles() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/foo.json": Self.eligibleStructSidecar(),
        ])
        // Drop a non-JSON file alongside.
        let strayURL = root.appendingPathComponent("p256k/README.md")
        try "not json".write(to: strayURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let report = try IndexabilityAuditor.auditModule(
            module: "p256k",
            archivesRoot: root,
            currentAllowlist: []
        )
        #expect(report.eligible.count == 1)
    }

    @Test("canonicalPath helper produces 'documentation/<module>/<...>' form")
    func canonicalPathDerivation() {
        let root = URL(fileURLWithPath: "/tmp/Websites/docs-21-dev/data/documentation")
        let sidecar = root.appendingPathComponent("p256k/p256k/signing.json")
        let canonical = IndexabilityAuditor.canonicalPath(for: sidecar, archivesRoot: root)
        #expect(canonical == "documentation/p256k/p256k/signing")
    }
}

// MARK: - Stale-Entry Detection

@Suite("IndexabilityAuditor — Stale Entries")
struct IndexabilityAuditorStaleTests {

    /// Build a small archives root populated with the given sidecars.
    private static func makeFixtureRoot(sidecars: [String: Data]) throws -> URL {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("IndexabilityAuditorStaleTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("documentation", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        for (relativePath, data) in sidecars {
            let url = tmp.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url)
        }
        return tmp
    }

    private static func symbolSidecar(roleHeading: String, symbolKind: String, textLength: Int) -> Data {
        let json: [String: Any] = [
            "metadata": ["roleHeading": roleHeading, "symbolKind": symbolKind],
            "primaryContentSections": [
                [
                    "kind": "content",
                    "content": [
                        [
                            "type": "paragraph",
                            "inlineContent": [
                                ["type": "text", "text": String(repeating: "z", count: textLength)] as [String: Any]
                            ],
                        ] as [String: Any]
                    ],
                ] as [String: Any]
            ],
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    private static func articleSidecar(textLength: Int) -> Data {
        // No symbolKind — DocC's signal that this is an article / landing page.
        let json: [String: Any] = [
            "metadata": ["roleHeading": "Article", "title": "Getting Started"],
            "primaryContentSections": [
                [
                    "kind": "content",
                    "content": [
                        [
                            "type": "paragraph",
                            "inlineContent": [
                                ["type": "text", "text": String(repeating: "y", count: textLength)] as [String: Any]
                            ],
                        ] as [String: Any]
                    ],
                ] as [String: Any]
            ],
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    // MARK: evaluateAllowlistEntry

    @Test("evaluateAllowlistEntry returns .eligible for symbol page that passes policy")
    func eligibleStatus() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/big.json": Self.symbolSidecar(roleHeading: "Structure", symbolKind: "struct", textLength: 250),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let status = try IndexabilityAuditor.evaluateAllowlistEntry(
            allowlistPath: "documentation/p256k/big",
            archivesRoot: root
        )
        guard case .eligible(let page) = status else {
            Issue.record("expected .eligible, got \(status)")
            return
        }
        #expect(page.path == "documentation/p256k/big")
        #expect(page.reason == "type:Structure:overview=250")
    }

    @Test("evaluateAllowlistEntry returns .stale for symbol page that fails policy")
    func staleStatus() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/thin.json": Self.symbolSidecar(roleHeading: "Structure", symbolKind: "struct", textLength: 50),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let status = try IndexabilityAuditor.evaluateAllowlistEntry(
            allowlistPath: "documentation/p256k/thin",
            archivesRoot: root
        )
        guard case .stale(let entry) = status else {
            Issue.record("expected .stale, got \(status)")
            return
        }
        #expect(entry.path == "documentation/p256k/thin")
        #expect(entry.reason.contains("type:Structure"))
        #expect(entry.reason.contains("overview=50"))
        #expect(entry.reason.contains("≥200"))
    }

    @Test("evaluateAllowlistEntry returns .stale when sidecar is missing (deleted/renamed upstream)")
    func staleOnMissingSidecar() throws {
        let root = try Self.makeFixtureRoot(sidecars: [:])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        // An allowlist entry pointing at a non-bare-root path with no sidecar
        // on disk means the page was renamed or deleted upstream (e.g.,
        // `socket/connect(to:loop:)` → `socket/connect(to:loop:timeout:)`).
        // Flag as stale so the registry can be cleaned up — left in place
        // it would 404 in the sitemap.
        let status = try IndexabilityAuditor.evaluateAllowlistEntry(
            allowlistPath: "documentation/p256k/missing",
            archivesRoot: root
        )
        guard case .stale(let entry) = status else {
            Issue.record("expected .stale, got \(status)")
            return
        }
        #expect(entry.path == "documentation/p256k/missing")
        #expect(entry.reason.contains("no sidecar"))
        #expect(entry.reason.contains("deleted"))
    }

    @Test("evaluateAllowlistEntry returns .outOfScope for article (no symbolKind)")
    func outOfScopeArticle() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/gettingstarted.json": Self.articleSidecar(textLength: 1500),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let status = try IndexabilityAuditor.evaluateAllowlistEntry(
            allowlistPath: "documentation/p256k/gettingstarted",
            archivesRoot: root
        )
        guard case .outOfScope(let reason) = status else {
            Issue.record("expected .outOfScope, got \(status)")
            return
        }
        #expect(reason.lowercased().contains("article") || reason.lowercased().contains("symbolkind"))
    }

    @Test("evaluateAllowlistEntry returns .outOfScope for paths outside the archive root prefix")
    func outOfScopeNotUnderRoot() throws {
        let root = try Self.makeFixtureRoot(sidecars: [:])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let status = try IndexabilityAuditor.evaluateAllowlistEntry(
            allowlistPath: "tutorials/p256k/foo",  // wrong root prefix
            archivesRoot: root
        )
        guard case .outOfScope = status else {
            Issue.record("expected .outOfScope, got \(status)")
            return
        }
    }

    @Test("evaluateAllowlistEntry returns .outOfScope for the bare 'documentation' root hub")
    func outOfScopeBareRoot() throws {
        let root = try Self.makeFixtureRoot(sidecars: [:])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let status = try IndexabilityAuditor.evaluateAllowlistEntry(
            allowlistPath: "documentation",
            archivesRoot: root
        )
        guard case .outOfScope = status else {
            Issue.record("expected .outOfScope for bare root, got \(status)")
            return
        }
    }

    // MARK: auditModule integration

    @Test("auditModule populates staleEntries for thin allowlist entries")
    func auditModuleDetectsStaleEntries() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/big.json":  Self.symbolSidecar(roleHeading: "Structure", symbolKind: "struct", textLength: 250),
            "p256k/thin.json": Self.symbolSidecar(roleHeading: "Structure", symbolKind: "struct", textLength: 50),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        // Allowlist contains BOTH big (still eligible) and thin (now stale).
        let report = try IndexabilityAuditor.auditModule(
            module: "p256k",
            archivesRoot: root,
            currentAllowlist: ["documentation/p256k/big", "documentation/p256k/thin"]
        )
        #expect(report.eligible.map(\.path) == ["documentation/p256k/big"])
        #expect(report.alreadyAllowed.map(\.path) == ["documentation/p256k/big"])
        #expect(report.newlyDiscovered.isEmpty)
        #expect(report.staleEntries.map(\.path) == ["documentation/p256k/thin"])
    }

    @Test("auditModule flags allowlist entries pointing at missing sidecars as stale (deleted upstream)")
    func auditModuleDetectsDeletedPages() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/big.json": Self.symbolSidecar(roleHeading: "Structure", symbolKind: "struct", textLength: 250),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        // 'documentation/p256k/renamed' has no sidecar in the archive — e.g.,
        // a method whose signature changed upstream so the old canonical URL
        // no longer resolves. Must surface as stale so it can be removed
        // from the registry before the next sitemap publish.
        let report = try IndexabilityAuditor.auditModule(
            module: "p256k",
            archivesRoot: root,
            currentAllowlist: ["documentation/p256k/big", "documentation/p256k/renamed"]
        )
        #expect(report.staleEntries.map(\.path) == ["documentation/p256k/renamed"])
        if let entry = report.staleEntries.first {
            #expect(entry.reason.contains("no sidecar"))
            #expect(entry.reason.contains("deleted"))
        }
    }

    @Test("auditModule does NOT mark articles (no symbolKind) as stale")
    func auditModuleSkipsArticlesInStaleCheck() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/gettingstarted.json": Self.articleSidecar(textLength: 1500),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let report = try IndexabilityAuditor.auditModule(
            module: "p256k",
            archivesRoot: root,
            currentAllowlist: ["documentation/p256k/gettingstarted"]
        )
        #expect(report.staleEntries.isEmpty,
                "Articles must not be flagged as stale; got \(report.staleEntries.map(\.path))")
    }

    // MARK: AuditReport aggregation

    @Test("AuditReport.totalStaleEntries sums across modules")
    func auditReportAggregatesStale() {
        let m1 = IndexabilityAuditor.ModuleReport(
            module: "p256k", eligible: [], alreadyAllowed: [], newlyDiscovered: [],
            staleEntries: [
                .init(path: "documentation/p256k/a", reason: "x"),
                .init(path: "documentation/p256k/b", reason: "y"),
            ]
        )
        let m2 = IndexabilityAuditor.ModuleReport(
            module: "tor", eligible: [], alreadyAllowed: [], newlyDiscovered: [],
            staleEntries: [.init(path: "documentation/tor/c", reason: "z")]
        )
        let report = IndexabilityAuditor.AuditReport(modules: [m1, m2])
        #expect(report.totalStaleEntries == 3)
    }

    @Test("AuditReport.hasGap is true when ANY drift direction exists")
    func auditReportHasGapBidirectional() {
        // Stale only
        let staleOnly = IndexabilityAuditor.AuditReport(modules: [
            .init(module: "x", eligible: [], alreadyAllowed: [], newlyDiscovered: [],
                  staleEntries: [.init(path: "documentation/x/a", reason: "r")])
        ])
        #expect(staleOnly.hasGap)

        // Newly-discovered only
        let newOnly = IndexabilityAuditor.AuditReport(modules: [
            .init(module: "x",
                  eligible: [.init(path: "documentation/x/b", reason: "r")],
                  alreadyAllowed: [],
                  newlyDiscovered: [.init(path: "documentation/x/b", reason: "r")],
                  staleEntries: [])
        ])
        #expect(newOnly.hasGap)

        // Neither
        let clean = IndexabilityAuditor.AuditReport(modules: [
            .init(module: "x", eligible: [], alreadyAllowed: [], newlyDiscovered: [], staleEntries: [])
        ])
        #expect(!clean.hasGap)
    }
}

// MARK: - Content Counting & Framework Role
//
// Covers two empirically-verified issues uncovered by sampling real DocC
// archives (see conversation thread 2026-04-30):
//
// 1. The pre-fix `discussionCharCount` read only the FIRST kind:content
//    section of `primaryContentSections` and ignored the `abstract` field.
//    Real DocC method pages emit Return Value as the first content section
//    (short) followed by Discussion (long), so the auditor undercounted
//    authored prose by 10–18× on every method-with-return-value page.
//
// 2. `roleHeading: "Framework"` was not in any rule bucket, so module
//    landing pages (1300–2000 authored chars each) fell through to stale.
//
// These tests encode the real DocC sidecar shape observed in the OpenSSL
// archive (abstract + Return Value section + Discussion section) and the
// Framework landing shape.

@Suite("IndexabilityAuditor — Content Counting & Framework")
struct IndexabilityAuditorContentCountingTests {

    // MARK: Fixture helpers

    /// Build a sidecar matching DocC's real shape: optional top-level
    /// `abstract`, then a declarations section, then zero or more
    /// `kind: content` sections (Return Value, Discussion, etc.).
    private static func sidecarWithAbstractAndSections(
        roleHeading: String,
        symbolKind: String,
        abstract: String?,
        contentSections: [[[String: Any]]]
    ) -> Data {
        var json: [String: Any] = [
            "metadata": ["roleHeading": roleHeading, "symbolKind": symbolKind],
        ]
        if let abs = abstract {
            json["abstract"] = [textNode(abs)]
        }
        var sections: [[String: Any]] = [
            // Declarations block is auto-generated; the auditor must ignore it.
            ["kind": "declarations", "declarations": [] as [Any]] as [String: Any],
        ]
        for nodes in contentSections {
            sections.append([
                "kind": "content",
                "content": nodes as [Any],
            ] as [String: Any])
        }
        json["primaryContentSections"] = sections
        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    private static func textNode(_ s: String) -> [String: Any] {
        ["type": "text", "text": s]
    }

    private static func paragraphOf(_ text: String) -> [String: Any] {
        ["type": "paragraph", "inlineContent": [textNode(text)]]
    }

    private static func codeListingNode(lines: [String]) -> [String: Any] {
        ["type": "codeListing", "syntax": "swift", "code": lines]
    }

    /// Small fixture root for allowlist-entry evaluation tests.
    private static func makeFixtureRoot(sidecars: [String: Data]) throws -> URL {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("IndexabilityAuditorContentCountingTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("documentation", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        for (relativePath, data) in sidecars {
            let url = tmp.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url)
        }
        return tmp
    }

    // MARK: Fix A — authored content counting

    @Test("authoredCharCount sums abstract + all kind:content sections (regression for disc=67 bug)")
    func authoredCharCountMultiSection() throws {
        // Mimics real DocC method-page shape: 50-char abstract + 60-char Return
        // Value section + 400-char Discussion section. The pre-fix auditor read
        // only the first content section (60) and missed both abstract and
        // Discussion. Expected total under the fix: 50 + 60 + 400 = 510.
        let data = Self.sidecarWithAbstractAndSections(
            roleHeading: "Instance Method", symbolKind: "method",
            abstract: String(repeating: "a", count: 50),
            contentSections: [
                [Self.paragraphOf(String(repeating: "r", count: 60))],   // Return Value
                [Self.paragraphOf(String(repeating: "d", count: 400))],  // Discussion
            ]
        )
        let root = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(IndexabilityAuditor.authoredCharCount(root: root) == 510)
    }

    @Test("authoredCharCount counts abstract alone when no kind:content sections are present")
    func authoredCharCountAbstractOnly() throws {
        // Pages with only a one-line summary (e.g. trivial initializers) emit
        // an `abstract` but no `kind: content` section. The auditor must still
        // see the authored prose.
        let data = Self.sidecarWithAbstractAndSections(
            roleHeading: "Initializer", symbolKind: "init",
            abstract: String(repeating: "a", count: 75),
            contentSections: []
        )
        let root = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        #expect(IndexabilityAuditor.authoredCharCount(root: root) == 75)
    }

    @Test("authoredCharCount excludes codeListings from the count")
    func authoredCharCountExcludesCode() throws {
        // Code samples are not authored prose for SEO purposes — they appear
        // verbatim on the page but don't signal content quality.
        let data = Self.sidecarWithAbstractAndSections(
            roleHeading: "Instance Method", symbolKind: "method",
            abstract: String(repeating: "a", count: 30),
            contentSections: [
                [
                    Self.paragraphOf(String(repeating: "p", count: 100)),
                    Self.codeListingNode(lines: [String(repeating: "c", count: 500)]),
                ]
            ]
        )
        let root = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        // 30 (abstract) + 100 (prose). Code listing NOT counted.
        #expect(IndexabilityAuditor.authoredCharCount(root: root) == 130)
    }

    @Test("evaluate() recognises a method page with abstract + RV + Discussion as eligible (regression)")
    func evaluateRealDocCShape() throws {
        // Matches the real openssl/sha256/hash(data:) shape:
        //   abstract=45, Return Value section=71, Discussion section=679
        //   → 795 total authored chars.
        // Pre-fix the auditor reported disc=71 and flagged as stale. Post-fix
        // it reads the full 795 and passes the 300-char method threshold.
        let data = Self.sidecarWithAbstractAndSections(
            roleHeading: "Instance Method", symbolKind: "method",
            abstract: String(repeating: "a", count: 45),
            contentSections: [
                [Self.paragraphOf(String(repeating: "r", count: 71))],   // Return Value
                [Self.paragraphOf(String(repeating: "d", count: 679))],  // Discussion
            ]
        )
        let page = try IndexabilityAuditor.evaluate(
            sidecarData: data,
            canonicalPath: "documentation/openssl/sha256/hash(data:)"
        )
        #expect(page != nil, "Multi-section method with 795 authored chars must be eligible under the fix")
        #expect(page?.reason.contains("method:Instance Method") == true)
        // Reason carries the TOTAL authored count.
        #expect(page?.reason.contains("disc=795") == true,
                "Expected disc=795 in reason, got: \(page?.reason ?? "nil")")
    }

    // MARK: Fix B — Framework role eligibility

    @Test("evaluate() returns eligible for Framework role with Overview ≥ 500 chars")
    func frameworkEligibleAboveThreshold() throws {
        // Matches the real openssl Framework landing shape:
        //   abstract=147, Overview section≈1924 (total 2071).
        // Here we use a minimum-viable fixture at 550 total chars.
        let data = Self.sidecarWithAbstractAndSections(
            roleHeading: "Framework", symbolKind: "module",
            abstract: String(repeating: "a", count: 50),
            contentSections: [
                [Self.paragraphOf(String(repeating: "o", count: 500))]
            ]
        )
        let page = try IndexabilityAuditor.evaluate(
            sidecarData: data,
            canonicalPath: "documentation/mymodule"
        )
        #expect(page != nil, "Framework landing with 550 authored chars must be eligible")
        #expect(page?.reason.contains("framework:Framework") == true)
        #expect(page?.reason.contains("overview=550") == true)
    }

    @Test("evaluate() returns nil for Framework role below 500-char threshold")
    func frameworkBelowThreshold() throws {
        // Total 430 chars — above the 200-char type threshold but below the
        // 500-char framework threshold. Framework rule must NOT fall back to
        // the type rule (Framework role is distinct from type kinds).
        let data = Self.sidecarWithAbstractAndSections(
            roleHeading: "Framework", symbolKind: "module",
            abstract: String(repeating: "a", count: 30),
            contentSections: [
                [Self.paragraphOf(String(repeating: "o", count: 400))]
            ]
        )
        let page = try IndexabilityAuditor.evaluate(
            sidecarData: data,
            canonicalPath: "documentation/thin-framework"
        )
        #expect(page == nil, "Framework with only 430 authored chars must NOT be eligible")
    }

    @Test("evaluateAllowlistEntry returns .stale for Framework role below threshold with correct reason")
    func frameworkStaleViaAllowlistEntry() throws {
        // A thin Framework landing (100 chars total) should be classified as
        // stale with a reason that identifies the Framework rule and the
        // 500-char target for maintainer action.
        let root = try Self.makeFixtureRoot(sidecars: [
            "thin.json": Self.sidecarWithAbstractAndSections(
                roleHeading: "Framework", symbolKind: "module",
                abstract: String(repeating: "a", count: 20),
                contentSections: [
                    [Self.paragraphOf(String(repeating: "o", count: 80))]
                ]
            )
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let status = try IndexabilityAuditor.evaluateAllowlistEntry(
            allowlistPath: "documentation/thin",
            archivesRoot: root
        )
        guard case .stale(let entry) = status else {
            Issue.record("expected .stale, got \(status)")
            return
        }
        #expect(entry.path == "documentation/thin")
        #expect(entry.reason.contains("framework:Framework"))
        #expect(entry.reason.contains("overview=100"))
        #expect(entry.reason.contains("≥500"))
    }
}

// MARK: - Defaults & Constants

@Suite("IndexabilityAuditor — Defaults")
struct IndexabilityAuditorDefaultsTests {

    @Test("Hybrid policy thresholds match documented values")
    func documentedThresholds() {
        #expect(IndexabilityAuditor.typeOverviewMinChars == 200)
        #expect(IndexabilityAuditor.methodDiscussionMinChars == 300)
        #expect(IndexabilityAuditor.asideDiscussionMinChars == 100)
        #expect(IndexabilityAuditor.frameworkOverviewMinChars == 500)
    }

    @Test("Framework role headings cover DocC module landings")
    func frameworkRoleHeadingsAreClosedSet() {
        let expected: Set<String> = ["Framework", "Module"]
        #expect(IndexabilityAuditor.frameworkRoleHeadings == expected)
    }

    @Test("Default exclusions cover Tor's internal protocol-plumbing trees")
    func defaultExclusionsForTor() {
        let torExclusions = IndexabilityAuditor.defaultModuleExclusions["tor"] ?? []
        #expect(torExclusions.contains("documentation/tor/controlprotocolparser/"))
        #expect(torExclusions.contains("documentation/tor/controlsocket/"))
        // URLSession extensions are user-facing — must NOT be excluded.
        #expect(!torExclusions.contains(where: { $0.contains("foundation") }))
    }

    @Test("Default exclusions cover ZKP's P256K re-export tree")
    func defaultExclusionsForZKP() {
        let zkpExclusions = IndexabilityAuditor.defaultModuleExclusions["zkp"] ?? []
        #expect(zkpExclusions.contains("documentation/zkp/"))
    }

    @Test("Type role headings cover the six DocC type kinds")
    func typeRoleHeadingsAreClosedSet() {
        let expected: Set<String> = [
            "Structure", "Enumeration", "Class", "Protocol", "Type Alias", "Actor",
        ]
        #expect(IndexabilityAuditor.typeRoleHeadings == expected)
    }

    @Test("Method role headings cover the eight DocC method-like kinds (incl. Case)")
    func methodRoleHeadingsAreClosedSet() {
        let expected: Set<String> = [
            "Instance Method", "Type Method", "Initializer", "Operator", "Subscript",
            "Instance Property", "Type Property", "Case",
        ]
        #expect(IndexabilityAuditor.methodRoleHeadings == expected)
    }

    @Test("Near-miss candidate gap defaults to 50 chars (documented heuristic)")
    func candidateMaxGapDefault() {
        // 50 chars ≈ one short authored sentence. Not backed by an authoritative
        // Apple/Google source — see the 2026-04-30 retrospective for rationale.
        #expect(IndexabilityAuditor.candidateMaxGapChars == 50)
    }
}

// MARK: - Near-Miss Candidate Detection
//
// Near-miss candidates are pages that FAIL the hybrid policy but sit within
// `candidateMaxGapChars` of their role-bucket threshold. They're surfaced as
// an editorial signal: "add ~1 sentence of authored prose and this page
// becomes eligible for the index". Pages already in the allowlist are
// excluded (they surface as `stale` instead — same-shape failure, different
// recommended action).

@Suite("IndexabilityAuditor — Near-Miss Candidates")
struct IndexabilityAuditorCandidateTests {

    // MARK: Fixture helpers

    private static func sidecar(
        roleHeading: String,
        symbolKind: String = "method",
        textLength: Int,
        includeAside: Bool = false
    ) -> Data {
        var content: [[String: Any]] = [
            [
                "type": "paragraph",
                "inlineContent": [
                    ["type": "text", "text": String(repeating: "x", count: textLength)] as [String: Any]
                ],
            ]
        ]
        if includeAside {
            content.append([
                "type": "aside",
                "style": "note",
                "content": [] as [Any],
            ])
        }
        let json: [String: Any] = [
            "metadata": [
                "roleHeading": roleHeading,
                "symbolKind": symbolKind,
                "title": "TestSymbol",
            ],
            "primaryContentSections": [
                ["kind": "content", "content": content] as [String: Any]
            ],
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    private static func articleSidecar() -> Data {
        let json: [String: Any] = [
            "metadata": ["roleHeading": "Article", "title": "Getting Started"],
            "primaryContentSections": [] as [Any],
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    private static func makeFixtureRoot(sidecars: [String: Data]) throws -> URL {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("IndexabilityAuditorCandidateTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("documentation", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        for (relativePath, data) in sidecars {
            let url = tmp.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url)
        }
        return tmp
    }

    // MARK: evaluateNearMiss — per-bucket boundaries

    @Test("Method page at gap=30 is a candidate with correct reason")
    func methodGap30IsCandidate() throws {
        let data = Self.sidecar(roleHeading: "Instance Method", textLength: 270)
        let candidate = try IndexabilityAuditor.evaluateNearMiss(
            sidecarData: data, canonicalPath: "documentation/x/foo"
        )
        try #require(candidate != nil)
        #expect(candidate!.path == "documentation/x/foo")
        #expect(candidate!.gap == 30)
        #expect(candidate!.reason.contains("method:Instance Method"))
        #expect(candidate!.reason.contains("disc=270"))
        #expect(candidate!.reason.contains("gap=30"))
        #expect(candidate!.reason.contains("≥300"))
    }

    @Test("Method page at gap=50 (exact boundary) is a candidate")
    func methodGap50BoundaryInclusive() throws {
        let data = Self.sidecar(roleHeading: "Instance Method", textLength: 250)
        let candidate = try IndexabilityAuditor.evaluateNearMiss(
            sidecarData: data, canonicalPath: "documentation/x/foo"
        )
        #expect(candidate != nil)
        #expect(candidate?.gap == 50)
    }

    @Test("Method page at gap=51 (one past boundary) is NOT a candidate")
    func methodGap51BoundaryExclusive() throws {
        let data = Self.sidecar(roleHeading: "Instance Method", textLength: 249)
        let candidate = try IndexabilityAuditor.evaluateNearMiss(
            sidecarData: data, canonicalPath: "documentation/x/foo"
        )
        #expect(candidate == nil)
    }

    @Test("Eligible page (gap=0 or passing) is NOT a candidate")
    func eligibleIsNotCandidate() throws {
        // disc=310 passes the 300-char method threshold → already indexable,
        // not a near-miss.
        let data = Self.sidecar(roleHeading: "Instance Method", textLength: 310)
        let candidate = try IndexabilityAuditor.evaluateNearMiss(
            sidecarData: data, canonicalPath: "documentation/x/foo"
        )
        #expect(candidate == nil, "Eligible pages are already indexable, not candidates")
    }

    @Test("Type page at gap=20 (below 200-char threshold) is a candidate")
    func typeGap20IsCandidate() throws {
        let data = Self.sidecar(roleHeading: "Structure", symbolKind: "struct", textLength: 180)
        let candidate = try IndexabilityAuditor.evaluateNearMiss(
            sidecarData: data, canonicalPath: "documentation/x/foo"
        )
        try #require(candidate != nil)
        #expect(candidate!.gap == 20)
        #expect(candidate!.reason.contains("type:Structure"))
        #expect(candidate!.reason.contains("overview=180"))
        #expect(candidate!.reason.contains("≥200"))
    }

    @Test("Framework page at gap=30 (below 500-char threshold) is a candidate")
    func frameworkGap30IsCandidate() throws {
        let data = Self.sidecar(roleHeading: "Framework", symbolKind: "module", textLength: 470)
        let candidate = try IndexabilityAuditor.evaluateNearMiss(
            sidecarData: data, canonicalPath: "documentation/mymodule"
        )
        try #require(candidate != nil)
        #expect(candidate!.gap == 30)
        #expect(candidate!.reason.contains("framework:Framework"))
        #expect(candidate!.reason.contains("overview=470"))
        #expect(candidate!.reason.contains("≥500"))
    }

    @Test("Method with aside at chars=85 reports aside bucket (not method bucket)")
    func methodWithAsideReportsAsideBucket() throws {
        // chars=85: method bucket (300) misses by 215 chars (too far),
        // aside bucket (100) misses by 15 chars (near-miss). The closer,
        // more-achievable target is aside — that's what we report.
        let data = Self.sidecar(
            roleHeading: "Initializer", symbolKind: "init",
            textLength: 85, includeAside: true
        )
        let candidate = try IndexabilityAuditor.evaluateNearMiss(
            sidecarData: data, canonicalPath: "documentation/x/init(_:)"
        )
        try #require(candidate != nil)
        #expect(candidate!.gap == 15, "Expected gap=15 (aside threshold), not gap=215 (method threshold)")
        #expect(candidate!.reason.contains("aside:Initializer"))
        #expect(candidate!.reason.contains("disc=85"))
        #expect(candidate!.reason.contains("≥100"))
        #expect(!candidate!.reason.contains("method:"),
                "Method bucket must NOT be reported when aside bucket is more achievable")
    }

    @Test("Method without aside at gap=30 reports method bucket (not aside bucket)")
    func methodWithoutAsideReportsMethodBucket() throws {
        let data = Self.sidecar(
            roleHeading: "Instance Method", textLength: 270,
            includeAside: false
        )
        let candidate = try IndexabilityAuditor.evaluateNearMiss(
            sidecarData: data, canonicalPath: "documentation/x/foo"
        )
        try #require(candidate != nil)
        #expect(candidate!.reason.contains("method:"))
        #expect(!candidate!.reason.contains("aside:"),
                "Aside bucket must NOT be reported for pages without asides")
    }

    // MARK: evaluateNearMiss — custom maxGap override

    @Test("Custom maxGap=100 surfaces pages up to gap=100 (method page at gap=75)")
    func customMaxGapSurfacesWider() throws {
        // gap=75 (chars=225, need=300) is outside the 50-char default but
        // inside a 100-char override.
        let data = Self.sidecar(roleHeading: "Instance Method", textLength: 225)

        let defaultGap = try IndexabilityAuditor.evaluateNearMiss(
            sidecarData: data, canonicalPath: "documentation/x/foo"
        )
        #expect(defaultGap == nil, "gap=75 exceeds default maxGap=50")

        let wideGap = try IndexabilityAuditor.evaluateNearMiss(
            sidecarData: data, canonicalPath: "documentation/x/foo",
            maxGap: 100
        )
        try #require(wideGap != nil)
        #expect(wideGap!.gap == 75)
    }

    @Test("Custom maxGap=0 surfaces zero candidates (disables near-miss detection)")
    func customMaxGapZeroDisablesCandidates() throws {
        let data = Self.sidecar(roleHeading: "Instance Method", textLength: 299)  // gap=1
        let candidate = try IndexabilityAuditor.evaluateNearMiss(
            sidecarData: data, canonicalPath: "documentation/x/foo",
            maxGap: 0
        )
        #expect(candidate == nil)
    }

    // MARK: evaluateNearMiss — out-of-scope inputs

    @Test("Article (no symbolKind) is NOT a candidate")
    func articleIsNotCandidate() throws {
        let data = Self.articleSidecar()
        let candidate = try IndexabilityAuditor.evaluateNearMiss(
            sidecarData: data, canonicalPath: "documentation/x/gettingstarted"
        )
        #expect(candidate == nil)
    }

    @Test("Unknown role heading is NOT a candidate")
    func unknownRoleHeadingIsNotCandidate() throws {
        let data = Self.sidecar(roleHeading: "UnknownKind", textLength: 250)
        let candidate = try IndexabilityAuditor.evaluateNearMiss(
            sidecarData: data, canonicalPath: "documentation/x/foo"
        )
        #expect(candidate == nil)
    }

    // MARK: auditModule integration

    @Test("auditModule populates candidates for near-miss pages NOT in allowlist")
    func auditModuleSurfacesCandidates() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            // Near-miss: gap=30, NOT in allowlist → candidate
            "p256k/near.json":   Self.sidecar(roleHeading: "Instance Method", textLength: 270),
            // Eligible: NOT in allowlist → newlyDiscovered, NOT candidate
            "p256k/big.json":    Self.sidecar(roleHeading: "Instance Method", textLength: 400),
            // Far-miss: gap=200, NOT in allowlist → silently dropped
            "p256k/tiny.json":   Self.sidecar(roleHeading: "Instance Method", textLength: 100),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let report = try IndexabilityAuditor.auditModule(
            module: "p256k",
            archivesRoot: root,
            currentAllowlist: []
        )
        #expect(report.candidates.map(\.path) == ["documentation/p256k/near"])
        #expect(report.candidates.first?.gap == 30)
    }

    @Test("auditModule excludes in-allowlist near-misses from candidates (they surface as stale)")
    func auditModuleExcludesAllowlistedFromCandidates() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/near.json": Self.sidecar(roleHeading: "Instance Method", textLength: 270),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        // near.json is in the allowlist — should show as stale, NOT as candidate.
        // Prevents double-counting the same page in two categories.
        let report = try IndexabilityAuditor.auditModule(
            module: "p256k",
            archivesRoot: root,
            currentAllowlist: ["documentation/p256k/near"]
        )
        #expect(report.candidates.isEmpty,
                "In-allowlist near-misses belong in .staleEntries, not .candidates")
        #expect(report.staleEntries.map(\.path) == ["documentation/p256k/near"])
    }

    @Test("auditModule respects excludedPathPrefixes for candidates")
    func auditModuleRespectsExclusionsForCandidates() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "tor/torclient.json":                 Self.sidecar(roleHeading: "Instance Method", textLength: 270),
            "tor/controlsocket/readline.json":    Self.sidecar(roleHeading: "Instance Method", textLength: 270),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let report = try IndexabilityAuditor.auditModule(
            module: "tor",
            archivesRoot: root,
            currentAllowlist: [],
            excludedPathPrefixes: ["documentation/tor/controlsocket/"]
        )
        // Only the non-excluded near-miss surfaces.
        #expect(report.candidates.map(\.path) == ["documentation/tor/torclient"])
    }

    @Test("auditModule sorts candidates by path")
    func auditModuleSortsCandidates() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/zebra.json": Self.sidecar(roleHeading: "Instance Method", textLength: 270),
            "p256k/alpha.json": Self.sidecar(roleHeading: "Instance Method", textLength: 270),
            "p256k/mango.json": Self.sidecar(roleHeading: "Instance Method", textLength: 270),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let report = try IndexabilityAuditor.auditModule(
            module: "p256k",
            archivesRoot: root,
            currentAllowlist: []
        )
        #expect(report.candidates.map(\.path) == [
            "documentation/p256k/alpha",
            "documentation/p256k/mango",
            "documentation/p256k/zebra",
        ])
    }

    @Test("auditModule candidateMaxGap override propagates to evaluateNearMiss")
    func auditModuleCandidateMaxGapOverride() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/close.json":  Self.sidecar(roleHeading: "Instance Method", textLength: 290),  // gap=10
            "p256k/medium.json": Self.sidecar(roleHeading: "Instance Method", textLength: 225),  // gap=75
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        // Default maxGap=50: only `close` surfaces.
        let defaultReport = try IndexabilityAuditor.auditModule(
            module: "p256k",
            archivesRoot: root,
            currentAllowlist: []
        )
        #expect(defaultReport.candidates.map(\.path) == ["documentation/p256k/close"])

        // Override maxGap=100: both surface.
        let wideReport = try IndexabilityAuditor.auditModule(
            module: "p256k",
            archivesRoot: root,
            currentAllowlist: [],
            candidateMaxGap: 100
        )
        #expect(wideReport.candidates.map(\.path) == [
            "documentation/p256k/close",
            "documentation/p256k/medium",
        ])
    }

    // MARK: AuditReport aggregation

    @Test("AuditReport.totalCandidates sums across modules")
    func auditReportAggregatesCandidates() {
        let m1 = IndexabilityAuditor.ModuleReport(
            module: "p256k", eligible: [], alreadyAllowed: [], newlyDiscovered: [],
            staleEntries: [],
            candidates: [
                .init(path: "documentation/p256k/a", reason: "r", gap: 10),
                .init(path: "documentation/p256k/b", reason: "r", gap: 20),
            ]
        )
        let m2 = IndexabilityAuditor.ModuleReport(
            module: "tor", eligible: [], alreadyAllowed: [], newlyDiscovered: [],
            staleEntries: [],
            candidates: [.init(path: "documentation/tor/c", reason: "r", gap: 30)]
        )
        let report = IndexabilityAuditor.AuditReport(modules: [m1, m2])
        #expect(report.totalCandidates == 3)
    }

    @Test("AuditReport.hasGap is UNCHANGED by candidates (informational only)")
    func candidatesDoNotAffectHasGap() {
        // Candidates alone must NOT flip hasGap — they're advisory, not drift.
        let candidatesOnly = IndexabilityAuditor.AuditReport(modules: [
            .init(module: "x", eligible: [], alreadyAllowed: [], newlyDiscovered: [],
                  staleEntries: [],
                  candidates: [.init(path: "documentation/x/a", reason: "r", gap: 10)])
        ])
        #expect(!candidatesOnly.hasGap,
                "Candidates are editorial polish, not drift — must not flip hasGap")
    }
}

// MARK: - evaluateAllowlistEntry Reason-Bucket Fix
//
// Bug: for a method-role page with an aside callout and prose below both the
// method threshold (300) AND the aside threshold (100), the stale reason
// string reports `method:…(need ≥300)` — the HIGHER, less-achievable
// threshold. Readers are told to add 201 chars when just 1 char would
// satisfy the more relevant aside bucket.
//
// Fix: when a method-role page has an aside AND fails both thresholds,
// report the aside bucket in the stale reason (the closer, more achievable
// target).

@Suite("IndexabilityAuditor — Stale Reason Bucket Selection")
struct IndexabilityAuditorStaleReasonTests {

    private static func makeFixtureRoot(sidecars: [String: Data]) throws -> URL {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("IndexabilityAuditorStaleReasonTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("documentation", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        for (relativePath, data) in sidecars {
            let url = tmp.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url)
        }
        return tmp
    }

    private static func sidecar(
        roleHeading: String, symbolKind: String,
        textLength: Int, includeAside: Bool
    ) -> Data {
        var content: [[String: Any]] = [
            [
                "type": "paragraph",
                "inlineContent": [
                    ["type": "text", "text": String(repeating: "x", count: textLength)] as [String: Any]
                ],
            ]
        ]
        if includeAside {
            content.append([
                "type": "aside",
                "style": "note",
                "content": [] as [Any],
            ])
        }
        let json: [String: Any] = [
            "metadata": ["roleHeading": roleHeading, "symbolKind": symbolKind],
            "primaryContentSections": [
                ["kind": "content", "content": content] as [String: Any]
            ],
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    @Test("Method with aside at chars=99 reports aside bucket in stale reason (gap=1, not gap=201)")
    func methodWithAsideReportsAsideBucketOnStale() throws {
        // Real-world page: documentation/p256k/p256k/recovery/ecdsasignature/init(compactrepresentation:recoveryid:)
        // — method role + aside callout + 99 chars. Pre-fix reported
        // `method:Initializer:disc=99 (need ≥300)` (implying need 201 more chars).
        // Post-fix reports `aside:Initializer:disc=99 (need ≥100)` (just 1 char).
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/init.json": Self.sidecar(
                roleHeading: "Initializer", symbolKind: "init",
                textLength: 99, includeAside: true
            )
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let status = try IndexabilityAuditor.evaluateAllowlistEntry(
            allowlistPath: "documentation/p256k/init",
            archivesRoot: root
        )
        guard case .stale(let entry) = status else {
            Issue.record("expected .stale, got \(status)")
            return
        }
        #expect(entry.reason.contains("aside:Initializer"),
                "Aside-bearing method must report aside bucket; got: \(entry.reason)")
        #expect(entry.reason.contains("disc=99"))
        #expect(entry.reason.contains("≥100"),
                "Aside bucket threshold (100) must be reported; got: \(entry.reason)")
        #expect(!entry.reason.contains("≥300"),
                "Method bucket threshold (300) must NOT be reported for aside-bearing pages")
    }

    @Test("Method without aside at chars=99 still reports method bucket (≥300)")
    func methodWithoutAsideReportsMethodBucketOnStale() throws {
        // Sanity: the aside-bucket override must NOT affect pages without asides.
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/init.json": Self.sidecar(
                roleHeading: "Initializer", symbolKind: "init",
                textLength: 99, includeAside: false
            )
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let status = try IndexabilityAuditor.evaluateAllowlistEntry(
            allowlistPath: "documentation/p256k/init",
            archivesRoot: root
        )
        guard case .stale(let entry) = status else {
            Issue.record("expected .stale, got \(status)")
            return
        }
        #expect(entry.reason.contains("method:Initializer"))
        #expect(entry.reason.contains("≥300"))
        #expect(!entry.reason.contains("aside:"))
    }
}

// MARK: - Article Drift Detection
//
// Articles (`metadata.role == "article"`, no `symbolKind`) are hand-curated
// in per-module `llms.txt` files — they are NOT policy-gated. But the auditor
// must still surface drift between archives and the registry so future bumps
// catch newly-shipped articles before they get noindex'd in the live site.
// `newArticles` is informational only; it does NOT contribute to `hasGap`
// or flip `--strict` exit codes (matches the `candidates` semantics).

@Suite("IndexabilityAuditor — Article Drift")
struct IndexabilityAuditorArticleTests {

    // MARK: Fixture helpers

    /// Build an article sidecar (role=article, no symbolKind).
    private static func articleSidecar(
        title: String = "An Article",
        textLength: Int = 500
    ) -> Data {
        let json: [String: Any] = [
            "metadata": [
                "role": "article",
                "title": title,
            ],
            "primaryContentSections": [
                [
                    "kind": "content",
                    "content": [
                        [
                            "type": "paragraph",
                            "inlineContent": [
                                ["type": "text", "text": String(repeating: "a", count: textLength)] as [String: Any]
                            ],
                        ] as [String: Any]
                    ],
                ] as [String: Any]
            ],
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    /// Build a symbol-page sidecar (has symbolKind — NOT an article).
    private static func symbolSidecar(textLength: Int = 250) -> Data {
        let json: [String: Any] = [
            "metadata": [
                "roleHeading": "Structure",
                "symbolKind": "struct",
                "role": "symbol",
            ],
            "primaryContentSections": [
                [
                    "kind": "content",
                    "content": [
                        [
                            "type": "paragraph",
                            "inlineContent": [
                                ["type": "text", "text": String(repeating: "x", count: textLength)] as [String: Any]
                            ],
                        ] as [String: Any]
                    ],
                ] as [String: Any]
            ],
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    /// Build an auto-generated collection-group landing (role=collectionGroup, no symbolKind).
    /// Mirrors DocC's `LocalizedError-Implementations` / `Error-Implementations` shape.
    private static func collectionGroupSidecar() -> Data {
        let json: [String: Any] = [
            "metadata": [
                "role": "collectionGroup",
                "title": "LocalizedError Implementations",
            ],
            "primaryContentSections": [] as [Any],
        ]
        return try! JSONSerialization.data(withJSONObject: json, options: [])
    }

    private static func makeFixtureRoot(sidecars: [String: Data]) throws -> URL {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("IndexabilityAuditorArticleTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("documentation", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        for (relativePath, data) in sidecars {
            let url = tmp.appendingPathComponent(relativePath)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url)
        }
        return tmp
    }

    // MARK: evaluateArticle — per-sidecar classification

    @Test("evaluateArticle returns ArticleEntry for sidecar with role=article")
    func articleDetected() throws {
        let data = Self.articleSidecar(title: "Getting Started", textLength: 750)
        let entry = try IndexabilityAuditor.evaluateArticle(
            sidecarData: data,
            canonicalPath: "documentation/event/gettingstarted"
        )
        try #require(entry != nil)
        #expect(entry!.path == "documentation/event/gettingstarted")
        #expect(entry!.title == "Getting Started")
        #expect(entry!.chars == 750)
    }

    @Test("evaluateArticle returns nil for symbol pages (has symbolKind)")
    func symbolPagesNotArticles() throws {
        let data = Self.symbolSidecar()
        let entry = try IndexabilityAuditor.evaluateArticle(
            sidecarData: data,
            canonicalPath: "documentation/event/eventloop"
        )
        #expect(entry == nil)
    }

    @Test("evaluateArticle returns nil for collectionGroup landings (auto-generated)")
    func collectionGroupNotArticle() throws {
        let data = Self.collectionGroupSidecar()
        let entry = try IndexabilityAuditor.evaluateArticle(
            sidecarData: data,
            canonicalPath: "documentation/event/socketerror/localizederror-implementations"
        )
        #expect(entry == nil)
    }

    @Test("evaluateArticle returns nil for malformed sidecar JSON")
    func malformedSidecarNotArticle() throws {
        let data = Data("not valid json".utf8)
        let entry = try IndexabilityAuditor.evaluateArticle(
            sidecarData: data,
            canonicalPath: "documentation/event/junk"
        )
        #expect(entry == nil)
    }

    @Test("evaluateArticle falls back to title='?' when metadata.title is missing")
    func articleMissingTitleFallback() throws {
        // Minimal article-shape sidecar without a title field.
        let json: [String: Any] = [
            "metadata": ["role": "article"],
            "primaryContentSections": [] as [Any],
        ]
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        let entry = try IndexabilityAuditor.evaluateArticle(
            sidecarData: data,
            canonicalPath: "documentation/event/untitled"
        )
        try #require(entry != nil)
        #expect(entry!.title == "?")
    }

    // MARK: auditModule integration

    @Test("auditModule populates newArticles for articles NOT in allowlist")
    func auditModuleSurfacesNewArticles() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "event/gettingstarted.json":   Self.articleSidecar(title: "Getting Started", textLength: 500),
            "event/newarticle.json":       Self.articleSidecar(title: "Brand New Article", textLength: 4000),
            "event/eventloop.json":        Self.symbolSidecar(textLength: 250),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let report = try IndexabilityAuditor.auditModule(
            module: "event",
            archivesRoot: root,
            // gettingstarted is in the allowlist; newarticle is NOT.
            currentAllowlist: ["documentation/event/gettingstarted", "documentation/event/eventloop"]
        )
        #expect(report.newArticles.map(\.path) == ["documentation/event/newarticle"])
        #expect(report.newArticles.first?.title == "Brand New Article")
        #expect(report.newArticles.first?.chars == 4000)
    }

    @Test("auditModule excludes already-allowlisted articles from newArticles")
    func auditModuleExcludesAllowlistedArticles() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "event/gettingstarted.json": Self.articleSidecar(textLength: 500),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let report = try IndexabilityAuditor.auditModule(
            module: "event",
            archivesRoot: root,
            currentAllowlist: ["documentation/event/gettingstarted"]
        )
        #expect(report.newArticles.isEmpty,
                "Articles already in the allowlist must not surface as drift; got \(report.newArticles.map(\.path))")
    }

    @Test("auditModule excludes symbol pages from newArticles (even if not in allowlist)")
    func auditModuleExcludesSymbolsFromArticles() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "event/eventloop.json": Self.symbolSidecar(textLength: 250),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let report = try IndexabilityAuditor.auditModule(
            module: "event",
            archivesRoot: root,
            currentAllowlist: []
        )
        #expect(report.newArticles.isEmpty,
                "Symbol pages must not appear in newArticles (they go through the symbol policy path)")
    }

    @Test("auditModule sorts newArticles by path")
    func auditModuleSortsNewArticles() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "event/zebra.json": Self.articleSidecar(title: "Zebra", textLength: 500),
            "event/alpha.json": Self.articleSidecar(title: "Alpha", textLength: 500),
            "event/mango.json": Self.articleSidecar(title: "Mango", textLength: 500),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let report = try IndexabilityAuditor.auditModule(
            module: "event",
            archivesRoot: root,
            currentAllowlist: []
        )
        #expect(report.newArticles.map(\.path) == [
            "documentation/event/alpha",
            "documentation/event/mango",
            "documentation/event/zebra",
        ])
    }

    @Test("auditModule respects excludedPathPrefixes for newArticles")
    func auditModuleRespectsExclusionsForArticles() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "tor/torclientarticle.json":            Self.articleSidecar(textLength: 500),
            "tor/controlsocket/internalarticle.json": Self.articleSidecar(textLength: 500),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let report = try IndexabilityAuditor.auditModule(
            module: "tor",
            archivesRoot: root,
            currentAllowlist: [],
            excludedPathPrefixes: ["documentation/tor/controlsocket/"]
        )
        #expect(report.newArticles.map(\.path) == ["documentation/tor/torclientarticle"])
    }

    // MARK: AuditReport aggregation

    @Test("AuditReport.totalNewArticles sums across modules")
    func auditReportAggregatesNewArticles() {
        let m1 = IndexabilityAuditor.ModuleReport(
            module: "event", eligible: [], alreadyAllowed: [], newlyDiscovered: [],
            newArticles: [
                .init(path: "documentation/event/a", chars: 500, title: "A"),
                .init(path: "documentation/event/b", chars: 600, title: "B"),
            ]
        )
        let m2 = IndexabilityAuditor.ModuleReport(
            module: "tor", eligible: [], alreadyAllowed: [], newlyDiscovered: [],
            newArticles: [.init(path: "documentation/tor/c", chars: 700, title: "C")]
        )
        let report = IndexabilityAuditor.AuditReport(modules: [m1, m2])
        #expect(report.totalNewArticles == 3)
    }

    @Test("AuditReport.hasGap is NOT flipped by newArticles alone (advisory only)")
    func newArticlesDoNotFlipHasGap() {
        let report = IndexabilityAuditor.AuditReport(modules: [
            .init(
                module: "event", eligible: [], alreadyAllowed: [], newlyDiscovered: [],
                newArticles: [.init(path: "documentation/event/a", chars: 500, title: "A")]
            )
        ])
        // newArticles is editorial drift, not policy drift — must behave like candidates.
        #expect(!report.hasGap)
        #expect(report.totalNewArticles == 1)
    }
}
