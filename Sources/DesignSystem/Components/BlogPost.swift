//
//  BlogPost.swift
//  21-DOT-DEV/BlogPost.swift
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Slipstream

/// Compound blog post component that composes header, content, and footer.
/// Follows composition pattern for maximum flexibility and reusability.
public struct BlogPostComponent<Content: View>: View {
    private let content: Content
    private let header: BlogPostHeader
    private let footer: BlogPostFooter
    
    /// Creates a blog post with composed components.
    /// - Parameters:
    ///   - content: The blog content component
    ///   - header: The blog post header component
    ///   - footer: The blog post footer component
    public init(content: Content, header: BlogPostHeader, footer: BlogPostFooter) {
        self.content = content
        self.header = header
        self.footer = footer
    }
    
    public var body: some View {
        VStack(spacing: 32) {
            header
            content
            footer
        }
    }
}
