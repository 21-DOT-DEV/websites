//
//  OrganizationSchema.swift
//  DesignSystem
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Schema.org Organization type for company/organization structured data.
/// https://schema.org/Organization
public struct OrganizationSchema: Schema {
    public static let schemaType = "Organization"
    
    private let type = "Organization"
    public let id: String?
    public let name: String
    public let url: String?
    public let logo: String?
    public let description: String?
    public let sameAs: [String]?
    
    /// Creates an Organization schema.
    /// - Parameters:
    ///   - id: Optional @id for referencing this organization from other schemas
    ///   - name: Organization name
    ///   - url: Organization website URL
    ///   - logo: URL to organization logo
    ///   - description: Brief description of the organization
    ///   - sameAs: Array of social profile URLs
    public init(
        id: String? = nil,
        name: String,
        url: String? = nil,
        logo: String? = nil,
        description: String? = nil,
        sameAs: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.logo = logo
        self.description = description
        self.sameAs = sameAs
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case name
        case url
        case logo
        case description
        case sameAs
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(logo, forKey: .logo)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(sameAs, forKey: .sameAs)
    }
}
