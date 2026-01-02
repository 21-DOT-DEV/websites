//
//  BlogMetadata.swift
//  21-DOT-DEV/BlogMetadata.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Represents the frontmatter metadata for a blog post
public struct BlogMetadata: Codable, Sendable {
    public let title: String
    public let date: String
    public let slug: String
    public let excerpt: String
    public let tags: [String]
    
    public init(title: String, date: String, slug: String, excerpt: String, tags: [String]) {
        self.title = title
        self.date = date
        self.slug = slug
        self.excerpt = excerpt
        self.tags = tags
    }
    
    /// Parse date string into a Date object for sorting
    public var parsedDate: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date) ?? Date.distantPast
    }
    
    /// Format date for display
    public var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: self.date) else {
            return self.date
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .long
        return displayFormatter.string(from: date)
    }
    
    /// Calculate estimated read time based on content length
    public func estimatedReadTime(for content: String) -> String {
        let wordsPerMinute = 200
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        let minutes = max(1, (wordCount + wordsPerMinute - 1) / wordsPerMinute)
        return "\(minutes) min read"
    }
    
    /// Convert date string to ISO8601 format for article metadata
    ///
    /// Converts the blog post date (yyyy-MM-dd) to ISO8601 format suitable
    /// for Open Graph article:published_time meta tags.
    ///
    /// - Returns: ISO8601 formatted date string (e.g., "2025-01-01T00:00:00Z")
    public var iso8601Date: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: self.date) else {
            return self.date
        }
        
        let iso8601Formatter = ISO8601DateFormatter()
        return iso8601Formatter.string(from: date)
    }
    
    /// Convert BlogMetadata to ArticleMetadata for Open Graph article tags
    ///
    /// This adapter method transforms blog post frontmatter into the format
    /// required for Open Graph article meta tags. Follows the Adapter Pattern
    /// to decouple domain models (BlogMetadata) from presentation concerns (ArticleMetadata).
    ///
    /// - Parameter author: Author name to use for article:author tag. Defaults to "21.dev"
    /// - Returns: ArticleMetadata suitable for rendering Open Graph article tags
    ///
    /// ## Example
    /// ```swift
    /// let blogPost = BlogPost.parse(from: markdownContent)
    /// let articleMeta = blogPost.metadata.toArticleMetadata()
    /// ```
    public func toArticleMetadata(author: String = "21.dev") -> ArticleMetadata {
        ArticleMetadata(
            publishedTime: iso8601Date,
            author: author,
            tags: tags
        )
    }
}
