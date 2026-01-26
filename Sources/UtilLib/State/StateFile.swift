//
//  StateFile.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// State for a single subdomain's lastmod tracking.
public struct SubdomainState: Codable, Sendable, Equatable {
    /// Last modification date for this subdomain
    public var lastmod: Date
    
    public init(lastmod: Date) {
        self.lastmod = lastmod
    }
}

/// Tracks package version and generation dates for docs/md sitemaps.
///
/// Used to preserve lastmod dates between builds when the package version
/// hasn't changed.
public struct StateFile: Codable, Sendable {
    /// Current swift-secp256k1 package version
    public var packageVersion: String
    
    /// When state was last updated
    public var generatedDate: Date
    
    /// Per-subdomain state (keyed by site name, e.g., "docs-21-dev")
    public var subdomains: [String: SubdomainState]
    
    enum CodingKeys: String, CodingKey {
        case packageVersion = "package_version"
        case generatedDate = "generated_date"
        case subdomains
    }
    
    public init(packageVersion: String, generatedDate: Date, subdomains: [String: SubdomainState]) {
        self.packageVersion = packageVersion
        self.generatedDate = generatedDate
        self.subdomains = subdomains
    }
}
