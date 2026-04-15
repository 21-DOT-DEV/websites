//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

/// Configuration for Open Graph and Twitter Card meta tags rendered in the HTML `<head>`.
///
/// Pass an `OpenGraphConfig` to `BasePage` to include the standard set of
/// `og:*` and `twitter:*` meta tags for rich social media link previews.
///
/// ```swift
/// BasePage(
///     title: "My Page",
///     openGraph: OpenGraphConfig(
///         title: "My Page",
///         description: "Page description",
///         type: .website,
///         url: "https://21.dev/",
///         siteName: "21.dev",
///         twitterCard: "summary",
///         twitterSite: "@21_DOT_DEV"
///     )
/// ) {
///     Text("Hello")
/// }
/// ```
public struct OpenGraphConfig: Sendable {
    /// The page title for social sharing (`og:title`).
    public let title: String
    
    /// The page description for social sharing (`og:description`).
    public let description: String?
    
    /// The Open Graph object type (`og:type`).
    public let type: OGType
    
    /// The canonical URL of the page (`og:url`). Must be absolute.
    public let url: String
    
    /// The site name shown in social previews (`og:site_name`).
    public let siteName: String
    
    /// The Twitter/X card format (`twitter:card`).
    public let twitterCard: String
    
    /// The Twitter/X handle associated with the site (`twitter:site`).
    public let twitterSite: String?
    
    /// The absolute URL of the share image (`og:image`).
    public let image: String?
    
    /// The image width in pixels (`og:image:width`).
    public let imageWidth: Int?
    
    /// The image height in pixels (`og:image:height`).
    public let imageHeight: Int?
    
    /// Alt text for the share image (`og:image:alt`, `twitter:image:alt`).
    public let imageAlt: String?
    
    /// Open Graph object types.
    public enum OGType: String, Sendable {
        /// Standard web page (homepage, landing pages, listing pages).
        case website
        /// Article content (blog posts, news articles).
        case article
    }
    
    /// Creates an Open Graph configuration.
    ///
    /// - Parameters:
    ///   - title: The page title for `og:title`.
    ///   - description: Optional page description for `og:description`.
    ///   - type: The OG object type (`.website` or `.article`).
    ///   - url: The absolute canonical URL for `og:url`.
    ///   - siteName: The site name for `og:site_name`.
    ///   - twitterCard: The Twitter card type (e.g. `"summary"`).
    ///   - twitterSite: Optional Twitter handle for `twitter:site`.
    public init(
        title: String,
        description: String? = nil,
        type: OGType = .website,
        url: String,
        siteName: String,
        twitterCard: String = "summary",
        twitterSite: String? = nil,
        image: String? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        imageAlt: String? = nil
    ) {
        self.title = title
        self.description = description
        self.type = type
        self.url = url
        self.siteName = siteName
        self.twitterCard = twitterCard
        self.twitterSite = twitterSite
        self.image = image
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageAlt = imageAlt
    }
}
