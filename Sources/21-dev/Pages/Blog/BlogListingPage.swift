//
//  BlogListingPage.swift
//  21-DOT-DEV/BlogListingPage.swift
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream
import DesignSystem
import SchemaLib

struct BlogListingPage {
    // Page metadata
    private static let pageTitle = "Bitcoin Dev + Swift Cryptography Tutorials & Updates | 21.dev Blog"
    private static let pageDescription = "Practical Bitcoin developer notes, Swift cryptography tutorials, and the latest P256K open-source updates—21.dev."
    private static let pageURL = "\(SiteIdentity.url)blog/"
    
    static func page(posts: [BlogPost]) -> some View {
        let itemList = ItemListSchema(id: "\(pageURL)#itemlist", items: posts.enumerated().map { index, post in
            ListItemSchema(
                position: index + 1,
                url: "\(SiteIdentity.url)blog/\(post.metadata.slug)/",
                name: post.metadata.title
            )
        })
        
        return BasePage(
            title: pageTitle,
            description: pageDescription,
            canonicalURL: URL(string: pageURL),
            robotsDirective: "noindex",
            schemas: [
                SiteIdentity.webPageSchema(
                    url: pageURL,
                    pageType: .collectionPage,
                    name: pageTitle,
                    description: pageDescription,
                    mainEntity: SchemaReference(id: "\(pageURL)#itemlist")
                ),
                itemList,
                SiteIdentity.organizationSchema,
                BreadcrumbListSchema(items: [
                    BreadcrumbItemSchema(position: 1, name: "Home", item: SiteIdentity.url),
                    BreadcrumbItemSchema(position: 2, name: "Blog")
                ])
            ],
            llmsTxtURL: SiteIdentity.llmsTxtURL
        ) {
            SiteDefaults.header
            
            // Blog posts section
            blogPostsSection(posts: posts)
            
            SiteDefaults.footer
        }
    }
    
    @ViewBuilder
    static func blogPostsSection(posts: [BlogPost]) -> some View {
        
        Div {
            Div {
                H1 {
                    Text("Blog")
                }
                .fontSize(.fourXLarge)
                .fontWeight(.bold)
                .margin(.bottom, 32)
                
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
            .frame(maxWidth: .fourXLarge)
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
        .shadow("lg")
    }
}

// Helper extension to make BlogPost work with ForEach
extension BlogPost: Identifiable {
    var id: String { metadata.slug }
}

