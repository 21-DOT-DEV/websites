//
//  FAQ.swift
//  DesignSystem
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A FAQ component that renders a visual accordion.
/// Uses native HTML5 details/summary for accessibility and progressive enhancement.
/// For JSON-LD structured data, use the `schema` property and pass to BasePage.
public struct FAQ: View {
    public let items: [FAQItem]
    
    /// Creates a FAQ with an array of FAQ items.
    /// - Parameters:
    ///   - items: Array of FAQItem items to display
    public init(items: [FAQItem]) {
        self.items = items
    }
    
    /// Returns an FAQPageSchema for use with BasePage's schemas parameter.
    /// Only includes items where includeInJSONLD is true.
    public var schema: FAQPageSchema {
        FAQPageSchema(items: items)
    }
    
    private func faqItem(_ item: FAQItem) -> some View {
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
                item.content
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .textColor(.palette(.gray, darkness: 600))
            .fontSize(.small)
        }
        .background(.palette(.gray, darkness: 50))
        .cornerRadius(.extraLarge)
        .border(.palette(.gray, darkness: 200))
        .margin(.bottom, 16)
        .transition(.colors)
        .modifier(ClassModifier(add: "duration-200 hover:bg-gray-100"))
    }
    
    public var body: some View {
        Div {
            ForEach(items, id: \.id) { item in
                faqItem(item)
            }
        }
    }
}
