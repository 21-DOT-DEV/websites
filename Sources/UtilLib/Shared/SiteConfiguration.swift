//
//  SiteConfiguration.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Identifies the target site/subdomain for utility operations.
public enum SiteName: String, CaseIterable, Codable, Sendable {
    case dev21 = "21-dev"
    case docs21dev = "docs-21-dev"
    case md21dev = "md-21-dev"
    
    /// The base URL for this site.
    public var baseURL: String {
        switch self {
        case .dev21: return "https://21.dev"
        case .docs21dev: return "https://docs.21.dev"
        case .md21dev: return "https://md.21.dev"
        }
    }
    
    /// The output directory path for built site files.
    public var outputDirectory: String {
        return "Websites/\(rawValue)"
    }
}

/// Strategy for discovering URLs in a built site output.
public enum URLDiscoveryStrategy: Sendable {
    /// Scan for .html files in the specified directory
    case htmlFiles(directory: String)
    /// Scan for .md files in the specified directory
    case markdownFiles(directory: String)
    /// Use Slipstream's Sitemap dictionary (build-time tracking)
    case sitemapDictionary
}

/// Strategy for determining lastmod dates for sitemap entries.
public enum LastmodStrategy: Sendable {
    /// Use git log for file's last commit date
    case gitCommitDate
    /// Use state file's generated_date based on package version
    case packageVersionState
    /// Fallback to current date/time
    case currentDate
}

/// Configuration for sitemap generation and validation operations.
public struct SiteConfiguration: Sendable {
    /// The site identifier
    public let name: SiteName
    
    /// The base URL for the site (e.g., "https://21.dev")
    public let baseURL: String
    
    /// The output directory path (e.g., "Websites/21-dev")
    public let outputDirectory: String
    
    /// How to discover URLs in the output directory
    public let urlDiscoveryStrategy: URLDiscoveryStrategy
    
    /// How to determine lastmod dates
    public let lastmodStrategy: LastmodStrategy
    
    /// Creates a configuration for the specified site.
    public init(
        name: SiteName,
        baseURL: String,
        outputDirectory: String,
        urlDiscoveryStrategy: URLDiscoveryStrategy,
        lastmodStrategy: LastmodStrategy
    ) {
        self.name = name
        self.baseURL = baseURL
        self.outputDirectory = outputDirectory
        self.urlDiscoveryStrategy = urlDiscoveryStrategy
        self.lastmodStrategy = lastmodStrategy
    }
    
    /// Returns the default configuration for the specified site.
    public static func `for`(_ site: SiteName) -> SiteConfiguration {
        switch site {
        case .dev21:
            return SiteConfiguration(
                name: .dev21,
                baseURL: SiteName.dev21.baseURL,
                outputDirectory: SiteName.dev21.outputDirectory,
                urlDiscoveryStrategy: .htmlFiles(directory: SiteName.dev21.outputDirectory),
                lastmodStrategy: .gitCommitDate
            )
        case .docs21dev:
            return SiteConfiguration(
                name: .docs21dev,
                baseURL: SiteName.docs21dev.baseURL,
                outputDirectory: SiteName.docs21dev.outputDirectory,
                urlDiscoveryStrategy: .htmlFiles(directory: "\(SiteName.docs21dev.outputDirectory)/documentation"),
                lastmodStrategy: .packageVersionState
            )
        case .md21dev:
            return SiteConfiguration(
                name: .md21dev,
                baseURL: SiteName.md21dev.baseURL,
                outputDirectory: SiteName.md21dev.outputDirectory,
                urlDiscoveryStrategy: .markdownFiles(directory: SiteName.md21dev.outputDirectory),
                lastmodStrategy: .packageVersionState
            )
        }
    }
}
