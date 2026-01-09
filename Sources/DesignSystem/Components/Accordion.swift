//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// An accordion component for displaying expandable question-and-answer pairs.
/// Uses native HTML5 details/summary elements for accessibility and progressive enhancement.
/// Supports multiple open items simultaneously.
public struct Accordion: View {
    public let items: [AccordionItem]
    
    /// Creates an accordion with an array of accordion items.
    /// - Parameters:
    ///   - items: Array of AccordionItem items to display
    public init(items: [AccordionItem]) {
        self.items = items
    }
    
    private func accordionItem(_ item: AccordionItem) -> some View {
        Details {
            Summary {
                Div {
                    Span {
                        Text(item.question)
                    }
                    .fontSize(.base)
                    .fontWeight(.medium)
                    .textColor(.palette(.gray, darkness: 700))
                    .modifier(ClassModifier(add: "flex-1"))
                    
                    ChevronIcon()
                        .modifier(ClassModifier(add: "accordion-icon text-orange-500"))
                }
                .display(.flex)
                .alignItems(.center)
                .justifyContent(.between)
                .padding(.all, 24)
            }
            .modifier(ClassModifier(add: "cursor-pointer list-none transition-colors duration-200"))
            
            Div {
                item.answer
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .modifier(ClassModifier(add: "text-gray-600 text-sm"))
        }
        .modifier(ConditionalAttributeModifier("open", condition: item.isDefaultOpen))
        .background(.palette(.gray, darkness: 50))
        .modifier(ClassModifier(add: "rounded-xl border border-gray-200 mb-4 transition-colors duration-200 hover:bg-gray-100"))
    }
    
    public var body: some View {
        Div {
            ForEach(items, id: \.id) { item in
                accordionItem(item)
            }
        }
    }
}
