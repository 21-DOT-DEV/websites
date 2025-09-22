//
//  Typography+Paragraph.swift
//  21-DOT-DEV/Typography+Paragraph.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Slipstream

/// Typography foundation for paragraph content.
extension Typography {
    /// Block-level paragraph component with consistent blog styling.
    public struct Paragraph<Content: View>: View {
        private let content: Content
        
        /// Creates a paragraph with custom content.
        /// - Parameter content: The paragraph content
        public init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        public var body: some View {
            Slipstream.Paragraph {
                content
            }
            .fontSize(.large)
            .textColor(.palette(.gray, darkness: 700))
            .margin(.bottom, 16)
            .modifier(ClassModifier(add: "leading-7"))
        }
    }
    
    /// Simple paragraph for plain text content.
    public struct TextParagraph: View {
        private let text: String
        
        /// Creates a paragraph with plain text.
        /// - Parameter text: The paragraph text
        public init(_ text: String) {
            self.text = text
        }
        
        public var body: some View {
            Paragraph {
                Typography.Text(text)
            }
        }
    }
}
