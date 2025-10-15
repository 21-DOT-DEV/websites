//
//  BlogPostHeader.swift
//  21-DOT-DEV/BlogPostHeader.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Header component for blog posts displaying metadata, title, and tags.
/// Supports different heading levels and optional linking for various contexts.
public struct BlogPostHeader: View {
    public enum HeadingLevel: Sendable {
        case h1, h2
    }
    
    private let metadata: BlogMetadata
    private let titleLevel: HeadingLevel
    private let isLinked: Bool
    private let content: String
    
    /// Creates a blog post header with metadata and configuration.
    /// - Parameters:
    ///   - metadata: Blog post metadata containing title, date, tags, etc.
    ///   - titleLevel: Whether to use H1 or H2 for the title
    ///   - isLinked: Whether the title should link to the post
    ///   - content: Blog post content for read time calculation
    public init(metadata: BlogMetadata, titleLevel: HeadingLevel = .h1, isLinked: Bool = false, content: String = "") {
        self.metadata = metadata
        self.titleLevel = titleLevel
        self.isLinked = isLinked
        self.content = content
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Metadata line (date and read time)
            Div {
                HStack(spacing: 8) {
                    Slipstream.Text(metadata.displayDate)
                    Slipstream.Text("•")
                        .textColor(.palette(.gray, darkness: 500))
                    Slipstream.Text(metadata.estimatedReadTime(for: content))
                }
            }
            .fontSize(.small)
            .textColor(.palette(.gray, darkness: 500))
            
            // Title
            titleView
            
            // Tags
            if !metadata.tags.isEmpty {
                Div {
                    HStack(spacing: 8) {
                        ForEach(metadata.tags.map { TagWrapper(text: $0) }) { tagWrapper in
                            Tag(tagWrapper.text)
                        }
                    }
                }
                .margin(.bottom, 24)
            }
        }
    }
    
    @ViewBuilder
    private var titleView: some View {
        switch (titleLevel, isLinked) {
        case (.h1, false):
            H1 {
                Slipstream.Text(metadata.title)
            }
            .fontSize(.fourXLarge)
            .fontWeight(.bold)
            .textColor(.palette(.gray, darkness: 900))
            .margin(.bottom, 16)
            
        case (.h1, true):
            Link(URL(string: "/blog/\(metadata.slug)/")) {
                H1 {
                    Slipstream.Text(metadata.title)
                }
                .fontSize(.fourXLarge)
                .fontWeight(.bold)
                .textColor(.palette(.gray, darkness: 900))
                .textDecoration(.none)
                .margin(.bottom, 16)
            }
            
        case (.h2, false):
            H2 {
                Slipstream.Text(metadata.title)
            }
            .fontSize(.fourXLarge)
            .fontWeight(.bold)
            .textColor(.palette(.gray, darkness: 900))
            .margin(.bottom, 16)
            
        case (.h2, true):
            Link(URL(string: "/blog/\(metadata.slug)/")) {
                H2 {
                    Slipstream.Text(metadata.title)
                }
                .fontSize(.fourXLarge)
                .fontWeight(.bold)
                .textColor(.palette(.gray, darkness: 900))
                .textDecoration(.none)
                .margin(.bottom, 16)
            }
        }
    }
}

// Helper struct for tag rendering
struct TagWrapper: Identifiable {
    let id = UUID()
    let text: String
}
