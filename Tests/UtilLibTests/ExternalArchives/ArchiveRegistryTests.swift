//
//  ArchiveRegistryTests.swift
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

/// Validates the registry-level fields introduced in Phase 1 of the
/// archive-registry refactor (`globals`, per-archive `indexablePages`,
/// per-archive `knownNames`).
///
/// These tests are tolerant of empty/missing collections during Phase 1
/// (when the JSON file has not yet been migrated). After Phase 2 lands,
/// `globals.hubs` is expected to be non-empty.
@Suite("ArchiveRegistryTests")
struct ArchiveRegistryTests {

    private static let pathPattern = #"^documentation(/[^\s]*)?$"#
    private static let displayNamePattern = #"^.+$"#

    private static func loadRegistry() throws -> ArchiveRegistry {
        try ArchiveRegistry.loadDefault()
    }

    // MARK: - Schema decoding

    @Test("registry decodes with optional fields treated as defaults")
    func decodesWithOptionals() throws {
        let json = #"""
        {
          "archives": {
            "minimal": {
              "repo": "owner/name",
              "tag": "1.0.0",
              "artifact": "Foo.zip",
              "sha256": "0000000000000000000000000000000000000000000000000000000000000000",
              "bundleID": "Foo"
            }
          }
        }
        """#
        let data = json.data(using: .utf8)!
        let registry = try JSONDecoder().decode(ArchiveRegistry.self, from: data)
        #expect(registry.globals.hubs.isEmpty, "globals.hubs defaults to empty when omitted")
        #expect(registry.globals.knownNames.isEmpty, "globals.knownNames defaults to empty when omitted")
        #expect(registry.archives["minimal"]?.indexablePages == nil)
        #expect(registry.archives["minimal"]?.knownNames == nil)
    }

    @Test("registry decodes with full fields populated")
    func decodesWithFullFields() throws {
        let json = #"""
        {
          "globals": {
            "hubs": ["documentation"],
            "knownNames": { "documentation": "API Reference" }
          },
          "archives": {
            "p256k": {
              "repo": "owner/name",
              "tag": "1.0.0",
              "artifact": "P256K.zip",
              "sha256": "0000000000000000000000000000000000000000000000000000000000000000",
              "bundleID": "P256K",
              "indexablePages": ["documentation/p256k"],
              "knownNames": { "p256k": "P256K" }
            }
          }
        }
        """#
        let data = json.data(using: .utf8)!
        let registry = try JSONDecoder().decode(ArchiveRegistry.self, from: data)
        #expect(registry.globals.hubs == ["documentation"])
        #expect(registry.globals.knownNames["documentation"] == "API Reference")
        #expect(registry.archives["p256k"]?.indexablePages == ["documentation/p256k"])
        #expect(registry.archives["p256k"]?.knownNames?["p256k"] == "P256K")
    }

    // MARK: - File-content invariants

    @Test("every globals.hubs entry starts with `documentation`")
    func hubsHaveValidPrefix() throws {
        let registry = try Self.loadRegistry()
        for hub in registry.globals.hubs {
            #expect(
                hub.range(of: Self.pathPattern, options: .regularExpression) != nil,
                "globals.hubs entry must match ^documentation(/...)? — got: \(hub)"
            )
        }
    }

    @Test("every per-archive indexablePages entry starts with `documentation/`")
    func indexablePagesHaveValidPrefix() throws {
        let registry = try Self.loadRegistry()
        for (key, archive) in registry.archives {
            for page in archive.indexablePages ?? [] {
                #expect(
                    page.hasPrefix("documentation/"),
                    "archives[\(key)].indexablePages entry must start with documentation/ — got: \(page)"
                )
            }
        }
    }

    @Test("indexablePages have no duplicates across all archives + globals")
    func indexablePagesUniqueAcrossArchives() throws {
        let registry = try Self.loadRegistry()
        var seen: [String: String] = [:]   // page → first-source-key
        var duplicates: [String] = []
        for hub in registry.globals.hubs {
            seen[hub] = "globals.hubs"
        }
        for (key, archive) in registry.archives {
            for page in archive.indexablePages ?? [] {
                if let existing = seen[page] {
                    duplicates.append("\(page) is in both \(existing) and archives[\(key)]")
                } else {
                    seen[page] = "archives[\(key)]"
                }
            }
        }
        #expect(duplicates.isEmpty, "Duplicate indexablePages entries: \(duplicates)")
    }

    @Test("every knownNames key is a non-empty lowercased URL slug")
    func knownNamesKeysAreSlugs() throws {
        let registry = try Self.loadRegistry()
        let slugPattern = #"^[a-z0-9][a-z0-9_-]*$"#

        for (key, value) in registry.globals.knownNames {
            #expect(
                key.range(of: slugPattern, options: .regularExpression) != nil,
                "globals.knownNames key '\(key)' must be a lowercase URL slug"
            )
            #expect(!value.isEmpty, "globals.knownNames['\(key)'] must be non-empty")
        }

        for (archiveKey, archive) in registry.archives {
            for (slugKey, displayName) in archive.knownNames ?? [:] {
                #expect(
                    slugKey.range(of: slugPattern, options: .regularExpression) != nil,
                    "archives[\(archiveKey)].knownNames key '\(slugKey)' must be a lowercase URL slug"
                )
                #expect(!displayName.isEmpty, "archives[\(archiveKey)].knownNames['\(slugKey)'] must be non-empty")
            }
        }
    }

    // MARK: - Aggregation helpers

    @Test("allIndexablePages aggregates globals.hubs and per-archive indexablePages")
    func allIndexablePagesAggregates() throws {
        let registry = ArchiveRegistry(
            globals: .init(hubs: ["documentation"], knownNames: [:]),
            archives: [
                "alpha": .init(
                    repo: "a/b", tag: "1", artifact: "x.zip",
                    sha256: String(repeating: "0", count: 64),
                    bundleID: "Alpha",
                    indexablePages: ["documentation/alpha"]
                )
            ]
        )
        let all = registry.allIndexablePages
        #expect(all == Set(["documentation", "documentation/alpha"]))
    }

    @Test("allKnownNames merges globals + archive entries (archive wins on collision)")
    func allKnownNamesArchiveWinsOnCollision() throws {
        let registry = ArchiveRegistry(
            globals: .init(hubs: [], knownNames: ["foo": "GlobalFoo"]),
            archives: [
                "bar": .init(
                    repo: "a/b", tag: "1", artifact: "x.zip",
                    sha256: String(repeating: "0", count: 64),
                    bundleID: "Bar",
                    indexablePages: nil,
                    knownNames: ["foo": "ArchiveFoo", "baz": "Baz"]
                )
            ]
        )
        let all = registry.allKnownNames
        #expect(all["foo"] == "ArchiveFoo", "archive-specific knownNames must win on key collision")
        #expect(all["baz"] == "Baz")
    }
}
