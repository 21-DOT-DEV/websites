//
//  WebSiteSchema.swift
//  SchemaLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Schema.org WebSite type for site-level references.
/// https://schema.org/WebSite
public struct WebSiteSchema: Schema {
    public static let schemaType = "WebSite"
    
    private let type = "WebSite"
    public let id: String?
    public let name: String?
    public let url: String
    
    /// Creates a WebSite schema.
    /// - Parameters:
    ///   - id: Stable entity identifier (e.g., https://21.dev/#website)
    ///   - name: Display name for the website or section
    ///   - url: The URL of the website
    public init(id: String? = nil, name: String? = nil, url: String) {
        self.id = id
        self.name = name
        self.url = url
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case name
        case url
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(url, forKey: .url)
    }
}
