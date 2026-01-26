//
//  StateManager.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Manages state files for sitemap lastmod tracking.
public enum StateManager {
    
    /// Default path for the state file.
    public static let defaultPath = "Resources/sitemap-state.json"
    
    // MARK: - Read/Write
    
    /// Reads a state file from the specified path.
    /// - Parameter path: Path to the state file
    /// - Returns: The state file contents, or nil if file doesn't exist
    /// - Throws: If the file exists but cannot be parsed
    public static func read(from path: String) throws -> StateFile? {
        guard FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(StateFile.self, from: data)
    }
    
    /// Writes a state file to the specified path.
    /// - Parameters:
    ///   - state: The state to write
    ///   - path: Path to write to
    public static func write(_ state: StateFile, to path: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(state)
        
        // Ensure parent directory exists
        let url = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        try data.write(to: url)
    }
    
    // MARK: - Update
    
    /// Updates the state file with a new package version.
    ///
    /// If the version has changed, updates all subdomain lastmod dates.
    /// If the version is unchanged, preserves existing lastmod dates.
    ///
    /// - Parameters:
    ///   - path: Path to the state file
    ///   - packageVersion: The new package version
    /// - Returns: The updated state
    @discardableResult
    public static func update(at path: String, packageVersion: String) throws -> StateFile {
        let now = Date()
        
        if let existing = try read(from: path) {
            if existing.packageVersion == packageVersion {
                // Version unchanged - preserve existing dates
                var updated = existing
                updated.generatedDate = now
                try write(updated, to: path)
                return updated
            } else {
                // Version changed - update all subdomain dates
                var updated = existing
                updated.packageVersion = packageVersion
                updated.generatedDate = now
                
                // Update all subdomain lastmod dates
                for key in updated.subdomains.keys {
                    updated.subdomains[key] = SubdomainState(lastmod: now)
                }
                
                try write(updated, to: path)
                return updated
            }
        } else {
            // Create new state file
            let state = StateFile(
                packageVersion: packageVersion,
                generatedDate: now,
                subdomains: [
                    "docs-21-dev": SubdomainState(lastmod: now),
                    "md-21-dev": SubdomainState(lastmod: now)
                ]
            )
            try write(state, to: path)
            return state
        }
    }
    
    // MARK: - Validation
    
    /// Validates a state file at the specified path.
    /// - Parameter path: Path to the state file
    /// - Returns: Validation result
    public static func validate(at path: String) -> ValidationResult {
        guard FileManager.default.fileExists(atPath: path) else {
            return ValidationResult.failure([
                ValidationError(
                    code: "FILE_NOT_FOUND",
                    message: "State file not found",
                    location: path
                )
            ])
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            _ = try decoder.decode(StateFile.self, from: data)
            
            return ValidationResult.success()
        } catch {
            return ValidationResult.failure([
                ValidationError(
                    code: "PARSE_ERROR",
                    message: "Failed to parse state file: \(error.localizedDescription)",
                    location: path
                )
            ])
        }
    }
    
    // MARK: - Version Detection
    
    /// Attempts to detect the swift-secp256k1 package version from Package.resolved.
    /// - Parameter resolvedPath: Path to Package.resolved file
    /// - Returns: The detected version, or nil if not found
    public static func detectPackageVersion(from resolvedPath: String = "Package.resolved") throws -> String? {
        guard FileManager.default.fileExists(atPath: resolvedPath) else {
            return nil
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: resolvedPath))
        
        // Parse Package.resolved JSON
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pins = json["pins"] as? [[String: Any]] else {
            return nil
        }
        
        // Find swift-secp256k1 package
        for pin in pins {
            guard let identity = pin["identity"] as? String,
                  identity == "swift-secp256k1",
                  let state = pin["state"] as? [String: Any],
                  let version = state["version"] as? String else {
                continue
            }
            return version
        }
        
        return nil
    }
}
