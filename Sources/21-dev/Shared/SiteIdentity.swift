//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import DesignSystem

/// Centralized site identity information - single source of truth for all site-wide data
public struct SiteIdentity {
    // Organization identity
    public static let name = "21.dev"
    public static let legalName = "Timechain Software Initiative, Inc."
    public static let url = "https://21.dev/"
    public static let schemaID = "https://21.dev/#organization"
    
    // Social URLs
    public static let githubURL = "https://github.com/21-DOT-DEV"
    public static let twitterURL = "https://x.com/21_DOT_DEV"
    public static let nostrURL = "https://primal.net/21"
    
    // Documentation URLs
    public static let docsBaseURL = "https://docs.21.dev/"
    public static let p256kDocsURL = "https://docs.21.dev/documentation/p256k/"
    
    // Repository URLs
    public static let p256kRepoURL = "https://github.com/21-DOT-DEV/swift-secp256k1"
    public static let slipstreamRepoURL = "https://github.com/ClutchEngineering/slipstream"
    
    // Package Index
    public static let spiURL = "https://swiftpackageindex.com/21-DOT-DEV"
    
    // Contact
    public static let contactEmail = "hello@21.dev"
    
    // Social links array for sameAs schema.org property
    public static let sameAs: [String] = [githubURL, twitterURL, nostrURL]
    
    // Organization schema for structured data
    public static let organizationSchema = OrganizationSchema(
        id: schemaID,
        name: name,
        url: url,
        sameAs: sameAs
    )
}
