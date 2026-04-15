//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

/// Configuration for favicon link tags and PWA meta tags rendered in the HTML `<head>`.
///
/// Pass a `FaviconConfig` to `BasePage` to include the standard set of
/// favicon `<link>` elements, `apple-mobile-web-app-title`, and `theme-color`
/// meta tags with cache-busting version query strings.
///
/// ```swift
/// BasePage(
///     title: "My Page",
///     favicon: FaviconConfig(version: "20260413", appTitle: "21.dev", themeColor: "#ffffff")
/// ) {
///     Text("Hello")
/// }
/// ```
public struct FaviconConfig: Sendable {
    /// Cache-busting version string appended as `?v=` to favicon hrefs.
    public let version: String
    
    /// Title shown when the site is added to an iOS home screen.
    public let appTitle: String
    
    /// Browser toolbar / address bar color on mobile.
    public let themeColor: String
    
    /// Creates a favicon configuration.
    ///
    /// - Parameters:
    ///   - version: A version string for cache busting (e.g. `"20260413"`).
    ///   - appTitle: The iOS home-screen label (rendered as `apple-mobile-web-app-title`).
    ///   - themeColor: The mobile browser toolbar color (rendered as `theme-color`).
    public init(version: String, appTitle: String, themeColor: String) {
        self.version = version
        self.appTitle = appTitle
        self.themeColor = themeColor
    }
}
