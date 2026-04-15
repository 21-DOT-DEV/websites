//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import SchemaLib
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
    let llmsTxtURL: URL?
    let favicon: FaviconConfig?
    let alternateMarkdownURL: URL?
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
        favicon: FaviconConfig? = nil,
        llmsTxtURL: URL? = nil,
        alternateMarkdownURL: URL? = nil,
        @ViewBuilder bodyContent: () -> Content
    ) {
        self.title = title
        self.description = description
        self.stylesheet = stylesheet
        self.canonicalURL = canonicalURL
        self.robotsDirective = robotsDirective
        self.articleMetadata = articleMetadata
        self.schemas = schemas
        self.favicon = favicon
        self.llmsTxtURL = llmsTxtURL
        self.alternateMarkdownURL = alternateMarkdownURL
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
        favicon: FaviconConfig? = nil,
        llmsTxtURL: URL? = nil,
        alternateMarkdownURL: URL? = nil,
        text: String = "Initial Website"
    ) {
        self.title = title
        self.description = description
        self.stylesheet = stylesheet
        self.canonicalURL = canonicalURL
        self.robotsDirective = robotsDirective
        self.articleMetadata = articleMetadata
        self.schemas = schemas
        self.favicon = favicon
        self.llmsTxtURL = llmsTxtURL
        self.alternateMarkdownURL = alternateMarkdownURL
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
                    RawHTML("<meta property=\"article:published_time\" content=\"\(article.publishedTime)\">")
                    if let modifiedTime = article.modifiedTime {
                        RawHTML("<meta property=\"article:modified_time\" content=\"\(modifiedTime)\">")
                    }
                    if let author = article.author {
                        RawHTML("<meta property=\"article:author\" content=\"\(author)\">")
                    }
                    ForEach(article.tags, id: \.self) { tag in
                        RawHTML("<meta property=\"article:tag\" content=\"\(tag)\">")
                    }
                }
                Viewport.mobileFriendly
                Canonical(canonicalURL)
                if let llmsTxtURL {
                    LLMsTxtLink(llmsTxtURL)
                }
                if let alternateMarkdownURL {
                    Alternate(alternateMarkdownURL, type: "text/markdown")
                }
                if let favicon {
                    Icon(URL(string: "/favicon.ico?v=\(favicon.version)"), sizes: "32x32", type: "image/x-icon")
                    Icon(URL(string: "/favicon-96x96.png?v=\(favicon.version)"), sizes: "96x96", type: "image/png")
                    // Slipstream Icon only supports rel="icon"; apple-touch-icon requires a different rel value
                    RawHTML("<link rel=\"apple-touch-icon\" sizes=\"180x180\" href=\"/apple-touch-icon.png?v=\(favicon.version)\">")
                    Manifest(URL(string: "/site.webmanifest?v=\(favicon.version)"))
                }
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
