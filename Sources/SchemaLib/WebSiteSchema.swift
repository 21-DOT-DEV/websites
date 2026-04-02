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
    public let url: String
    
    /// Creates a WebSite schema.
    /// - Parameter url: The URL of the website
    public init(url: String) {
        self.url = url
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case url
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(url, forKey: .url)
    }
}
