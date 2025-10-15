//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A reusable section introduction component with badge, title, and description.
/// Provides consistent styling for section headers across the site.
/// Includes Section/Div wrapper and supports trailing closure for content.
public struct SectionIntro<Content: View>: View {
    public let badge: String
    public let title: String
    private let descriptionView: AnyView
    public let maxWidth: MaxWidth
    public let content: Content
    
    /// Creates a section intro with badge, title, plain text description, and content.
    /// - Parameters:
    ///   - badge: The small badge/category text displayed above the title
    ///   - title: The main section heading
    ///   - description: Plain text description below the title
    ///   - maxWidth: Maximum content width (default: xl)
    ///   - content: The content to display after the intro
    public init(
        badge: String,
        title: String,
        description: String,
        maxWidth: MaxWidth = .xL,
        @ViewBuilder content: () -> Content
    ) {
        self.badge = badge
        self.title = title
        self.descriptionView = AnyView(Paragraph(description))
        self.maxWidth = maxWidth
        self.content = content()
    }
    
    /// Creates a section intro with badge, title, rich view-based description, and content.
    /// - Parameters:
    ///   - badge: The small badge/category text displayed above the title
    ///   - title: The main section heading
    ///   - description: ViewBuilder closure for rich description content (supports links, formatting, etc.)
    ///   - maxWidth: Maximum content width (default: xl)
    ///   - content: The content to display after the intro
    public init(
        badge: String,
        title: String,
        @ViewBuilder description: () -> some View,
        maxWidth: MaxWidth = .xL,
        @ViewBuilder content: () -> Content
    ) {
        self.badge = badge
        self.title = title
        let descriptionContent = description()
        self.descriptionView = AnyView(Paragraph { descriptionContent })
        self.maxWidth = maxWidth
        self.content = content()
    }
    
    public var body: some View {
        Section {
            Div {
                // Intro content
                Div {
                    // Badge
                    Span {
                        Text(badge)
                    }
                    .modifier(ClassModifier(add: "text-transparent bg-clip-text font-medium tracking-widest bg-gradient-to-r from-orange-400 via-yellow-500 to-red-500 text-xs uppercase"))
                    .display(.inlineBlock)
                    
                    // Title
                    Paragraph(title)
                        .fontSize(.extraExtraExtraLarge)
                        .margin(.top, 32)
                        .fontWeight(.regular)
                        .textColor(.black)
                    
                    // Description
                    descriptionView
                        .modifier(ClassModifier(add: maxWidth.cssClass))
                        .margin(.top, 16)
                        .fontSize(.extraLarge)
                        .textColor(.palette(.slate, darkness: 400))
                }
                .modifier(ClassModifier(add: maxWidth.cssClass))
                
                // Content
                content
                .margin(.top, 24)
            }
            .modifier(ClassModifier(add: "max-w-4xl"))
            .margin(.horizontal, .auto)
            .padding(.horizontal, 16)
            .padding(.horizontal, 24, condition: .startingAt(.small))
        }
        .padding(.vertical, 64)
    }
}
