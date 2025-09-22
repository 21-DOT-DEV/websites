//
//  Typography+InlineCode.swift
//  21-DOT-DEV/Typography+InlineCode.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Slipstream

/// Typography foundation for inline code content.
extension Typography {
    /// Inline code component for code snippets within text.
    public struct InlineCode: View {
        private let code: String
        
        /// Creates inline code content.
        /// - Parameter code: The code content to display
        public init(_ code: String) {
            self.code = code
        }
        
        public var body: some View {
            Code(code)
                .modifier(ClassModifier(add: "font-mono text-sm text-gray-800 bg-gray-100 px-1 py-0.5 rounded"))
        }
    }
}
