//
//  FAQ.swift
//  DesignSystem
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Slipstream

/// A FAQ component that renders a visual accordion with JSON-LD schema support.
/// Uses Accordion internally for rendering, adding SEO structured data capabilities.
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
    
    /// Converts FAQItems to AccordionItems for rendering.
    private var accordionItems: [AccordionItem] {
        items.map { faqItem in
            AccordionItem(
                question: faqItem.question,
                answer: faqItem.content,
                id: faqItem.id
            )
        }
    }
    
    public var body: some View {
        Accordion(items: accordionItems)
    }
}
