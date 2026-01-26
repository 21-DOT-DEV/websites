//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A grid component for displaying clickable content cards in a responsive layout.
/// Displays cards in a 1-column mobile, 2-column tablet, 3-column desktop grid with hover effects.
public struct CardGrid: View {
    public let items: [ContentItem]
    
    /// Creates a card grid with an array of content items.
    /// - Parameter items: Array of ContentItem items to display
    public init(items: [ContentItem]) {
        self.items = items
    }
    
    @ViewBuilder
    private func card(item: ContentItem) -> some View {
        if let link = item.link {
            Link(URL(string: link)) {
                cardContent(item: item)
            }
            .display(.block)
        } else {
            cardContent(item: item)
        }
    }
    
    private func cardContent(item: ContentItem) -> some View {
        Div {
            // Icon container
            Div {
                item.icon
            }
            .modifier(ClassModifier(add: "flex items-center justify-center w-12 h-12 text-white shadow-indigo-500/20 bg-gradient-to-tr shadow-2xl from-gray-900 to-gray-700 rounded-xl"))
            
            // Title
            H3 {
                Text(item.title)
            }
            .margin(.top, 20)
            .fontSize(.large)
            .fontSize(.extraLarge, condition: Condition(startingAt: .large))
            .fontWeight(.semibold)
            .textColor(.palette(.gray, darkness: 700))
            .modifier(ClassModifier(add: "dark:text-white"))
            
            // Description
            Paragraph {
                Text(item.description)
            }
            .margin(.top, 12)
            .fontSize(.base)
            .textColor(.palette(.gray, darkness: 500))
            .modifier(ClassModifier(add: "dark:text-gray-300"))
            
            // Link indicator (only shown if card has a link)
            if item.link != nil {
                Div {
                    Span {
                        Text("Learn more")
                    }
                    .margin(.horizontal, 4)
                    
                    // Arrow icon
                    ArrowRightIcon()
                        .modifier(ClassModifier(add: "mx-1 rtl:-scale-x-100"))
                }
                .modifier(ClassModifier(add: "flex items-center -mx-1 text-sm text-orange-500 capitalize transition-colors duration-300 transform hover:underline hover:text-orange-600 mt-4"))
            }
        }
        .modifier(ClassModifier(add: "flex flex-col items-center p-6 space-y-3 text-center bg-gray-50 rounded-xl border border-gray-200 hover:shadow-lg transition-all duration-300 hover:scale-[1.02] h-full"))
        .modifier(ClassModifier(add: "dark:bg-gray-800 dark:border-gray-700"))
    }
    
    public var body: some View {
        Div {
            ForEach(items) { item in
                card(item: item)
            }
        }
        .modifier(ClassModifier(add: "grid gap-8 mt-8 grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:gap-16"))
    }
}
