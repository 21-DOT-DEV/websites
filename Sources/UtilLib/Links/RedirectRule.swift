//
//  RedirectRule.swift
//  Utilities
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// A single rule parsed from a Cloudflare `_redirects` file.
public struct RedirectRule: Sendable, Equatable {
    /// Source path pattern, e.g. `/docs`, `/p256k/*/index.html`, `/old/:slug`.
    public let source: String

    /// Target path or absolute URL; may embed `:splat` and `:placeholder` references.
    public let target: String

    /// Declared HTTP status; an absent status column parses as `302` (the edge default).
    public let status: Int

    public init(source: String, target: String, status: Int) {
        self.source = source
        self.target = target
        self.status = status
    }

    /// Redirect statuses the edge answers with (`301`, `302`, `303`, `307`, `308`).
    static let redirectStatuses: Set<Int> = [301, 302, 303, 307, 308]

    /// Whether the source contains wildcards — a `*` splat or `:placeholder` references.
    public var isWildcard: Bool {
        source.contains("*")
            || source.range(of: ":[A-Za-z]", options: .regularExpression) != nil
    }

    /// Whether the edge would apply this rule to a matching request.
    ///
    /// A rule applies when both its declared shape is one the edge honors and
    /// it does not re-trigger itself:
    ///
    /// - Shape — mirrors the platform's `PERMITTED_STATUS_CODES` ({200, 301,
    ///   302, 303, 307, 308}): a rule declaring any other status is invalid and
    ///   skipped at the edge, so it grants no exemption and does not consume
    ///   the first-match slot. A `200` proxy additionally requires a
    ///   site-relative target: external proxying is unsupported, so such a
    ///   rule is ignored as well.
    /// - Self-retrigger — a redirect loops when the re-requested target, in
    ///   literal or canonicalized form, matches the source again (`/a/* /a/x`
    ///   and `/* /index.html` in the `3xx` sense both loop). A `200` proxy
    ///   instead fetches its target without re-running `_redirects` (proxying
    ///   is not chained), so it loops only through a *canonical* redirect
    ///   whose destination re-matches — `/a/* /a/x` proxied is fine,
    ///   `/a/* /a/x.html` proxied loops through `/a/x`. A catch-all proxying
    ///   bare `/` is the SPA-shell fallback: it applies to nothing even though
    ///   it cannot loop. A source that fails to compile (more than one `*`)
    ///   can never match either.
    ///
    /// Evaluating this compiles the source per call; use ``RedirectMatcher``
    /// for lookups.
    public var isAppliedByEdge: Bool {
        CompiledRedirectRule(rule: self).appliedByEdge
    }

    /// Whether the declared status and target shape are ones the edge honors —
    /// before the self-retriggering check (``isAppliedByEdge`` adds that).
    var hasApplicableShape: Bool {
        if Self.redirectStatuses.contains(status) { return true }
        return status == 200 && targetIsSiteRelative
    }

    /// Whether the source is a site-wide catch-all (`*` or `/*`) — the shape
    /// that turns a root proxy into an SPA-shell fallback. Sub-tree splats
    /// like `/docs/*` scope to their prefix and are not catch-alls.
    var isCatchAll: Bool {
        source == "*" || source == "/*"
    }

    /// Whether the target is a site-relative path the edge can serve or proxy
    /// (`/`-prefixed, not protocol-relative).
    var targetIsSiteRelative: Bool {
        target.hasPrefix("/") && !target.hasPrefix("//")
    }

    /// The target's literal request path: query and fragment stripped,
    /// percent-decoded, and dot-segments normalized. A target escaping the
    /// root yields `""`, which no real source matches.
    var normalizedLiteralTarget: String {
        var literal = target
        if let cut = literal.firstIndex(where: { $0 == "?" || $0 == "#" }) {
            literal = String(literal[..<cut])
        }
        guard case .ok(let normalized) = InternalLinkChecker.normalizedSitePath(literal) else {
            return ""
        }
        return normalized
    }

    /// The URL form the edge actually serves the target at:
    /// ``normalizedLiteralTarget`` plus canonical index stripping
    /// (`x/index.html` → `x/`, `x/index` → `x/`, `x.html` → `x`).
    var servedTargetPath: String {
        var served = normalizedLiteralTarget
        if served.hasSuffix("/index.html") {
            served = String(served.dropLast("index.html".count))
        } else if served.hasSuffix("/index") {
            served = String(served.dropLast("index".count))
        } else if served.hasSuffix(".html") {
            served = String(served.dropLast(".html".count))
        }
        return served
    }
}

/// Captured wildcard values from a matched `_redirects` source.
public struct RedirectMatch: Sendable, Equatable {
    /// Value captured by the source's `*` splat, if present.
    public let splat: String?

    /// Values captured by `:placeholder` references, keyed by placeholder name.
    public let placeholders: [String: String]

    public init(splat: String?, placeholders: [String: String]) {
        self.splat = splat
        self.placeholders = placeholders
    }
}

/// A `_redirects` source pattern compiled for matching.
///
/// Cloudflare source syntax: a single `*` splat greedily matching any characters
/// anywhere in the path (compiled to `.*`), and `:placeholder` references —
/// `:[A-Za-z]\w*` — each matching exactly one path segment (`[^/]+`). Everything
/// else is literal text. A source with more than one splat is invalid and never
/// matches.
struct CompiledRedirectRule: Sendable {
    let rule: RedirectRule
    fileprivate let regex: NSRegularExpression?
    fileprivate let splatGroup: Int?
    fileprivate let namedGroups: [String: Int]

    /// Compiles a rule's source into a matchable pattern, or `nil` when the
    /// source is invalid (more than one `*` splat).
    init(rule: RedirectRule) {
        self.rule = rule
        var pattern = "\\A"
        var group = 0
        var splatGroup: Int? = nil
        var namedGroups: [String: Int] = [:]
        var splatCount = 0
        var isValid = true

        var index = rule.source.startIndex
        while index < rule.source.endIndex, isValid {
            let character = rule.source[index]
            if character == "*" {
                splatCount += 1
                guard splatCount == 1 else {
                    isValid = false
                    break
                }
                group += 1
                splatGroup = group
                pattern += "(.*)"
                index = rule.source.index(after: index)
            } else if character == ":",
                      let nameStart = rule.source.index(index, offsetBy: 1, limitedBy: rule.source.endIndex),
                      nameStart < rule.source.endIndex,
                      isPlaceholderStart(rule.source[nameStart]) {
                var nameEnd = nameStart
                while nameEnd < rule.source.endIndex, isPlaceholderCharacter(rule.source[nameEnd]) {
                    nameEnd = rule.source.index(after: nameEnd)
                }
                group += 1
                namedGroups[String(rule.source[nameStart..<nameEnd])] = group
                pattern += "([^/]+)"
                index = nameEnd
            } else {
                pattern += NSRegularExpression.escapedPattern(for: String(character))
                index = rule.source.index(after: index)
            }
        }
        pattern += "\\z"

        func matches(_ path: String, in compiled: NSRegularExpression) -> Bool {
            let range = NSRange(path.startIndex..., in: path)
            return compiled.firstMatch(in: path, range: range) != nil
        }

        let refused: Bool
        if isValid, let compiled = try? NSRegularExpression(pattern: pattern) {
            self.regex = compiled
            self.splatGroup = splatGroup
            self.namedGroups = namedGroups
            if rule.targetIsSiteRelative {
                let literal = rule.normalizedLiteralTarget
                let canonical = rule.servedTargetPath
                if rule.status == 200 {
                    // A proxy target is fetched without re-running _redirects,
                    // so the only loop runs through a canonical redirect whose
                    // destination re-matches the source — plus the catch-all
                    // root proxy, which is the SPA shell the checker refuses.
                    refused = (canonical != literal && matches(canonical, in: compiled))
                        || (rule.isCatchAll && literal == "/")
                } else {
                    // A redirect loops when the re-requested target — literal
                    // or canonicalized — matches the source again.
                    refused = matches(literal, in: compiled) || matches(canonical, in: compiled)
                }
            } else {
                refused = false
            }
        } else {
            self.regex = nil
            self.splatGroup = nil
            self.namedGroups = [:]
            refused = false
        }
        self.refusedLoop = refused
        self.appliedByEdge = rule.hasApplicableShape && !refused && self.regex != nil
    }

    /// Whether the rule's served target URL re-matches its own source — the
    /// edge refuses such self-retriggering rules (e.g. `/* /index.html 200`).
    let refusedLoop: Bool

    /// Whether the edge would apply this rule — cached at compile time so a
    /// ``RedirectMatcher`` never re-evaluates it per request path.
    let appliedByEdge: Bool

    /// Matches a site-relative path, returning captured wildcard values on success.
    func match(sitePath: String) -> RedirectMatch? {
        guard let regex else { return nil }
        let range = NSRange(sitePath.startIndex..., in: sitePath)
        guard let result = regex.firstMatch(in: sitePath, range: range) else { return nil }

        var splat: String? = nil
        if let splatGroup, let capturedRange = Range(result.range(at: splatGroup), in: sitePath) {
            splat = String(sitePath[capturedRange])
        }
        var placeholders: [String: String] = [:]
        for (name, group) in namedGroups {
            if let capturedRange = Range(result.range(at: group), in: sitePath) {
                placeholders[name] = String(sitePath[capturedRange])
            }
        }
        return RedirectMatch(splat: splat, placeholders: placeholders)
    }
}

/// Whether a character can start a placeholder name (`:[A-Za-z]…`).
private func isPlaceholderStart(_ character: Character) -> Bool {
    character.isASCII && character.isLetter
}

/// Whether a character can continue a placeholder name (`\w` — ASCII word chars).
private func isPlaceholderCharacter(_ character: Character) -> Bool {
    character.isASCII && (character.isLetter || character.isNumber || character == "_")
}

/// A `_redirects` rule set compiled once and queried per request path.
///
/// Matching evaluates rules in file order; rules the edge would ignore
/// (`isAppliedByEdge == false`) never consume the first-match slot.
///
/// Known modeling limitation: Cloudflare advises placing static rules before
/// dynamic ones and applies separate per-kind limits, which hints at a
/// static-first lookup the docs never state as precedence. Both shipped
/// `_redirects` files already order static-first, so file-order matching —
/// the documented "top-most match is applied" — is used unconditionally.
public struct RedirectMatcher: Sendable {
    private let rules: [CompiledRedirectRule]

    public init(rules: [RedirectRule]) {
        self.rules = rules.map(CompiledRedirectRule.init(rule:))
    }

    /// The first rule in file order that both matches the path and would be
    /// applied by the edge, with its captured wildcard values.
    ///
    /// - Parameter sitePath: Path relative to site root, starting with `/`.
    /// - Returns: The governing rule and its match, or `nil` when no applied
    ///   rule matches — the edge would then serve whatever is on disk.
    public func firstAppliedMatch(sitePath: String) -> (rule: RedirectRule, match: RedirectMatch)? {
        for compiled in rules where compiled.appliedByEdge {
            if let match = compiled.match(sitePath: sitePath) {
                return (compiled.rule, match)
            }
        }
        return nil
    }
}

/// Parses Cloudflare `_redirects` files and matches request paths against rule sources.
///
/// Format: `source target [status]`, one per line; `#` starts a comment. A line
/// that does not follow the format is ignored, mirroring the edge. Sources may
/// contain one `*` splat (matching any characters anywhere in the path) and
/// `:placeholder` references (each matching exactly one path segment).
public enum RedirectsParser {

    /// Parses `_redirects` file contents into rules, skipping blank lines,
    /// comments, and malformed lines (wrong field count or non-numeric status).
    /// - Parameter contents: Raw file contents.
    /// - Returns: Parsed rules in file order.
    public static func parse(_ contents: String) -> [RedirectRule] {
        contents
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { rawLine -> RedirectRule? in
                let line = rawLine.trimmingCharacters(in: .whitespaces)
                guard !line.isEmpty, !line.hasPrefix("#") else { return nil }
                let fields = line.split(whereSeparator: { $0.isWhitespace })
                guard fields.count == 2 || fields.count == 3 else { return nil }
                // Cloudflare defaults to 302 when no status column is present;
                // a non-numeric column makes the line invalid.
                guard let status = fields.count == 3 ? Int(fields[2]) : 302 else { return nil }
                return RedirectRule(
                    source: String(fields[0]),
                    target: String(fields[1]),
                    status: status
                )
            }
    }

    /// Loads and parses `_redirects` from a site output directory, if present.
    /// - Parameter directory: Site output root.
    /// - Returns: Parsed rules plus a warning when the file exists but cannot be
    ///   read — an unreadable file must not be silently treated as zero rules,
    ///   since lost exemptions surface as unexplained broken links.
    public static func loadRules(from directory: String) -> (rules: [RedirectRule], warning: String?) {
        let path = (directory as NSString).appendingPathComponent("_redirects")
        guard FileManager.default.fileExists(atPath: path) else { return ([], nil) }
        do {
            return (parse(try String(contentsOfFile: path, encoding: .utf8)), nil)
        } catch {
            return ([], "_redirects could not be read: \(error.localizedDescription)")
        }
    }

    /// Whether a site-relative request path matches the rule's source pattern.
    /// - Parameters:
    ///   - rule: The rule whose source is matched.
    ///   - sitePath: Path relative to site root, always starting with `/`.
    /// - Returns: `true` when the source pattern matches the path.
    public static func matches(_ rule: RedirectRule, sitePath: String) -> Bool {
        match(rule, sitePath: sitePath) != nil
    }

    /// Matches a site-relative path against the rule's source, returning captures.
    /// - Parameters:
    ///   - rule: The rule whose source is matched.
    ///   - sitePath: Path relative to site root, always starting with `/`.
    /// - Returns: Captured splat and placeholder values, or `nil` on no match.
    public static func match(_ rule: RedirectRule, sitePath: String) -> RedirectMatch? {
        CompiledRedirectRule(rule: rule).match(sitePath: sitePath)
    }

    /// Builds a matcher that precompiles every rule for repeated lookups.
    /// - Parameter rules: Parsed rules, in file order.
    /// - Returns: A ``RedirectMatcher`` evaluating rules in file order.
    public static func compiledMatcher(rules: [RedirectRule]) -> RedirectMatcher {
        RedirectMatcher(rules: rules)
    }

    /// Substitutes `:splat` and `:placeholder` references in a target string.
    /// - Parameters:
    ///   - target: The rule's target, e.g. `/documentation/p256k/:splat/`.
    ///   - match: Captured values from ``match(_:sitePath:)``.
    /// - Returns: The target with known references replaced; unknown references
    ///   are left untouched. `:splat` resolves only against the `*` capture —
    ///   a source placeholder literally named `splat` is a named capture, so
    ///   a rule with no `*` leaves the reference literal.
    public static func substitute(_ target: String, with match: RedirectMatch) -> String {
        var result = ""
        var index = target.startIndex
        while index < target.endIndex {
            if target[index] == ":",
               let nameStart = target.index(index, offsetBy: 1, limitedBy: target.endIndex),
               nameStart < target.endIndex,
               isPlaceholderStart(target[nameStart]) {
                var nameEnd = nameStart
                while nameEnd < target.endIndex, isPlaceholderCharacter(target[nameEnd]) {
                    nameEnd = target.index(after: nameEnd)
                }
                let name = String(target[nameStart..<nameEnd])
                if let value = name == "splat" ? match.splat : match.placeholders[name] {
                    result += value
                    index = nameEnd
                    continue
                }
            }
            result.append(target[index])
            index = target.index(after: index)
        }
        return result
    }
}
