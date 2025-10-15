//
//  Typography+Heading.swift
//  21-DOT-DEV/Typography+Heading.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Slipstream

/// Typography foundation for heading content.
extension Typography {
    /// Heading component with consistent typography hierarchy.
    /// Provides different heading levels with appropriate styling for blog content.
    public struct Heading: View {
        private let text: String
        private let level: Int
        
        /// Creates a heading with the specified level and text.
        /// - Parameters:
        ///   - level: Heading level (1-6)
        ///   - text: The heading text
        public init(level: Int, text: String) {
            self.level = level
            self.text = text
        }
        
        public var body: some View {
            switch level {
            case 1:
                H1 {
                    Slipstream.Text(text)
                }
                .fontSize(.fourXLarge)
                .fontWeight(.bold)
                .textColor(.palette(.gray, darkness: 900))
                .margin(.bottom, 32)
            case 2:
                H2 {
                    Slipstream.Text(text)
                }
                .fontSize(.extraExtraLarge)
                .fontWeight(.bold)
                .textColor(.palette(.gray, darkness: 900))
                .margin(.top, 48)
                .margin(.bottom, 24)
            case 3:
                H3 {
                    Slipstream.Text(text)
                }
                .fontSize(.extraLarge)
                .fontWeight(.semibold)
                .textColor(.palette(.gray, darkness: 900))
                .margin(.top, 32)
                .margin(.bottom, 16)
            case 4:
                H4 {
                    Slipstream.Text(text)
                }
                .fontSize(.extraLarge)
                .fontWeight(.semibold)
                .textColor(.palette(.gray, darkness: 900))
                .margin(.top, 24)
                .margin(.bottom, 12)
            case 5:
                H5 {
                    Slipstream.Text(text)
                }
                .fontSize(.large)
                .fontWeight(.medium)
                .textColor(.palette(.gray, darkness: 900))
                .margin(.top, 20)
                .margin(.bottom, 8)
            default: // 6 or higher
                H6 {
                    Slipstream.Text(text)
                }
                .fontSize(.base)
                .fontWeight(.medium)
                .textColor(.palette(.gray, darkness: 900))
                .margin(.top, 16)
                .margin(.bottom, 8)
            }
        }
    }
}
