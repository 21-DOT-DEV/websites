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
    let description: String?
    let stylesheet: String
    let canonicalURL: URL?
    let robotsDirective: String?
    let articleMetadata: ArticleMetadata?
    let bodyContent: any View
    
    /// Creates a base page with the specified title and custom body content.
    /// - Parameters:
    ///   - title: The page title to display in the browser tab
    ///   - stylesheet: CSS file path (defaults to "/static/style.css")
    ///   - bodyContent: The page body content
    public init<Content: View>(
        title: String,
        description: String? = nil,
        stylesheet: String = "/static/style.css",
        canonicalURL: URL? = nil,
        robotsDirective: String? = nil,
        articleMetadata: ArticleMetadata? = nil,
        @ViewBuilder bodyContent: () -> Content
    ) {
        self.title = title
        self.description = description
        self.stylesheet = stylesheet
        self.canonicalURL = canonicalURL
        self.robotsDirective = robotsDirective
        self.articleMetadata = articleMetadata
        self.bodyContent = bodyContent()
    }
    
    /// Creates a base page with default placeholder content.
    /// - Parameters:
    ///   - title: The page title to display in the browser tab
    ///   - stylesheet: CSS file path (defaults to "/static/style.css")
    ///   - text: The placeholder text (defaults to "Initial Website")
    public init(
        title: String,
        description: String? = nil,
        stylesheet: String = "/static/style.css",
        canonicalURL: URL? = nil,
        robotsDirective: String? = nil,
        articleMetadata: ArticleMetadata? = nil,
        text: String = "Initial Website"
    ) {
        self.title = title
        self.description = description
        self.stylesheet = stylesheet
        self.canonicalURL = canonicalURL
        self.robotsDirective = robotsDirective
        self.articleMetadata = articleMetadata
        self.bodyContent = PlaceholderView(text: text)
    }
    
    public var body: some View {
        HTML {
            Head {
                Charset(.utf8)
                Title(title)
                if let description {
                    Meta(.description, content: description)
                }
                if let robotsDirective {
                    Meta("robots", content: robotsDirective)
                }
                if let article = articleMetadata {
                    Meta("article:published_time", content: article.publishedTime)
                    if let modifiedTime = article.modifiedTime {
                        Meta("article:modified_time", content: modifiedTime)
                    }
                    if let author = article.author {
                        Meta("article:author", content: author)
                    }
                    ForEach(article.tags, id: \.self) { tag in
                        Meta("article:tag", content: tag)
                    }
                }
                Viewport.mobileFriendly
                Canonical(canonicalURL)
                Stylesheet(URL(string: stylesheet))
            }
            Body {
                AnyView(bodyContent)
            }
        }
        .language("en")
    }
}
