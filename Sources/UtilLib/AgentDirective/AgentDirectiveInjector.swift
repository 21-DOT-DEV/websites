//
//  AgentDirectiveInjector.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import SchemaLib

/// Injects agent directive tags into HTML files to guide AI agents toward
/// machine-readable markdown versions.
public enum AgentDirectiveInjector {

    /// Marker string used to detect existing JSON-LD directives.
    /// Present in both full directives (with markdown link) and fallback directives.
    static let marker = "\"isPartOf\""

    /// Legacy marker class from the previous `<p>` tag format.
    static let legacyMarkerClass = "agent-directive"

    /// Derives the markdown-relative path for an HTML page path.
    ///
    /// Transformation: `documentation/p256k/context/index.html`
    /// → `data/documentation/p256k/context.md`
    ///
    /// - Parameter relativePath: File path relative to the output directory
    /// - Returns: The relative path to the expected markdown file
    public static func deriveMarkdownRelativePath(from relativePath: String) -> String {
        var path = relativePath

        if path.hasSuffix("/index.html") {
            path = String(path.dropLast("/index.html".count))
        } else if path.hasSuffix(".html") {
            path = String(path.dropLast(".html".count))
        }

        return "data/" + path + ".md"
    }

    /// Derives the markdown URL for an HTML page path.
    ///
    /// Transformation: `documentation/p256k/context/index.html`
    /// → `{baseURL}/data/documentation/p256k/context.md`
    ///
    /// - Parameters:
    ///   - baseURL: Site base URL (e.g., `https://docs.21.dev`)
    ///   - relativePath: File path relative to the output directory
    /// - Returns: The derived markdown URL
    public static func deriveMarkdownURL(baseURL: URL, relativePath: String) -> URL {
        let markdownPath = deriveMarkdownRelativePath(from: relativePath)
        return baseURL.appendingPathComponent(markdownPath)
    }

    /// Extracts the module name from a documentation-relative path.
    ///
    /// `documentation/p256k/p256k/context/index.html` → `p256k`
    /// `documentation/index.html` → `nil` (no module)
    ///
    /// Requires at least three path components (`documentation/{module}/{…}`)
    /// so that top-level pages like `documentation/index.html` correctly
    /// return `nil` instead of treating the filename as a module name.
    ///
    /// - Parameter relativePath: File path relative to the output directory
    /// - Returns: The module name, or `nil` if not under a module subdirectory
    public static func extractModule(from relativePath: String) -> String? {
        let components = relativePath.split(separator: "/")
        guard components.count >= 3, components[0] == "documentation" else {
            return nil
        }
        return String(components[1])
    }

    /// Marker for the `<link rel="alternate">` markdown tag.
    static let alternateMarker = "rel=\"alternate\" type=\"text/markdown\""

    /// Builds the agent directive tags for injection into `<head>`.
    ///
    /// Produces up to two tags:
    /// 1. `<link rel="alternate" type="text/markdown">` — standard HTML alternate
    ///    link pointing to the markdown version of this page (only when markdown exists)
    /// 2. `<script type="application/ld+json">` — JSON-LD with schema.org hierarchy:
    ///    - `isPartOf`: Module-level `llms.txt` index (or parent site)
    ///    - `mainEntity`: Root `llms.txt` index
    ///
    /// - Parameters:
    ///   - markdownURL: The markdown URL for this specific page, or `nil` if none exists
    ///   - module: The documentation module name (e.g., `p256k`), or `nil`
    ///   - baseURL: Site base URL
    /// - Returns: Combined HTML string for injection before `</head>`
    public static func buildDirective(
        markdownURL: URL?,
        module: String?,
        baseURL: URL
    ) throws -> String {
        let globalLlms = baseURL.appendingPathComponent("llms.txt").absoluteString

        let partOf: WebSiteSchema
        if let module {
            let moduleLlms = baseURL
                .appendingPathComponent("data/documentation/\(module)/llms.txt")
                .absoluteString
            partOf = WebSiteSchema(name: "\(module.uppercased()) Module", url: moduleLlms)
        } else {
            partOf = WebSiteSchema(name: baseURL.host, url: baseURL.absoluteString)
        }

        let schema = AgentDirectiveWebPage(
            isPartOf: partOf,
            mainEntity: WebSiteSchema(url: globalLlms)
        )

        var parts: [String] = []

        // 1. Standard <link rel="alternate"> for markdown (when available)
        if let markdownURL {
            parts.append("<link \(alternateMarker) href=\"\(markdownURL.absoluteString)\" />")
        }

        // 2. JSON-LD for site hierarchy
        let json = try SchemaGraph(schema).renderCompact()
        parts.append("<script type=\"application/ld+json\">\(json)</script>")

        return parts.joined(separator: "\n")
    }

    /// Injects agent directive tags into HTML content.
    ///
    /// Inserts up to two tags immediately before `</head>`:
    /// 1. `<link rel="alternate" type="text/markdown">` (when markdown exists)
    /// 2. `<script type="application/ld+json">` (always)
    ///
    /// If a directive already exists (detected by JSON-LD marker, alternate
    /// link marker, or legacy `agent-directive` class), the file is skipped
    /// unless `force` is `true`.
    ///
    /// Uses string manipulation (not DOM parsing) to preserve the original
    /// HTML structure exactly — important for DocC Vue.js apps.
    ///
    /// - Parameters:
    ///   - html: The HTML content
    ///   - directive: The directive tag(s) HTML
    ///   - force: If `true`, replaces an existing directive
    /// - Returns: Tuple of (modified HTML, action taken)
    public static func inject(
        html: String,
        directive: String,
        force: Bool
    ) -> (String, InjectionAction) {
        let hasExisting = html.contains(marker)
        let hasAlternate = html.contains(alternateMarker)
        let hasLegacy = html.contains("class=\"\(legacyMarkerClass)\"")

        if (hasExisting || hasAlternate || hasLegacy) && !force {
            return (html, .skipped)
        }

        var content = html

        // Remove existing JSON-LD directive if forcing
        if hasExisting && force {
            content = removeTag(
                from: content,
                startMarker: marker,
                openTag: "<script",
                closeTag: "</script>"
            )
        }

        // Remove existing <link rel="alternate" type="text/markdown"> if forcing
        if hasAlternate && force {
            content = removeSelfClosingTag(from: content, marker: alternateMarker)
        }

        // Remove legacy <p class="agent-directive"> tag if forcing
        if hasLegacy && force {
            content = removeTag(
                from: content,
                startMarker: "class=\"\(legacyMarkerClass)\"",
                openTag: "<p",
                closeTag: "</p>"
            )
        }

        // Insert before </head>
        guard let headEnd = content.range(of: "</head>", options: .caseInsensitive) else {
            return (html, .failed)
        }

        content.insert(contentsOf: directive + "\n", at: headEnd.lowerBound)
        return (content, .injected)
    }

    /// Removes a self-closing HTML tag (e.g., `<link ... />`) containing a marker string.
    private static func removeSelfClosingTag(from content: String, marker: String) -> String {
        var result = content
        guard let markerRange = result.range(of: marker) else {
            return result
        }

        // Search backward from marker to find the opening <
        let searchBackward = result[result.startIndex..<markerRange.lowerBound]
        guard let openRange = searchBackward.range(of: "<", options: .backwards) else {
            return result
        }

        // Search forward from marker to find the closing /> or >
        let afterMarker = markerRange.upperBound..<result.endIndex
        guard let closeRange = result.range(of: "/>", range: afterMarker)
                ?? result.range(of: ">", range: afterMarker) else {
            return result
        }

        var removeStart = openRange.lowerBound
        var removeEnd = closeRange.upperBound

        // Include surrounding newlines
        if removeStart > result.startIndex {
            let before = result.index(before: removeStart)
            if result[before] == "\n" {
                removeStart = before
            }
        }
        if removeEnd < result.endIndex && result[removeEnd] == "\n" {
            removeEnd = result.index(after: removeEnd)
        }

        result.removeSubrange(removeStart..<removeEnd)
        return result
    }

    /// Removes an HTML tag containing a marker string, including surrounding newlines.
    private static func removeTag(
        from content: String,
        startMarker: String,
        openTag: String,
        closeTag: String
    ) -> String {
        var result = content
        guard let markerRange = result.range(of: startMarker) else {
            return result
        }

        // Search backward from marker to find the opening tag
        let searchBackward = result[result.startIndex..<markerRange.lowerBound]
        guard let openRange = searchBackward.range(of: openTag, options: .backwards) else {
            return result
        }

        // Search forward from marker to find the closing tag
        guard let closeRange = result.range(
            of: closeTag,
            range: markerRange.upperBound..<result.endIndex
        ) else {
            return result
        }

        var removeStart = openRange.lowerBound
        var removeEnd = closeRange.upperBound

        // Include surrounding newlines
        if removeStart > result.startIndex {
            let before = result.index(before: removeStart)
            if result[before] == "\n" {
                removeStart = before
            }
        }
        if removeEnd < result.endIndex && result[removeEnd] == "\n" {
            removeEnd = result.index(after: removeEnd)
        }

        result.removeSubrange(removeStart..<removeEnd)
        return result
    }

    /// Processes all HTML files in a directory, injecting agent directives.
    ///
    /// Only processes `.html` files under `documentation/` subdirectory.
    ///
    /// - Parameters:
    ///   - directoryPath: Path to the output directory
    ///   - baseURL: Site base URL
    ///   - force: If `true`, replaces existing directives
    ///   - dryRun: If `true`, don't modify files
    /// - Returns: An injection report
    public static func injectDirectory(
        at directoryPath: String,
        baseURL: URL,
        force: Bool,
        dryRun: Bool
    ) throws -> InjectionReport {
        let entries = try HTMLFileWalker.findHTMLFiles(
            in: directoryPath,
            pathPrefix: "documentation/"
        )
        var results: [InjectionResult] = []

        for entry in entries {
            do {
                let html = try String(contentsOfFile: entry.absolutePath, encoding: .utf8)
                let mdRelPath = deriveMarkdownRelativePath(from: entry.relativePath)
                let mdLocalPath = (directoryPath as NSString).appendingPathComponent(mdRelPath)
                let markdownURL: URL? = FileManager.default.fileExists(atPath: mdLocalPath)
                    ? deriveMarkdownURL(baseURL: baseURL, relativePath: entry.relativePath)
                    : nil
                let module = extractModule(from: entry.relativePath)
                let directive = try buildDirective(markdownURL: markdownURL, module: module, baseURL: baseURL)

                let (fixedHTML, action) = inject(html: html, directive: directive, force: force)

                if !dryRun && (action == .injected) {
                    try fixedHTML.write(toFile: entry.absolutePath, atomically: true, encoding: .utf8)
                }

                results.append(InjectionResult(
                    filePath: entry.absolutePath,
                    relativePath: entry.relativePath,
                    action: action,
                    errorMessage: nil
                ))
            } catch {
                results.append(InjectionResult(
                    filePath: entry.absolutePath,
                    relativePath: entry.relativePath,
                    action: .failed,
                    errorMessage: error.localizedDescription
                ))
            }
        }

        return InjectionReport(results: results)
    }

    /// Verifies that all documentation HTML files contain an agent directive.
    ///
    /// Detects the current combined format (JSON-LD marker or alternate link),
    /// and also accepts the legacy `<p class="agent-directive">` format.
    ///
    /// - Parameter directoryPath: Path to the output directory
    /// - Returns: Tuple of (total files, files with directive, relative paths of files missing directive)
    public static func verify(
        at directoryPath: String
    ) throws -> (total: Int, present: Int, missing: [String]) {
        let entries = try HTMLFileWalker.findHTMLFiles(
            in: directoryPath,
            pathPrefix: "documentation/"
        )

        var present = 0
        var missing: [String] = []

        for entry in entries {
            let html = try String(contentsOfFile: entry.absolutePath, encoding: .utf8)
            if html.contains(marker)
                || html.contains(alternateMarker)
                || html.contains("class=\"\(legacyMarkerClass)\"") {
                present += 1
            } else {
                missing.append(entry.relativePath)
            }
        }

        return (total: entries.count, present: present, missing: missing)
    }
}
