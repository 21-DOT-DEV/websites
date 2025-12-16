//
//  HeadersCommand.swift
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

/// CLI command for headers validation operations.
struct HeadersCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "headers",
        abstract: "Cloudflare _headers validation",
        subcommands: [Validate.self],
        defaultSubcommand: Validate.self
    )
}

extension HeadersCommand {
    /// Validates a Cloudflare _headers file.
    struct Validate: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "validate",
            abstract: "Validate a Cloudflare _headers file"
        )
        
        @Option(name: .long, help: "Target site identifier (21-dev, docs-21-dev, md-21-dev)")
        var site: String
        
        @Option(name: .long, help: "Environment (prod, dev)")
        var env: String
        
        @Option(name: .long, help: "Headers file path (overrides default)")
        var input: String?
        
        @Flag(name: .shortAndLong, help: "Show verbose output")
        var verbose: Bool = false
        
        mutating func run() throws {
            // Parse site name
            guard let siteName = SiteName(rawValue: site) else {
                throw ValidationError("Invalid site name: \(site). Valid values: 21-dev, docs-21-dev, md-21-dev")
            }
            
            // Parse environment
            guard let environment = HeadersEnvironment(rawValue: env) else {
                throw ValidationError("Invalid environment: \(env). Valid values: prod, dev")
            }
            
            // Determine input path
            let path = input ?? HeadersValidator.defaultPath(for: siteName, environment: environment)
            
            if verbose {
                print("Validating headers for \(site) (\(env))...")
                print("  Input: \(path)")
            }
            
            // Validate
            do {
                let result = try HeadersValidator.validateFile(at: path, environment: environment)
                
                if result.isValid {
                    print("✅ Headers valid: \(site) (\(env))")
                    
                    if verbose && !result.warnings.isEmpty {
                        print("  Warnings:")
                        for warning in result.warnings {
                            print("    - \(warning)")
                        }
                    }
                } else {
                    print("❌ Headers validation failed:")
                    for error in result.errors {
                        print("  \(error.description)")
                    }
                    
                    if !result.warnings.isEmpty {
                        print("  Warnings:")
                        for warning in result.warnings {
                            print("    - \(warning)")
                        }
                    }
                    
                    throw ExitCode(4) // Missing required headers
                }
            } catch let error as HeadersError {
                switch error {
                case .fileNotFound:
                    print("❌ \(error.localizedDescription)")
                    throw ExitCode(2)
                case .parseError, .invalidFormat:
                    print("❌ \(error.localizedDescription)")
                    throw ExitCode(3)
                }
            }
        }
    }
}
