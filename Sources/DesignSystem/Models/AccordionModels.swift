//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Represents an accordion item for use in expandable FAQ sections.
/// Provides flexible content support with rich text, links, and interactive elements.
public struct AccordionItem: Sendable, Identifiable {
    /// Unique identifier for the accordion item
    public let id: String
    /// The question or header text
    public let question: String
    /// The answer content (can be rich content)
    public let answer: AnyView
    /// Whether this item should be open by default
    public let isDefaultOpen: Bool
    
    /// Creates an accordion item.
    /// - Parameters:
    ///   - question: The question or header text
    ///   - answer: The answer content (supports rich content)
    ///   - id: Optional custom identifier (auto-generated if not provided)
    ///   - isDefaultOpen: Whether this item should be open by default
    public init<Answer: View>(
        question: String,
        answer: Answer,
        id: String? = nil,
        isDefaultOpen: Bool = false
    ) {
        self.question = question
        self.answer = AnyView(answer)
        self.id = id ?? UUID().uuidString
        self.isDefaultOpen = isDefaultOpen
    }
}
