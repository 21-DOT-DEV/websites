//
//  BlogPostingSchema.swift
//  SchemaLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Schema.org BlogPosting type for blog post structured data.
/// https://schema.org/BlogPosting
public struct BlogPostingSchema: Schema {
    public static let schemaType = "BlogPosting"
    
    private let type = "BlogPosting"
    public let id: String?
    public let headline: String
    public let datePublished: String
    public let dateModified: String?
    public let description: String?
    public let image: String?
    public let author: SchemaReference?
    public let publisher: SchemaReference?
    public let url: String?
    public let inLanguage: String?
    public let wordCount: Int?
    public let articleSection: String?
    public let keywords: [String]?
    public let mainEntityOfPage: SchemaReference?
    
    /// Creates a BlogPosting schema.
    /// - Parameters:
    ///   - id: Stable entity identifier (e.g., https://21.dev/blog/hello-world/#blogposting)
    ///   - headline: Blog post title
    ///   - datePublished: ISO 8601 publication date
    ///   - dateModified: ISO 8601 last modification date (omit if same as datePublished)
    ///   - description: Post excerpt or summary
    ///   - image: URL to the primary image for the article
    ///   - author: Reference to the author Organization/Person via @id
    ///   - publisher: Reference to the publisher Organization via @id
    ///   - url: Canonical URL of the blog post
    ///   - inLanguage: BCP-47 language tag (defaults to "en-US")
    ///   - wordCount: Approximate word count of the article body
    ///   - articleSection: Section or category the article belongs to
    ///   - keywords: Keywords relevant to the article
    ///   - mainEntityOfPage: Back-link to the WebPage that this posting is the main entity of
    public init(
        id: String? = nil,
        headline: String,
        datePublished: String,
        dateModified: String? = nil,
        description: String? = nil,
        image: String? = nil,
        author: SchemaReference? = nil,
        publisher: SchemaReference? = nil,
        url: String? = nil,
        inLanguage: String = "en-US",
        wordCount: Int? = nil,
        articleSection: String? = nil,
        keywords: [String]? = nil,
        mainEntityOfPage: SchemaReference? = nil
    ) {
        self.id = id
        self.headline = headline
        self.datePublished = datePublished
        self.dateModified = dateModified
        self.description = description
        self.image = image
        self.author = author
        self.publisher = publisher
        self.url = url
        self.inLanguage = inLanguage
        self.wordCount = wordCount
        self.articleSection = articleSection
        self.keywords = keywords
        self.mainEntityOfPage = mainEntityOfPage
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case headline
        case datePublished
        case dateModified
        case description
        case image
        case author
        case publisher
        case url
        case inLanguage
        case wordCount
        case articleSection
        case keywords
        case mainEntityOfPage
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(headline, forKey: .headline)
        try container.encode(datePublished, forKey: .datePublished)
        try container.encodeIfPresent(dateModified, forKey: .dateModified)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(image, forKey: .image)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(publisher, forKey: .publisher)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(inLanguage, forKey: .inLanguage)
        try container.encodeIfPresent(wordCount, forKey: .wordCount)
        try container.encodeIfPresent(articleSection, forKey: .articleSection)
        try container.encodeIfPresent(keywords, forKey: .keywords)
        try container.encodeIfPresent(mainEntityOfPage, forKey: .mainEntityOfPage)
    }
}
