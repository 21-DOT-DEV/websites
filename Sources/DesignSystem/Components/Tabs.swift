//
//  Tabs.swift
//  DesignSystem
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A single tab item containing a title and content
public struct TabItem: Sendable {
    public let title: String
    public let content: AnyView
    
    public init<Content: View>(title: String, @ViewBuilder content: @escaping @Sendable () -> Content) {
        self.title = title
        self.content = AnyView(content())
    }
}

/// A generic tabbed interface component with CSS-only tab switching
///
/// Uses builder pattern for clean API:
/// ```swift
/// Tabs(id: "install") {
///     Tab("Swift Package Manager") {
///         Code("swift package add...")
///     }
///     Tab("CocoaPods") {
///         Code("pod install...")
///     }
/// }
/// ```
public struct Tabs: View, StyleModifier {
    
    /// Unique identifier for this tab group
    public let id: String
    /// Array of tab items
    public let tabs: [TabItem]
    
    /// Creates a new Tabs component
    /// - Parameters:
    ///   - id: Unique identifier for CSS targeting
    ///   - tabs: Array of TabItem instances
    public init(id: String, tabs: [TabItem]) {
        self.id = id
        self.tabs = tabs
    }
    
    /// Creates a new Tabs component using result builder
    /// - Parameters:
    ///   - id: Unique identifier for CSS targeting
    ///   - builder: ViewBuilder closure containing Tab items
    public init(id: String, @TabsBuilder builder: () -> [TabItem]) {
        self.id = id
        self.tabs = builder()
    }
    
    /// Generates CSS for this specific tab configuration
    public var css: String {
        return Self.generateCSS(id: id, numberOfTabs: tabs.count)
    }
    
    /// Instance-based CSS generation using actual tab configuration
    public var style: String {
        return Self.generateCSS(id: id, numberOfTabs: tabs.count)
    }
    
    /// Component name for CSS rendering
    public var componentName: String {
        return "Tabs[\(id)]"
    }
    
    /// Static method to generate CSS for tabs with specified configuration
    public static func generateCSS(id: String, numberOfTabs: Int) -> String {
        return """
        /* \(id) Tabs Component Styles */
        
        /* Hide all tab contents by default */
        .tab-content {
            display: none;
        }
        
        /* Show first tab content by default */
        #\(id)-content-0 {
            display: block;
        }
        
        /* Show content when corresponding radio is checked */
        \((0..<numberOfTabs).map { i in
            "#\(id)-tab-\(i):checked ~ div:nth-of-type(2) #\(id)-content-\(i) { display: block !important; }"
        }.joined(separator: "\n"))
        
        /* Hide other content when a radio is checked */
        \((0..<numberOfTabs).map { i in
            "#\(id)-tab-\(i):checked ~ div:nth-of-type(2) .tab-content:not(#\(id)-content-\(i)) { display: none; }"
        }.joined(separator: "\n"))
        
        /* Active tab styling - target labels in the tab buttons container */
        \((0..<numberOfTabs).map { i in
            "#\(id)-tab-\(i):checked ~ div:first-of-type label[for=\"\(id)-tab-\(i)\"] { color: #ea580c !important; border-bottom-color: #ea580c !important; }"
        }.joined(separator: "\n"))
        """
    }
    
    public var body: some View {
        Div {
            // Radio inputs (hidden)
            ForEach(tabs.indices, id: \.self) { index in
                let tabId = "\(id)-tab-\(index)"
                let isChecked = index == 0
                RadioButton(name: "\(id)-tabs", id: tabId, checked: isChecked)
                    .modifier(ClassModifier(add: "sr-only"))
            }
            
            // Tab buttons container
            Div {
                ForEach(tabs.indices, id: \.self) { index in
                    let tabId = "\(id)-tab-\(index)"
                    Label(tabs[index].title, for: tabId)
                        .modifier(ClassModifier(add: "cursor-pointer px-4 py-2 text-sm font-medium text-gray-600 border-b-2 border-transparent hover:text-orange-500 hover:border-orange-300 transition-colors"))
                }
            }
            .display(.flex)
            .modifier(ClassModifier(add: "border-b border-gray-200"))
            
            // Tab contents container
            Div {
                ForEach(tabs.indices, id: \.self) { index in
                    let contentId = "\(id)-content-\(index)"
                    Div {
                        tabs[index].content
                    }
                    .id(contentId)
                    .modifier(ClassModifier(add: "tab-content"))
                }
            }
            .margin(.top, 24) // mt-6
        }
    }
}

/// Result builder for creating Tab items
@resultBuilder
public struct TabsBuilder {
    public static func buildBlock(_ tabs: TabItem...) -> [TabItem] {
        Array(tabs)
    }
    
    public static func buildArray(_ components: [TabItem]) -> [TabItem] {
        components
    }
}

/// Creates a tab item
/// - Parameters:
///   - title: Tab button text
///   - content: Tab content view
/// - Returns: TabItem for use in Tabs component
public func Tab<Content: View>(_ title: String, @ViewBuilder content: @escaping @Sendable () -> Content) -> TabItem {
    TabItem(title: title, content: content)
}
