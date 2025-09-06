//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Renders installation instructions with multiple package manager options in a tabbed interface.
/// 
/// Designed for displaying multiple package manager installation options in a clean,
/// tabbed interface. Each tab shows a different installation method (Swift PM, CocoaPods, etc.)
/// with syntax-highlighted code snippets.
/// 
/// ## Features
/// - SectionIntro-style badge
/// - CSS-only radio button tabs
/// - Orange accent styling
/// - Generic installation options array
/// - Responsive layout
/// 
/// ## Usage
/// ```swift
/// InstallationSection(
///     badge: "Installation",
///     title: "Get Started",
///     description: "Add P256K to your project using your preferred package manager.",
///     options: [
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
///     ]
/// )
/// ```
public struct InstallationSection: View, HasComponentCSS {
    public let badge: String
    public let title: String 
    public let description: String
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
                    .modifier(ClassModifier(add: "hover:bg-gray-200 hover:text-gray-700 transition-colors rounded-md flex-shrink-0"))
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
    
    // Instance-based CSS generation using actual tab configuration
    public var componentCSS: String {
        return tabs.componentCSS
    }
    
    public var componentName: String {
        return "InstallationSection"
    }
    
    /// Creates a new InstallationSection.
    ///
    /// - Parameters:
    ///   - badge: Badge text for the section
    ///   - title: Section title
    ///   - description: Description text
    ///   - options: Array of installation options to display
    public init(badge: String, title: String, description: String, options: [InstallationOption]) {
        self.badge = badge
        self.title = title
        self.description = description
        self.options = options
        self.tabs = Self.buildTabs(from: options)
    }
    
    public var body: some View {
        Section {
            Div {
                // Section intro with badge
                Div {
                    // Badge
                    Span {
                        Text(badge)
                    }
                    .modifier(ClassModifier(add: "text-transparent bg-clip-text font-medium tracking-widest bg-gradient-to-r from-orange-400 via-yellow-500 to-red-500 text-xs uppercase"))
                    .display(.inlineBlock)
                    
                    // Title
                    H2(title)
                        .fontSize(.extraExtraExtraLarge) // text-3xl
                        .fontWeight(.bold)
                        .textColor(.palette(.gray, darkness: 900))
                        .margin(.top, 32) // mt-8
                    
                    // Description
                    Paragraph(description)
                        .fontSize(.large) // text-lg
                        .textColor(.palette(.gray, darkness: 700))
                        .margin(.top, 16) // mt-4
                        .margin(.bottom, 32) // mb-8
                }
                .modifier(ClassModifier(add: "max-w-4xl")) // max-w-4xl
                .margin(.horizontal, .auto) // mx-auto
                
                // Installation tabs
                if !options.isEmpty {
                    tabs
                }
            }
            .modifier(ClassModifier(add: "max-w-4xl")) // max-w-4xl
            .margin(.horizontal, .auto) // mx-auto
            .padding(.horizontal, 16) // px-4
            .padding(.horizontal, 24, condition: .startingAt(.small)) // sm:px-6
        }
        .padding(.vertical, 64) // py-16
    }
}
