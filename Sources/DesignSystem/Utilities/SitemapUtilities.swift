//
//  SitemapUtilities.swift
//  DesignSystem
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//
/// DEPRECATED: These utilities have moved to the `Utilities` library.
/// Import `Utilities` directly and use the `util` CLI for sitemap operations.
/// This file re-exports the APIs for backward compatibility.

@_exported import Utilities

import Foundation

// MARK: - Deprecated Re-exports

/// Get the last modification date for a file from git history
/// - Parameter filePath: Relative path to the file in the repository
/// - Returns: ISO8601 formatted date string from git, or current date if git history unavailable
@available(*, deprecated, message: "Use SitemapGenerator.getGitLastmod(for:) from the Utilities library")
public func getGitLastModDate(filePath: String) async throws -> String {
    return await SitemapGenerator.getGitLastmod(for: filePath)
}
