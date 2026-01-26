//
//  ArticleMetadata.swift
//  21-DOT-DEV/ArticleMetadata.swift
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Open Graph article metadata for structured blog post meta tags.
///
/// `ArticleMetadata` is a presentation model used to render Open Graph `article:*` meta tags
/// in the HTML `<head>` section. It follows the **Adapter Pattern** to decouple domain models
/// (like ``BlogMetadata``) from presentation concerns.
///
/// ## Architecture
///
/// This struct serves as a view model specifically for rendering Open Graph article metadata:
/// - **Domain Layer**: ``BlogMetadata`` (frontmatter parsing, business logic)
/// - **Presentation Layer**: `ArticleMetadata` (rendering meta tags)
/// - **Adapter**: ``BlogMetadata/toArticleMetadata(author:)`` converts between layers
///
/// ## Open Graph Article Tags
///
/// When rendered in `BasePage`, this model generates the following meta tags:
/// ```html
/// <meta property="article:published_time" content="2025-01-01T00:00:00Z">
/// <meta property="article:modified_time" content="2025-01-15T00:00:00Z">
/// <meta property="article:author" content="21.dev">
/// <meta property="article:tag" content="swift">
/// <meta property="article:tag" content="bitcoin">
/// ```
///
/// These tags enable:
/// - Rich snippets in Google search results
/// - Proper article classification by search engines
/// - Better content discovery and indexing
///
/// ## Usage
///
/// Create `ArticleMetadata` from ``BlogMetadata`` using the adapter method:
/// ```swift
/// let blogPost = try BlogPost.parse(from: markdownContent)
/// let articleMeta = blogPost.metadata.toArticleMetadata()
///
/// BasePage(
///     title: blogPost.metadata.title,
///     description: blogPost.metadata.excerpt,
///     articleMetadata: articleMeta
/// ) {
///     // Page content
/// }
/// ```
///
/// ## Design Rationale
///
/// This separate struct (rather than extending `BlogMetadata` directly) ensures:
/// 1. **Separation of Concerns**: Domain models don't depend on presentation logic
/// 2. **Dependency Inversion**: `BasePage` depends on `ArticleMetadata` abstraction, not `BlogMetadata` concrete type
/// 3. **Reusability**: Other content types (documentation, changelogs) can use `ArticleMetadata` without `BlogMetadata`
/// 4. **Testability**: Presentation logic can be tested independently of domain logic
///
/// - SeeAlso: ``BlogMetadata/toArticleMetadata(author:)``
/// - SeeAlso: [Open Graph Protocol - Article](https://ogp.me/#type_article)
public struct ArticleMetadata: Sendable {
    
    /// Publication date in ISO8601 format.
    ///
    /// Used for the `article:published_time` Open Graph meta tag.
    /// Must be in ISO8601 format (e.g., "2025-01-01T00:00:00Z").
    public let publishedTime: String
    
    /// Last modification date in ISO8601 format (optional).
    ///
    /// Used for the `article:modified_time` Open Graph meta tag.
    /// Only include if the article has been updated after initial publication.
    public let modifiedTime: String?
    
    /// Author name (optional).
    ///
    /// Used for the `article:author` Open Graph meta tag.
    /// Typically represents the author's name or organization (e.g., "21.dev").
    public let author: String?
    
    /// Article tags/categories.
    ///
    /// Used to generate multiple `article:tag` Open Graph meta tags.
    /// Each tag is rendered as a separate meta tag for proper categorization.
    public let tags: [String]
    
    /// Creates article metadata for Open Graph tags.
    ///
    /// - Parameters:
    ///   - publishedTime: Publication date in ISO8601 format (e.g., "2025-01-01T00:00:00Z")
    ///   - modifiedTime: Optional modification date in ISO8601 format
    ///   - author: Optional author name (e.g., "21.dev")
    ///   - tags: Array of article tags/categories
    public init(
        publishedTime: String,
        modifiedTime: String? = nil,
        author: String? = nil,
        tags: [String] = []
    ) {
        self.publishedTime = publishedTime
        self.modifiedTime = modifiedTime
        self.author = author
        self.tags = tags
    }
}
