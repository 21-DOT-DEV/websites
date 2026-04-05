//
//  WebPageSchema.swift
//  SchemaLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Schema.org WebPage type for structured data.
/// Used both as a reference-only type (for mainEntityOfPage) and as a full
/// page-level schema node in @graph (with isPartOf, name, url, etc.).
/// Supports subtypes like CollectionPage via the pageType parameter.
/// https://schema.org/WebPage
public struct WebPageSchema: Schema {
    public static let schemaType = "WebPage"
    
    /// Schema.org page type variants.
    public enum PageType: String, Sendable {
        case webPage = "WebPage"
        case collectionPage = "CollectionPage"
    }
    
    private let type: String
    public let id: String
    public let isPartOf: SchemaReference?
    public let name: String?
    public let url: String?
    public let inLanguage: String?
    public let description: String?
    public let breadcrumb: SchemaReference?
    public let mainEntity: SchemaReference?
    
    /// Creates a WebPage schema reference (backward-compatible).
    /// - Parameters:
    ///   - id: The canonical URL of the web page
    ///   - pageType: The schema.org type (defaults to WebPage)
    public init(id: String, pageType: PageType = .webPage) {
        self.id = id
        self.type = pageType.rawValue
        self.isPartOf = nil
        self.name = nil
        self.url = nil
        self.inLanguage = nil
        self.description = nil
        self.breadcrumb = nil
        self.mainEntity = nil
    }
    
    /// Creates a full WebPage schema for @graph.
    /// - Parameters:
    ///   - id: Stable entity identifier (e.g., https://21.dev/#webpage)
    ///   - pageType: The schema.org type (defaults to WebPage, use .collectionPage for listing pages)
    ///   - isPartOf: Reference to the parent WebSite via @id
    ///   - name: Page title
    ///   - url: Canonical URL of the page
    ///   - inLanguage: BCP-47 language tag (defaults to "en-US")
    ///   - description: Page description (should match <meta name="description">)
    ///   - breadcrumb: Reference to the BreadcrumbList via @id
    ///   - mainEntity: Back-link to the primary entity on this page (e.g., BlogPosting)
    public init(
        id: String,
        pageType: PageType = .webPage,
        isPartOf: SchemaReference,
        name: String,
        url: String,
        inLanguage: String = "en-US",
        description: String? = nil,
        breadcrumb: SchemaReference? = nil,
        mainEntity: SchemaReference? = nil
    ) {
        self.id = id
        self.type = pageType.rawValue
        self.isPartOf = isPartOf
        self.name = name
        self.url = url
        self.inLanguage = inLanguage
        self.description = description
        self.breadcrumb = breadcrumb
        self.mainEntity = mainEntity
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case isPartOf
        case name
        case url
        case inLanguage
        case description
        case breadcrumb
        case mainEntity
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(isPartOf, forKey: .isPartOf)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(inLanguage, forKey: .inLanguage)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(breadcrumb, forKey: .breadcrumb)
        try container.encodeIfPresent(mainEntity, forKey: .mainEntity)
    }
}
