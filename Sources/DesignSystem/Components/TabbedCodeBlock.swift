//
//  TabbedCodeBlock.swift
//  DesignSystem
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A view component that displays multiple code blocks in tabbed interface.
///
/// This component creates an interactive tabbed interface where users can switch between
/// different code examples. Each tab contains a separate code block with syntax highlighting.
public struct TabbedCodeBlock: View {
    /// The tabs to display
    public let tabs: [CodeTab]
    
    /// Creates a new TabbedCodeBlock.
    ///
    /// - Parameter tabs: An array of CodeTab objects representing each tab
    public init(tabs: [CodeTab]) {
        self.tabs = tabs
    }
    
    public var body: some View {
        Div {
            Tabs(id: "code-hero", tabs: tabs.map { tab in
                Tab(tab.title) {
                    Section {
                        Div {
                            // Code content with copy button
                            Div {
                                Preformatted {
                                    Code {
                                        ForEach(tab.codeLines, id: \.text) { line in
                                            CodeLineView(line: line)
                                        }
                                    }
                                }
                                .modifier(ClassModifier(add: "flex-1"))
                                
                                // Copy button for the tab
                                Button(
                                    action: "navigator.clipboard.writeText(`\(tab.codeLines.map(\.text).joined(separator: "\\n"))`)"
                                ) {
                                    CopyIcon()
                                }
                                .padding(.all, 8)
                                .background(.palette(.gray, darkness: 100))
                                .textColor(.palette(.gray, darkness: 500))
                                .background(.palette(.gray, darkness: 200), condition: .hover)
                                .textColor(.palette(.gray, darkness: 700), condition: .hover)
                                .transition(.colors)
                                .cornerRadius(.medium)
                                .modifier(ClassModifier(add: "flex-shrink-0"))
                            }
                            .display(.flex)
                            .alignItems(.start)
                            .modifier(ClassModifier(add: "gap-4"))
                        }
                        .modifier(ClassModifier(add: "mt-4 bg-[#1c1e28] font-mono h-full overflow-hidden p-4 text-xs rounded-2xl shadow-3xl"))
                    }
                }
            })
        }
        .modifier(ClassModifier(add: "w-full border-white/10 lg:border lg:p-10 lg:rounded-3xl"))
    }
}
