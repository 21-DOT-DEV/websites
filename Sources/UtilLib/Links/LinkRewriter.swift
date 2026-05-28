//
//  LinkRewriter.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import SwiftSoup

/// Strips trailing `/index.html` from `<a href>` values in HTML files.
///
/// DocC's static-hosting output emits inter-page anchor links as
/// `href="../foo/index.html"` rather than the directory-style
/// `href="../foo/"` that matches the canonical URL form. This rewriter
/// normalizes the body anchors to the directory form so the in-page
/// links agree with the `<link rel="canonical">` tag emitted by the
/// `canonical fix` step.
///
/// Selector: `a[href$=/index.html]` — matches only anchors whose href
/// ends with the literal `/index.html` (with the leading slash). That
/// guarantees bare `href="index.html"` (which would rewrite to an empty
/// href and break the link) is not touched.
public enum LinkRewriter {

    /// Suffix the rewriter searches for and strips.
    /// The leading slash is intentional — without it, a bare
    /// `href="index.html"` would be rewritten to `href=""`.
    static let trailingSuffix = "/index.html"

    /// Rewrite a single HTML string.
    ///
    /// - Parameter html: The HTML content to rewrite.
    /// - Returns: A tuple of (rewritten HTML, number of anchors rewritten).
    /// - Throws: Re-throws SwiftSoup parse errors.
    public static func rewrite(html: String) throws -> (String, Int) {
        let document = try SwiftSoup.parse(html)
        let anchors = try document.select("a[href$=\(trailingSuffix)]")

        var count = 0
        for anchor in anchors {
            let href = try anchor.attr("href")
            // Defensive: the suffix selector should guarantee this, but
            // verify before slicing to avoid a substring out-of-bounds
            // when SwiftSoup's selector ever changes semantics.
            guard href.hasSuffix(trailingSuffix) else { continue }
            let newHref = String(href.dropLast("index.html".count))
            try anchor.attr("href", newHref)
            count += 1
        }

        return (try document.html(), count)
    }

    /// Rewrite every HTML file under a directory.
    ///
    /// - Parameters:
    ///   - directory: Path to the directory to scan recursively.
    ///   - dryRun: When `true`, parse and count without writing changes.
    /// - Returns: A `LinkRewriteReport` aggregating per-file results.
    /// - Throws: Re-throws ``HTMLFileWalkerError`` if the directory is unreadable.
    public static func rewriteDirectory(
        at directory: String,
        dryRun: Bool
    ) throws -> LinkRewriteReport {
        let entries = try HTMLFileWalker.findHTMLFiles(in: directory)
        var results: [LinkRewriteResult] = []

        for entry in entries {
            do {
                let html = try String(contentsOfFile: entry.absolutePath, encoding: .utf8)
                let (rewritten, count) = try rewrite(html: html)

                if count == 0 {
                    results.append(LinkRewriteResult(
                        filePath: entry.absolutePath,
                        action: .unchanged,
                        rewriteCount: 0,
                        errorMessage: nil
                    ))
                    continue
                }

                if !dryRun {
                    try rewritten.write(toFile: entry.absolutePath, atomically: true, encoding: .utf8)
                }

                results.append(LinkRewriteResult(
                    filePath: entry.absolutePath,
                    action: .rewritten,
                    rewriteCount: count,
                    errorMessage: nil
                ))
            } catch {
                results.append(LinkRewriteResult(
                    filePath: entry.absolutePath,
                    action: .failed,
                    rewriteCount: 0,
                    errorMessage: error.localizedDescription
                ))
            }
        }

        return LinkRewriteReport(results: results)
    }
}
