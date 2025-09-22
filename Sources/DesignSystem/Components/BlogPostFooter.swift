//
//  BlogPostFooter.swift
//  21-DOT-DEV/BlogPostFooter.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Footer component for blog posts with action links like "Read more" and "Back to blog".
/// Uses ContentItem for flexible action configuration.
public struct BlogPostFooter: View {
    private let actions: [ContentItem]
    
    /// Creates a blog post footer with action links.
    /// - Parameter actions: Array of ContentItem representing footer actions
    public init(actions: [ContentItem]) {
        self.actions = actions
    }
    
    public var body: some View {
        if !actions.isEmpty {
            Div {
                HStack(spacing: 16) {
                    ForEach(actions) { action in
                        if let link = action.link {
                            Link(URL(string: link)) {
                                Slipstream.Text(action.title)
                            }
                            .fontSize(.base)
                            .textColor(.palette(.orange, darkness: 600))
                            .fontWeight(.medium)
                            .textDecoration(.none)
                            .modifier(ClassModifier(add: "hover:text-orange-700 transition-colors"))
                        } else {
                            Span {
                                Slipstream.Text(action.title)
                            }
                            .fontSize(.base)
                            .textColor(.palette(.gray, darkness: 500))
                            .fontWeight(.medium)
                        }
                    }
                }
            }
        }
    }
}
