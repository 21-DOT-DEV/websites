//
//  BreadcrumbListSchema.swift
//  SchemaLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Schema.org BreadcrumbList type for breadcrumb navigation structured data.
/// Google uses this to display breadcrumb trails in search results.
/// https://schema.org/BreadcrumbList
public struct BreadcrumbListSchema: Schema {
    public static let schemaType = "BreadcrumbList"
    
    private let type = "BreadcrumbList"
    public let id: String?
    public let itemListElement: [BreadcrumbItemSchema]
    
    /// Creates a BreadcrumbList schema from an array of breadcrumb items.
    /// - Parameters:
    ///   - id: Stable entity identifier for cross-referencing (e.g., from WebPage.breadcrumb)
    ///   - items: Array of BreadcrumbItemSchema representing each level in the trail
    public init(id: String? = nil, items: [BreadcrumbItemSchema]) {
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

/// Schema.org ListItem type for individual breadcrumb entries.
/// Per Google's spec, the final breadcrumb should omit the `item` URL
/// since it represents the current page.
/// https://schema.org/ListItem
public struct BreadcrumbItemSchema: Encodable, Sendable {
    private let type = "ListItem"
    public let position: Int
    public let name: String
    public let item: String?
    
    /// Creates a breadcrumb item.
    /// - Parameters:
    ///   - position: 1-indexed position of the breadcrumb in the trail
    ///   - name: Display name for the breadcrumb level
    ///   - item: URL for the breadcrumb level (omit for the final/current page)
    public init(position: Int, name: String, item: String? = nil) {
        self.position = position
        self.name = name
        self.item = item
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case position
        case name
        case item
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(position, forKey: .position)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(item, forKey: .item)
    }
}
