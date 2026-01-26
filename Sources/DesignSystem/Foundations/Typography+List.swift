//
//  Typography+List.swift
//  21-DOT-DEV/Typography+List.swift
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Slipstream

/// Typography foundation for list content.
extension Typography {
    /// List component with consistent styling and spacing.
    /// Provides both ordered and unordered list support with blog-appropriate styling.
    public struct List<Content: View>: View {
        public let content: Content
        public let isOrdered: Bool
        
        /// Creates a list with consistent styling.
        /// - Parameters:
        ///   - ordered: Whether this is an ordered (numbered) list
        ///   - content: The list content
        public init(ordered: Bool = false, @ViewBuilder content: () -> Content) {
            self.isOrdered = ordered
            self.content = content()
        }
        
        public var body: some View {
            if isOrdered {
                Slipstream.List {
                    content
                }
                .modifier(ClassModifier(add: "list-decimal list-inside mb-6 pl-5"))
            } else {
                Slipstream.List {
                    content
                }
                .modifier(ClassModifier(add: "list-disc list-inside mb-6 pl-5"))
            }
        }
    }
    
    /// List item component with consistent styling.
    public struct ListItem<Content: View>: View {
        public let content: Content
        
        /// Creates a list item with consistent styling.
        /// - Parameters:
        ///   - content: The list item content
        public init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }
        
        public var body: some View {
            Slipstream.ListItem {
                content
            }
            .fontSize(.large)
            .textColor(.palette(.gray, darkness: 700))
            .margin(.bottom, 8)
            .modifier(ClassModifier(add: "leading-relaxed"))
        }
    }
}
