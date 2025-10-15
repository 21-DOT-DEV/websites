//
//  Typography+Emphasis.swift
//  21-DOT-DEV/Typography+Emphasis.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Slipstream

/// Typography foundation for emphasized/italic text content.
extension Typography {
    /// Emphasis component for italic text.
    public struct Emphasis<Content: View>: View {
        private let content: Content
        
        /// Creates emphasized/italic text content.
        /// - Parameter content: The content to emphasize
        public init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        public var body: some View {
            Span {
                content
            }
            .fontStyle(.italic)
            .textColor(.palette(.gray, darkness: 700))
        }
    }
}
