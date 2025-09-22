//
//  Typography+Strong.swift
//  21-DOT-DEV/Typography+Strong.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Slipstream

/// Typography foundation for strong/bold text content.
extension Typography {
    /// Strong emphasis component for bold text.
    public struct Strong<Content: View>: View {
        private let content: Content
        
        /// Creates strong/bold text content.
        /// - Parameter content: The content to emphasize
        public init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        public var body: some View {
            Slipstream.Strong {
                content
            }
            .fontWeight(.semibold)
            .textColor(.palette(.gray, darkness: 900))
        }
    }
}
