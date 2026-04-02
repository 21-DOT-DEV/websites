//
//  FAQPageSchema+FAQItem.swift
//  DesignSystem
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import SchemaLib

/// Bridges DesignSystem's `FAQItem` to SchemaLib's `FAQPageSchema`.
extension FAQPageSchema {
    /// Creates an FAQPage schema from FAQItems, filtering by includeInJSONLD.
    public init(items: [FAQItem]) {
        self.init(questions: items
            .filter { $0.includeInJSONLD }
            .map { QuestionSchema(question: $0.question, answer: $0.answer) }
        )
    }
}
