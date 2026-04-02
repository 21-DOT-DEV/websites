//
//  HTMLFileWalker.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// A discovered HTML file entry with resolved paths.
public struct HTMLFileEntry: Sendable {
    /// Absolute path to the file (symlinks resolved)
    public let absolutePath: String

    /// Path relative to the scan directory
    public let relativePath: String

    /// Creates a new HTML file entry.
    /// - Parameters:
    ///   - absolutePath: Absolute path to the file
    ///   - relativePath: Path relative to the scan directory
    public init(absolutePath: String, relativePath: String) {
        self.absolutePath = absolutePath
        self.relativePath = relativePath
    }
}

/// Shared file discovery for HTML processing commands.
///
/// Eliminates duplicated directory-walking logic across
/// `CanonicalChecker`, `AgentDirectiveInjector`, and future
/// HTML processing utilities.
public enum HTMLFileWalker {

    /// Finds all `.html` files in a directory, optionally filtered by path prefix.
    ///
    /// - Parameters:
    ///   - directory: Path to the directory to scan
    ///   - pathPrefix: If set, only include files whose relative path starts with this prefix
    /// - Returns: Array of discovered HTML file entries, sorted by relative path
    /// - Throws: ``HTMLFileWalkerError/cannotEnumerateDirectory(_:)`` if the directory cannot be read
    public static func findHTMLFiles(
        in directory: String,
        pathPrefix: String? = nil
    ) throws -> [HTMLFileEntry] {
        let fileManager = FileManager.default
        let resolvedPath = URL(fileURLWithPath: directory).resolvingSymlinksInPath().path
        let directoryURL = URL(fileURLWithPath: resolvedPath)

        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw HTMLFileWalkerError.cannotEnumerateDirectory(directory)
        }

        let normalizedPath = resolvedPath.hasSuffix("/")
            ? resolvedPath
            : resolvedPath + "/"

        var entries: [HTMLFileEntry] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "html" else { continue }

            let filePath = fileURL.resolvingSymlinksInPath().path
            let relativePath = String(filePath.dropFirst(normalizedPath.count))

            if let prefix = pathPrefix, !relativePath.hasPrefix(prefix) {
                continue
            }

            entries.append(HTMLFileEntry(absolutePath: filePath, relativePath: relativePath))
        }

        return entries.sorted { $0.relativePath < $1.relativePath }
    }
}

/// Errors that can occur during HTML file discovery.
public enum HTMLFileWalkerError: Error, LocalizedError {
    case cannotEnumerateDirectory(String)

    public var errorDescription: String? {
        switch self {
        case .cannotEnumerateDirectory(let path):
            return "Cannot enumerate directory: \(path)"
        }
    }
}
