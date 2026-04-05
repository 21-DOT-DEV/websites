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
    public let potentialAction: SearchActionSchema?
    
    /// Creates a WebSite schema.
    /// - Parameters:
    ///   - id: Stable entity identifier (e.g., https://21.dev/#website)
    ///   - name: Display name for the website or section
    ///   - url: The URL of the website
    ///   - potentialAction: Optional SearchAction for sitelinks search box
    public init(id: String? = nil, name: String? = nil, url: String, potentialAction: SearchActionSchema? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.potentialAction = potentialAction
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case name
        case url
        case potentialAction
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(potentialAction, forKey: .potentialAction)
    }
}

/// Schema.org SearchAction for sitelinks search box.
/// https://schema.org/SearchAction
public struct SearchActionSchema: Encodable, Sendable {
    private let type = "SearchAction"
    public let target: SearchActionTarget
    public let queryInput: String
    
    /// Creates a SearchAction schema.
    /// - Parameters:
    ///   - targetURLTemplate: URL template with {search_term_string} placeholder
    ///   - queryInput: Input specification (defaults to "required name=search_term_string")
    public init(targetURLTemplate: String, queryInput: String = "required name=search_term_string") {
        self.target = SearchActionTarget(urlTemplate: targetURLTemplate)
        self.queryInput = queryInput
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case target
        case queryInput = "query-input"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(target, forKey: .target)
        try container.encode(queryInput, forKey: .queryInput)
    }
}

/// Target object for SearchAction with URL template.
public struct SearchActionTarget: Encodable, Sendable {
    private let type = "EntryPoint"
    public let urlTemplate: String
    
    public init(urlTemplate: String) {
        self.urlTemplate = urlTemplate
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case urlTemplate
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(urlTemplate, forKey: .urlTemplate)
    }
}
