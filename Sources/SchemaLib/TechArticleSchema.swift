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
///
/// Used uniformly for **all** article-class DocC pages — authored prose
/// (e.g. "Getting Started", "Choosing Between P256K and ZKP") **and**
/// symbol / module-overview reference pages. The article-vs-reference
/// distinction is encoded via the `articleSection` property
/// ("Guides" vs "API Reference"), not the `@type`. This mirrors what
/// peer documentation sites (Vercel, Pulumi) ship and avoids the
/// non-Schema.org `APIReference` type that earlier drafts used.
///
/// `TechArticle` is a subtype of `Article`. Search engines (Google) treat it as
/// Article-eligible for rich-result purposes, while AI/LLM crawlers benefit
/// from the more specific subtype semantically.
///
/// https://schema.org/TechArticle
public struct TechArticleSchema: Schema {
    public static let schemaType = "TechArticle"

    /// Canonical `@id` fragment used for every TechArticle node we emit.
    /// Kept as a constant so the producer (this struct) and consumers
    /// (e.g. `WebPage.mainEntity` cross-references) stay in sync.
    public static let canonicalIDFragment = "#techarticle"

    /// Returns the canonical `@id` (`<pageURL>#techarticle`) for an article-class
    /// node attached to the given page URL. Use this from anywhere that emits a
    /// `mainEntity` back-reference so the producer and consumer never drift.
    public static func canonicalID(forPageURL pageURL: String) -> String {
        pageURL + canonicalIDFragment
    }

    private let type = "TechArticle"
    public let id: String?
    public let headline: String
    public let description: String?
    public let url: String?
    public let inLanguage: String?
    public let isPartOf: SchemaReference?
    public let mainEntityOfPage: SchemaReference?
    public let publisher: SchemaReference?
    /// Section the article belongs to — typically "Guides" for prose articles
    /// or "API Reference" for symbol/collection pages. Schema.org's `articleSection`
    /// is defined for this exact purpose ("Articles may belong to one or more
    /// 'sections' in a magazine or newspaper, such as Sports, Lifestyle, etc.").
    public let articleSection: String?
    /// Free-text "subject of" — typically the DocC module name (e.g., "Event",
    /// "P256K"). Only populated for symbol / collection pages where the page
    /// has an unambiguous single subject.
    public let about: String?

    /// Creates a TechArticle schema.
    /// - Parameters:
    ///   - id: Stable entity identifier (e.g., `<pageURL>#techarticle` —
    ///     prefer `TechArticleSchema.canonicalID(forPageURL:)`)
    ///   - headline: The article's title (typically `metadata.title` from a DocC sidecar)
    ///   - description: Article summary / abstract
    ///   - url: Canonical URL of the article
    ///   - inLanguage: BCP-47 language tag (defaults to "en-US")
    ///   - isPartOf: Reference to the parent WebSite via @id
    ///   - mainEntityOfPage: Back-link to the WebPage that this article is the main entity of
    ///   - publisher: Reference to the publishing Organization via @id
    ///   - articleSection: Section/category label (e.g., "Guides", "API Reference")
    ///   - about: Subject of the article (typically the DocC module name);
    ///     omit for prose articles that don't have a single subject
    public init(
        id: String? = nil,
        headline: String,
        description: String? = nil,
        url: String? = nil,
        inLanguage: String = "en-US",
        isPartOf: SchemaReference? = nil,
        mainEntityOfPage: SchemaReference? = nil,
        publisher: SchemaReference? = nil,
        articleSection: String? = nil,
        about: String? = nil
    ) {
        self.id = id
        self.headline = headline
        self.description = description
        self.url = url
        self.inLanguage = inLanguage
        self.isPartOf = isPartOf
        self.mainEntityOfPage = mainEntityOfPage
        self.publisher = publisher
        self.articleSection = articleSection
        self.about = about
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
        case articleSection
        case about
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
        try container.encodeIfPresent(articleSection, forKey: .articleSection)
        try container.encodeIfPresent(about, forKey: .about)
    }
}
