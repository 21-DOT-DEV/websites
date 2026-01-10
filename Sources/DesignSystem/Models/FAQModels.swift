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
import SwiftSoup

/// Represents an FAQ item with both visual content and JSON-LD structured data.
/// The answer for JSON-LD is automatically derived from the visual content.
public struct FAQItem: Sendable, Identifiable {
    /// Unique identifier for the FAQ item
    public let id: String
    /// The question text
    public let question: String
    /// Whether to include this item in JSON-LD structured data
    public let includeInJSONLD: Bool
    /// The visual content to render for the answer
    public let content: AnyView
    
    /// The answer as plain text for JSON-LD structured data.
    /// Automatically derived from the visual content by rendering to HTML and extracting text.
    public var answer: String {
        guard let html = try? renderHTML(content),
              let doc = try? SwiftSoup.parse(html),
              let text = try? doc.text() else {
            return ""
        }
        return text
    }
    
    /// Creates an FAQ item with question and visual content.
    /// The answer for JSON-LD is automatically derived from the content.
    /// - Parameters:
    ///   - question: The question text
    ///   - includeInJSONLD: Whether to include this item in JSON-LD (default false for SEO safety)
    ///   - id: Optional custom identifier (auto-generated if not provided)
    ///   - content: The visual content to render (also used to derive JSON-LD answer)
    public init<Content: View>(
        question: String,
        includeInJSONLD: Bool = false,
        id: String? = nil,
        @ViewBuilder content: @escaping @Sendable () -> Content
    ) {
        self.question = question
        self.includeInJSONLD = includeInJSONLD
        self.id = id ?? UUID().uuidString
        self.content = AnyView(content())
    }
}
