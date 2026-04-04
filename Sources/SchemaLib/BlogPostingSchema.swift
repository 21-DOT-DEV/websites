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
    public let author: SchemaReference?
    public let url: String?
    public let inLanguage: String?
    public let mainEntityOfPage: SchemaReference?
    
    /// Creates a BlogPosting schema.
    /// - Parameters:
    ///   - id: Stable entity identifier (e.g., https://21.dev/blog/hello-world/#blogposting)
    ///   - headline: Blog post title
    ///   - datePublished: ISO 8601 publication date
    ///   - dateModified: ISO 8601 last modification date (omit if same as datePublished)
    ///   - description: Post excerpt or summary
    ///   - author: Reference to the author Organization/Person via @id
    ///   - url: Canonical URL of the blog post
    ///   - inLanguage: BCP-47 language tag (defaults to "en-US")
    ///   - mainEntityOfPage: Back-link to the WebPage that this posting is the main entity of
    public init(
        id: String? = nil,
        headline: String,
        datePublished: String,
        dateModified: String? = nil,
        description: String? = nil,
        author: SchemaReference? = nil,
        url: String? = nil,
        inLanguage: String = "en-US",
        mainEntityOfPage: SchemaReference? = nil
    ) {
        self.id = id
        self.headline = headline
        self.datePublished = datePublished
        self.dateModified = dateModified
        self.description = description
        self.author = author
        self.url = url
        self.inLanguage = inLanguage
        self.mainEntityOfPage = mainEntityOfPage
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case id = "@id"
        case headline
        case datePublished
        case dateModified
        case description
        case author
        case url
        case inLanguage
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
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(inLanguage, forKey: .inLanguage)
        try container.encodeIfPresent(mainEntityOfPage, forKey: .mainEntityOfPage)
    }
}
