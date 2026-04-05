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
    public let itemListElement: [ListItemSchema]
    
    /// Creates an ItemList schema from an array of list items.
    /// - Parameter items: Array of ListItemSchema representing each item in the list
    public init(items: [ListItemSchema]) {
        self.itemListElement = items
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case itemListElement
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
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
    
    /// Creates a ListItem schema.
    /// - Parameters:
    ///   - position: 1-indexed position of the item in the list
    ///   - url: URL of the item
    ///   - name: Optional display name for the item
    public init(position: Int, url: String, name: String? = nil) {
        self.position = position
        self.url = url
        self.name = name
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case position
        case url
        case name
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(position, forKey: .position)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(name, forKey: .name)
    }
}
