//
//  StateCommand.swift
//  util
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import ArgumentParser
import Foundation
import Utilities

/// CLI command for state file management.
struct StateCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "state",
        abstract: "State file management for sitemap lastmod tracking",
        subcommands: [Update.self, Validate.self]
    )
}

extension StateCommand {
    /// Updates the state file with a new package version.
    struct Update: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "update",
            abstract: "Update state file with package version"
        )
        
        @Option(name: .shortAndLong, help: "Package version (auto-detects from Package.resolved if not specified)")
        var packageVersion: String?
        
        @Option(name: .shortAndLong, help: "State file path")
        var file: String = StateManager.defaultPath
        
        @Flag(name: .shortAndLong, help: "Show verbose output")
        var verbose: Bool = false
        
        mutating func run() throws {
            // Determine package version
            let version: String
            if let providedVersion = packageVersion {
                version = providedVersion
            } else {
                // Try to auto-detect from Package.resolved
                if let detected = try StateManager.detectPackageVersion() {
                    version = detected
                    if verbose {
                        print("Auto-detected package version: \(version)")
                    }
                } else {
                    throw ValidationError("Could not auto-detect package version. Please specify --package-version.")
                }
            }
            
            if verbose {
                print("Updating state file: \(file)")
                print("  Package version: \(version)")
            }
            
            let state = try StateManager.update(at: file, packageVersion: version)
            
            let formatter = ISO8601DateFormatter()
            print("✅ State updated:")
            print("  Package version: \(state.packageVersion)")
            print("  Generated date: \(formatter.string(from: state.generatedDate))")
            print("  Subdomains: \(state.subdomains.count)")
        }
    }
    
    /// Validates the state file.
    struct Validate: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "validate",
            abstract: "Validate state file format and contents"
        )
        
        @Option(name: .shortAndLong, help: "State file path")
        var file: String = StateManager.defaultPath
        
        @Flag(name: .shortAndLong, help: "Show verbose output")
        var verbose: Bool = false
        
        mutating func run() throws {
            if verbose {
                print("Validating state file: \(file)")
            }
            
            let result = StateManager.validate(at: file)
            
            if result.isValid {
                print("✅ State file valid: \(file)")
                
                // Show contents if verbose
                if verbose, let state = try? StateManager.read(from: file) {
                    let formatter = ISO8601DateFormatter()
                    print("  Package version: \(state.packageVersion)")
                    print("  Generated date: \(formatter.string(from: state.generatedDate))")
                    print("  Subdomains:")
                    for (name, subdomain) in state.subdomains {
                        print("    - \(name): \(formatter.string(from: subdomain.lastmod))")
                    }
                }
            } else {
                print("❌ State file validation failed:")
                for error in result.errors {
                    print("  \(error.description)")
                }
                throw ExitCode(1)
            }
        }
    }
}
