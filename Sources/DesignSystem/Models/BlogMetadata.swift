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
}
