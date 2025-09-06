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
public struct SectionIntro: View {
    public let badge: String
    public let title: String
    public let description: String
    public let maxWidth: MaxWidth
    
    /// Creates a section intro with badge, title, and description.
    /// - Parameters:
    ///   - badge: The small badge/category text displayed above the title
    ///   - title: The main section heading
    ///   - description: The descriptive text below the title
    ///   - maxWidth: Maximum content width (default: xl)
    public init(
        badge: String,
        title: String,
        description: String,
        maxWidth: MaxWidth = .xL
    ) {
        self.badge = badge
        self.title = title
        self.description = description
        self.maxWidth = maxWidth
    }
    
    public var body: some View {
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
            Paragraph(description)
                .modifier(ClassModifier(add: maxWidth.cssClass))
                .margin(.top, 16)
                .fontSize(.extraLarge)
                .textColor(.palette(.slate, darkness: 400))
        }
        .modifier(ClassModifier(add: maxWidth.cssClass))
    }
}
