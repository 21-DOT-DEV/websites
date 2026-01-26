//
//  SitemapCommand.swift
//  util
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import ArgumentParser
import Foundation
import UtilLib

/// CLI command for sitemap generation operations.
struct SitemapCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sitemap",
        abstract: "Sitemap generation and validation",
        subcommands: [Generate.self, Validate.self],
        defaultSubcommand: Generate.self
    )
}

extension SitemapCommand {
    /// Generates a sitemap.xml for a specified site.
    struct Generate: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "generate",
            abstract: "Generate sitemap.xml for a site"
        )
        
        @Option(name: .long, help: "Target site identifier (21-dev, docs-21-dev, md-21-dev)")
        var site: String
        
        @Option(name: .long, help: "Input directory containing built site files (overrides default)")
        var input: String?
        
        @Option(name: .long, help: "Output path for sitemap.xml (overrides default)")
        var output: String?
        
        @Flag(name: .long, help: "Print sitemap to stdout instead of writing to file")
        var dryRun: Bool = false
        
        @Flag(name: .shortAndLong, help: "Show verbose output")
        var verbose: Bool = false
        
        mutating func run() async throws {
            // Parse site name
            guard let siteName = SiteName(rawValue: site) else {
                throw ValidationError("Invalid site name: \(site). Valid values: 21-dev, docs-21-dev, md-21-dev")
            }
            
            // Get configuration
            var config = SiteConfiguration.for(siteName)
            
            // Override input directory if specified
            if let inputDir = input {
                let strategy: URLDiscoveryStrategy
                switch siteName {
                case .dev21, .docs21dev:
                    strategy = .htmlFiles(directory: inputDir)
                case .md21dev:
                    strategy = .markdownFiles(directory: inputDir)
                }
                
                config = SiteConfiguration(
                    name: siteName,
                    baseURL: config.baseURL,
                    outputDirectory: inputDir,
                    urlDiscoveryStrategy: strategy,
                    lastmodStrategy: config.lastmodStrategy
                )
            }
            
            if verbose {
                print("Generating sitemap for \(site)...")
                print("  Input: \(config.outputDirectory)")
            }
            
            // Generate sitemap
            let sitemap = try await SitemapGenerator.generate(for: config)
            
            if dryRun {
                print(sitemap)
            } else {
                // Determine output path
                let outputPath = output ?? "\(config.outputDirectory)/sitemap.xml"
                
                try SitemapGenerator.write(sitemap, to: outputPath)
                
                if verbose {
                    print("  Output: \(outputPath)")
                }
                print("✓ Sitemap generated: \(outputPath)")
            }
        }
    }
    
    /// Validates a sitemap.xml file.
    struct Validate: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "validate",
            abstract: "Validate a sitemap.xml file"
        )
        
        @Option(name: .long, help: "Target site identifier (21-dev, docs-21-dev, md-21-dev)")
        var site: String?
        
        @Option(name: .long, help: "Sitemap file path (overrides default)")
        var input: String?
        
        @Flag(name: .shortAndLong, help: "Show verbose output")
        var verbose: Bool = false
        
        mutating func run() throws {
            // Determine sitemap path
            let sitemapPath: String
            
            if let inputPath = input {
                sitemapPath = inputPath
            } else if let siteName = site.flatMap({ SiteName(rawValue: $0) }) {
                let config = SiteConfiguration.for(siteName)
                sitemapPath = "\(config.outputDirectory)/sitemap.xml"
            } else {
                throw ValidationError("Either --site or --input is required")
            }
            
            if verbose {
                print("Validating sitemap: \(sitemapPath)")
            }
            
            let result = SitemapValidator.validateFile(at: sitemapPath)
            
            if result.isValid {
                print("✅ Sitemap valid: \(sitemapPath)")
                
                if verbose && !result.warnings.isEmpty {
                    print("  Warnings:")
                    for warning in result.warnings {
                        print("    - \(warning)")
                    }
                }
            } else {
                print("❌ Sitemap validation failed:")
                for error in result.errors {
                    print("  \(error.description)")
                }
                throw ExitCode(1)
            }
        }
    }
}
