//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A gallery component for displaying organization/app icons in a responsive grid.
/// Uses fixed container sizing to ensure visual consistency across different logo aspect ratios.
public struct IconGallery: View {
    public let items: [ContentItem]
    
    /// Creates an icon gallery with an array of organization items.
    /// - Parameter items: Array of ContentItem items representing organizations/apps
    public init(items: [ContentItem]) {
        self.items = items
    }
    
    private func iconItem(_ item: ContentItem) -> some View {
        Div {
            if let urlString = item.link, let url = URL(string: urlString) {
                Link(url) {
                    iconContent(item)
                }
            } else {
                iconContent(item)
            }
        }
    }
    
    private func iconContent(_ item: ContentItem) -> some View {
        Div {
            item.icon
                .cornerRadius(.extraExtraLarge)
        }
        .display(.flex)
        .alignItems(.center)
        .justifyContent(.center)
        .frame(width: 128, height: 128)
        .padding(.all, 20)
        .modifier(ClassModifier(add: "w-32 h-32 p-5 flex items-center justify-center"))
    }
    
    public var body: some View {
        Div {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                iconItem(item)
            }
        }
        .modifier(ClassModifier(add: "grid grid-cols-3 gap-8 md:grid-cols-4 lg:grid-cols-5"))
    }
}
