//
//  DocCSidecarLoader.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Locates and decodes DocC page-data sidecars next to rendered HTML.
///
/// Sidecar discovery uses the same path transformation as the markdown
/// derivation in `AgentDirectiveInjector` — strip the trailing `index.html`
/// (or `.html`), then prepend `data/` and append `.json`.
///
/// This loader exposes two flavors:
///
/// 1. `load(...)` — strict, throws on missing-or-malformed sidecars. Used in
///    tests and when callers want to surface every failure.
/// 2. `loadIfPresent(...)` — tolerant, returns `nil` for sidecars that do not
///    exist (top-level `documentation/index.html` and similar) and surfaces
///    parse failures separately. Used by `AgentDirectiveInjector` so a single
///    bad sidecar never aborts a multi-thousand-page injection run.
public enum DocCSidecarLoader {

    /// Errors surfaced from sidecar lookup / decoding.
    public enum LoadError: Error, Sendable, CustomStringConvertible {
        /// Sidecar JSON was not present on disk.
        case fileNotFound(absolutePath: String)

        /// Sidecar JSON was present but failed to decode.
        case invalidJSON(absolutePath: String, underlying: String)

        public var description: String {
            switch self {
            case .fileNotFound(let path):
                return "DocC sidecar not found at: \(path)"
            case .invalidJSON(let path, let underlying):
                return "DocC sidecar parse failure at \(path): \(underlying)"
            }
        }
    }

    /// Result of a tolerant sidecar lookup.
    public enum LoadOutcome: Sendable {
        /// Sidecar was present and decoded successfully.
        case loaded(DocCSidecar)

        /// Sidecar was not present (expected for landing / top-level pages).
        case missing

        /// Sidecar was present but failed to decode. Caller should report
        /// and decide whether to fail the build at the summary level.
        case failed(absolutePath: String, message: String)
    }

    /// Derives the relative sidecar JSON path from an HTML relative path.
    ///
    /// Mirrors `AgentDirectiveInjector.deriveMarkdownRelativePath` but
    /// substitutes the `.json` extension.
    ///
    /// - `documentation/p256k/p256k/context/index.html`
    ///   → `data/documentation/p256k/p256k/context.json`
    /// - `documentation/p256k/gettingstarted.html`
    ///   → `data/documentation/p256k/gettingstarted.json`
    /// - `documentation/p256k/index.html`
    ///   → `data/documentation/p256k.json`
    ///
    /// - Parameter relativePath: HTML path relative to the docs output root.
    /// - Returns: Sidecar JSON path relative to the docs output root.
    public static func deriveSidecarRelativePath(from relativePath: String) -> String {
        var path = relativePath
        if path.hasSuffix("/index.html") {
            path = String(path.dropLast("/index.html".count))
        } else if path.hasSuffix(".html") {
            path = String(path.dropLast(".html".count))
        }
        return "data/" + path + ".json"
    }

    /// Strict sidecar loader. Throws `LoadError` for any failure.
    ///
    /// - Parameters:
    ///   - relativePath: HTML path relative to `directoryPath`.
    ///   - directoryPath: Absolute path to the docs output root
    ///     (e.g., `/.../Websites/docs-21-dev`).
    /// - Returns: Decoded `DocCSidecar`.
    /// - Throws: `LoadError.fileNotFound` or `LoadError.invalidJSON`.
    public static func load(relativePath: String, in directoryPath: String) throws -> DocCSidecar {
        let sidecarRel = deriveSidecarRelativePath(from: relativePath)
        let absolute = (directoryPath as NSString).appendingPathComponent(sidecarRel)

        guard FileManager.default.fileExists(atPath: absolute) else {
            throw LoadError.fileNotFound(absolutePath: absolute)
        }

        let url = URL(fileURLWithPath: absolute)
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw LoadError.invalidJSON(
                absolutePath: absolute,
                underlying: error.localizedDescription
            )
        }

        do {
            return try JSONDecoder().decode(DocCSidecar.self, from: data)
        } catch {
            throw LoadError.invalidJSON(
                absolutePath: absolute,
                underlying: String(describing: error)
            )
        }
    }

    /// Tolerant sidecar loader. Distinguishes "not present" from "present but
    /// malformed" so callers can keep going while still recording parse
    /// failures for a summary-level threshold check.
    ///
    /// - Parameters:
    ///   - relativePath: HTML path relative to `directoryPath`.
    ///   - directoryPath: Absolute path to the docs output root.
    /// - Returns: A `LoadOutcome` describing the result.
    public static func loadIfPresent(
        relativePath: String,
        in directoryPath: String
    ) -> LoadOutcome {
        do {
            let sidecar = try load(relativePath: relativePath, in: directoryPath)
            return .loaded(sidecar)
        } catch LoadError.fileNotFound {
            return .missing
        } catch let LoadError.invalidJSON(path, underlying) {
            return .failed(absolutePath: path, message: underlying)
        } catch {
            // Defensive fallback — `load` only throws `LoadError`, but this
            // keeps the API total even if that contract changes later.
            return .failed(absolutePath: relativePath, message: String(describing: error))
        }
    }
}
