//
//  MarkdownRenderer.swift
//  21-DOT-DEV/MarkdownRenderer.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//

import Foundation
import Slipstream
@preconcurrency import Markdown
import DesignSystem

/// A component that renders markdown content with consistent styling matching the 21.dev design system
struct MarkdownRenderer: View {
    private let content: String
    
    init(_ content: String) {
        self.content = content
    }
    
    var body: some View {
        BlogContent {
            MarkdownText(content) { node, context in
                renderNode(node, context: context, isInline: false)
            }
        }
    }
    
    @ViewBuilder
    private func renderNode(_ node: Markup, context: MarkdownText, isInline: Bool) -> some View {
        switch node {
        case let text as Markdown.Text:
            if isInline {
                Typography.Text(text.string)  // No paragraph wrapping
            } else {
                Typography.TextParagraph(text.string)  // Block-level paragraphs with styling
            }
        case let heading as Markdown.Heading:
            Typography.Heading(level: heading.level, text: extractTextContent(from: heading))
        case let paragraph as Markdown.Paragraph:
            Typography.Paragraph {
                renderChildren(of: paragraph, context: context, isInline: true)
            }
        case let strong as Markdown.Strong:
            Typography.Strong {
                renderChildren(of: strong, context: context, isInline: true)
            }
        case let emphasis as Markdown.Emphasis:
            Typography.Emphasis {
                renderChildren(of: emphasis, context: context, isInline: true)
            }
        case let link as Markdown.Link:
            Typography.Link(URL(string: link.destination ?? "")) {
                renderChildren(of: link, context: context, isInline: true)
            }
        case let code as Markdown.InlineCode:
            Typography.InlineCode(code.code)
        case let list as Markdown.UnorderedList:
            Typography.List(ordered: false) {
                renderChildren(of: list, context: context, isInline: false)
            }
        case let list as Markdown.OrderedList:
            Typography.List(ordered: true) {
                renderChildren(of: list, context: context, isInline: false)
            }
        case let listItem as Markdown.ListItem:
            Typography.ListItem {
                renderChildren(of: listItem, context: context, isInline: false)
            }
        case let blockquote as Markdown.BlockQuote:
            // Check if this blockquote should be rendered as a callout
            if let calloutType = detectCalloutType(from: blockquote) {
                Callout(calloutType) {
                    AnyView(renderChildren(of: blockquote, context: context, isInline: true))
                }
            } else {
                Blockquote {
                    AnyView(renderChildren(of: blockquote, context: context, isInline: false))
                }
            }
        default:
            renderChildren(of: node, context: context, isInline: isInline)
        }
    }
    
    @ViewBuilder
    private func renderChildren(of node: Markup, context: MarkdownText, isInline: Bool) -> some View {
        ForEach(Array(node.children.enumerated()), id: \.offset) { _, child in
            AnyView(renderNode(child, context: context, isInline: isInline))
        }
    }
    
    /// Detects if a blockquote should be rendered as a callout based on its content
    private func detectCalloutType(from blockquote: Markdown.BlockQuote) -> Callout<AnyView>.CalloutType? {
        // Look for callout patterns like "**Note:**", "**Tip:**", etc.
        let textContent = extractTextContent(from: blockquote).lowercased()
        
        if textContent.contains("**note:") || textContent.contains("note:") {
            return .note
        } else if textContent.contains("**tip:") || textContent.contains("tip:") {
            return .tip
        } else if textContent.contains("**warning:") || textContent.contains("warning:") {
            return .warning
        } else if textContent.contains("**get started:") || textContent.contains("get started:") || textContent.contains("**info:") || textContent.contains("info:") {
            return .info
        }
        
        return nil
    }
    
    /// Extracts plain text content from a markdown node for headings
    private func extractTextContent(from node: Markup) -> String {
        if let text = node as? Markdown.Text {
            return text.string
        }
        
        return node.children.compactMap { child in
            extractTextContent(from: child)
        }.joined()
    }
}
