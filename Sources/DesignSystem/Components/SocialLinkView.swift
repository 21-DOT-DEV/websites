//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A social media link view component that handles different rendering modes.
/// Supports SVG icons, text-based links, and custom SVG content.
public struct SocialLinkView: View {
    let socialLink: SocialLink
    
    public init(socialLink: SocialLink) {
        self.socialLink = socialLink
    }
    
    public var body: some View {
        Link(URL(string: socialLink.url), openInNewTab: true) {
            linkContent
        }
        .modifier(ClassModifier(add: commonStyling))
        .accessibilityLabel(socialLink.ariaLabel)
    }
    
    @ViewBuilder
    private var linkContent: some View {
        let platform = socialLink.platform
        if let displayText = platform.displayText {
            // Text-based social link (e.g., "nostr")
            Text(displayText)
                .modifier(ClassModifier(add: "font-mono text-sm"))
        } else if !platform.svgPath.isEmpty {
            // SVG-based social link using Slipstream SVG API
            SVG(viewBox: "0 0 24 24") {
                SVGPath(platform.svgPath)
            }
            .className("h-6 w-6 fill-current")
        }
    }
    
    private var commonStyling: Set<String> {
        ["text-gray-400", "hover:text-white", "transition-colors", "mb-3", "block"]
    }
}
