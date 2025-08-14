//
//  Copyright (c) 2025 21.dev
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Slipstream

/// A foundational page layout providing the HTML/Head/Body structure for sites.
/// Follows industry conventions for base page wrappers with sensible defaults.
/// Can be customized with different stylesheets and body content as needed.
public struct BasePage: View {
    let title: String
    let stylesheet: String
    let bodyContent: any View
    
    /// Creates a base page with the specified title and custom body content.
    /// - Parameters:
    ///   - title: The page title to display in the browser tab
    ///   - stylesheet: CSS file path (defaults to "static/style.output.css")
    ///   - bodyContent: The page body content
    public init<Content: View>(
        title: String,
        stylesheet: String = "static/style.output.css",
        @ViewBuilder bodyContent: () -> Content
    ) {
        self.title = title
        self.stylesheet = stylesheet
        self.bodyContent = bodyContent()
    }
    
    /// Creates a base page with default placeholder content.
    /// - Parameters:
    ///   - title: The page title to display in the browser tab
    ///   - stylesheet: CSS file path (defaults to "static/style.output.css")
    ///   - text: The placeholder text (defaults to "Initial Website")
    public init(
        title: String,
        stylesheet: String = "static/style.output.css",
        text: String = "Initial Website"
    ) {
        self.title = title
        self.stylesheet = stylesheet
        self.bodyContent = PlaceholderView(text: text)
    }
    
    public var body: some View {
        HTML {
            Head {
                Charset(.utf8)
                Title(title)
                Viewport.mobileFriendly
                Stylesheet(URL(string: stylesheet))
            }
            Body {
                AnyView(bodyContent)
            }
        }
    }
}
