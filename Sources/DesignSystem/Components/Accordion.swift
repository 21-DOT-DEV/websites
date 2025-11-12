//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// An accordion component for displaying expandable question-and-answer pairs.
/// Uses CSS-only interactions with smooth transitions and supports multiple open items.
public struct Accordion: View, StyleModifier {
    public let items: [AccordionItem]
    public let accordionId: String
    
    /// Creates an accordion with an array of accordion items.
    /// - Parameters:
    ///   - items: Array of AccordionItem items to display
    ///   - id: Optional unique identifier for the accordion (auto-generated if not provided)
    public init(items: [AccordionItem], id: String? = nil) {
        self.items = items
        self.accordionId = id ?? "accordion-\(UUID().uuidString.prefix(8))"
    }
    
    public var componentName: String {
        return "Accordion"
    }
    
    public var style: String {
        return """
        /* Accordion CSS-only interactions */
        .accordion-toggle {
            display: none;
        }
        
        .accordion-content {
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.3s ease-in-out, padding 0.3s ease-in-out;
            padding: 0 1.5rem;
        }
        
        .accordion-toggle:checked + .accordion-label + .accordion-content {
            max-height: 500px;
            padding: 1.25rem 1.5rem;
        }
        
        .accordion-icon {
            transition: transform 0.3s ease-in-out;
        }
        
        .accordion-toggle:checked + .accordion-label .accordion-icon {
            transform: rotate(90deg);
        }
        
        .accordion-item:hover {
            background-color: rgb(249 250 251);
        }
        """
    }
    
    private func accordionItem(_ item: AccordionItem, index: Int) -> some View {
        let toggleId = "\(accordionId)-toggle-\(index)"
        
        return Div {
            // Hidden checkbox for CSS-only toggle
            Checkbox(id: toggleId, checked: item.isDefaultOpen)
                .modifier(ClassModifier(add: "accordion-toggle"))
            
            // Clickable label (question)
            Label(for: toggleId) {
                Div {
                    Span {
                        Text(item.question)
                    }
                    .fontSize(.base)
                    .fontWeight(.medium)
                    .textColor(.palette(.gray, darkness: 700))
                    .modifier(ClassModifier(add: "flex-1"))
                    
                    // Chevron icon that rotates
                    ChevronIcon()
                        .modifier(ClassModifier(add: "accordion-icon text-orange-500"))
                }
                .display(.flex)
                .alignItems(.center)
                .justifyContent(.between)
                .padding(.all, 24)
            }
            .modifier(ClassModifier(add: "accordion-label cursor-pointer block w-full transition-colors duration-200"))
            
            // Answer content (expandable)
            Div {
                item.answer
            }
            .modifier(ClassModifier(add: "accordion-content text-gray-600 text-sm"))
        }
        .background(.palette(.gray, darkness: 50))
        .modifier(ClassModifier(add: "accordion-item rounded-xl border border-gray-200 mb-4 transition-colors duration-200"))
    }
    
    public var body: some View {
        Div {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                accordionItem(item, index: index)
            }
        }
    }
}
