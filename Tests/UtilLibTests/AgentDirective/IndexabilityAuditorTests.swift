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

    @Test("evaluateAllowlistEntry returns .outOfScope when no sidecar exists")
    func outOfScopeNoSidecar() throws {
        let root = try Self.makeFixtureRoot(sidecars: [:])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        let status = try IndexabilityAuditor.evaluateAllowlistEntry(
            allowlistPath: "documentation/p256k/missing",
            archivesRoot: root
        )
        guard case .outOfScope(let reason) = status else {
            Issue.record("expected .outOfScope, got \(status)")
            return
        }
        #expect(reason.contains("no sidecar"))
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

    @Test("auditModule does NOT mark hub-like allowlist entries (no sidecar) as stale")
    func auditModuleSkipsHubsInStaleCheck() throws {
        let root = try Self.makeFixtureRoot(sidecars: [
            "p256k/big.json": Self.symbolSidecar(roleHeading: "Structure", symbolKind: "struct", textLength: 250),
        ])
        defer { try? FileManager.default.removeItem(at: root.deletingLastPathComponent()) }

        // 'documentation/p256k/p256k' has no sidecar → out-of-scope, NOT stale.
        let report = try IndexabilityAuditor.auditModule(
            module: "p256k",
            archivesRoot: root,
            currentAllowlist: ["documentation/p256k/big", "documentation/p256k/p256k"]
        )
        #expect(report.staleEntries.isEmpty,
                "Hub entries with no sidecar must not be flagged as stale; got \(report.staleEntries.map(\.path))")
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
}
