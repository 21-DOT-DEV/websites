//
//  ResourceCopier.swift
//  UtilLib
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Utility for copying resource files with pattern-based exclusion
public struct ResourceCopier {
    
    /// Check if a filename should be excluded based on patterns
    /// - Parameters:
    ///   - filename: The filename to check
    ///   - patterns: Array of patterns to match (exact match or suffix match)
    /// - Returns: True if the file should be excluded
    public static func shouldExclude(_ filename: String, patterns: [String]) -> Bool {
        patterns.contains { pattern in
            filename == pattern || filename.hasSuffix(pattern)
        }
    }
    
    /// Copy resources recursively from source to destination, excluding files matching patterns
    /// - Parameters:
    ///   - sourceURL: Source directory URL
    ///   - destURL: Destination directory URL
    ///   - excludePatterns: Patterns for files/directories to exclude
    ///   - relativePath: Current relative path (for logging)
    ///   - logger: Optional closure for logging copied files
    public static func copyResources(
        from sourceURL: URL,
        to destURL: URL,
        excludePatterns: [String],
        relativePath: String = "",
        logger: ((String) -> Void)? = nil
    ) throws {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: sourceURL.path) else { return }
        
        // Ensure destination directory exists
        if !fileManager.fileExists(atPath: destURL.path) {
            try fileManager.createDirectory(at: destURL, withIntermediateDirectories: true)
        }
        
        let contents = try fileManager.contentsOfDirectory(
            at: sourceURL,
            includingPropertiesForKeys: [.isDirectoryKey]
        )
        
        for itemURL in contents {
            let filename = itemURL.lastPathComponent
            
            // Skip excluded files/directories
            if shouldExclude(filename, patterns: excludePatterns) { continue }
            
            let destItemURL = destURL.appendingPathComponent(filename)
            let displayPath = relativePath.isEmpty ? filename : "\(relativePath)/\(filename)"
            
            // Check if item is a directory
            let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
            let isDirectory = resourceValues.isDirectory ?? false
            
            if isDirectory {
                // Create directory and recurse
                try fileManager.createDirectory(at: destItemURL, withIntermediateDirectories: true)
                try copyResources(
                    from: itemURL,
                    to: destItemURL,
                    excludePatterns: excludePatterns,
                    relativePath: displayPath,
                    logger: logger
                )
            } else {
                // Copy file (remove existing for idempotency)
                if fileManager.fileExists(atPath: destItemURL.path) {
                    try fileManager.removeItem(at: destItemURL)
                }
                try fileManager.copyItem(at: itemURL, to: destItemURL)
                logger?(displayPath)
            }
        }
    }
}
