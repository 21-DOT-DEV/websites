//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// Represents a footer navigation link.
public struct FooterLink: Sendable {
    public let text: String
    public let href: String
    public let isExternal: Bool
    
    public init(text: String, href: String, isExternal: Bool = false) {
        self.text = text
        self.href = href
        self.isExternal = isExternal
    }
}

/// Represents a social media link with direct icon component.
public struct SocialLink: Sendable {
    public let url: String
    public let ariaLabel: String
    public let icon: AnyView
    
    /// Creates a social link with a direct icon component
    public init<Icon: View>(url: String, ariaLabel: String, icon: Icon) {
        self.url = url
        self.ariaLabel = ariaLabel
        self.icon = AnyView(icon)
    }
}
