//
//  SitemapPageSet.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Extracts the vitals page set from a generated `sitemap.xml`
/// (FR-008 — `Development/Specs/009-cwv-baseline/spec.md`).
///
/// The generator emits uniform `<url><loc>…</loc></url>` entries, so regex
/// extraction is sufficient — the same approach as `SitemapValidator`, with
/// two tightenings: extraction is scoped to `<url>` blocks so a sitemap
/// *index* file's `<sitemap><loc>` entries are never mistaken for pages,
/// and each `<loc>` value is XML-unescaped — the inverse of `xmlEscape`
/// applied at generation time — so a URL carrying a query string is
/// measured as itself, not its escaped form.
public enum SitemapPageSet {

    /// All page URLs in document order — the first `<loc>` of each
    /// `<url>` block, entity-decoded.
    /// - Parameter sitemapXML: The sitemap file's contents
    /// - Returns: Extracted URLs, empty when no `<url>` block contains a `<loc>`
    public static func extractURLs(from sitemapXML: String) -> [String] {
        guard let blockRegex = try? NSRegularExpression(
            pattern: "<url>(.*?)</url>",
            options: [.dotMatchesLineSeparators]
        ), let locRegex = try? NSRegularExpression(pattern: "<loc>([^<]+)</loc>")
        else { return [] }

        let range = NSRange(sitemapXML.startIndex..., in: sitemapXML)
        return blockRegex.matches(in: sitemapXML, range: range).compactMap { block in
            guard let blockRange = Range(block.range(at: 1), in: sitemapXML) else { return nil }
            let block = String(sitemapXML[blockRange])
            guard let locMatch = locRegex.firstMatch(in: block, range: NSRange(block.startIndex..., in: block)),
                  let locRange = Range(locMatch.range(at: 1), in: block)
            else { return nil }
            return xmlUnescape(String(block[locRange]))
        }
    }

    /// The page set to measure: the site's origin root first, then the
    /// sitemap's remaining URLs in document order, capped at `maxPages`.
    ///
    /// The root is promoted so the landing page is always measured —
    /// sitemaps need not list it (the docs site's does not). Any sitemap
    /// yielding no page URLs degrades to `[fallbackOrigin]` rather than
    /// erroring — absent or unreadable file (`nil`), an empty `<urlset>`,
    /// or a sitemap index. The baseline records gaps; it does not fail on
    /// them.
    ///
    /// - Parameters:
    ///   - sitemapXML: The sitemap file's contents, or `nil` when the file is absent or unreadable
    ///   - fallbackOrigin: The site's origin root (e.g., `"https://21.dev"`)
    ///   - maxPages: Maximum pages in the set — must be ≥ 1
    /// - Returns: The deduplicated, root-first page set
    public static func pageSet(
        sitemapXML: String?,
        fallbackOrigin: String,
        maxPages: Int
    ) -> [String] {
        precondition(maxPages >= 1, "maxPages must be >= 1, got \(maxPages)")
        guard let sitemapXML else { return [fallbackOrigin] }
        var seen = Set<String>()
        let ordered = ([fallbackOrigin] + extractURLs(from: sitemapXML))
            .filter { seen.insert(dedupKey($0)).inserted }
        return Array(ordered.prefix(maxPages))
    }

    /// Dedup key — `https://site/` and `https://site` name the same page;
    /// likewise any trailing-slash pair. The sitemap spells directory URLs
    /// with a trailing slash while the origin root does not; without
    /// normalization the root would be measured twice.
    private static func dedupKey(_ url: String) -> String {
        url.hasSuffix("/") ? String(url.dropLast()) : url
    }
}
