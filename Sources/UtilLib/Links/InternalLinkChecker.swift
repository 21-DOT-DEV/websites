//
//  InternalLinkChecker.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import SwiftSoup

/// Verifies that internal references in generated HTML resolve to files in the
/// site output — pages, images, stylesheets, and scripts — without any HTTP.
///
/// Resolution mirrors Cloudflare Pages serving: a reference is valid when the
/// site root contains the exact file, `path/index.html` (directory index), or
/// `path.html` (clean URL), or when the path matches a `_redirects` rule the
/// edge would apply — the edge evaluates `_redirects` before static assets, so
/// the first applied rule in file order governs: a redirect status (`301`,
/// `302`, `303`, `307`, `308`) exempts outright, while a `200` proxy exempts
/// only when its substituted site-relative target itself resolves on disk.
/// External URLs, non-HTTP schemes, and fragment-only references are skipped.
public enum InternalLinkChecker {

    /// How a raw attribute value was classified.
    enum Resolution: Equatable {
        /// Not an internal path — external URL, scheme, fragment-only, or empty.
        case skipped
        /// Internal reference resolved to this site-relative path (leading `/`).
        case sitePath(String)
        /// Internal reference that escapes above the site root via `..`.
        case outOfRoot
        /// A segment percent-decodes to a `/` or `\` — can't denote a file.
        case unservable
    }

    /// How a path normalized for site-relative resolution.
    enum PathNormalization: Equatable {
        /// Normalized to this site-relative form (leading `/`).
        case ok(String)
        /// `..` escapes above the site root.
        case escapesRoot
        /// A percent-decoded `/` or `\` inside a segment — can't denote a file.
        case unservable
    }

    /// Elements whose `href`/`src` are checked, and which attribute to read.
    private static let attributeSelectors: [(selector: String, attribute: ExtractedLink.Attribute)] = [
        ("a[href]", .href),
        ("area[href]", .href),
        ("link[href]", .href),
        ("img[src]", .src),
        ("script[src]", .src),
        ("source[src]", .src),
        ("video[src]", .src),
        ("audio[src]", .src),
        ("embed[src]", .src),
        ("iframe[src]", .src),
        ("track[src]", .src),
        ("img[srcset]", .srcset),
        ("source[srcset]", .srcset),
    ]

    /// Extracts every URL reference from an HTML string.
    /// - Parameter html: The HTML content to scan.
    /// - Returns: Extracted references grouped by selector pass (srcset expanded per candidate).
    static func extractLinks(html: String) throws -> [ExtractedLink] {
        let document = try SwiftSoup.parse(html)
        var links: [ExtractedLink] = []

        for (selector, attribute) in attributeSelectors {
            for element in try document.select(selector).array() {
                let value = try element.attr(attribute.rawValue)
                if attribute == .srcset {
                    links.append(contentsOf: parseSrcset(value).map {
                        ExtractedLink(attribute: .srcset, rawValue: $0)
                    })
                } else {
                    links.append(ExtractedLink(attribute: attribute, rawValue: value))
                }
            }
        }
        return links
    }

    /// Splits a `srcset` attribute into candidate URLs.
    ///
    /// Follows the WHATWG srcset algorithm: a URL is a run of non-whitespace
    /// characters — commas are legal inside it, so `data:` URIs (including
    /// payloads with commas) form a single candidate — and a candidate ends at
    /// a comma trailing its URL or a descriptor.
    static func parseSrcset(_ value: String) -> [String] {
        var urls: [String] = []
        var index = value.startIndex

        func skipWhitespaceAndCommas() {
            while index < value.endIndex, value[index] == "," || value[index].isWhitespace {
                index = value.index(after: index)
            }
        }
        func skipWhitespace() {
            while index < value.endIndex, value[index].isWhitespace {
                index = value.index(after: index)
            }
        }

        while index < value.endIndex {
            skipWhitespaceAndCommas()
            guard index < value.endIndex else { break }

            // URL token — every character up to whitespace, commas included.
            let urlStart = index
            while index < value.endIndex, !value[index].isWhitespace {
                index = value.index(after: index)
            }
            var url = value[urlStart..<index]
            if url.hasSuffix(",") {
                // A URL token ending in a comma terminates its own candidate.
                while url.hasSuffix(",") { url = url.dropLast() }
                if !url.isEmpty { urls.append(String(url)) }
                continue
            }

            // Descriptor tokens — whitespace-separated runs; a comma outside
            // parentheses terminates the candidate wherever it appears.
            descriptorLoop: while true {
                skipWhitespace()
                var depth = 0
                while index < value.endIndex {
                    let character = value[index]
                    if character == "(" { depth += 1 }
                    else if character == ")" { depth = max(depth - 1, 0) }
                    else if (character == "," && depth == 0) || character.isWhitespace { break }
                    index = value.index(after: index)
                }
                skipWhitespace()
                guard index < value.endIndex else { break }
                if value[index] == "," {
                    index = value.index(after: index)
                    break
                }
            }
            urls.append(String(url))
        }
        return urls
    }

    /// Classifies a raw attribute value and resolves internal ones to a site-relative path.
    /// - Parameters:
    ///   - rawValue: The attribute value (or srcset candidate).
    ///   - fileRelativePath: The containing HTML file's path relative to site root.
    /// - Returns: The resolution for this value.
    static func resolve(_ rawValue: String, from fileRelativePath: String) -> Resolution {
        // WHATWG URL parsing removes ASCII tab/newline and treats `\` as `/`
        // in special schemes — normalize both before classifying, so `a\b`
        // resolves like `a/b` and `\\host` counts as protocol-relative.
        let value = rawValue
            .replacingOccurrences(of: "\\", with: "/")
            .replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else { return .skipped }
        guard !trimmed.hasPrefix("//") else { return .skipped }
        // Any explicit scheme (`https:`, `mailto:`, `tel:`, `data:`, `javascript:`…) — not internal.
        // A scheme must start with a letter, so `2024:recap.html` stays a path.
        if let colon = trimmed.firstIndex(of: ":"),
           trimmed.first?.isLetter == true,
           trimmed[..<colon].allSatisfy({ $0.isLetter || $0.isNumber || "+.-".contains($0) }) {
            return .skipped
        }

        // Strip query and fragment — both are server- or client-side concerns.
        var path = trimmed
        if let cut = path.firstIndex(where: { $0 == "?" || $0 == "#" }) {
            let stripped = String(path[..<cut])
            // A query-only `?x` reference targets the containing page itself —
            // a `#x` fragment-only reference is explicitly skipped (FR-006).
            if stripped.isEmpty {
                guard path[cut] == "?" else { return .skipped }
                path = "/" + fileRelativePath
            } else {
                path = stripped
            }
        }
        guard !path.isEmpty else { return .skipped }

        if path.hasPrefix("/") {
            switch normalizedSitePath(path) {
            case .ok(let normalized): return .sitePath(normalized)
            case .escapesRoot: return .outOfRoot
            case .unservable: return .unservable
            }
        }

        // Relative reference: resolve against the containing file's directory.
        // For index.html that directory is the page's own URL space; for other
        // files it is the parent — both match what browsers resolve against.
        let baseDirectory = (fileRelativePath as NSString).deletingLastPathComponent
        let joined = baseDirectory.isEmpty ? path : baseDirectory + "/" + path
        switch normalizedSitePath(joined) {
        case .ok(let normalized): return .sitePath(normalized)
        case .escapesRoot: return .outOfRoot
        case .unservable: return .unservable
        }
    }

    /// Collapses `.` and `..` segments in a path into normalized site-relative
    /// form (leading `/`). Percent-decoding happens per segment: the raw path
    /// is split on `/` first, so a segment decoding to `/` or `\` (e.g. `%2F`,
    /// `%5C`) is *not* a separator — it can't denote a servable file and the
    /// whole path fails. Percent-encoded `.`/`..` normalize like literal dots.
    /// A trailing `/`, `/.`, or `/..` keeps its directory shape — `_redirects`
    /// sources distinguish `/blog` from `/blog/`.
    ///
    /// Decoding happens here, *before* `_redirects` matching — the edge
    /// matches the request path as sent, so a form like `/a%2Fb` can match a
    /// source the edge would not. Accepted divergence for generated output.
    /// - Parameter path: An absolute (`/`-leading) or relative path.
    static func normalizedSitePath(_ path: String) -> PathNormalization {
        let path = path.replacingOccurrences(of: "\\", with: "/")
        var segments: [String] = []
        var lastRawSegment: Substring = ""
        for rawSegment in path.split(separator: "/") {
            lastRawSegment = rawSegment
            let segment = String(rawSegment).removingPercentEncoding ?? String(rawSegment)
            if segment.contains("/") || segment.contains("\\") {
                return .unservable
            }
            switch segment {
            case ".": continue
            case "..":
                guard !segments.isEmpty else { return .escapesRoot }
                segments.removeLast()
            default:
                segments.append(segment)
            }
        }
        var result = "/" + segments.joined(separator: "/")
        let trailing = lastRawSegment.removingPercentEncoding ?? String(lastRawSegment)
        let directoryShape = path.hasSuffix("/") || trailing == "." || trailing == ".."
        if directoryShape && result != "/" { result += "/" }
        return .ok(result)
    }

    /// Whether a site-relative path exists as a servable file in the output directory.
    ///
    /// Covers the Cloudflare Pages serving forms: the exact file,
    /// `path/index.html` (directory index), and `path.html` (clean URL). This is
    /// also the check applied to a `200` proxy rule's substituted target.
    /// Dot-segments are normalized first and a path escaping the root is
    /// reported missing — links and proxied targets both come through here.
    ///
    /// Known limitation: `FileManager` follows the filesystem's case semantics,
    /// so on case-insensitive volumes (default APFS — local dev and the macOS
    /// CI runners) a link whose case differs from the file's still passes even
    /// though the edge serves paths case-sensitively.
    /// - Parameters:
    ///   - sitePath: Path relative to site root, starting with `/`.
    ///   - root: Site output directory.
    /// - Returns: `true` when a servable file exists.
    static func fileExists(sitePath: String, inRoot root: String) -> Bool {
        guard case .ok(let normalized) = normalizedSitePath(sitePath) else { return false }
        // `_redirects`, `_headers`, … sit in the output root but are config,
        // not assets — the edge never serves them (a trailing-slash spelling
        // addresses the same unservable config).
        let unslashed = normalized.hasSuffix("/") ? String(normalized.dropLast()) : normalized
        guard !unservedRootFiles.contains(unslashed) else { return false }
        let fileManager = FileManager.default
        let relativePath = String(normalized.dropFirst()) // drop leading "/"
        // A trailing slash still tries the clean-URL form — `/file/` resolves
        // through `file.html` because Pages redirects non-canonical spellings.
        let indexCandidate = relativePath.isEmpty ? "index.html" : relativePath + "/index.html"
        var candidates = [
            (root as NSString).appendingPathComponent(relativePath),
            (root as NSString).appendingPathComponent(indexCandidate),
        ]
        if !relativePath.isEmpty {
            // The root path has no clean-URL file form — `/.html` is a dotfile,
            // not a page.
            let htmlCandidate = relativePath.hasSuffix("/")
                ? String(relativePath.dropLast()) + ".html"
                : relativePath + ".html"
            candidates.append((root as NSString).appendingPathComponent(htmlCandidate))
        }
        var isDirectory: ObjCBool = false
        for candidate in candidates where fileManager.fileExists(atPath: candidate, isDirectory: &isDirectory) {
            if !isDirectory.boolValue { return true }
        }
        return false
    }

    /// Cloudflare Pages config files that live in the output root but are
    /// never served as assets — a link to one 404s at the edge even though
    /// the file is on disk.
    private static let unservedRootFiles: Set<String> = [
        "/_redirects", "/_headers", "/_routes.json", "/_worker.js",
    ]

    /// Whether a site-relative path would be answered by the edge — by an applied
    /// `_redirects` rule or by a file in the output directory.
    ///
    /// The edge evaluates `_redirects` before static assets and applies the
    /// top-most matching rule, so the first *applied* rule governs: a supported
    /// redirect status exempts outright (the edge answers with a redirect even
    /// when the target is absent); a `200` proxy exempts only when its
    /// substituted target resolves on disk — without re-applying `_redirects`,
    /// since proxies do not chain — and otherwise shadows the path entirely,
    /// leaving the reference broken even if a file sits at the source path.
    /// Rules the edge ignores (unsupported declared status, external proxy
    /// target) never consume the match, so a later rule may still apply.
    /// - Parameters:
    ///   - sitePath: Path relative to site root, starting with `/`.
    ///   - root: Site output directory.
    ///   - matcher: Precompiled `_redirects` rules, in file order.
    /// - Returns: `true` when the path is servable.
    static func exists(sitePath: String, inRoot root: String, matcher: RedirectMatcher) -> Bool {
        if let (rule, match) = matcher.firstAppliedMatch(sitePath: sitePath) {
            if rule.status == 200 {
                var target = RedirectsParser.substitute(rule.target, with: match)
                if let cut = target.firstIndex(where: { $0 == "?" || $0 == "#" }) {
                    target = String(target[..<cut])
                }
                return fileExists(sitePath: target, inRoot: root)
            }
            return true
        }
        return fileExists(sitePath: sitePath, inRoot: root)
    }

    /// Convenience overload compiling parsed rules once for a single lookup.
    /// - Parameters:
    ///   - sitePath: Path relative to site root, starting with `/`.
    ///   - root: Site output directory.
    ///   - redirects: Parsed `_redirects` rules.
    /// - Returns: `true` when the path is servable.
    static func exists(sitePath: String, inRoot root: String, redirects: [RedirectRule]) -> Bool {
        exists(sitePath: sitePath, inRoot: root, matcher: RedirectsParser.compiledMatcher(rules: redirects))
    }

    /// Checks every HTML file under a directory for broken internal references.
    ///
    /// A file that cannot be read or parsed is recorded as skipped — named in
    /// the report's warnings rather than dropped, so a parse regression cannot
    /// silently green the gate.
    /// - Parameter directory: Site output root containing generated HTML (and optionally `_redirects`).
    /// - Returns: A `LinkCheckReport` aggregating per-file results.
    /// - Throws: ``HTMLFileWalkerError`` if the directory cannot be enumerated.
    public static func checkDirectory(at directory: String) throws -> LinkCheckReport {
        let entries = try HTMLFileWalker.findHTMLFiles(in: directory)
        let loadedRedirects = RedirectsParser.loadRules(from: directory)
        let matcher = RedirectsParser.compiledMatcher(rules: loadedRedirects.rules)
        var results: [FileLinkCheck] = []

        for entry in entries {
            do {
                let html = try String(contentsOfFile: entry.absolutePath, encoding: .utf8)
                let links = try extractLinks(html: html)

                let references: [CheckedReference] = links.map { link in
                    let outcome: CheckedReference.Outcome
                    switch resolve(link.rawValue, from: entry.relativePath) {
                    case .skipped:
                        outcome = .skipped
                    case .outOfRoot:
                        outcome = .broken(
                            resolvedPath: "(above site root)",
                            reason: "relative reference escapes site root"
                        )
                    case .unservable:
                        outcome = .broken(
                            resolvedPath: "(unservable path)",
                            reason: "percent-encoded separator can't denote a servable file"
                        )
                    case .sitePath(let sitePath):
                        outcome = exists(sitePath: sitePath, inRoot: directory, matcher: matcher)
                            ? .resolved(sitePath: sitePath)
                            : .broken(
                                resolvedPath: sitePath,
                                reason: "no file, directory index, or redirect rule"
                            )
                    }
                    return CheckedReference(attribute: link.attribute, rawValue: link.rawValue, outcome: outcome)
                }

                results.append(FileLinkCheck(
                    filePath: entry.absolutePath,
                    relativePath: entry.relativePath,
                    references: references
                ))
            } catch {
                results.append(FileLinkCheck(
                    filePath: entry.absolutePath,
                    relativePath: entry.relativePath,
                    references: [],
                    skippedReason: error.localizedDescription
                ))
            }
        }

        var scanWarnings = loadedRedirects.warning.map { [$0] } ?? []
        // A catch-all 200 proxy exempts every internal link it shadows — the
        // edge really does serve it, but a masked gate must never be silent.
        for rule in loadedRedirects.rules where rule.status == 200 && rule.isCatchAll && rule.isAppliedByEdge {
            scanWarnings.append(
                "_redirects catch-all 200 proxy '\(rule.source) \(rule.target)' exempts every internal link — the gate may be masked"
            )
        }

        return LinkCheckReport(
            results: results,
            scanDirectory: directory,
            scanWarnings: scanWarnings
        )
    }
}
