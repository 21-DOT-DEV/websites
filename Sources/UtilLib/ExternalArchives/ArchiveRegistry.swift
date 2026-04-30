//
//  ArchiveRegistry.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Decoded shape of `Resources/docs-21-dev/external-archives.json`.
///
/// This is the Swift-side schema for the external-archives config file. It
/// mirrors the JSON Schema at `Resources/docs-21-dev/external-archives.schema.json`.
/// If either shape changes, both must be updated together.
///
/// ## Responsibilities
///
/// The registry has three concerns:
///
/// 1. **Archive fetching** (`Archive.repo`, `tag`, `artifact`, `sha256`, `bundleID`) —
///    metadata used by CI to download and `docc merge` external doccarchives.
/// 2. **Search-indexability** (`Archive.indexablePages`, `Globals.hubs`) —
///    DocC page paths that should NOT receive `<meta name="robots" content="noindex">`.
///    Per-archive lists co-version with archive releases; cross-cutting hubs
///    (site root, namespace pages) live in `Globals`.
/// 3. **Breadcrumb display names** (`Archive.knownNames`, `Globals.knownNames`) —
///    overrides for URL-segment → display-name resolution. Single-word segments
///    use capitalize-first fallback; only multi-word compounds need entries.
///
/// ## Loading
///
/// Use `ArchiveRegistry.loadDefault()` to load from the standard CWD-relative
/// path (`Resources/docs-21-dev/external-archives.json`). Tests that need a
/// custom path should use `ArchiveRegistry.load(from:)`.
public struct ArchiveRegistry: Decodable, Sendable, Equatable {

    /// Cross-cutting metadata not owned by any single archive.
    public struct Globals: Decodable, Sendable, Equatable {
        /// Top-level navigation pages (e.g., docs root, namespace hubs) that
        /// should be search-indexable but don't belong to a specific archive.
        public let hubs: [String]

        /// Display-name overrides applied across all archives.
        public let knownNames: [String: String]

        public init(hubs: [String] = [], knownNames: [String: String] = [:]) {
            self.hubs = hubs
            self.knownNames = knownNames
        }

        private enum CodingKeys: String, CodingKey {
            case hubs
            case knownNames
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.hubs = try container.decodeIfPresent([String].self, forKey: .hubs) ?? []
            self.knownNames = try container.decodeIfPresent([String: String].self, forKey: .knownNames) ?? [:]
        }
    }

    /// A single external archive entry.
    public struct Archive: Decodable, Sendable, Equatable {
        public let repo: String
        public let tag: String
        public let artifact: String
        public let sha256: String
        public let bundleID: String
        public let indexablePages: [String]?
        public let knownNames: [String: String]?

        public init(
            repo: String,
            tag: String,
            artifact: String,
            sha256: String,
            bundleID: String,
            indexablePages: [String]? = nil,
            knownNames: [String: String]? = nil
        ) {
            self.repo = repo
            self.tag = tag
            self.artifact = artifact
            self.sha256 = sha256
            self.bundleID = bundleID
            self.indexablePages = indexablePages
            self.knownNames = knownNames
        }
    }

    /// Cross-cutting registry-level metadata. Defaults to empty `hubs` and
    /// `knownNames` when omitted from the JSON file (Phase 1 migration safety).
    public let globals: Globals

    /// Per-archive entries, keyed by archive identifier (e.g., `"p256k"`, `"tor"`).
    public let archives: [String: Archive]

    public init(globals: Globals = Globals(), archives: [String: Archive]) {
        self.globals = globals
        self.archives = archives
    }

    private enum CodingKeys: String, CodingKey {
        case globals
        case archives
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.globals = try container.decodeIfPresent(Globals.self, forKey: .globals) ?? Globals()
        self.archives = try container.decode([String: Archive].self, forKey: .archives)
    }
}

// MARK: - Loading

extension ArchiveRegistry {

    /// Errors raised by `ArchiveRegistry` loaders.
    public enum LoadError: Error, CustomStringConvertible {
        case fileNotFound(URL)
        case decodingFailed(URL, underlying: Error)

        public var description: String {
            switch self {
            case .fileNotFound(let url):
                return "ArchiveRegistry: external-archives.json not found at \(url.path)"
            case .decodingFailed(let url, let underlying):
                return "ArchiveRegistry: failed to decode \(url.path): \(underlying)"
            }
        }
    }

    /// Standard relative path of the registry file from the package root.
    public static let defaultRelativePath = "Resources/docs-21-dev/external-archives.json"

    /// Loads the registry from the standard path, anchored at the current
    /// working directory. SPM tests and the `util` executable both run with
    /// CWD set to the package root, so this resolves to
    /// `<package>/Resources/docs-21-dev/external-archives.json`.
    ///
    /// - Throws: `LoadError.fileNotFound` if the file is missing,
    ///   `LoadError.decodingFailed` if JSON decoding fails.
    public static func loadDefault() throws -> ArchiveRegistry {
        let cwd = FileManager.default.currentDirectoryPath
        let url = URL(fileURLWithPath: cwd).appendingPathComponent(defaultRelativePath)
        return try load(from: url)
    }

    /// Loads the registry from an explicit file URL.
    ///
    /// - Parameter url: Absolute file URL of `external-archives.json`.
    /// - Throws: `LoadError.fileNotFound` if the file is missing,
    ///   `LoadError.decodingFailed` if JSON decoding fails.
    public static func load(from url: URL) throws -> ArchiveRegistry {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw LoadError.fileNotFound(url)
        }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LoadError.fileNotFound(url)
        }
        do {
            return try JSONDecoder().decode(ArchiveRegistry.self, from: data)
        } catch {
            throw LoadError.decodingFailed(url, underlying: error)
        }
    }
}

// MARK: - Aggregation Helpers

extension ArchiveRegistry {

    /// All search-indexable page paths, aggregated across `globals.hubs` and
    /// every archive's `indexablePages`.
    public var allIndexablePages: Set<String> {
        var pages = Set(globals.hubs)
        for archive in archives.values {
            pages.formUnion(archive.indexablePages ?? [])
        }
        return pages
    }

    /// All known display-name overrides, with archive-specific entries
    /// overriding global entries on key collision (archive-specific wins).
    public var allKnownNames: [String: String] {
        var names = globals.knownNames
        for archive in archives.values {
            for (key, value) in archive.knownNames ?? [:] {
                names[key] = value
            }
        }
        return names
    }
}
