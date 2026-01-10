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
public struct Accordion: View, StyleModifier {
    
    // MARK: - StyleModifier
    
    public var style: String {
        """
        /* Accordion icon rotation when open */
        details[open] .accordion-icon {
            transform: rotate(90deg);
        }
        .accordion-icon {
            transition: transform 0.3s ease-in-out;
        }
        """
    }
    
    public var componentName: String { "Accordion" }
    
    // MARK: - Properties
    
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
                        .textColor(.palette(.orange, darkness: 500))
                        .modifier(ClassModifier(add: "accordion-icon"))
                }
                .display(.flex)
                .alignItems(.center)
                .justifyContent(.between)
                .padding(.all, 24)
            }
            .pointerStyle(.pointer)
            .listStyle(.none)
            .transition(.colors)
            .modifier(ClassModifier(add: "duration-200"))
            
            Div {
                item.answer
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .textColor(.palette(.gray, darkness: 600))
            .fontSize(.small)
        }
        .modifier(ConditionalAttributeModifier("open", condition: item.isDefaultOpen))
        .background(.palette(.gray, darkness: 50))
        .cornerRadius(.extraLarge)
        .border(.palette(.gray, darkness: 200))
        .margin(.bottom, 16)
        .transition(.colors)
        .modifier(ClassModifier(add: "duration-200"))
        .background(.palette(.gray, darkness: 100), condition: .hover)
    }
    
    public var body: some View {
        Div {
            ForEach(items, id: \.id) { item in
                accordionItem(item)
            }
        }
    }
}
