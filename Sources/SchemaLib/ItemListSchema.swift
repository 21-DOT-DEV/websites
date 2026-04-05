//
//  ItemListSchema.swift
//  SchemaLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Schema.org ItemList type for ordered/unordered lists of items.
/// Used on listing pages (e.g., blog index) to enable rich results.
/// https://schema.org/ItemList
public struct ItemListSchema: Schema {
    public static let schemaType = "ItemList"
    
    private let type = "ItemList"
    public let id: String?
    public let itemListElement: [ListItemSchema]
    
    /// Creates an ItemList schema from an array of list items.
    /// - Parameters:
    ///   - id: Stable entity identifier (e.g., https://21.dev/blog/#itemlist)
    ///   - items: Array of ListItemSchema representing each item in the list
    public init(id: String? = nil, items: [ListItemSchema]) {
        self.id = id
        self.itemListElement = items
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case itemListElement
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(itemListElement, forKey: .itemListElement)
    }
}

/// Schema.org ListItem type for individual items within an ItemList.
/// https://schema.org/ListItem
public struct ListItemSchema: Encodable, Sendable {
    private let type = "ListItem"
    public let position: Int
    public let url: String
    public let name: String?
    public let description: String?
    
    /// Creates a ListItem schema.
    /// - Parameters:
    ///   - position: 1-indexed position of the item in the list
    ///   - url: URL of the item
    ///   - name: Optional display name for the item
    ///   - description: Optional description of the item (useful for LLMs and structured data consumers)
    public init(position: Int, url: String, name: String? = nil, description: String? = nil) {
        self.position = position
        self.url = url
        self.name = name
        self.description = description
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case position
        case url
        case name
        case description
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(position, forKey: .position)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
    }
}
