//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
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
    let schemas: [any Schema]?
    let bodyContent: any View
    
    /// Creates a base page with the specified title and custom body content.
    /// - Parameters:
    ///   - title: The page title to display in the browser tab
    ///   - stylesheet: CSS file path (defaults to "/static/style.css")
    ///   - schemas: Array of Schema objects for JSON-LD structured data (uses @graph approach)
    ///   - bodyContent: The page body content
    public init<Content: View>(
        title: String,
        description: String? = nil,
        stylesheet: String = "/static/style.css",
        canonicalURL: URL? = nil,
        robotsDirective: String? = nil,
        articleMetadata: ArticleMetadata? = nil,
        schemas: [any Schema]? = nil,
        @ViewBuilder bodyContent: () -> Content
    ) {
        self.title = title
        self.description = description
        self.stylesheet = stylesheet
        self.canonicalURL = canonicalURL
        self.robotsDirective = robotsDirective
        self.articleMetadata = articleMetadata
        self.schemas = schemas
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
        schemas: [any Schema]? = nil,
        text: String = "Initial Website"
    ) {
        self.title = title
        self.description = description
        self.stylesheet = stylesheet
        self.canonicalURL = canonicalURL
        self.robotsDirective = robotsDirective
        self.articleMetadata = articleMetadata
        self.schemas = schemas
        self.bodyContent = PlaceholderView(text: text)
    }
    
    /// Renders the JSON-LD structured data from schemas.
    private var structuredDataJSON: String? {
        guard let schemas, !schemas.isEmpty else { return nil }
        let graph = SchemaGraph(schemas)
        return try? graph.render()
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
                if let json = structuredDataJSON {
                    Script(json)
                        .modifier(AttributeModifier("type", value: "application/ld+json"))
                }
            }
            Body {
                AnyView(bodyContent)
            }
        }
        .language("en")
    }
}
