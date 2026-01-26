//
//  SearchConsoleCommand.swift
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

/// CLI command for Google Search Console operations.
struct SearchConsoleCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "search-console",
        abstract: "Google Search Console operations",
        subcommands: [Submit.self],
        defaultSubcommand: Submit.self
    )
}

extension SearchConsoleCommand {
    /// Submits a sitemap to Google Search Console.
    struct Submit: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "submit",
            abstract: "Submit a sitemap to Google Search Console"
        )
        
        @Option(name: .long, help: "Target site identifier (21-dev, docs-21-dev, md-21-dev)")
        var site: String?
        
        @Option(name: .long, help: "Explicit sitemap URL (overrides --site)")
        var sitemapUrl: String?
        
        @Option(name: .long, help: "Path to service account JSON file")
        var credentialsFile: String?
        
        @Flag(name: .long, help: "Output in JSON format")
        var json: Bool = false
        
        @Flag(name: .shortAndLong, help: "Show verbose output")
        var verbose: Bool = false
        
        mutating func validate() throws {
            // Must have either --site or --sitemap-url
            if site == nil && sitemapUrl == nil {
                throw ValidationError("Either --site or --sitemap-url is required")
            }
            
            // Cannot have both
            if site != nil && sitemapUrl != nil {
                throw ValidationError("Cannot specify both --site and --sitemap-url")
            }
            
            // Validate site name if provided
            if let siteName = site, SiteName(rawValue: siteName) == nil {
                throw ValidationError("Invalid site name: \(siteName). Valid values: 21-dev, docs-21-dev, md-21-dev")
            }
        }
        
        mutating func run() async throws {
            // Resolve sitemap URL
            let sitemapURL: String
            if let explicitURL = sitemapUrl {
                sitemapURL = explicitURL
            } else if let siteName = site.flatMap({ SiteName(rawValue: $0) }) {
                sitemapURL = SearchConsoleService.deriveSitemapURL(for: siteName)
            } else {
                throw ValidationError("Could not determine sitemap URL")
            }
            
            if verbose && !json {
                print("🔍 Submitting sitemap to Google Search Console...")
                print("   Sitemap URL: \(sitemapURL)")
                print("   Site URL: \(SearchConsoleService.formatSiteURL(from: sitemapURL))")
            }
            
            // Resolve credentials
            let credentials: ServiceAccountCredentials
            do {
                // Check for JSON string from environment (for CI)
                let envJSON = ProcessInfo.processInfo.environment["GOOGLE_SERVICE_ACCOUNT_JSON"]
                credentials = try GoogleAuthService.resolveCredentials(
                    filePath: credentialsFile,
                    jsonString: envJSON
                )
                
                if verbose && !json {
                    print("   Service Account: \(credentials.clientEmail)")
                }
            } catch {
                outputError(sitemapURL: sitemapURL, error: error.localizedDescription)
                throw ExitCode(1)
            }
            
            // Authenticate
            let accessToken: String
            do {
                if verbose && !json {
                    print("   Authenticating...")
                }
                accessToken = try await GoogleAuthService.authenticate(credentials: credentials)
            } catch {
                outputError(sitemapURL: sitemapURL, error: "Authentication failed: \(error.localizedDescription)")
                throw ExitCode(1)
            }
            
            // Submit sitemap
            do {
                let result = try await SearchConsoleService.submitSitemap(
                    sitemapURL: sitemapURL,
                    accessToken: accessToken
                )
                
                if result.success {
                    outputSuccess(sitemapURL: sitemapURL)
                } else {
                    outputError(sitemapURL: sitemapURL, error: result.errorMessage ?? "Unknown error")
                    throw ExitCode(1)
                }
            } catch let error as SearchConsoleError {
                outputError(sitemapURL: sitemapURL, error: error.localizedDescription)
                throw ExitCode(1)
            } catch {
                outputError(sitemapURL: sitemapURL, error: error.localizedDescription)
                throw ExitCode(1)
            }
        }
        
        private func outputSuccess(sitemapURL: String) {
            if json {
                print(SearchConsoleService.formatJSONOutput(
                    success: true,
                    sitemapURL: sitemapURL,
                    error: nil
                ))
            } else {
                print(SearchConsoleService.formatSuccessOutput(sitemapURL: sitemapURL))
            }
        }
        
        private func outputError(sitemapURL: String, error: String) {
            if json {
                print(SearchConsoleService.formatJSONOutput(
                    success: false,
                    sitemapURL: sitemapURL,
                    error: error
                ))
            } else {
                print(SearchConsoleService.formatErrorOutput(sitemapURL: sitemapURL, error: error))
            }
        }
    }
}
