//
//  SitemapPageSetTests.swift
//  UtilLibTests
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing
import UtilLib

/// `SitemapPageSet` — the FR-008 page set: the origin root first, then
/// sitemap URLs in document order, capped at `maxPages`. Every unusable
/// input — absent, unreadable, empty, or a sitemap index — degrades to
/// the origin root alone.
@Suite("Vitals — SitemapPageSet")
struct VitalsSitemapPageSetTests {

    private let origin = "https://21.dev"

    private let sitemap = """
        <?xml version="1.0" encoding="UTF-8"?>
        <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
        <url>
          <loc>https://21.dev/blog/hello-world/</loc>
        </url>
        <url>
          <loc>https://21.dev/</loc>
        </url>
        <url>
          <loc>https://21.dev/packages/</loc>
        </url>
        <url>
          <loc>https://21.dev/packages/p256k/</loc>
        </url>
        </urlset>
        """

    // MARK: extractURLs — extraction shape

    @Test("extracts <loc> values in document order")
    func extractsInDocumentOrder() {
        #expect(SitemapPageSet.extractURLs(from: sitemap) == [
            "https://21.dev/blog/hello-world/",
            "https://21.dev/",
            "https://21.dev/packages/",
            "https://21.dev/packages/p256k/",
        ])
    }

    @Test("decodes XML entities in extracted URLs")
    func decodesEntities() {
        let xml = "<url><loc>https://21.dev/?a=1&amp;b=2</loc></url>"
        #expect(SitemapPageSet.extractURLs(from: xml) == ["https://21.dev/?a=1&b=2"])
    }

    @Test("extracts <loc> even when it is not the first child of <url>")
    func locNeedNotBeFirstChild() {
        let xml = "<url><lastmod>2026-11-20</lastmod><loc>https://21.dev/</loc></url>"
        #expect(SitemapPageSet.extractURLs(from: xml) == ["https://21.dev/"])
    }

    @Test("takes the first <loc> when a <url> contains more than one")
    func firstLocPerUrlBlock() {
        let xml = "<url><loc>https://21.dev/a</loc><loc>https://21.dev/b</loc></url>"
        #expect(SitemapPageSet.extractURLs(from: xml) == ["https://21.dev/a"])
    }

    @Test("ignores <loc> entries inside a sitemap index")
    func ignoresSitemapIndexEntries() {
        let index = """
            <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            <sitemap><loc>https://21.dev/sitemap-main.xml</loc></sitemap>
            <sitemap><loc>https://docs.21.dev/sitemap.xml</loc></sitemap>
            </sitemapindex>
            """
        #expect(SitemapPageSet.extractURLs(from: index) == [])
    }

    // MARK: pageSet — selection, cap, fallback

    @Test("promotes the origin root to the front when the sitemap lists it later")
    func promotesRoot() {
        let pages = SitemapPageSet.pageSet(sitemapXML: sitemap, fallbackOrigin: origin, maxPages: 10)
        // The sitemap's slash-spelled root ("https://21.dev/") is deduplicated
        // against the origin ("https://21.dev") — the root is measured once.
        #expect(pages == [
            origin,
            "https://21.dev/blog/hello-world/",
            "https://21.dev/packages/",
            "https://21.dev/packages/p256k/",
        ])
    }

    @Test("prepends the origin root when the sitemap omits it")
    func prependsRoot() {
        let xml = "<url><loc>https://21.dev/packages/</loc></url>"
        let pages = SitemapPageSet.pageSet(sitemapXML: xml, fallbackOrigin: origin, maxPages: 10)
        #expect(pages == [origin, "https://21.dev/packages/"])
    }

    @Test("does not duplicate the root when it already leads the sitemap")
    func dedupesRoot() {
        let xml = """
            <url><loc>https://21.dev/</loc></url>
            <url><loc>https://21.dev/packages/</loc></url>
            """
        let pages = SitemapPageSet.pageSet(sitemapXML: xml, fallbackOrigin: origin, maxPages: 10)
        #expect(pages == [origin, "https://21.dev/packages/"])
    }

    @Test("caps the set at maxPages, root included")
    func capsAtMaxPages() {
        let pages = SitemapPageSet.pageSet(sitemapXML: sitemap, fallbackOrigin: origin, maxPages: 2)
        #expect(pages == [origin, "https://21.dev/blog/hello-world/"])
    }

    @Test("a maxPages of one measures only the origin root")
    func capOfOne() {
        let pages = SitemapPageSet.pageSet(sitemapXML: sitemap, fallbackOrigin: origin, maxPages: 1)
        #expect(pages == [origin])
    }

    @Test("maxPages beyond the URL count returns the whole set")
    func capBeyondCount() {
        let xml = "<url><loc>https://21.dev/packages/</loc></url>"
        let pages = SitemapPageSet.pageSet(sitemapXML: xml, fallbackOrigin: origin, maxPages: 10)
        #expect(pages.count == 2)
    }

    @Test("nil sitemap falls back to the origin root")
    func nilFallsBack() {
        let pages = SitemapPageSet.pageSet(sitemapXML: nil, fallbackOrigin: origin, maxPages: 10)
        #expect(pages == [origin])
    }

    @Test("a sitemap with no <url> entries falls back to the origin root")
    func emptyFallsBack() {
        let xml = """
            <?xml version="1.0" encoding="UTF-8"?>
            <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            </urlset>
            """
        let pages = SitemapPageSet.pageSet(sitemapXML: xml, fallbackOrigin: origin, maxPages: 10)
        #expect(pages == [origin])
    }

    @Test("a sitemap index falls back to the origin root")
    func indexFallsBack() {
        let index = """
            <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            <sitemap><loc>https://21.dev/sitemap-main.xml</loc></sitemap>
            </sitemapindex>
            """
        let pages = SitemapPageSet.pageSet(sitemapXML: index, fallbackOrigin: origin, maxPages: 10)
        #expect(pages == [origin])
    }
}
