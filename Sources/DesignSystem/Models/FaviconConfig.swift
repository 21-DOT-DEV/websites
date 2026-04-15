//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

/// Configuration for favicon link tags rendered in the HTML `<head>`.
///
/// Pass a `FaviconConfig` to `BasePage` to include the standard set of
/// favicon `<link>` elements with cache-busting version query strings.
///
/// ```swift
/// BasePage(
///     title: "My Page",
///     favicon: FaviconConfig(version: "20260413")
/// ) {
///     Text("Hello")
/// }
/// ```
public struct FaviconConfig: Sendable {
    /// Cache-busting version string appended as `?v=` to favicon hrefs.
    public let version: String
    
    /// Creates a favicon configuration.
    ///
    /// - Parameter version: A version string for cache busting (e.g. `"20260413"`).
    public init(version: String) {
        self.version = version
    }
}
