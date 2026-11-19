//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation
import Testing

/// RFC 9116 `security.txt` shipped under `Resources/<site>/well-known/`.
/// Beyond the format checks, the suite enforces the renewal contract:
/// `Expires` must stay more than 60 days out — when that fails, re-review the
/// file and bump the date (RFC 9116 §2.5.5; a stale file is worse than none).
@Suite("security.txt Tests")
struct SecurityTxtTests {
    private struct Site {
        let directory: String
        let canonicalURL: String
    }

    private let sites: [Site] = [
        Site(directory: "21-dev", canonicalURL: "https://21.dev/.well-known/security.txt"),
        Site(directory: "docs-21-dev", canonicalURL: "https://docs.21.dev/.well-known/security.txt"),
    ]

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func fileURL(for site: Site) -> URL {
        repositoryRoot
            .appendingPathComponent("Resources")
            .appendingPathComponent(site.directory)
            .appendingPathComponent("well-known")
            .appendingPathComponent("security.txt")
    }

    private func fields(in content: String) -> [(name: String, value: String)] {
        content.components(separatedBy: .newlines).compactMap { rawLine in
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#"), let colon = line.firstIndex(of: ":") else {
                return nil
            }
            return (
                name: String(line[..<colon]).lowercased(),
                value: String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            )
        }
    }

    private func fields(for site: Site) throws -> [(name: String, value: String)] {
        fields(in: try String(contentsOf: fileURL(for: site), encoding: .utf8))
    }

    private func headerFileURL(for site: Site, environment: String) -> URL {
        repositoryRoot
            .appendingPathComponent("Resources")
            .appendingPathComponent(site.directory)
            .appendingPathComponent("_headers.\(environment)")
    }

    /// Parses a Cloudflare `_headers` file into `(pattern, headers)` blocks:
    /// a non-indented line starts a rule; indented `Name: value` lines belong to it.
    private func headerRules(in content: String) -> [(pattern: String, headers: [(name: String, value: String)])] {
        var rules: [(pattern: String, headers: [(name: String, value: String)])] = []
        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            if rawLine.first?.isWhitespace == true {
                guard let colon = line.firstIndex(of: ":"), !rules.isEmpty else { continue }
                rules[rules.count - 1].headers.append((
                    name: String(line[..<colon]).lowercased(),
                    value: String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                ))
            } else {
                rules.append((pattern: line, headers: []))
            }
        }
        return rules
    }

    @Test("security.txt exists for every site")
    func filesExist() {
        for site in sites {
            #expect(FileManager.default.fileExists(atPath: fileURL(for: site).path), "\(site.directory) is missing well-known/security.txt")
        }
    }

    @Test("Contact fields carry mailto:, tel:, or https:// URIs")
    func contactFieldsAreURIs() throws {
        for site in sites {
            let contacts = try fields(for: site).filter { $0.name == "contact" }
            #expect(!contacts.isEmpty, "\(site.directory) must declare at least one Contact")
            for contact in contacts {
                #expect(
                    contact.value.hasPrefix("mailto:") || contact.value.hasPrefix("tel:") || contact.value.hasPrefix("https://"),
                    "\(site.directory) Contact is not a mailto:, tel:, or https:// URI: \(contact.value)"
                )
            }
        }
    }

    @Test("Expires appears exactly once and stays more than 60 days out")
    func expiresStaysFresh() throws {
        for site in sites {
            let expires = try fields(for: site).filter { $0.name == "expires" }
            #expect(expires.count == 1, "\(site.directory) must declare Expires exactly once")
            let date = try #require(
                expires.first.flatMap { ISO8601DateFormatter().date(from: $0.value) },
                "\(site.directory) Expires is not a valid RFC 3339 timestamp"
            )
            #expect(
                date.timeIntervalSinceNow > 60 * 24 * 60 * 60,
                "\(site.directory) security.txt expires \(expires[0].value) — re-review the file and renew the date"
            )
            // RFC 9116 §2.5.5 recommends under a year; a far-future typo (e.g.
            // 2037) would arm the renewal alarm for the wrong decade.
            #expect(
                date.timeIntervalSinceNow < 400 * 24 * 60 * 60,
                "\(site.directory) security.txt expires \(expires[0].value) — over a year out; check for a year typo"
            )
        }
    }

    @Test("Canonical fields cover each site's fetch URL")
    func canonicalCoversFetchURL() throws {
        // RFC 9116 §2.5.2 — a file fetched from a URI absent from every
        // Canonical field SHOULD NOT be trusted.
        for site in sites {
            let canonicals = try fields(for: site).filter { $0.name == "canonical" }.map(\.value)
            #expect(canonicals.contains(site.canonicalURL), "\(site.directory) Canonical fields must include \(site.canonicalURL)")
        }
    }

    @Test("Web-URI fields use https://")
    func webURIFieldsUseHTTPS() throws {
        // Contact URIs are covered separately (mailto:/tel: allowed); every
        // other RFC 9116 web-URI field must be https.
        let httpsFields: Set<String> = ["policy", "canonical", "encryption", "acknowledgments", "hiring", "csaf"]
        for site in sites {
            let fileFields = try fields(for: site)
            for field in fileFields where httpsFields.contains(field.name) {
                #expect(field.value.hasPrefix("https://"), "\(site.directory) \(field.name) must be an https:// URI: \(field.value)")
            }
        }
    }

    @Test("Header files pin security.txt to text/plain and well-known to no-store")
    func headerRulesCoverSecurityTxt() throws {
        // Both deployed `_headers` variants must carry the same guarantees the
        // Specs/003 quickstart curl checks assert post-deploy.
        for site in sites {
            for environment in ["dev", "prod"] {
                let rules = try headerRules(in: String(
                    contentsOf: headerFileURL(for: site, environment: environment), encoding: .utf8
                ))
                let wellKnown = rules.filter { $0.pattern == "/.well-known/*" }
                #expect(
                    !wellKnown.isEmpty && wellKnown.allSatisfy {
                        $0.headers.contains { $0.name == "cache-control" && $0.value == "no-store" }
                            && $0.headers.contains { $0.name == "pragma" && $0.value == "no-cache" }
                    },
                    "\(site.directory)/_headers.\(environment) must serve /.well-known/* with Cache-Control: no-store + Pragma: no-cache"
                )
                let securityTxt = rules.filter { $0.pattern == "/.well-known/security.txt" }
                #expect(
                    !securityTxt.isEmpty && securityTxt.allSatisfy {
                        $0.headers.contains { $0.name == "content-type" && $0.value == "text/plain; charset=utf-8" }
                    },
                    "\(site.directory)/_headers.\(environment) must pin Content-Type: text/plain; charset=utf-8 on /.well-known/security.txt"
                )
            }
        }
    }

    @Test("_headers patterns stay within Cloudflare's single-splat limit")
    func headerPatternsStaySingleSplat() throws {
        // Cloudflare allows one `*` per pattern — a second silently matches
        // nothing, which is how `/**/*.json` and `/**/*.md` shipped as dead
        // rules. The splat also matches across `/`, so one is always enough.
        for site in sites {
            for environment in ["dev", "prod"] {
                let rules = try headerRules(in: String(
                    contentsOf: headerFileURL(for: site, environment: environment), encoding: .utf8
                ))
                for rule in rules {
                    let splats = rule.pattern.filter { $0 == "*" }.count
                    #expect(
                        splats <= 1,
                        "\(site.directory)/_headers.\(environment) pattern `\(rule.pattern)` uses \(splats) splats — Cloudflare supports one per rule; extras make it silently match nothing"
                    )
                }
            }
        }
    }

    /// True when a pattern can reach a path under `/.well-known/`. Either the
    /// literal prefix before the first `*`/`:` already sits inside the
    /// namespace, or it's a prefix of `/.well-known/` that a wildcard then
    /// expands across (`/*`, `/.w*`, `/.well-known*`, `/:x/*`…). A
    /// conservative approximation — it may over-flag a lone placeholder —
    /// which is the safe direction for a guard.
    private func reachesWellKnown(_ pattern: String) -> Bool {
        var path = pattern
        if let scheme = path.range(of: "://"),
           let slash = path[scheme.upperBound...].firstIndex(of: "/") {
            path = String(path[slash...])
        }
        let wildcard = path.firstIndex { $0 == "*" || $0 == ":" } ?? path.endIndex
        let literalPrefix = path[path.startIndex..<wildcard]
        return literalPrefix.hasPrefix("/.well-known/")
            || (literalPrefix.count < path.count && "/.well-known/".hasPrefix(literalPrefix))
    }

    @Test("No broad-reach rule carries Cache-Control onto /.well-known/*")
    func broadPatternsCarryNoCacheControl() throws {
        // A pattern whose path part starts with a splat or placeholder also
        // matches `/.well-known/…` — Cache-Control there concatenates with the
        // well-known no-store. Legal single-splat forms like `/*.json`
        // recreate the contradiction the removed /**/*.json guard covered.
        // Exemptions: `/.well-known/*` itself (the other test pins its value
        // to no-store) and 21-dev's dev `/*` catch-all — it sets Cache-Control
        // by design (preview-only trade-off; prod omits it).
        for site in sites {
            for environment in ["dev", "prod"] {
                let rules = try headerRules(in: String(
                    contentsOf: headerFileURL(for: site, environment: environment), encoding: .utf8
                ))
                for rule in rules where reachesWellKnown(rule.pattern) {
                    if rule.pattern == "/.well-known/*"
                        || (site.directory == "21-dev" && environment == "dev" && rule.pattern == "/*") {
                        continue
                    }
                    #expect(
                        !rule.headers.contains { $0.name == "cache-control" },
                        "\(site.directory)/_headers.\(environment) pattern `\(rule.pattern)` reaches /.well-known/* — its Cache-Control would concatenate with no-store"
                    )
                }
            }
        }
    }

    @Test("Policy and Preferred-Languages are present")
    func requiredFieldsPresent() throws {
        // Both fields are required by this spec's design — deleting one from
        // both copies would slip past the drift check, which only compares
        // the files to each other.
        for site in sites {
            let names = try fields(for: site).map(\.name)
            #expect(names.contains("policy"), "\(site.directory) must declare a Policy field")
            #expect(
                names.filter { $0 == "preferred-languages" }.count == 1,
                "\(site.directory) must declare Preferred-Languages exactly once"
            )
        }
        // The primary channel is mail — dropping it while keeping the GitHub
        // Contact would still satisfy "at least one Contact".
        for site in sites {
            let contacts = try fields(for: site).filter { $0.name == "contact" }
            #expect(
                contacts.contains { $0.value.hasPrefix("mailto:") },
                "\(site.directory) must keep a mailto: Contact — the primary reporting channel"
            )
        }
    }

    @Test("Site copies keep identical field sets")
    func fieldSetsDoNotDrift() throws {
        // The per-site files differ only in comments — fields ship identical
        // so a fix on one host can't silently diverge from the other.
        let rendered = try sites.map { site in
            try fields(for: site).map { "\($0.name): \($0.value)" }
        }
        guard let first = rendered.first else { return }
        for other in rendered.dropFirst() {
            #expect(other == first, "security.txt field sets diverged between sites")
        }
    }
}
