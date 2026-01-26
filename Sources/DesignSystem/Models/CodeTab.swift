//
//  CodeTab.swift
//  DesignSystem
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

/// Represents a single tab in a tabbed code block.
public struct CodeTab: Sendable {
    /// The title displayed on the tab
    public let title: String
    
    /// The code lines to display in this tab
    public let codeLines: [CodeLine]
    
    /// Creates a new code tab.
    ///
    /// - Parameters:
    ///   - title: The title displayed on the tab
    ///   - codeLines: The code lines to display in this tab
    public init(title: String, codeLines: [CodeLine]) {
        self.title = title
        self.codeLines = codeLines
    }
}
