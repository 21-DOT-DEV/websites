//
//  BlogPost.swift
//  21-DOT-DEV/BlogPost.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import DesignSystem

/// Represents a complete blog post with metadata and content
struct BlogPost {
    let metadata: BlogMetadata
    let content: String
    
    /// Parse a markdown file with frontmatter
    static func parse(from markdownContent: String) throws -> BlogPost {
        let lines = markdownContent.components(separatedBy: .newlines)
        
        // Check if file starts with frontmatter
        guard lines.first == "---" else {
            throw BlogParsingError.noFrontmatter
        }
        
        // Find the end of frontmatter
        var frontmatterEndIndex = -1
        for (index, line) in lines.enumerated() {
            if index > 0 && line == "---" {
                frontmatterEndIndex = index
                break
            }
        }
        
        guard frontmatterEndIndex > 0 else {
            throw BlogParsingError.invalidFrontmatter
        }
        
        // Extract frontmatter and content
        let frontmatterLines = Array(lines[1..<frontmatterEndIndex])
        let contentLines = Array(lines[(frontmatterEndIndex + 1)...])
        
        let frontmatterString = frontmatterLines.joined(separator: "\n")
        let content = contentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse YAML frontmatter manually (simple key-value parser)
        let metadata = try parseFrontmatter(frontmatterString)
        
        return BlogPost(metadata: metadata, content: content)
    }
    
    /// Parse YAML frontmatter into BlogMetadata
    private static func parseFrontmatter(_ yaml: String) throws -> BlogMetadata {
        var title = ""
        var date = ""
        var slug = ""
        var excerpt = ""
        var tags: [String] = []
        var seoTitle: String?
        
        let lines = yaml.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }
            
            if let colonRange = trimmed.range(of: ": ") {
                let key = String(trimmed[..<colonRange.lowerBound])
                let value = String(trimmed[colonRange.upperBound...])
                
                // Remove quotes if present
                let cleanValue = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                
                switch key {
                case "title":
                    title = cleanValue
                case "date":
                    date = cleanValue
                case "slug":
                    slug = cleanValue
                case "excerpt":
                    excerpt = cleanValue
                case "tags":
                    // Parse simple array format: ["tag1", "tag2"]
                    if cleanValue.hasPrefix("[") && cleanValue.hasSuffix("]") {
                        let tagsString = String(cleanValue.dropFirst().dropLast())
                        tags = tagsString.components(separatedBy: ", ")
                            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
                    }
                case "seoTitle":
                    seoTitle = cleanValue
                default:
                    break
                }
            }
        }
        
        guard !title.isEmpty, !date.isEmpty, !slug.isEmpty else {
            throw BlogParsingError.missingRequiredFields
        }
        
        let metadata = BlogMetadata(title: title, date: date, slug: slug, excerpt: excerpt, tags: tags, seoTitle: seoTitle)
        
        // Soft validation: log warning if seoTitle exceeds 60 characters
        if metadata.shouldWarnAboutSeoTitleLength {
            print("⚠️  SEO Title Warning: '\(slug)' has seoTitle longer than 60 characters (\(seoTitle?.count ?? 0) chars). Google typically displays 50-60 characters.")
        }
        
        return metadata
    }
}

/// Errors that can occur during blog post parsing
enum BlogParsingError: Error, LocalizedError {
    case noFrontmatter
    case invalidFrontmatter
    case missingRequiredFields
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .noFrontmatter:
            return "Blog post must start with frontmatter (---)"
        case .invalidFrontmatter:
            return "Invalid frontmatter format"
        case .missingRequiredFields:
            return "Missing required fields: title, date, or slug"
        case .fileNotFound:
            return "Blog post file not found"
        }
    }
}
