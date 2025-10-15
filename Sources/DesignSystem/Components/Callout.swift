//
//  Callout.swift
//  21-DOT-DEV/Callout.swift
//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Slipstream

/// Callout box component for highlighting important information.
/// Supports different visual styles for various types of notifications.
public struct Callout<Content: View>: View {
    public enum CalloutType: Sendable {
        case note
        case tip 
        case warning
        case info
        
        var backgroundColor: String {
            switch self {
            case .note: return "bg-blue-50"
            case .tip: return "bg-green-50"
            case .warning: return "bg-yellow-50"
            case .info: return "bg-orange-50"
            }
        }
        
        var borderColor: String {
            switch self {
            case .note: return "border-blue-500"
            case .tip: return "border-green-500"
            case .warning: return "border-yellow-500"
            case .info: return "border-orange-500"
            }
        }
        
        var textColor: String {
            switch self {
            case .note: return "text-blue-800"
            case .tip: return "text-green-800"
            case .warning: return "text-yellow-800"
            case .info: return "text-orange-800"
            }
        }
    }
    
    public let type: CalloutType
    public let content: Content
    
    /// Creates a callout with specified type and content.
    /// - Parameters:
    ///   - type: The callout type (note, tip, warning, info)
    ///   - content: The callout content
    public init(_ type: CalloutType, @ViewBuilder content: () -> Content) {
        self.type = type
        self.content = content()
    }
    
    public var body: some View {
        Div {
            content
        }
        .modifier(ClassModifier(add: "\(type.backgroundColor) border-l-4 \(type.borderColor) p-4 mb-8"))
        .modifier(ClassModifier(add: "[&_p]:!\(type.textColor) [&_p]:!text-base [&_p]:!mb-0 [&_p]:!leading-normal [&_strong]:!\(type.textColor) [&_a]:!text-orange-600 [&_a]:hover:!text-orange-700 [&_a]:!underline"))
    }
}
