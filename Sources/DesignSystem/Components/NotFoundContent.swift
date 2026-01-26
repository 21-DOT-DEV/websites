//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A reusable 404 not found content component.
/// Displays a centered error message with configurable headline, description, and navigation links.
/// Designed to work within the site's existing layout (header/footer).
///
/// Example usage:
/// ```swift
/// NotFoundContent(
///     headline: "404: Page not found",
///     description: "This URL doesn't match any content on our site.",
///     navigationLinks: [
///         NavigationLink(title: "Homepage", href: "/"),
///         NavigationLink(title: "Blog", href: "/blog/")
///     ]
/// )
/// ```
public struct NotFoundContent: View {
    public let headline: String
    public let description: String
    public let navigationLinks: [NavigationLink]
    
    /// Creates a not found content section.
    /// - Parameters:
    ///   - headline: The main headline (e.g., "404: Page not found")
    ///   - description: A brief description of the error
    ///   - navigationLinks: Links to help users navigate back to valid pages
    public init(
        headline: String = "404: Page not found",
        description: String = "This URL doesn't match any content on our site.",
        navigationLinks: [NavigationLink] = []
    ) {
        self.headline = headline
        self.description = description
        self.navigationLinks = navigationLinks
    }
    
    public var body: some View {
        Div {
            Div {
                VStack(alignment: .center, spacing: 32) {
                    // Error headline
                    H1 {
                        Text(headline)
                    }
                    .fontSize(.extraExtraExtraLarge)
                    .fontSize(.fourXLarge, condition: Condition(startingAt: .medium))
                    .fontWeight(.bold)
                    .textColor(.palette(.gray, darkness: 900))
                    .textAlignment(.center)
                    
                    // Description
                    Paragraph {
                        Text(description)
                    }
                    .fontSize(.large)
                    .fontSize(.extraLarge, condition: Condition(startingAt: .medium))
                    .textColor(.palette(.gray, darkness: 600))
                    .textAlignment(.center)
                    
                    // Navigation links
                    if !navigationLinks.isEmpty {
                        Div {
                            ForEach(navigationLinks, id: \.href) { link in
                                Link(link.title, destination: URL(string: link.href))
                                    .textColor(.palette(.orange, darkness: 600))
                                    .textColor(.palette(.orange, darkness: 700), condition: .hover)
                                    .fontWeight(.medium)
                                    .textDecoration(.underline, condition: .hover)
                            }
                        }
                        .display(.flex)
                        .flexDirection(.y)
                        .flexDirection(.x, condition: Condition(startingAt: .small))
                        .flexGap(.x, width: 24)
                        .flexGap(.y, width: 12)
                        .justifyContent(.center)
                        .alignItems(.center)
                    }
                }
            }
            .textAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 64)
            .frame(width: .full)
            .display(.flex)
            .flexDirection(.y)
            .alignItems(.center)
            .justifyContent(.center)
            .modifier(ClassModifier(add: "min-h-[60vh]"))
        }
        .background(.palette(.gray, darkness: 50))
        .frame(width: .full)
    }
}
