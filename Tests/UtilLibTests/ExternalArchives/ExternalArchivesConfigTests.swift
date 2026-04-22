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

/// Codable shape of `Resources/docs-21-dev/external-archives.json`.
///
/// This struct is the Swift-side schema for the external-archives config file.
/// It mirrors the JSON Schema at `Resources/docs-21-dev/external-archives.schema.json`.
/// If either shape changes, both must be updated together.
private struct ExternalArchives: Decodable {
    struct Archive: Decodable {
        let repo: String
        let tag: String
        let artifact: String
        let sha256: String
        let bundleID: String
    }
    let archives: [String: Archive]
}

@Suite("ExternalArchivesConfigTests")
struct ExternalArchivesConfigTests {

    /// Returns the absolute path to `Resources/docs-21-dev/external-archives.json`,
    /// anchored at the current working directory (SPM runs tests from the package root).
    private static func configFileURL() -> URL {
        let cwd = FileManager.default.currentDirectoryPath
        return URL(fileURLWithPath: cwd)
            .appendingPathComponent("Resources")
            .appendingPathComponent("docs-21-dev")
            .appendingPathComponent("external-archives.json")
    }

    // Regex patterns from the JSON Schema (stored as String literals to avoid
    // Swift 6 concurrency warnings about static non-Sendable Regex<Substring> values).
    private static let sha256Pattern = "^[0-9a-f]{64}$"
    private static let repoPattern = #"^[^/]+/[^/]+$"#

    @Test("external-archives.json decodes into ExternalArchives")
    func decodes() throws {
        let url = Self.configFileURL()
        let data = try Data(contentsOf: url)
        _ = try JSONDecoder().decode(ExternalArchives.self, from: data)
    }

    @Test("external-archives.json has at least one archive entry")
    func hasAtLeastOneArchive() throws {
        let url = Self.configFileURL()
        let data = try Data(contentsOf: url)
        let config = try JSONDecoder().decode(ExternalArchives.self, from: data)
        #expect(!config.archives.isEmpty, "external-archives.json must declare at least one archive")
    }

    @Test("every archive `sha256` is 64 lowercase hex characters")
    func sha256IsValidHex() throws {
        let url = Self.configFileURL()
        let data = try Data(contentsOf: url)
        let config = try JSONDecoder().decode(ExternalArchives.self, from: data)

        for (key, archive) in config.archives {
            #expect(
                archive.sha256.range(of: Self.sha256Pattern, options: .regularExpression) != nil,
                "archives[\(key)].sha256 must match ^[0-9a-f]{64}$ (got: \(archive.sha256))"
            )
        }
    }

    @Test("every archive `repo` is in owner/name form")
    func repoIsOwnerName() throws {
        let url = Self.configFileURL()
        let data = try Data(contentsOf: url)
        let config = try JSONDecoder().decode(ExternalArchives.self, from: data)

        for (key, archive) in config.archives {
            #expect(
                archive.repo.range(of: Self.repoPattern, options: .regularExpression) != nil,
                "archives[\(key)].repo must match owner/name (got: \(archive.repo))"
            )
        }
    }

    @Test("every archive `artifact` ends in .zip")
    func artifactEndsInZip() throws {
        let url = Self.configFileURL()
        let data = try Data(contentsOf: url)
        let config = try JSONDecoder().decode(ExternalArchives.self, from: data)

        for (key, archive) in config.archives {
            #expect(
                archive.artifact.hasSuffix(".zip"),
                "archives[\(key)].artifact must end in .zip (got: \(archive.artifact))"
            )
        }
    }

    @Test("every archive has non-empty `tag`")
    func tagNonEmpty() throws {
        let url = Self.configFileURL()
        let data = try Data(contentsOf: url)
        let config = try JSONDecoder().decode(ExternalArchives.self, from: data)

        for (key, archive) in config.archives {
            #expect(
                !archive.tag.isEmpty,
                "archives[\(key)].tag must be non-empty"
            )
        }
    }

    @Test("every archive has non-empty `bundleID`")
    func bundleIDNonEmpty() throws {
        let url = Self.configFileURL()
        let data = try Data(contentsOf: url)
        let config = try JSONDecoder().decode(ExternalArchives.self, from: data)

        for (key, archive) in config.archives {
            #expect(
                !archive.bundleID.isEmpty,
                "archives[\(key)].bundleID must be non-empty"
            )
        }
    }

    @Test("bundle IDs are unique across archives")
    func bundleIDsAreUnique() throws {
        let url = Self.configFileURL()
        let data = try Data(contentsOf: url)
        let config = try JSONDecoder().decode(ExternalArchives.self, from: data)

        let ids = config.archives.values.map(\.bundleID)
        let uniqueIDs = Set(ids)
        #expect(
            ids.count == uniqueIDs.count,
            "bundleID values must be unique across archives to avoid docc merge collisions"
        )
    }
}
