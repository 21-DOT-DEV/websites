//
//  BlogPostPage.swift
//  21-DOT-DEV/BlogPostPage.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem

struct BlogPostPage {
    private let post: BlogPost
    
    init(post: BlogPost) {
        self.post = post
    }
    
    static func page(for slug: String) -> (any View)? {
        guard let post = BlogService.loadPost(slug: slug) else {
            return nil
        }
        
        return BlogPostPage(post: post).body
    }
    
    private func generateDescription() -> String {
        if !post.metadata.excerpt.isEmpty {
            return post.metadata.excerpt
        }
        
        let cleanContent = post.content
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanContent.count <= 150 {
            return cleanContent
        }
        
        let truncated = String(cleanContent.prefix(150))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        
        return truncated + "..."
    }
    
    var body: some View {
        BasePage(
            title: post.metadata.seoTitle ?? "\(post.metadata.title) | 21.dev Blog",
            description: generateDescription(),
            canonicalURL: URL(string: "https://21.dev/blog/\(post.metadata.slug)/"),
            articleMetadata: post.metadata.toArticleMetadata()
        ) {
            SiteDefaults.header
            
            // Main content using compound BlogPost component
            Div {
                BlogPostComponent(
                    content: BlogContent {
                        MarkdownRenderer(post.content)
                    },
                    header: BlogPostHeader(
                        metadata: post.metadata,
                        titleLevel: .h1,
                        isLinked: false,
                        content: post.content
                    ),
                    footer: BlogPostFooter(actions: [
                        ContentItem(
                            title: "← Back to Blog",
                            description: "",
                            icon: EmptyView(),
                            link: "/blog/"
                        )
                    ])
                )
                .padding(.horizontal, 16)
                .padding(.horizontal, 24, condition: Condition(startingAt: .small))
                .padding(.horizontal, 32, condition: Condition(startingAt: .large))
                .modifier(ClassModifier(add: "max-w-3xl"))
                .margin(.horizontal, .auto)
            }
            .padding(.vertical, 64)
            .background(.white)
            
            SiteDefaults.footer
        }
    }
}
