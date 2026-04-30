//
//  ExternalArchivesConfigTests.swift
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

/// Validates the fetch-related fields of `external-archives.json` against the
/// JSON Schema's regex patterns. Indexability and breadcrumb-name fields are
/// covered by `ArchiveRegistryTests`.
@Suite("ExternalArchivesConfigTests")
struct ExternalArchivesConfigTests {

    // Regex patterns from the JSON Schema (stored as String literals to avoid
    // Swift 6 concurrency warnings about static non-Sendable Regex<Substring> values).
    private static let sha256Pattern = "^[0-9a-f]{64}$"
    private static let repoPattern = #"^[^/]+/[^/]+$"#

    private static func loadRegistry() throws -> ArchiveRegistry {
        try ArchiveRegistry.loadDefault()
    }

    @Test("external-archives.json decodes into ArchiveRegistry")
    func decodes() throws {
        _ = try Self.loadRegistry()
    }

    @Test("external-archives.json has at least one archive entry")
    func hasAtLeastOneArchive() throws {
        let config = try Self.loadRegistry()
        #expect(!config.archives.isEmpty, "external-archives.json must declare at least one archive")
    }

    @Test("every archive `sha256` is 64 lowercase hex characters")
    func sha256IsValidHex() throws {
        let config = try Self.loadRegistry()

        for (key, archive) in config.archives {
            #expect(
                archive.sha256.range(of: Self.sha256Pattern, options: .regularExpression) != nil,
                "archives[\(key)].sha256 must match ^[0-9a-f]{64}$ (got: \(archive.sha256))"
            )
        }
    }

    @Test("every archive `repo` is in owner/name form")
    func repoIsOwnerName() throws {
        let config = try Self.loadRegistry()

        for (key, archive) in config.archives {
            #expect(
                archive.repo.range(of: Self.repoPattern, options: .regularExpression) != nil,
                "archives[\(key)].repo must match owner/name (got: \(archive.repo))"
            )
        }
    }

    @Test("every archive `artifact` ends in .zip")
    func artifactEndsInZip() throws {
        let config = try Self.loadRegistry()

        for (key, archive) in config.archives {
            #expect(
                archive.artifact.hasSuffix(".zip"),
                "archives[\(key)].artifact must end in .zip (got: \(archive.artifact))"
            )
        }
    }

    @Test("every archive has non-empty `tag`")
    func tagNonEmpty() throws {
        let config = try Self.loadRegistry()

        for (key, archive) in config.archives {
            #expect(
                !archive.tag.isEmpty,
                "archives[\(key)].tag must be non-empty"
            )
        }
    }

    @Test("every archive has non-empty `bundleID`")
    func bundleIDNonEmpty() throws {
        let config = try Self.loadRegistry()

        for (key, archive) in config.archives {
            #expect(
                !archive.bundleID.isEmpty,
                "archives[\(key)].bundleID must be non-empty"
            )
        }
    }

    @Test("bundle IDs are unique across archives")
    func bundleIDsAreUnique() throws {
        let config = try Self.loadRegistry()

        let ids = config.archives.values.map(\.bundleID)
        let uniqueIDs = Set(ids)
        #expect(
            ids.count == uniqueIDs.count,
            "bundleID values must be unique across archives to avoid docc merge collisions"
        )
    }
}
