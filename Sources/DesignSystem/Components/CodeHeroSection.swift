//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Represents the type of code block to display in the hero section.
public enum CodeBlockType: Sendable {
    /// Simple code block with an array of code lines
    case simple([CodeLine])
    /// Tabbed code block component
    case tabbed(TabbedCodeBlock)
}

/// A hero section component featuring a 2-column grid layout with product information and code sample.
/// 
/// Designed for product pages where showcasing code usage is important. The left column contains
/// product details and call-to-action, while the right column displays a syntax-highlighted code example.
/// The layout is responsive, stacking vertically on mobile and displaying side-by-side on larger screens.
/// 
/// ## Features
/// - Responsive 2-column grid layout
/// - Icon + title combination support
/// - Sponsor attribution support
/// - Syntax-highlighted code block (simple or tabbed)
/// - Customizable CTA button
/// 
/// ## Usage
/// ```swift
/// // Simple code block
/// CodeHeroSection(
///     icon: "🔐",
///     title: "P256K",
///     headline: "Enhance Your Swift Development for Bitcoin Apps",
///     description: "Seamlessly integrate, test, and utilize secp256k1...",
///     sponsorText: "Proudly sponsored by Geyser",
///     ctaButton: CTAButton(text: "Get Started", href: "https://docs.21.dev/", style: .primary, isExternal: true),
///     codeBlock: .simple([
///         CodeLine(text: "// Swift Package", style: .comment),
///         CodeLine(text: "import ", style: .keyword, highlights: [CodeHighlight(text: "P256K", style: .type)])
///     ])
/// )
/// 
/// // Tabbed code block
/// CodeHeroSection(
///     icon: "🔐",
///     title: "P256K",
///     headline: "Enhance Your Swift Development for Bitcoin Apps",
///     description: "Seamlessly integrate, test, and utilize secp256k1...",
///     sponsorText: "Proudly sponsored by Geyser",
///     ctaButton: CTAButton(text: "Get Started", href: "https://docs.21.dev/", style: .primary, isExternal: true),
///     codeBlock: .tabbed(TabbedCodeBlock(tabs: [
///         CodeTab(title: "ECDSA", codeLines: [...]),
///         CodeTab(title: "Schnorr", codeLines: [...])
///     ]))
/// )
/// ```
public struct CodeHeroSection: View {
    /// Optional icon to display next to the title
    public let icon: String?
    /// The product/section title
    public let title: String
    /// Main headline text
    public let headline: String
    /// Description content (as a View)
    private let descriptionView: AnyView
    /// Optional sponsor attribution text
    public let sponsorText: String?
    /// Optional sponsor logo components
    public let sponsorLogos: [SponsorLogo]
    /// Call-to-action button
    public let ctaButton: CTAButton
    /// Type of code block to display (simple or tabbed)
    public let codeBlock: CodeBlockType
    /// Stored tabs for CSS generation (nil for simple code blocks)
    public let tabs: Tabs?
    
    // Generate tabs for tabbed code blocks - uses actual tab data
    private static func buildTabs(from tabbedBlock: TabbedCodeBlock) -> Tabs {
        return Tabs(id: "code-hero", tabs: tabbedBlock.tabs.map { tab in
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
                            .modifier(ClassModifier(add: "hover:bg-gray-200 hover:text-gray-700 transition-colors rounded-md flex-shrink-0"))
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
    
    /// Creates a new CodeHeroSection with a plain text description.
    ///
    /// - Parameters:
    ///   - icon: Optional icon to display next to title
    ///   - title: Main title text
    ///   - headline: Hero headline text
    ///   - description: Plain text description below headline
    ///   - sponsorText: Optional sponsor attribution text
    ///   - sponsorLogos: Array of sponsor logo views
    ///   - ctaButton: Call-to-action button configuration
    ///   - codeBlock: Type of code block to display (simple or tabbed)
    public init(
        icon: String? = nil,
        title: String,
        headline: String,
        description: String,
        sponsorText: String? = nil,
        sponsorLogos: [SponsorLogo] = [],
        ctaButton: CTAButton,
        codeBlock: CodeBlockType
    ) {
        self.icon = icon
        self.title = title
        self.headline = headline
        self.descriptionView = AnyView(Paragraph(description))
        self.sponsorText = sponsorText
        self.sponsorLogos = sponsorLogos
        self.ctaButton = ctaButton
        self.codeBlock = codeBlock
        
        // Generate tabs for tabbed code blocks, nil for simple blocks
        switch codeBlock {
        case .tabbed(let tabbedBlock):
            self.tabs = Self.buildTabs(from: tabbedBlock)
        case .simple:
            self.tabs = nil
        }
    }
    
    /// Creates a new CodeHeroSection with a rich view-based description.
    ///
    /// - Parameters:
    ///   - icon: Optional icon to display next to title
    ///   - title: Main title text
    ///   - headline: Hero headline text
    ///   - description: ViewBuilder closure for rich description content (supports links, formatting, etc.)
    ///   - sponsorText: Optional sponsor attribution text
    ///   - sponsorLogos: Array of sponsor logo views
    ///   - ctaButton: Call-to-action button configuration
    ///   - codeBlock: Type of code block to display (simple or tabbed)
    public init(
        icon: String? = nil,
        title: String,
        headline: String,
        @ViewBuilder description: () -> some View,
        sponsorText: String? = nil,
        sponsorLogos: [SponsorLogo] = [],
        ctaButton: CTAButton,
        codeBlock: CodeBlockType
    ) {
        self.icon = icon
        self.title = title
        self.headline = headline
        // Capture the view result before wrapping to avoid Sendable issues
        let descriptionContent = description()
        self.descriptionView = AnyView(Paragraph { descriptionContent })
        self.sponsorText = sponsorText
        self.sponsorLogos = sponsorLogos
        self.ctaButton = ctaButton
        self.codeBlock = codeBlock
        
        // Generate tabs for tabbed code blocks, nil for simple blocks
        switch codeBlock {
        case .tabbed(let tabbedBlock):
            self.tabs = Self.buildTabs(from: tabbedBlock)
        case .simple:
            self.tabs = nil
        }
    }
    
    /// Convenience initializer for simple code blocks with plain text description.
    public init(
        icon: String? = nil,
        title: String,
        headline: String,
        description: String,
        sponsorText: String? = nil,
        sponsorLogos: [SponsorLogo] = [],
        ctaButton: CTAButton,
        codeLines: [CodeLine]
    ) {
        self.init(
            icon: icon,
            title: title,
            headline: headline,
            description: description,
            sponsorText: sponsorText,
            sponsorLogos: sponsorLogos,
            ctaButton: ctaButton,
            codeBlock: .simple(codeLines)
        )
    }
    
    /// Convenience initializer for simple code blocks with rich view-based description.
    public init(
        icon: String? = nil,
        title: String,
        headline: String,
        @ViewBuilder description: () -> some View,
        sponsorText: String? = nil,
        sponsorLogos: [SponsorLogo] = [],
        ctaButton: CTAButton,
        codeLines: [CodeLine]
    ) {
        self.init(
            icon: icon,
            title: title,
            headline: headline,
            description: description,
            sponsorText: sponsorText,
            sponsorLogos: sponsorLogos,
            ctaButton: ctaButton,
            codeBlock: .simple(codeLines)
        )
    }
    
    public var body: some View {
        Section {
            Div {
                // 2-column grid container
                Div {
                    // Left column - Product information
                    Div {
                        // Icon + Title row
                        Div {
                            if let icon = icon {
                                Span(icon)
                                    .fontSize(.extraExtraLarge) // text-2xl
                                    .margin(.right, 8) // mr-2
                            }
                            
                            H1(title)
                                .fontSize(.fourXLarge) // text-4xl
                                .fontWeight(.bold)
                                .textColor(.palette(.gray, darkness: 900))
                        }
                        .display(.flex)
                        .alignItems(.center)
                        .margin(.bottom, 16) // mb-4
                        
                        // Main headline
                        H2(headline)
                            .fontSize(.extraExtraExtraLarge) // text-3xl
                            .fontWeight(.bold)
                            .textColor(.palette(.gray, darkness: 900))
                            .margin(.bottom, 24) // mb-6
                        
                        // Description
                        descriptionView
                            .fontSize(.extraLarge) // text-xl
                            .textColor(.palette(.gray, darkness: 600))
                            .margin(.bottom, 24) // mb-6
                        
                        // Optional sponsor text and/or logos
                        if let sponsor = sponsorText, !sponsorLogos.isEmpty {
                            // Show both text and logos together
                            Div {
                                Text(sponsor)
                                    .textColor(.palette(.gray, darkness: 600))
                                    .margin(.right, 8) // mr-2
                                
                                // Display sponsor logos
                                Div {
                                    ForEach(sponsorLogos.indices, id: \.self) { index in
                                        Div {
                                            sponsorLogos[index].logoView()
                                        }
                                        .margin(.right, 8) // mr-2
                                    }
                                }
                                .display(.flex)
                                .alignItems(.center)
                            }
                            .display(.flex)
                            .alignItems(.center)
                            .margin(.bottom, 32) // mb-8
                        } else if !sponsorLogos.isEmpty {
                            // Show just logos
                            Div {
                                ForEach(sponsorLogos.indices, id: \.self) { index in
                                    Div {
                                        sponsorLogos[index].logoView()
                                    }
                                    .margin(.right, 8) // mr-2
                                }
                            }
                            .display(.flex)
                            .alignItems(.center)
                            .margin(.bottom, 32) // mb-8
                        } else if let sponsor = sponsorText {
                            // Show just text
                            Paragraph {
                                Text(sponsor.replacingOccurrences(of: " by ", with: " by "))
                                    .textColor(.palette(.gray, darkness: 600))
                                if sponsor.contains(" by ") {
                                    let parts = sponsor.components(separatedBy: " by ")
                                    if parts.count == 2 {
                                        Strong(parts[1])
                                    }
                                }
                            }
                            .textColor(.palette(.gray, darkness: 600))
                            .margin(.bottom, 32) // mb-8
                        }
                        
                        // CTA Button
                        CTAButtonView(button: ctaButton)
                    }
                    
                    // Right column - Code block
                    switch codeBlock {
                    case .simple(let lines):
                        CodeBlockDisplay(lines: lines)
                    case .tabbed:
                        // Use stored tabs with wrapper for styling consistency
                        if let tabs = tabs {
                            Div {
                                tabs
                            }
                            .modifier(ClassModifier(add: "w-full border-white/10 lg:border lg:p-10 lg:rounded-3xl"))
                        }
                    }
                }
                // TODO: Missing Slipstream Grid API - using ClassModifier
                .modifier(ClassModifier(add: "grid grid-cols-1 lg:grid-cols-2 gap-12 items-center"))
            }
            .frame(maxWidth: .sixXLarge) // max-w-6xl
            .margin(.horizontal, .auto) // mx-auto
            .padding(.horizontal, 16) // px-4
            .padding(.horizontal, 24, condition: .startingAt(.small)) // sm:px-6
            .padding(.horizontal, 32, condition: .startingAt(.large)) // lg:px-8
        }
        .padding(.vertical, 80) // py-20
    }
}

/// A code block display component for syntax-highlighted code samples.
/// 
/// Renders code lines with proper syntax highlighting in a dark theme container.
/// Supports different text styles for comments, keywords, types, variables, etc.
private struct CodeBlockDisplay: View {
    let lines: [CodeLine]
    
    init(lines: [CodeLine]) {
        self.lines = lines
    }
    
    var body: some View {
        Div {
            // Render each code line
            ForEach(lines, id: \.text) { line in
                CodeLineView(line: line)
            }
        }
        .background(.palette(.gray, darkness: 900)) // bg-gray-900
        .padding(.all, 24) // p-6
        .fontSize(.small) // text-sm
        .fontDesign(.monospaced) // font-mono
        .textColor(.palette(.green, darkness: 400)) // text-green-400 (default)
        // TODO: Missing Slipstream APIs - using ClassModifier for:
        // - rounded-lg
        // - overflow-x-auto
        .modifier(ClassModifier(add: "rounded-lg overflow-x-auto"))
    }
}

/// A single line of code with syntax highlighting.
/// 
/// Supports different text styles and inline highlights for syntax elements.
public struct CodeLineView: View {
    public let line: CodeLine
    
    public init(line: CodeLine) {
        self.line = line
    }
    
    public var body: some View {
        if line.text.isEmpty {
            // Empty lines render as simple line breaks using Slipstream Linebreak API
            Linebreak()
        } else {
            // Each code line is a paragraph element (following working example pattern)
            Paragraph {
                if line.highlights.isEmpty {
                    // Simple line without highlights using Slipstream Span API
                    Span(line.text)
                        .modifier(ClassModifier(add: line.style.cssClass))
                } else {
                    // Line with syntax highlighting using span elements
                    SyntaxHighlightedText(text: line.text, highlights: line.highlights, baseStyle: line.style)
                }
            }
            .margin(.all, 0) // Remove default paragraph margins
        }
    }
}

/// A text component that renders syntax highlighting for code.
/// 
/// Processes a text string and applies different color styles to highlighted portions.
private struct SyntaxHighlightedText: View {
    let text: String
    let highlights: [CodeHighlight]
    let baseStyle: CodeLineStyle
    
    init(text: String, highlights: [CodeHighlight], baseStyle: CodeLineStyle) {
        self.text = text
        self.highlights = highlights
        self.baseStyle = baseStyle
    }
    
    var body: some View {
        // Build HTML with span elements for syntax highlighting
        buildHighlightedHTML()
    }
    
    private func buildHighlightedHTML() -> some View {
        var html = ""
        var currentIndex = text.startIndex
        
        // Sort highlights by position to process them in order
        let sortedHighlights = highlights.sorted { text.range(of: $0.text)?.lowerBound ?? text.endIndex < text.range(of: $1.text)?.lowerBound ?? text.endIndex }
        
        for highlight in sortedHighlights {
            if let range = text.range(of: highlight.text, range: currentIndex..<text.endIndex) {
                // Add text before highlight with base style
                if currentIndex < range.lowerBound {
                    let beforeText = String(text[currentIndex..<range.lowerBound])
                    if !beforeText.isEmpty {
                        html += "<span class=\"\(baseStyle.cssClass)\">\(beforeText)</span>"
                    }
                }
                
                // Add highlighted text
                html += "<span class=\"\(highlight.style.cssClass)\">\(highlight.text)</span>"
                currentIndex = range.upperBound
            }
        }
        
        // Add remaining text with base style
        if currentIndex < text.endIndex {
            let remainingText = String(text[currentIndex..<text.endIndex])
            if !remainingText.isEmpty {
                html += "<span class=\"\(baseStyle.cssClass)\">\(remainingText)</span>"
            }
        }
        
        return RawHTML(html)
    }
}
