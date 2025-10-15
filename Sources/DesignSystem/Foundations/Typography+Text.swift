//
//  Typography+Text.swift
//  21-DOT-DEV/Typography+Text.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Slipstream

/// Typography foundation for inline text content.
extension Typography {
    /// Inline text component for spans and text nodes.
    public struct Text: View {
        private let content: String
        
        /// Creates inline text content.
        /// - Parameter content: The text content to display
        public init(_ content: String) {
            self.content = content
        }
        
        public var body: some View {
            DOMString(content)
        }
    }
}
