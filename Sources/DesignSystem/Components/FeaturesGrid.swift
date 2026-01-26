//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A grid component for displaying feature cards in a responsive layout.
/// Displays features in a 1-column mobile, 3-column desktop grid with consistent styling.
public struct FeaturesGrid: View {
    public let features: [ContentItem]
    
    /// Creates a features grid with an array of content items.
    /// - Parameter features: Array of ContentItem items to display
    public init(features: [ContentItem]) {
        self.features = features
    }
    
    private func featureCard(feature: ContentItem) -> some View {
        Div {
            // Icon and title container
            Div {
                // Icon container
                Div {
                    feature.icon
                }
                .modifier(ClassModifier(add: "flex items-center justify-center w-12 h-12 text-white shadow-indigo-500/20 bg-gradient-to-tr shadow-2xl from-gray-900 to-gray-700 rounded-xl"))
                
                // Title
                H3 {
                    Text(feature.title)
                }
                .margin(.top, 20)
                .fontSize(.large)
                .fontSize(.extraLarge, condition: Condition(startingAt: .large))
                .fontWeight(.medium)
                .textColor(.black)
            }
            
            // Description
            Div {
                Text(feature.description)
            }
            .margin(.top, 8)
            .fontSize(.base)
            .textColor(.palette(.slate, darkness: 400))
        }
    }
    
    public var body: some View {
        Div {
            ForEach(features) { feature in
                featureCard(feature: feature)
            }
        }
        .modifier(ClassModifier(add: "grid gap-8 mt-6 list-none grid-cols-1 md:grid-cols-3 lg:grid-cols-3 lg:gap-12 lg:mt-24"))
    }
}
