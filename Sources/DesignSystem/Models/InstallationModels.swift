//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Represents an installation option for a package manager
public struct InstallationOption: Sendable {
    /// The title/name of the package manager (e.g., "Swift Package Manager", "CocoaPods")
    public let title: String
    
    /// The code snippet to be displayed
    public let codeSnippet: String
    
    /// Optional language identifier for syntax highlighting
    public let language: String?
    
    /// Optional instruction text that appears below the code snippet
    public let instructions: String?
    
    /// Creates a new installation option
    /// - Parameters:
    ///   - title: The display name of the package manager
    ///   - codeSnippet: The code to be copied/displayed
    ///   - language: Optional language for syntax highlighting (e.g., "swift", "ruby")
    ///   - instructions: Optional instruction text for this installation method
    public init(title: String, codeSnippet: String, language: String? = nil, instructions: String? = nil) {
        self.title = title
        self.codeSnippet = codeSnippet
        self.language = language
        self.instructions = instructions
    }
}
