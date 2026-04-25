//
//  TechArticleSchema.swift
//  SchemaLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Schema.org TechArticle type for technical article structured data.
/// Used for authored prose pages in technical documentation (e.g. DocC articles
/// like "Getting Started", "Choosing Between P256K and ZKP").
///
/// `TechArticle` is a subtype of `Article`. Search engines (Google) treat it as
/// Article-eligible for rich-result purposes, while AI/LLM crawlers benefit
/// from the more specific subtype semantically.
///
/// https://schema.org/TechArticle
public struct TechArticleSchema: Schema {
    public static let schemaType = "TechArticle"

    private let type = "TechArticle"
    public let id: String?
    public let headline: String
    public let description: String?
    public let url: String?
    public let inLanguage: String?
    public let isPartOf: SchemaReference?
    public let mainEntityOfPage: SchemaReference?
    public let publisher: SchemaReference?

    /// Creates a TechArticle schema.
    /// - Parameters:
    ///   - id: Stable entity identifier (e.g., `<pageURL>#techarticle`)
    ///   - headline: The article's title (typically `metadata.title` from a DocC sidecar)
    ///   - description: Article summary / abstract
    ///   - url: Canonical URL of the article
    ///   - inLanguage: BCP-47 language tag (defaults to "en-US")
    ///   - isPartOf: Reference to the parent WebSite via @id
    ///   - mainEntityOfPage: Back-link to the WebPage that this article is the main entity of
    ///   - publisher: Reference to the publishing Organization via @id
    public init(
        id: String? = nil,
        headline: String,
        description: String? = nil,
        url: String? = nil,
        inLanguage: String = "en-US",
        isPartOf: SchemaReference? = nil,
        mainEntityOfPage: SchemaReference? = nil,
        publisher: SchemaReference? = nil
    ) {
        self.id = id
        self.headline = headline
        self.description = description
        self.url = url
        self.inLanguage = inLanguage
        self.isPartOf = isPartOf
        self.mainEntityOfPage = mainEntityOfPage
        self.publisher = publisher
    }

    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case headline
        case description
        case url
        case inLanguage
        case isPartOf
        case mainEntityOfPage
        case publisher
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(headline, forKey: .headline)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(inLanguage, forKey: .inLanguage)
        try container.encodeIfPresent(isPartOf, forKey: .isPartOf)
        try container.encodeIfPresent(mainEntityOfPage, forKey: .mainEntityOfPage)
        try container.encodeIfPresent(publisher, forKey: .publisher)
    }
}
