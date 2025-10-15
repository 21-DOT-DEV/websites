//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// A single line of code with optional syntax highlighting.
/// 
/// Represents a line of code that can be displayed in a code block with
/// appropriate syntax highlighting and styling.
public struct CodeLine: Sendable {
    /// The text content of the code line
    public let text: String
    /// The base style for the line (comment, keyword, etc.)
    public let style: CodeLineStyle
    /// Optional inline highlights for specific parts of the text
    public let highlights: [CodeHighlight]
    
    /// Creates a code line with text and styling.
    /// - Parameters:
    ///   - text: The text content of the code line
    ///   - style: The base style for the line (defaults to .normal)
    ///   - highlights: Optional inline highlights for specific parts of the text
    public init(text: String, style: CodeLineStyle = .normal, highlights: [CodeHighlight] = []) {
        self.text = text
        self.style = style
        self.highlights = highlights
    }
}

/// Styles for different types of code lines.
/// 
/// Provides semantic styling for various code elements like comments,
/// keywords, strings, etc. Each style maps to appropriate CSS classes.
public enum CodeLineStyle: Sendable {
    case normal     // Default white text
    case comment    // Gray text for comments
    case keyword    // Blue text for language keywords
    case string     // Green text for string literals
    case number     // Orange text for numbers
    
    /// CSS class for the code line style
    public var cssClass: String {
        switch self {
        case .normal:
            return "text-white"
        case .comment:
            return "text-gray-500"
        case .keyword:
            return "text-blue-400"
        case .string:
            return "text-green-400"
        case .number:
            return "text-orange-400"
        }
    }
}

/// A highlighted portion within a code line.
/// 
/// Represents a specific part of a code line that should be styled differently,
/// such as variable names, function names, or type names.
public struct CodeHighlight: Sendable {
    /// The text to highlight
    public let text: String
    /// The style to apply to the highlighted text
    public let style: CodeHighlightStyle
    
    /// Creates a code highlight with text and style.
    /// - Parameters:
    ///   - text: The text to highlight
    ///   - style: The style to apply to the highlighted text
    public init(text: String, style: CodeHighlightStyle) {
        self.text = text
        self.style = style
    }
}

/// Styles for highlighted portions of code.
/// 
/// Provides semantic styling for specific code elements that need
/// to stand out within a line, such as types, variables, functions.
public enum CodeHighlightStyle: Sendable {
    case type       // Light purple for type names like Signing.PrivateKey() (matches Xcode)
    case function   // Darker purple text for function names (matches Xcode)
    case property   // Darker purple text for property names (matches Xcode)
    case keyword    // Purple/magenta text for keywords like let, import (matches Xcode)
    case string     // Red text for string literals (matches Xcode)
    
    /// CSS class for the highlight style
    public var cssClass: String {
        switch self {
        case .type:
            return "text-[#D0A8FF]"  // Light purple "Other Type Names" for types like Signing.PrivateKey()
        case .function, .property:
            return "text-[#A167E6]"  // Dark purple "Other Function and Method Names"
        case .keyword:
            return "text-[#FF7AB2]"  // Magenta for keywords (let, import, etc.)
        case .string:
            return "text-[#FF8170]"  // Red for string literals
        }
    }
}
