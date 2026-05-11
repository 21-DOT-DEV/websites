//
//  IndexabilityAuditor.swift
//  UtilLib
//
//  Copyright (c) 2026 Timechain Software Initiative, Inc.
//  Distributed under the MIT software license
//
//  See the accompanying file LICENSE for information
//

import Foundation

/// Hybrid-policy indexability auditor for DocC sidecar pages.
///
/// Walks DocC-emitted JSON sidecars under one or more archive roots, applies
/// the project's hybrid prose-based policy, and reports which pages are
/// **eligible** for the search-engine index (i.e., should NOT receive a
/// `<meta name="robots" content="noindex">` tag) versus which are already
/// covered by the registry's `indexablePages` allowlist.
///
/// This is the canonical implementation of the audit recipe documented on
/// `AgentDirectiveInjector.indexablePages`. It replaces the prior
/// `Tools/audit_prose_pages.py` shim, keeping a single source of truth in
/// Swift.
///
/// ## Hybrid Indexing Policy
///
/// A symbol page is eligible when **any** of these hold:
///
/// 1. **Type page** (`Structure` / `Enumeration` / `Class` / `Protocol` /
///    `Type Alias` / `Actor`) with `## Overview` ≥ 200 chars of authored prose.
/// 2. **Method page** (`Instance Method` / `Type Method` / `Initializer` /
///    `Operator` / `Subscript` / `Instance Property` / `Type Property` /
///    `Case`) with `## Discussion` ≥ 300 chars.
/// 3. **Aside-bearing** page with at least one authored aside callout AND
///    `## Discussion` ≥ 100 chars.
///
/// Char counts come from the top-level `abstract` plus every
/// `primaryContentSections[]` entry with `kind == "content"` (e.g. Return
/// Value, Discussion, Overview), flattened to plain text with code listings
/// excluded. Reading only the first content section would pick the short
/// Return Value block and miss the long Discussion that follows — a subtle
/// undercount that historically inflated the stale-entry count.
///
/// Articles (`metadata.symbolKind == nil`) are NOT type-checked here — they
/// are hand-curated via per-module `llms.txt` files instead.
///
/// ## Project-specific exclusions
///
/// - `documentation/zkp/<symbol>/...` (excluding the two ZKP-unique authored
///   articles) re-exports P256K and stays `noindex` for SEO de-duplication.
/// - `documentation/tor/controlprotocolparser/...` and
///   `documentation/tor/controlsocket/...` are internal protocol plumbing and
///   stay `noindex`. (Tor's `Foundation/URLSessionConfiguration/*` extensions
///   are user-facing per the package's README and remain indexable.)
///
/// These defaults live on `defaultModuleExclusions` and may be overridden per
/// call.
public enum IndexabilityAuditor {

    // MARK: - Hybrid Policy Constants

    /// Minimum char count of `## Overview` content for a type page to be
    /// considered authored-enough to warrant indexing.
    public static let typeOverviewMinChars: Int = 200

    /// Minimum char count of `## Discussion` content for a method page.
    public static let methodDiscussionMinChars: Int = 300

    /// Minimum char count of `## Discussion` content when the page bears at
    /// least one authored aside callout (Note / Warning / Tip / Important).
    public static let asideDiscussionMinChars: Int = 100

    /// Minimum char count of authored prose on a **Framework / Module**
    /// landing page. Module landings carry long-form project overviews by
    /// nature (README-style content, installation, architecture summary),
    /// so the bar is set higher than per-type Overviews to avoid trivial
    /// stub landings slipping into the allowlist.
    public static let frameworkOverviewMinChars: Int = 500

    /// Maximum char-gap below a role-bucket threshold to surface as a
    /// near-miss **candidate** for editorial improvement.
    ///
    /// A candidate is a page that FAILS the hybrid policy but sits within
    /// this many chars of its (most-achievable) threshold. The intent is to
    /// flag the cheapest editorial wins — pages roughly one authored
    /// sentence away from eligibility — so maintainers can spend a minute
    /// of doc-comment effort to convert a `noindex` page into an indexed
    /// one.
    ///
    /// ## Rationale for the default (50)
    ///
    /// There is **no authoritative industry source** for this threshold:
    ///
    /// - Google's Helpful Content guidance explicitly lists *"writing to a
    ///   particular word count"* as a RED FLAG, not a target.
    /// - Apple's Style Guide and Xcode's *Writing Documentation* page don't
    ///   prescribe minimum Discussion lengths.
    ///
    /// The 50-char default is a heuristic with two grounding signals:
    ///
    /// 1. **Mental model**: 50 chars ≈ 8–9 English words ≈ one short
    ///    authored sentence. That's the unit of doc-comment improvement a
    ///    maintainer can realistically add on the spot.
    /// 2. **Empirical sampling** across the 5 archives (p256k, openssl,
    ///    event, tor, zkp) yielded roughly 46 candidates at gap ≤ 50,
    ///    73 at gap ≤ 75, and 93 at gap ≤ 100. 50 surfaces an actionable
    ///    batch without overwhelming review effort.
    ///
    /// Override per call (e.g., `auditModule(... candidateMaxGap: 100)`) or
    /// at the CLI (`util agent-directive audit --candidate-gap 100`) when a
    /// wider or narrower net is wanted.
    public static let candidateMaxGapChars: Int = 50

    /// DocC `metadata.roleHeading` values that classify a page as a "type page".
    public static let typeRoleHeadings: Set<String> = [
        "Structure", "Enumeration", "Class", "Protocol", "Type Alias", "Actor",
    ]

    /// DocC `metadata.roleHeading` values that classify a page as a "method page".
    public static let methodRoleHeadings: Set<String> = [
        "Instance Method", "Type Method", "Initializer", "Operator", "Subscript",
        "Instance Property", "Type Property", "Case",
    ]

    /// DocC `metadata.roleHeading` values that classify a page as a module
    /// landing. `Framework` is emitted by Swift-DocC for Swift package
    /// modules; `Module` appears for Objective-C / language-agnostic
    /// builds. Both are top-level hub pages carrying README-style authored
    /// prose.
    public static let frameworkRoleHeadings: Set<String> = [
        "Framework", "Module",
    ]

    /// Default per-module path prefixes excluded from auditing. Pages under
    /// any of these prefixes never appear in audit results, even when they
    /// satisfy the hybrid policy.
    ///
    /// - **zkp**: All `documentation/zkp/` symbol pages are P256K re-exports
    ///   and stay `noindex` for SEO de-duplication. (The two ZKP-unique
    ///   authored articles — `documentation/zkp` and
    ///   `documentation/zkp/choosingp256kvszkp` — don't have `symbolKind`
    ///   set and are filtered out earlier; they're hand-curated via
    ///   `external-archives.json`'s `indexablePages`.)
    /// - **tor**: Internal control-protocol plumbing trees stay `noindex`.
    ///   `Foundation/URLSessionConfiguration/*` extensions remain indexable
    ///   per the swift-tor README's user-facing API surface.
    public static let defaultModuleExclusions: [String: [String]] = [
        "zkp": [
            "documentation/zkp/",
        ],
        "tor": [
            "documentation/tor/controlprotocolparser/",
            "documentation/tor/controlsocket/",
        ],
    ]

    // MARK: - Public Types

    /// One symbol page that satisfies the hybrid policy.
    public struct EligiblePage: Sendable, Equatable, Hashable {
        /// Canonical URL form (e.g., `documentation/p256k/p256k/signing`).
        public let path: String
        /// Human-readable explanation of why the page qualified
        /// (e.g., `type:Structure:overview=243`).
        public let reason: String

        public init(path: String, reason: String) {
            self.path = path
            self.reason = reason
        }
    }

    /// One allowlist entry that no longer satisfies the hybrid policy.
    ///
    /// SEO-relevant: stale entries appear in the sitemap and are crawled by
    /// search engines despite being thin-content pages. Helpful Content
    /// signals demote whole domains over time when too many thin pages
    /// accumulate, so stale-entry detection is the higher-priority drift
    /// direction (vs. newly-discovered pages, which are merely missing from
    /// the index).
    public struct StaleEntry: Sendable, Equatable, Hashable {
        /// Canonical URL form already in the registry's `indexablePages`.
        public let path: String
        /// Human-readable explanation of why the page no longer qualifies
        /// (e.g., `type:Structure:overview=87 (need ≥200)`).
        public let reason: String

        public init(path: String, reason: String) {
            self.path = path
            self.reason = reason
        }
    }

    /// One symbol page that FAILS the hybrid policy but sits within
    /// `candidateMaxGapChars` of its most-achievable threshold.
    ///
    /// Editorial signal: "add ~1 sentence of authored prose and this page
    /// becomes eligible for search indexing." Candidates are informational
    /// only — they do NOT constitute drift (`AuditReport.hasGap` is
    /// unaffected) and do NOT flip `--strict` exit codes. Only pages NOT
    /// in the current allowlist are surfaced as candidates; in-allowlist
    /// failures remain classified as `StaleEntry` (same shape, different
    /// recommended action).
    public struct CandidateEntry: Sendable, Equatable, Hashable {
        /// Canonical URL form (e.g., `documentation/p256k/p256k/signing/privatekey/publickey`).
        public let path: String
        /// Human-readable explanation of the near-miss
        /// (e.g., `method:Instance Property:disc=297 (gap=3 to ≥300)`).
        public let reason: String
        /// Chars the page needs to gain on its most-achievable threshold
        /// to become eligible. Always in `1...candidateMaxGapChars`.
        public let gap: Int

        public init(path: String, reason: String, gap: Int) {
            self.path = path
            self.reason = reason
            self.gap = gap
        }
    }

    /// One article-shape DocC page (`role == "article"`, no `symbolKind`) that
    /// is NOT in the current `indexablePages` allowlist.
    ///
    /// Articles are hand-curated — they live in per-module `llms.txt` files
    /// and the corresponding registry allowlist, NOT in the policy-gated
    /// symbol audit. This bucket exists to surface the *drift signal* (the
    /// archive shipped a new article that hasn't been added to the registry
    /// yet) so future bumps don't silently noindex newly-shipped prose.
    ///
    /// Informational only: `newArticles` does NOT contribute to
    /// `AuditReport.hasGap` and never flips `--strict` exit codes. The
    /// editorial decision (add to `indexablePages` + write a `## Documentation`
    /// bullet) stays with the maintainer.
    public struct ArticleEntry: Sendable, Equatable, Hashable {
        /// Canonical URL form (e.g., `documentation/event/asynctcpserverinswift`).
        public let path: String
        /// Approximate authored char count from `primaryContentSections`,
        /// shown so maintainers can prioritize long-form prose over stubs.
        public let chars: Int
        /// `metadata.title` from the DocC sidecar, or `"?"` when missing.
        public let title: String

        public init(path: String, chars: Int, title: String) {
            self.path = path
            self.chars = chars
            self.title = title
        }
    }

    /// Result of evaluating a single allowlist entry against the hybrid policy.
    public enum AllowlistStatus: Sendable, Equatable {
        /// Sidecar exists, is a symbol page, AND passes the hybrid policy.
        case eligible(EligiblePage)
        /// Sidecar exists, is a symbol page, BUT fails the hybrid policy.
        /// SEO-relevant drift signal — page should be removed from the allowlist.
        case stale(StaleEntry)
        /// Cannot apply policy: no sidecar, article (no `symbolKind`), or path
        /// outside the archive root. NOT a drift signal — these entries are
        /// hand-curated (llms.txt, hubs).
        case outOfScope(String)
    }

    /// Audit result for a single module.
    public struct ModuleReport: Sendable, Equatable {
        /// Module name (e.g., `"p256k"`, `"tor"`).
        public let module: String
        /// All eligible pages discovered, sorted by path.
        public let eligible: [EligiblePage]
        /// Subset of `eligible` already in the current allowlist.
        public let alreadyAllowed: [EligiblePage]
        /// Subset of `eligible` NOT in the current allowlist (the "newly
        /// discovered" gap — missing-good entries).
        public let newlyDiscovered: [EligiblePage]
        /// Allowlist entries that exist on disk as symbol pages but no longer
        /// satisfy the hybrid policy (the "stale" gap — indexed-but-thin).
        /// Empty by default for backward compatibility with callers that
        /// don't populate this field.
        public let staleEntries: [StaleEntry]
        /// Pages NOT in the allowlist that fail policy but are within
        /// `candidateMaxGapChars` of their most-achievable threshold — the
        /// cheapest editorial wins. Informational only; does NOT contribute
        /// to `AuditReport.hasGap`.
        public let candidates: [CandidateEntry]
        /// Article-shape DocC pages discovered in the archive but NOT in the
        /// allowlist. Editorial drift signal — articles are hand-curated, so
        /// the auditor never auto-adds, but it must surface drift so the next
        /// bump PR can decide whether to add a Documentation bullet. Like
        /// `candidates`, this bucket is informational only and does NOT
        /// contribute to `AuditReport.hasGap`.
        public let newArticles: [ArticleEntry]

        public init(
            module: String,
            eligible: [EligiblePage],
            alreadyAllowed: [EligiblePage],
            newlyDiscovered: [EligiblePage],
            staleEntries: [StaleEntry] = [],
            candidates: [CandidateEntry] = [],
            newArticles: [ArticleEntry] = []
        ) {
            self.module = module
            self.eligible = eligible
            self.alreadyAllowed = alreadyAllowed
            self.newlyDiscovered = newlyDiscovered
            self.staleEntries = staleEntries
            self.candidates = candidates
            self.newArticles = newArticles
        }
    }

    /// Aggregated audit result across all modules.
    public struct AuditReport: Sendable, Equatable {
        public let modules: [ModuleReport]

        public init(modules: [ModuleReport]) {
            self.modules = modules
        }

        public var totalEligible: Int {
            modules.reduce(0) { $0 + $1.eligible.count }
        }

        public var totalNewlyDiscovered: Int {
            modules.reduce(0) { $0 + $1.newlyDiscovered.count }
        }

        public var totalStaleEntries: Int {
            modules.reduce(0) { $0 + $1.staleEntries.count }
        }

        /// Total near-miss candidates across all modules. Informational —
        /// candidate counts never affect `hasGap` or CI-strict exit codes.
        public var totalCandidates: Int {
            modules.reduce(0) { $0 + $1.candidates.count }
        }

        /// Total newly-discovered articles across all modules. Editorial
        /// drift signal — like `totalCandidates`, never affects `hasGap`
        /// or CI-strict exit codes (articles are hand-curated).
        public var totalNewArticles: Int {
            modules.reduce(0) { $0 + $1.newArticles.count }
        }

        /// Bidirectional drift signal: true when the registry doesn't match
        /// reality in either direction (newly-eligible pages missing from
        /// the allowlist, OR allowlist entries that no longer pass policy).
        ///
        /// Near-miss candidates are explicitly excluded — they're editorial
        /// polish, not drift, and must not flip `--strict` exit codes on
        /// every CI run.
        public var hasGap: Bool {
            totalNewlyDiscovered > 0 || totalStaleEntries > 0
        }
    }

    /// Errors raised by the auditor.
    public enum AuditError: Error, CustomStringConvertible {
        case archivesRootMissing(URL)
        case noModulesFound(URL)

        public var description: String {
            switch self {
            case .archivesRootMissing(let url):
                return "IndexabilityAuditor: archives root not found at \(url.path)"
            case .noModulesFound(let url):
                return "IndexabilityAuditor: no module subdirectories found under \(url.path)"
            }
        }
    }

    // MARK: - Sidecar JSON Shape (audit-only fields)

    /// Minimal Decodable shape covering ONLY the fields needed for the audit.
    /// Independent of `DocCSidecar` (which is shaped for schema rendering and
    /// does not need `roleHeading` or `primaryContentSections`).
    private struct AuditSidecar: Decodable {
        struct Metadata: Decodable {
            let roleHeading: String?
            let symbolKind: String?
            /// DocC's high-level page classification (`"article"`, `"symbol"`,
            /// `"collectionGroup"`, etc.). Used by `evaluateArticle(...)` to
            /// distinguish hand-curated articles from auto-generated landings.
            let role: String?
            /// Human-readable page title, shown in article-drift output.
            let title: String?
        }
        let metadata: Metadata?
    }

    // MARK: - Public API

    /// Evaluate one DocC sidecar's bytes against the hybrid policy.
    ///
    /// - Parameters:
    ///   - data: Raw JSON bytes of the DocC sidecar.
    ///   - canonicalPath: Canonical URL form (e.g.,
    ///     `documentation/p256k/p256k/signing`) — written into the returned
    ///     `EligiblePage.path` if eligible.
    /// - Returns: An `EligiblePage` when the page qualifies, otherwise `nil`.
    /// - Throws: Re-throws JSON parse errors (corrupt sidecar).
    public static func evaluate(sidecarData data: Data, canonicalPath: String) throws -> EligiblePage? {
        // Decode shaped portion (metadata) for fast fail on non-symbol pages.
        let shaped = try JSONDecoder().decode(AuditSidecar.self, from: data)
        guard let meta = shaped.metadata, meta.symbolKind != nil, let heading = meta.roleHeading else {
            return nil  // Articles, missing metadata, etc.
        }

        // For prose-traversal we use JSONSerialization (the content tree is
        // recursive with mixed types and not worth a full Decodable model).
        guard let any = try? JSONSerialization.jsonObject(with: data, options: []),
              let root = any as? [String: Any] else {
            return nil
        }
        let chars = authoredCharCount(root: root)
        let sections = root["primaryContentSections"] as? [[String: Any]] ?? []
        let aside = sectionsContainAside(sections)

        // Framework / Module landings: tried first because `Framework` is NOT
        // in `typeRoleHeadings` and would otherwise fall through to stale.
        if frameworkRoleHeadings.contains(heading), chars >= frameworkOverviewMinChars {
            return EligiblePage(path: canonicalPath, reason: "framework:\(heading):overview=\(chars)")
        }
        if typeRoleHeadings.contains(heading), chars >= typeOverviewMinChars {
            return EligiblePage(path: canonicalPath, reason: "type:\(heading):overview=\(chars)")
        }
        if methodRoleHeadings.contains(heading), chars >= methodDiscussionMinChars {
            return EligiblePage(path: canonicalPath, reason: "method:\(heading):disc=\(chars)")
        }
        if aside, chars >= asideDiscussionMinChars {
            return EligiblePage(path: canonicalPath, reason: "aside:\(heading):disc=\(chars)")
        }
        return nil
    }

    /// Evaluate one allowlist entry against the hybrid policy.
    ///
    /// Resolves the canonical path to a sidecar file and classifies the
    /// entry into one of three buckets:
    ///
    /// - `.eligible(EligiblePage)` — sidecar is a symbol page that passes policy
    /// - `.stale(StaleEntry)` — sidecar is a symbol page that fails policy,
    ///   OR the sidecar is missing entirely (page deleted/renamed upstream)
    /// - `.outOfScope(reason)` — article, bare-root hub, or path outside the root
    ///
    /// The `.stale` case is the SEO-relevant drift signal: the registry says
    /// this page should be indexed, but either the authored prose has fallen
    /// below the policy thresholds OR the upstream archive no longer contains
    /// the page at all. Helpful Content systems penalize domains with too
    /// many thin-content pages in the sitemap, and dead URLs in the sitemap
    /// surface as 404s to crawlers.
    ///
    /// - Parameters:
    ///   - allowlistPath: Canonical URL form (e.g., `documentation/p256k/foo`).
    ///   - archivesRoot: Same archives root used by `auditModule(...)`.
    /// - Returns: An `AllowlistStatus` describing the entry's relationship
    ///   to the hybrid policy.
    /// - Throws: Re-throws unrecoverable filesystem errors (the common
    ///   "file not found" case is mapped to `.outOfScope` instead of throwing).
    public static func evaluateAllowlistEntry(
        allowlistPath: String,
        archivesRoot: URL
    ) throws -> AllowlistStatus {
        // Resolve canonical URL form -> sidecar file URL.
        let prefix = archivesRoot.lastPathComponent + "/"  // e.g. "documentation/"
        guard allowlistPath.hasPrefix(prefix) else {
            return .outOfScope("path does not start with '\(prefix)'")
        }
        let relative = String(allowlistPath.dropFirst(prefix.count))
        if relative.isEmpty {
            return .outOfScope("bare root landing page (no sidecar)")
        }
        let sidecarURL = archivesRoot.appendingPathComponent(relative + ".json")

        guard FileManager.default.fileExists(atPath: sidecarURL.path) else {
            // Missing sidecar at a non-bare-root path means the upstream
            // archive no longer contains this page — typically a
            // renamed/deleted symbol (e.g., a method whose signature gained
            // a new parameter, retiring the old canonical URL). Bare-root
            // hubs (`documentation/<module>`) are handled earlier via the
            // `relative.isEmpty` branch and stay outOfScope.
            return .stale(StaleEntry(
                path: allowlistPath,
                reason: "no sidecar at \(sidecarURL.lastPathComponent) (deleted or renamed upstream)"
            ))
        }
        let data: Data
        do {
            data = try Data(contentsOf: sidecarURL)
        } catch {
            return .outOfScope("unreadable sidecar: \(error.localizedDescription)")
        }

        // Decode the metadata-only shape first to distinguish symbols from articles.
        let shaped: AuditSidecar
        do {
            shaped = try JSONDecoder().decode(AuditSidecar.self, from: data)
        } catch {
            return .outOfScope("malformed sidecar JSON")
        }
        guard let meta = shaped.metadata else {
            return .outOfScope("sidecar missing metadata block")
        }
        guard meta.symbolKind != nil, let heading = meta.roleHeading else {
            // Articles, landings, collections — hand-curated, not policy-eligible.
            return .outOfScope("article / landing page (no symbolKind)")
        }

        // Try the eligibility path first.
        if let page = try evaluate(sidecarData: data, canonicalPath: allowlistPath) {
            return .eligible(page)
        }

        // Symbol page that failed all policy rules — STALE.
        let parsed = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] ?? [:]
        let chars = authoredCharCount(root: parsed)
        let sections = parsed["primaryContentSections"] as? [[String: Any]] ?? []
        let aside = sectionsContainAside(sections)

        // Report the most-achievable threshold for the reader. For a
        // method page with an aside callout and chars below both
        // thresholds, the aside bucket (≥100) is closer than the method
        // bucket (≥300) — surface the actionable target.
        let reason: String
        if frameworkRoleHeadings.contains(heading) {
            reason = "framework:\(heading):overview=\(chars) (need ≥\(frameworkOverviewMinChars))"
        } else if typeRoleHeadings.contains(heading) {
            reason = "type:\(heading):overview=\(chars) (need ≥\(typeOverviewMinChars))"
        } else if methodRoleHeadings.contains(heading) {
            if aside {
                reason = "aside:\(heading):disc=\(chars) (need ≥\(asideDiscussionMinChars))"
            } else {
                reason = "method:\(heading):disc=\(chars) (need ≥\(methodDiscussionMinChars))"
            }
        } else {
            reason = "\(heading):chars=\(chars) (failed hybrid policy thresholds)"
        }
        return .stale(StaleEntry(path: allowlistPath, reason: reason))
    }

    /// Evaluate one DocC sidecar for near-miss candidacy.
    ///
    /// Returns a `CandidateEntry` iff **all** of these hold:
    ///
    /// 1. The sidecar is a symbol page (`metadata.symbolKind != nil`).
    /// 2. The page FAILS the hybrid policy (not currently eligible).
    /// 3. The gap between its authored char count and its most-achievable
    ///    role-bucket threshold is `1...maxGap`.
    ///
    /// Pages that already pass policy (gap ≤ 0) return `nil` — they're
    /// already indexable. Pages with gap > `maxGap` also return `nil` —
    /// their thin content is far enough from threshold that a one-sentence
    /// fix isn't realistic, so they're not surfaced as low-cost editorial
    /// wins.
    ///
    /// The reported threshold is the MOST ACHIEVABLE one for the page's
    /// role, mirroring `evaluate`'s bucket-selection order:
    ///
    /// - `framework:Framework:overview=X (gap=N to ≥500)` — Framework / Module
    /// - `type:Structure:overview=X (gap=N to ≥200)` — type pages
    /// - `aside:Initializer:disc=X (gap=N to ≥100)` — method page WITH aside
    /// - `method:Instance Method:disc=X (gap=N to ≥300)` — method page without aside
    ///
    /// - Parameters:
    ///   - data: Raw JSON bytes of the DocC sidecar.
    ///   - canonicalPath: Canonical URL form written into the returned
    ///     `CandidateEntry.path`.
    ///   - maxGap: Max char-gap below threshold to qualify as a candidate.
    ///     Defaults to `candidateMaxGapChars` (50).
    /// - Returns: A `CandidateEntry` iff the page is a near-miss, else `nil`.
    /// - Throws: Re-throws JSON parse errors (corrupt sidecar).
    public static func evaluateNearMiss(
        sidecarData data: Data,
        canonicalPath: String,
        maxGap: Int = candidateMaxGapChars
    ) throws -> CandidateEntry? {
        // Early-out: pages that already pass policy are not candidates.
        if try evaluate(sidecarData: data, canonicalPath: canonicalPath) != nil {
            return nil
        }

        let shaped = try JSONDecoder().decode(AuditSidecar.self, from: data)
        guard let meta = shaped.metadata, meta.symbolKind != nil, let heading = meta.roleHeading else {
            return nil  // Articles / missing metadata / unknown role.
        }

        guard let any = try? JSONSerialization.jsonObject(with: data, options: []),
              let root = any as? [String: Any] else {
            return nil
        }
        let chars = authoredCharCount(root: root)
        let sections = root["primaryContentSections"] as? [[String: Any]] ?? []
        let aside = sectionsContainAside(sections)

        // Determine the most-achievable threshold for this page's role.
        // Same order as `evaluate`: framework → type → (method OR aside).
        let bucketPrefix: String
        let target: Int
        let valueKey: String
        if frameworkRoleHeadings.contains(heading) {
            bucketPrefix = "framework:\(heading)"
            target = frameworkOverviewMinChars
            valueKey = "overview"
        } else if typeRoleHeadings.contains(heading) {
            bucketPrefix = "type:\(heading)"
            target = typeOverviewMinChars
            valueKey = "overview"
        } else if methodRoleHeadings.contains(heading) {
            if aside {
                bucketPrefix = "aside:\(heading)"
                target = asideDiscussionMinChars
            } else {
                bucketPrefix = "method:\(heading)"
                target = methodDiscussionMinChars
            }
            valueKey = "disc"
        } else {
            return nil  // Unknown role — don't surface as candidate.
        }

        let gap = target - chars
        guard gap > 0, gap <= maxGap else { return nil }
        return CandidateEntry(
            path: canonicalPath,
            reason: "\(bucketPrefix):\(valueKey)=\(chars) (gap=\(gap) to ≥\(target))",
            gap: gap
        )
    }

    /// Classify one DocC sidecar as an article-shape page.
    ///
    /// Returns an `ArticleEntry` iff the sidecar's `metadata.role == "article"`
    /// AND it has no `symbolKind` (so it's a hand-authored prose page, not an
    /// auto-generated symbol or collection landing). Articles are NOT
    /// policy-gated — the auditor's job is to surface drift between the
    /// archive's article set and the registry's `indexablePages` allowlist,
    /// not to vet authored prose length the way symbol pages are vetted.
    ///
    /// Returns `nil` for symbol pages, `collectionGroup` landings,
    /// non-article roles, and malformed sidecars. Malformed bytes are
    /// swallowed rather than thrown so a single corrupt file in the
    /// archive can't abort the whole audit pass.
    ///
    /// - Parameters:
    ///   - data: Raw JSON bytes of the DocC sidecar.
    ///   - canonicalPath: Canonical URL form (e.g.,
    ///     `documentation/event/asynctcpserverinswift`).
    /// - Returns: An `ArticleEntry` when the sidecar is an article, else `nil`.
    /// - Throws: Does not throw — JSON parse failures yield `nil`.
    public static func evaluateArticle(
        sidecarData data: Data,
        canonicalPath: String
    ) throws -> ArticleEntry? {
        guard let shaped = try? JSONDecoder().decode(AuditSidecar.self, from: data),
              let meta = shaped.metadata,
              meta.role == "article",
              meta.symbolKind == nil else {
            return nil
        }
        let chars: Int
        if let any = try? JSONSerialization.jsonObject(with: data, options: []),
           let root = any as? [String: Any] {
            chars = authoredCharCount(root: root)
        } else {
            chars = 0
        }
        // Fallback to "?" rather than empty string so the CLI output is
        // unambiguous (an empty title would render as a dangling bracket).
        let title = meta.title ?? "?"
        return ArticleEntry(path: canonicalPath, chars: chars, title: title)
    }

    /// Audit one module's sidecar tree.
    ///
    /// - Parameters:
    ///   - module: Module identifier (e.g., `"p256k"`). Resolved to
    ///     `<archivesRoot>/<module>/`.
    ///   - archivesRoot: Directory containing per-module sidecar trees,
    ///     typically `Websites/docs-21-dev/data/documentation`.
    ///   - currentAllowlist: Set of paths already in the registry's
    ///     `indexablePages` for this module. Used to compute both
    ///     `newlyDiscovered` (eligible-but-missing) and `staleEntries`
    ///     (allowlisted-but-thin).
    ///   - excludedPathPrefixes: Path prefixes to drop from auto-discovery
    ///     (e.g., Tor's internal-plumbing trees). Stale-checking ignores
    ///     this filter — explicit allowlist entries are always evaluated.
    /// - Returns: A `ModuleReport` summarizing eligible / already-allowed /
    ///   newly-discovered / stale entries.
    /// - Throws: `AuditError.archivesRootMissing` if the module tree is absent;
    ///   re-throws sidecar decode errors from `evaluateAllowlistEntry`.
    public static func auditModule(
        module: String,
        archivesRoot: URL,
        currentAllowlist: Set<String>,
        excludedPathPrefixes: [String] = [],
        candidateMaxGap: Int = candidateMaxGapChars
    ) throws -> ModuleReport {
        let moduleRoot = archivesRoot.appendingPathComponent(module)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: moduleRoot.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw AuditError.archivesRootMissing(moduleRoot)
        }

        // Phase A: discover all eligible pages, near-miss candidates, AND
        // article-shape pages by scanning the sidecar tree. Each sidecar is
        // classified into AT MOST ONE bucket:
        //   - eligible (passes hybrid policy)
        //   - candidate (symbol page, not eligible, near-miss, NOT allowlisted)
        //   - article (role=article, NOT allowlisted)
        // Articles are gated separately from the symbol path — they're
        // hand-curated, not policy-gated, so they bypass `evaluate` /
        // `evaluateNearMiss` entirely and surface as editorial drift.
        var eligible: [EligiblePage] = []
        var candidates: [CandidateEntry] = []
        var newArticles: [ArticleEntry] = []
        let enumerator = FileManager.default.enumerator(
            at: moduleRoot,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        while let item = enumerator?.nextObject() as? URL {
            guard item.pathExtension == "json" else { continue }
            let canonical = canonicalPath(for: item, archivesRoot: archivesRoot)
            if excludedPathPrefixes.contains(where: { canonical.hasPrefix($0) }) {
                continue
            }
            let data: Data
            do { data = try Data(contentsOf: item) }
            catch { continue }  // unreadable file — skip silently
            if let page = try? evaluate(sidecarData: data, canonicalPath: canonical) {
                eligible.append(page)
            } else if let article = try? evaluateArticle(sidecarData: data, canonicalPath: canonical) {
                // Article-shape page — emit as drift signal ONLY if not in
                // the allowlist. In-allowlist articles are the steady state
                // (the maintainer has already curated them) so they don't
                // need to be reported. Articles can never be `eligible` or
                // `candidate` (those buckets require `symbolKind`), so this
                // branch is disjoint from the symbol branches above and
                // below — no double-counting risk.
                if !currentAllowlist.contains(canonical) {
                    newArticles.append(article)
                }
            } else if !currentAllowlist.contains(canonical),
                      let candidate = try? evaluateNearMiss(
                          sidecarData: data,
                          canonicalPath: canonical,
                          maxGap: candidateMaxGap
                      ) {
                // Near-miss — but only surface if NOT already allowlisted.
                // In-allowlist failures belong in `.staleEntries` (the
                // maintainer-action signal), not `.candidates` (the
                // editorial-polish signal). Keeps the two categories
                // disjoint and prevents double-counting.
                candidates.append(candidate)
            }
        }

        eligible.sort { $0.path < $1.path }
        candidates.sort { $0.path < $1.path }
        newArticles.sort { $0.path < $1.path }
        let eligiblePaths = Set(eligible.map(\.path))
        let already = eligible.filter { currentAllowlist.contains($0.path) }
        let gap = eligible.filter { !currentAllowlist.contains($0.path) }

        // Phase B: stale-entry detection.
        // For each allowlist entry NOT in the eligible set, run the
        // per-entry classifier. Ignores `excludedPathPrefixes` — explicit
        // allowlist entries are always evaluated, even if under an excluded
        // prefix, because the maintainer chose to list them.
        var stale: [StaleEntry] = []
        for entry in currentAllowlist.subtracting(eligiblePaths).sorted() {
            if case .stale(let staleEntry) = try evaluateAllowlistEntry(
                allowlistPath: entry,
                archivesRoot: archivesRoot
            ) {
                stale.append(staleEntry)
            }
        }

        return ModuleReport(
            module: module,
            eligible: eligible,
            alreadyAllowed: already,
            newlyDiscovered: gap,
            staleEntries: stale,
            candidates: candidates,
            newArticles: newArticles
        )
    }

    /// Audit every module listed in the registry.
    ///
    /// - Parameters:
    ///   - archivesRoot: Directory containing per-module sidecar trees.
    ///   - registry: Loaded `ArchiveRegistry`. Provides the module list and
    ///     current `indexablePages` allowlist (globals + per-archive).
    ///   - moduleExclusions: Map of module → path-prefix exclusions. Defaults
    ///     to `defaultModuleExclusions` (Tor internal plumbing).
    /// - Returns: An `AuditReport` covering every module in the registry that
    ///   has a corresponding sidecar tree on disk. Modules with no sidecar
    ///   tree are skipped (not an error — archives may not be downloaded yet).
    /// - Throws: `AuditError.noModulesFound` when none of the registry's
    ///   modules have sidecar trees on disk.
    public static func audit(
        archivesRoot: URL,
        registry: ArchiveRegistry,
        moduleExclusions: [String: [String]] = defaultModuleExclusions,
        candidateMaxGap: Int = candidateMaxGapChars
    ) throws -> AuditReport {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: archivesRoot.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw AuditError.archivesRootMissing(archivesRoot)
        }

        var reports: [ModuleReport] = []
        for module in registry.archives.keys.sorted() {
            let moduleDir = archivesRoot.appendingPathComponent(module)
            var moduleIsDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: moduleDir.path, isDirectory: &moduleIsDir),
                  moduleIsDir.boolValue else {
                continue  // Module not unpacked locally — silently skip.
            }
            // Use the per-archive allowlist for both newly-discovered
            // partitioning and stale-entry detection. Each module's eligible
            // pages live under a unique URL prefix (`documentation/<module>/...`),
            // so per-archive vs. global yields the same partition for
            // `newlyDiscovered`. Per-archive scoping is required for stale
            // detection: globals.hubs entries (e.g., `documentation`) have no
            // sidecar and would all be `.outOfScope` anyway.
            let perArchiveAllowlist = Set(registry.archives[module]?.indexablePages ?? [])
            let exclusions = moduleExclusions[module] ?? []
            let report = try auditModule(
                module: module,
                archivesRoot: archivesRoot,
                currentAllowlist: perArchiveAllowlist,
                excludedPathPrefixes: exclusions,
                candidateMaxGap: candidateMaxGap
            )
            reports.append(report)
        }

        if reports.isEmpty {
            throw AuditError.noModulesFound(archivesRoot)
        }
        return AuditReport(modules: reports)
    }

    // MARK: - Internal Helpers

    /// Convert a sidecar file URL to its canonical URL form.
    ///
    /// Example: `<root>/data/documentation/p256k/p256k/signing.json` →
    /// `documentation/p256k/p256k/signing` (when archivesRoot is
    /// `<root>/data/documentation`).
    static func canonicalPath(for sidecar: URL, archivesRoot: URL) -> String {
        // archivesRoot is `<...>/data/documentation`, so the sidecar's
        // canonical form prepends "documentation/".
        let rootPath = archivesRoot.standardizedFileURL.path
        let sidecarPath = sidecar.standardizedFileURL.path
        guard sidecarPath.hasPrefix(rootPath) else { return sidecar.lastPathComponent }
        var trimmed = String(sidecarPath.dropFirst(rootPath.count))
        if trimmed.hasPrefix("/") { trimmed.removeFirst() }
        if trimmed.hasSuffix(".json") { trimmed.removeLast(5) }
        // Reattach the "documentation/" prefix that archivesRoot's last path
        // component represents.
        let lastComponent = archivesRoot.lastPathComponent  // "documentation"
        return lastComponent + "/" + trimmed
    }

    /// Total authored-prose char count for one sidecar. Counts two sources:
    ///
    /// 1. The top-level `abstract` field — DocC's home for the doc-comment
    ///    summary sentence, separate from `primaryContentSections`.
    /// 2. Every `primaryContentSections[]` entry with `kind == "content"`
    ///    (e.g. Return Value section, Discussion section, Overview section).
    ///    DocC emits multiple content sections per page; summing them all
    ///    is required to match what a reader actually sees.
    ///
    /// Code listings (`type: codeListing`) are excluded — they're code
    /// samples, not authored prose, and don't carry SEO signal.
    ///
    /// This replaces the original `discussionCharCount(sections:)` which
    /// read only the first `kind: content` section and ignored the
    /// `abstract` field, producing 10–18× undercounts on method pages.
    public static func authoredCharCount(root: [String: Any]) -> Int {
        // 1. Abstract (summary sentence / doc-comment first line).
        let abstractNodes = root["abstract"] as? [Any] ?? []
        var total = flattenedText(abstractNodes).count
        // 2. All kind:content sections — not just the first.
        let sections = root["primaryContentSections"] as? [[String: Any]] ?? []
        for section in sections where (section["kind"] as? String) == "content" {
            if let nodes = section["content"] as? [Any] {
                total += flattenedText(nodes).count
            }
        }
        return total
    }

    /// True iff any `type: aside` node appears anywhere in the section tree.
    static func sectionsContainAside(_ sections: [[String: Any]]) -> Bool {
        return sections.contains { containsAsideNode($0) }
    }

    private static func containsAsideNode(_ node: Any) -> Bool {
        if let dict = node as? [String: Any] {
            if (dict["type"] as? String) == "aside" { return true }
            for value in dict.values where containsAsideNode(value) { return true }
            return false
        }
        if let array = node as? [Any] {
            return array.contains { containsAsideNode($0) }
        }
        return false
    }

    /// Recursively flatten DocC content nodes into plain text. Code listings
    /// (`type: codeListing`) are excluded — they're not authored prose.
    private static func flattenedText(_ node: Any) -> String {
        if let str = node as? String { return str }
        if let dict = node as? [String: Any] {
            if (dict["type"] as? String) == "codeListing" { return "" }
            if let text = dict["text"] as? String { return text }
            var out = ""
            for key in ["inlineContent", "content", "items"] {
                if let value = dict[key] {
                    out += flattenedText(value)
                }
            }
            return out
        }
        if let array = node as? [Any] {
            return array.map { flattenedText($0) }.joined()
        }
        return ""
    }
}
