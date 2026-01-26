//
//  Typography+Link.swift
//  21-DOT-DEV/Typography+Link.swift
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Typography foundation for link content.
extension Typography {
    /// Link component for clickable text content.
    public struct Link<Content: View>: View {
        private let url: URL?
        private let content: Content
        
        /// Creates a link with custom content.
        /// - Parameters:
        ///   - url: The URL to link to (optional)
        ///   - content: The link content
        public init(_ url: URL?, @ViewBuilder content: () -> Content) {
            self.url = url
            self.content = content()
        }
        
        public var body: some View {
            if let url = url {
                Slipstream.Link(url) {
                    content
                }
                .textColor(.palette(.blue, darkness: 600))
                .textDecoration(.underline)
                .modifier(ClassModifier(add: "hover:text-blue-800"))
            } else {
                Span {
                    content
                }
                .textColor(.palette(.blue, darkness: 600))
            }
        }
    }
}
