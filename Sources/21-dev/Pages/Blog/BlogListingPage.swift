//
//  BlogListingPage.swift
//  21-DOT-DEV/BlogListingPage.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem

struct BlogListingPage {
    // CSS components for rendering styles
    static var cssComponents: [any HasComponentCSS] {
        [SiteDefaults.header]
    }
    
    static var page: some View {
        BasePage(
            title: "Blog - 21.dev",
            canonicalURL: URL(string: "https://21.dev/blog/")
        ) {
            SiteDefaults.header
            
            // Blog posts section
            blogPostsSection
            
            SiteDefaults.footer
        }
    }
    
    @ViewBuilder
    static var blogPostsSection: some View {
        let posts = BlogService.loadAllPosts()
        
        Div {
            Div {
                if posts.isEmpty {
                    // No posts message
                    Div {
                        Paragraph {
                            Text("No blog posts yet. Check back soon!")
                        }
                        .fontSize(.large)
                        .textColor(.palette(.gray, darkness: 600))
                        .textAlignment(.center)
                    }
                    .padding(48)
                } else {
                    // Posts list
                    VStack(spacing: 48) {
                        ForEach(posts) { post in
                            blogPostCard(post)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.horizontal, 24, condition: Condition(startingAt: .small))
            .padding(.horizontal, 32, condition: Condition(startingAt: .large))
            .modifier(ClassModifier(add: "max-w-4xl"))
            .margin(.horizontal, .auto)
        }
        .padding(.vertical, 64)
        .background(.palette(.gray, darkness: 50))
    }
    
    @ViewBuilder
    static func blogPostCard(_ post: BlogPost) -> some View {
        BlogPostComponent(
            content: BlogContent {
                MarkdownRenderer(post.content)
            },
            header: BlogPostHeader(
                metadata: post.metadata,
                titleLevel: .h2,
                isLinked: true,
                content: post.content
            ),
            footer: BlogPostFooter(actions: [
                ContentItem(
                    title: "Read full post →",
                    description: "",
                    icon: EmptyView(),
                    link: "/blog/\(post.metadata.slug)/"
                )
            ])
        )
        .background(Slipstream.Color.white)
        .padding(32)
        .cornerRadius(.large)
        .modifier(ClassModifier(add: "shadow-lg"))
    }
}

// Helper extension to make BlogPost work with ForEach
extension BlogPost: Identifiable {
    var id: String { metadata.slug }
}

