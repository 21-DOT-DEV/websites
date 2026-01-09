//
//  FAQModels.swift
//  DesignSystem
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Represents an FAQ item with both visual content and JSON-LD structured data.
/// Ensures single source of truth for question/answer pairs displayed on page and in schema.org markup.
public struct FAQItem: Sendable, Identifiable {
    /// Unique identifier for the FAQ item
    public let id: String
    /// The question text
    public let question: String
    /// The answer as HTML string for JSON-LD structured data
    public let answer: String
    /// Whether to include this item in JSON-LD structured data
    public let includeInJSONLD: Bool
    /// The visual content to render for the answer
    public let content: AnyView
    
    /// Creates an FAQ item with both structured data and visual content.
    /// - Parameters:
    ///   - question: The question text (used in both visual and JSON-LD)
    ///   - answer: The answer as plain text for JSON-LD
    ///   - includeInJSONLD: Whether to include this item in JSON-LD (default true)
    ///   - id: Optional custom identifier (auto-generated if not provided)
    ///   - content: The visual content to render for the answer
    public init<Content: View>(
        question: String,
        answer: String,
        includeInJSONLD: Bool = true,
        id: String? = nil,
        @ViewBuilder content: @escaping @Sendable () -> Content
    ) {
        self.question = question
        self.answer = answer
        self.includeInJSONLD = includeInJSONLD
        self.id = id ?? UUID().uuidString
        self.content = AnyView(content())
    }
    
    /// Generates JSON-LD object for this FAQ item.
    /// Returns a Question schema object with acceptedAnswer.
    public var jsonLD: String {
        let escapedQuestion = escapeJSONString(question)
        let escapedAnswer = escapeJSONString(answer)
        
        return """
        {
          "@type": "Question",
          "name": "\(escapedQuestion)",
          "acceptedAnswer": {
            "@type": "Answer",
            "text": "\(escapedAnswer)"
          }
        }
        """
    }
    
    /// Escapes a string for safe inclusion in JSON.
    private func escapeJSONString(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(of: "\\", with: "\\\\")
        result = result.replacingOccurrences(of: "\"", with: "\\\"")
        result = result.replacingOccurrences(of: "\n", with: "\\n")
        result = result.replacingOccurrences(of: "\r", with: "\\r")
        result = result.replacingOccurrences(of: "\t", with: "\\t")
        return result
    }
}
