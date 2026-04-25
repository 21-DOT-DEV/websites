//
//  APIReferenceSchema.swift
//  SchemaLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Schema.org APIReference type for API reference documentation.
/// Used for symbol pages (classes, structs, methods, etc.) and module-root
/// pages in DocC-generated documentation.
///
/// `APIReference` is a subtype of `TechArticle` (which itself extends `Article`).
/// Search engines treat it as Article-eligible; AI/LLM crawlers benefit from
/// the more specific subtype, and APIReference exposes API-specific properties
/// (`programmingLanguage`, `codeRepository`, `about`) that materially improve
/// classification of reference docs.
///
/// https://schema.org/APIReference
public struct APIReferenceSchema: Schema {
    public static let schemaType = "APIReference"

    private let type = "APIReference"

    // Inherited Article/TechArticle fields
    public let id: String?
    public let headline: String
    public let description: String?
    public let url: String?
    public let inLanguage: String?
    public let isPartOf: SchemaReference?
    public let mainEntityOfPage: SchemaReference?
    public let publisher: SchemaReference?

    // APIReference-specific fields
    public let programmingLanguage: String?
    public let codeRepository: String?
    /// Free-text "subject of" — typically the module name (e.g., "Event", "P256K").
    public let about: String?

    /// Creates an APIReference schema.
    /// - Parameters:
    ///   - id: Stable entity identifier (e.g., `<pageURL>#apireference`)
    ///   - headline: The page's title (typically `metadata.title` from a DocC sidecar)
    ///   - description: API summary / abstract
    ///   - url: Canonical URL of the page
    ///   - inLanguage: BCP-47 language tag (defaults to "en-US")
    ///   - isPartOf: Reference to the parent WebSite via @id
    ///   - mainEntityOfPage: Back-link to the WebPage that this reference is the main entity of
    ///   - publisher: Reference to the publishing Organization via @id
    ///   - programmingLanguage: e.g., "Swift"
    ///   - codeRepository: URL of the source-code repository (typically the GitHub repo root)
    ///   - about: Free-text subject of the API reference (typically the module name)
    public init(
        id: String? = nil,
        headline: String,
        description: String? = nil,
        url: String? = nil,
        inLanguage: String = "en-US",
        isPartOf: SchemaReference? = nil,
        mainEntityOfPage: SchemaReference? = nil,
        publisher: SchemaReference? = nil,
        programmingLanguage: String? = nil,
        codeRepository: String? = nil,
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
        self.programmingLanguage = programmingLanguage
        self.codeRepository = codeRepository
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
        case programmingLanguage
        case codeRepository
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
        try container.encodeIfPresent(programmingLanguage, forKey: .programmingLanguage)
        try container.encodeIfPresent(codeRepository, forKey: .codeRepository)
        try container.encodeIfPresent(about, forKey: .about)
    }
}
