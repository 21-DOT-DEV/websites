//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Renders installation options in a tabbed interface.
/// 
/// Designed for displaying multiple package manager installation options in a clean,
/// tabbed interface. Each tab shows a different installation method (Swift PM, CocoaPods, etc.)
/// with syntax-highlighted code snippets.
/// 
/// ## Features
/// - CSS-only radio button tabs
/// - Orange accent styling
/// - Generic installation options array
/// - Responsive layout
/// 
/// ## Usage
/// ```swift
/// SectionIntro(
///     badge: "Installation",
///     title: "Get Started", 
///     description: "Add P256K to your project using your preferred package manager."
/// ) {
///     InstallationSection(options: [
///         InstallationOption(
///             title: "Swift Package Manager",
///             codeSnippet: ".package(url: \"https://github.com/21-DOT-DEV/swift-secp256k1\", exact: \"0.21.1\")",
///             language: "swift"
///         ),
///         InstallationOption(
///             title: "CocoaPods",
///             codeSnippet: "pod 'swift-secp256k1', '0.21.1'",
///             language: "ruby"
///         )
///     ])
/// }
/// ```
public struct InstallationSection: View {
    public let options: [InstallationOption]
    public let tabs: Tabs
    
    // Generate tabs for rendering - uses actual options data
    private static func buildTabs(from options: [InstallationOption]) -> Tabs {
        return Tabs(id: "install", tabs: options.map { option in
            Tab(option.title) {
                // Code snippet container with copy button
                Div {
                    Code(option.codeSnippet)
                        .textColor(.palette(.gray, darkness: 900))
                        .fontDesign(.monospaced)
                        .modifier(ClassModifier(add: "flex-1"))
                    
                    // Copy button with proper styling
                    Button(
                        action: "navigator.clipboard.writeText(`\(option.codeSnippet)`)"
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
                .alignItems(.center)
                .modifier(ClassModifier(add: "gap-4"))
                .background(.palette(.gray, darkness: 50))
                .padding(.all, 16)
                .fontSize(.small)
                .modifier(ClassModifier(add: "rounded-lg border border-gray-200 relative"))
                
                // Optional instructions
                if let instructions = option.instructions {
                    Paragraph(instructions)
                        .textColor(.palette(.gray, darkness: 600))
                        .fontSize(.small)
                        .margin(.top, 12)
                }
            }
        })
    }
    
    /// Creates a new InstallationSection.
    ///
    /// - Parameters:
    ///   - options: Array of installation options to display
    public init(options: [InstallationOption]) {
        self.options = options
        self.tabs = Self.buildTabs(from: options)
    }
    
    public var body: some View {
        // Installation tabs only - intro content handled by SectionIntro wrapper
        if !options.isEmpty {
            tabs
        }
    }
}
