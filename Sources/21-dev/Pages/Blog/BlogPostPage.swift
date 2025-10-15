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
    
    // CSS components for rendering styles
    static var cssComponents: [any HasComponentCSS] {
        [SiteDefaults.header]
    }
    
    static func page(for slug: String) -> (any View)? {
        guard let post = BlogService.loadPost(slug: slug) else {
            return nil
        }
        
        return BlogPostPage(post: post).body
    }
    
    var body: some View {
        BasePage(title: "\(post.metadata.title) - Blog - 21.dev") {
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
