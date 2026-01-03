//
//  BlogMetadataTests.swift
//  21-DOT-DEV/BlogMetadataTests.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
@testable import DesignSystem

@Suite("BlogMetadata Tests")
struct BlogMetadataTests {
    
    // MARK: - ISO8601 Date Conversion Tests
    
    @Test("ISO8601 conversion with valid date")
    func testISO8601ConversionWithValidDate() {
        let metadata = BlogMetadata(
            title: "Test Post",
            date: "2025-01-01",
            slug: "test-post",
            excerpt: "Test excerpt",
            tags: []
        )
        
        let iso8601 = metadata.iso8601Date
        
        // Should convert to ISO8601 format with timezone
        #expect(iso8601.hasPrefix("2025-01-01T"))
        #expect(iso8601.hasSuffix("Z"))
    }
    
    @Test("ISO8601 conversion with invalid date returns original")
    func testISO8601ConversionWithInvalidDate() {
        let metadata = BlogMetadata(
            title: "Test Post",
            date: "invalid-date",
            slug: "test-post",
            excerpt: "Test excerpt",
            tags: []
        )
        
        let iso8601 = metadata.iso8601Date
        
        // Should return original string when parsing fails
        #expect(iso8601 == "invalid-date")
    }
    
    @Test("ISO8601 conversion with edge case dates")
    func testISO8601ConversionEdgeCases() {
        let testCases = [
            ("2025-12-31", "2025-12-31T"),  // End of year
            ("2024-02-29", "2024-02-29T"),  // Leap year
            ("2025-01-01", "2025-01-01T"),  // Start of year
        ]
        
        for (input, expectedPrefix) in testCases {
            let metadata = BlogMetadata(
                title: "Test",
                date: input,
                slug: "test",
                excerpt: "",
                tags: []
            )
            
            #expect(metadata.iso8601Date.hasPrefix(expectedPrefix),
                   "Date \(input) should convert to ISO8601 starting with \(expectedPrefix)")
        }
    }
    
    // MARK: - ArticleMetadata Conversion Tests
    
    @Test("toArticleMetadata with default author")
    func testToArticleMetadataWithDefaultAuthor() {
        let metadata = BlogMetadata(
            title: "Test Post",
            date: "2025-01-01",
            slug: "test-post",
            excerpt: "Test excerpt",
            tags: ["swift", "bitcoin"]
        )
        
        let articleMeta = metadata.toArticleMetadata()
        
        #expect(articleMeta.publishedTime.hasPrefix("2025-01-01T"))
        #expect(articleMeta.author == "21.dev")
        #expect(articleMeta.tags == ["swift", "bitcoin"])
        #expect(articleMeta.modifiedTime == nil)
    }
    
    @Test("toArticleMetadata with custom author")
    func testToArticleMetadataWithCustomAuthor() {
        let metadata = BlogMetadata(
            title: "Test Post",
            date: "2025-01-01",
            slug: "test-post",
            excerpt: "Test excerpt",
            tags: []
        )
        
        let articleMeta = metadata.toArticleMetadata(author: "John Doe")
        
        #expect(articleMeta.author == "John Doe")
    }
    
    @Test("toArticleMetadata preserves all tags")
    func testToArticleMetadataPreservesTags() {
        let tags = ["swift", "bitcoin", "crypto", "open-source"]
        let metadata = BlogMetadata(
            title: "Test Post",
            date: "2025-01-01",
            slug: "test-post",
            excerpt: "Test excerpt",
            tags: tags
        )
        
        let articleMeta = metadata.toArticleMetadata()
        
        #expect(articleMeta.tags.count == 4)
        #expect(articleMeta.tags == tags)
    }
    
    @Test("toArticleMetadata with empty tags")
    func testToArticleMetadataWithEmptyTags() {
        let metadata = BlogMetadata(
            title: "Test Post",
            date: "2025-01-01",
            slug: "test-post",
            excerpt: "Test excerpt",
            tags: []
        )
        
        let articleMeta = metadata.toArticleMetadata()
        
        #expect(articleMeta.tags.isEmpty)
    }
    
    // MARK: - Adapter Pattern Integration Tests
    
    @Test("ArticleMetadata adapter maintains data integrity")
    func testAdapterMaintainsDataIntegrity() {
        let metadata = BlogMetadata(
            title: "Complex Post Title",
            date: "2025-06-15",
            slug: "complex-post",
            excerpt: "A complex excerpt with special characters: <>&\"'",
            tags: ["tag1", "tag2", "tag3"]
        )
        
        let articleMeta = metadata.toArticleMetadata(author: "Test Author")
        
        // Verify no data loss in conversion
        #expect(articleMeta.publishedTime.contains("2025-06-15"))
        #expect(articleMeta.author == "Test Author")
        #expect(articleMeta.tags.count == 3)
        #expect(articleMeta.tags[0] == "tag1")
        #expect(articleMeta.tags[1] == "tag2")
        #expect(articleMeta.tags[2] == "tag3")
    }
    
    @Test("Multiple conversions produce consistent results")
    func testMultipleConversionsConsistent() {
        let metadata = BlogMetadata(
            title: "Test",
            date: "2025-01-01",
            slug: "test",
            excerpt: "",
            tags: ["a", "b"]
        )
        
        let result1 = metadata.toArticleMetadata()
        let result2 = metadata.toArticleMetadata()
        
        // Conversions should be deterministic
        #expect(result1.publishedTime == result2.publishedTime)
        #expect(result1.author == result2.author)
        #expect(result1.tags == result2.tags)
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Conversion handles maximum length tags")
    func testConversionHandlesLongTags() {
        let longTag = String(repeating: "a", count: 100)
        let metadata = BlogMetadata(
            title: "Test",
            date: "2025-01-01",
            slug: "test",
            excerpt: "",
            tags: [longTag]
        )
        
        let articleMeta = metadata.toArticleMetadata()
        
        #expect(articleMeta.tags[0] == longTag)
    }
    
    @Test("Conversion handles special characters in tags")
    func testConversionHandlesSpecialCharactersInTags() {
        let specialTags = ["swift#lang", "c++", "node.js", "@types", "React/Native"]
        let metadata = BlogMetadata(
            title: "Test",
            date: "2025-01-01",
            slug: "test",
            excerpt: "",
            tags: specialTags
        )
        
        let articleMeta = metadata.toArticleMetadata()
        
        #expect(articleMeta.tags == specialTags)
    }
    
    // MARK: - SEO Title Tests
    
    @Test("BlogMetadata with optional seoTitle")
    func testBlogMetadataWithSeoTitle() {
        let metadata = BlogMetadata(
            title: "Hello World",
            date: "2025-01-01",
            slug: "hello-world",
            excerpt: "Test excerpt",
            tags: [],
            seoTitle: "Hello World: Why 21.dev Exists + Introducing P256K | 21.dev Blog"
        )
        
        #expect(metadata.seoTitle == "Hello World: Why 21.dev Exists + Introducing P256K | 21.dev Blog")
    }
    
    @Test("BlogMetadata without seoTitle defaults to nil")
    func testBlogMetadataWithoutSeoTitle() {
        let metadata = BlogMetadata(
            title: "Test Post",
            date: "2025-01-01",
            slug: "test-post",
            excerpt: "Test excerpt",
            tags: []
        )
        
        #expect(metadata.seoTitle == nil)
    }
    
    @Test("SEO title validation warns for long titles")
    func testSeoTitleValidationWarning() {
        let shortTitle = "Short Title"
        let optimalTitle = String(repeating: "x", count: 60)
        let longTitle = String(repeating: "x", count: 80)
        
        let shortMeta = BlogMetadata(
            title: "Test",
            date: "2025-01-01",
            slug: "test",
            excerpt: "",
            tags: [],
            seoTitle: shortTitle
        )
        
        let optimalMeta = BlogMetadata(
            title: "Test",
            date: "2025-01-01",
            slug: "test",
            excerpt: "",
            tags: [],
            seoTitle: optimalTitle
        )
        
        let longMeta = BlogMetadata(
            title: "Test",
            date: "2025-01-01",
            slug: "test",
            excerpt: "",
            tags: [],
            seoTitle: longTitle
        )
        
        // Should not warn for short/optimal titles
        #expect(!shortMeta.shouldWarnAboutSeoTitleLength)
        #expect(!optimalMeta.shouldWarnAboutSeoTitleLength)
        
        // Should warn for long title
        #expect(longMeta.shouldWarnAboutSeoTitleLength)
    }
}
