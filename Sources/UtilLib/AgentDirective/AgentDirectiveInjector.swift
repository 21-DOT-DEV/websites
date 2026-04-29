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
import SiteIdentity

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

    /// Marker for the `<link rel="llms-txt">` tag.
    static let llmsTxtMarker = "rel=\"llms-txt\""

    /// Marker for the `<link rel="alternate">` markdown tag.
    static let alternateMarker = "rel=\"alternate\" type=\"text/markdown\""

    /// The exact noindex robots meta tag injected for non-allowlisted pages.
    static let noindexTag = "<meta name=\"robots\" content=\"noindex, follow\">"

    /// Marker for detecting existing noindex meta tags in HTML.
    static let noindexMarker = "name=\"robots\""

    /// Pages that should be indexed by search engines (no noindex tag).
    ///
    /// Sources:
    /// - `Resources/docs-21-dev/data/documentation/p256k/llms.txt` (23 curated entries)
    /// - One-time audit of pages with `<h2>Discussion</h2>` sections (52 entries)
    /// - One-time audit of pages with authored Parameters/Return Value/aside sections (29 entries)
    /// - `Resources/docs-21-dev/data/documentation/event/llms.txt` (10 curated entries)
    /// - `Resources/docs-21-dev/data/documentation/openssl/llms.txt` (12 curated entries)
    /// - ZKP-unique authored articles (2 entries: module overview + ChoosingP256KvsZKP)
    ///
    /// ZKP symbol pages (`p256k/...` under `zkp/`) re-export P256K, so they are
    /// SEO duplicates and remain excluded. Only ZKP-unique authored articles
    /// (module overview, product-selection guides, future bulletproof/rangeproof
    /// pages) are allowlisted.
    ///
    /// When llms.txt or doc comments change, re-audit with:
    ///   find Websites/docs-21-dev/documentation/p256k -name index.html \( \
    ///     -exec grep -l '<h2>Discussion</h2>' {} \; -o \
    ///     -exec grep -l '<h2>Return Value</h2>' {} \; -o \
    ///     -exec grep -l '<h2>Parameters</h2>' {} \; -o \
    ///     -exec grep -l 'class="aside' {} \; \
    ///   \) | sed 's|Websites/docs-21-dev/||; s|/index.html||' | sort -u
    static let indexablePages: Set<String> = [
        // --- Hub pages (2 entries, manually curated) ---
        // Top-level navigation entry points not surfaced by authored-content
        // audits: docs.21.dev root and the P256K namespace-enum Topics hub.
        "documentation",
        "documentation/p256k/p256k",

        // --- P256K llms.txt (23 entries) ---
        // ## Documentation
        "documentation/p256k/gettingstarted",
        "documentation/p256k",
        // Authored articles added in PR fb0c08 — mirror the `## Documentation`
        // entries in Resources/docs-21-dev/data/documentation/p256k/llms.txt.
        // The first two (ellipticcurvediffiehellman, silentpayments) ship for
        // the first time in swift-secp256k1 0.23.1-prerelease-3.
        "documentation/p256k/ellipticcurvediffiehellman",
        "documentation/p256k/silentpayments",
        "documentation/p256k/tweakingkeys",
        "documentation/p256k/musig2multisignatures",
        "documentation/p256k/recoveringpublickeys",
        "documentation/p256k/serializingkeys",
        "documentation/p256k/securityconsiderations",
        "documentation/p256k/keyformats",
        // ## Symbols
        "documentation/p256k/p256k/context",
        "documentation/p256k/p256k/signing",
        "documentation/p256k/p256k/keyagreement",
        "documentation/p256k/p256k/schnorr",
        "documentation/p256k/p256k/recovery",
        "documentation/p256k/p256k/musig",
        // ## Optional
        "documentation/p256k/p256k/signing/privatekey",
        "documentation/p256k/p256k/signing/publickey",
        "documentation/p256k/p256k/keyagreement/privatekey",
        "documentation/p256k/p256k/schnorr/privatekey",
        "documentation/p256k/p256k/recovery/privatekey",
        "documentation/p256k/int256",
        "documentation/p256k/uint256",

        // --- Pages with Discussion sections (52 entries, audit 2025-04-06) ---
        // Context
        "documentation/p256k/p256k/context/create()",
        "documentation/p256k/p256k/context/rawrepresentation",
        // KeyAgreement
        "documentation/p256k/p256k/keyagreement/privatekey/init(datarepresentation:format:)",
        "documentation/p256k/p256k/keyagreement/privatekey/init(format:)",
        "documentation/p256k/p256k/keyagreement/privatekey/sharedsecretfromkeyagreement(with:format:)",
        "documentation/p256k/p256k/keyagreement/publickey/init(datarepresentation:format:)",
        "documentation/p256k/p256k/keyagreement/publickey/init(x963representation:)",
        // MuSig
        "documentation/p256k/p256k/musig/aggregate(_:)",
        "documentation/p256k/p256k/musig/aggregatesignature/init(datarepresentation:)",
        "documentation/p256k/p256k/musig/aggregatesignatures(_:)",
        "documentation/p256k/p256k/musig/nonce/generate(secretkey:publickey:msg32:extrainput32:)",
        "documentation/p256k/p256k/musig/nonce/generate(sessionid:secretkey:publickey:msg32:extrainput32:)",
        "documentation/p256k/p256k/musig/nonce/init(aggregating:)",
        "documentation/p256k/p256k/musig/nonce/init(datarepresentation:)",
        "documentation/p256k/p256k/musig/publickey/add(_:format:)",
        "documentation/p256k/p256k/musig/publickey/init(datarepresentation:format:cache:)",
        "documentation/p256k/p256k/musig/publickey/isvalidsignature(_:publickey:nonce:for:)",
        "documentation/p256k/p256k/musig/xonlykey/add(_:)",
        // Recovery
        "documentation/p256k/p256k/recovery/ecdsasignature/init(compactrepresentation:recoveryid:)",
        "documentation/p256k/p256k/recovery/ecdsasignature/init(datarepresentation:)",
        "documentation/p256k/p256k/recovery/ecdsasignature/normalize",
        "documentation/p256k/p256k/recovery/privatekey/init(datarepresentation:format:)",
        "documentation/p256k/p256k/recovery/privatekey/init(format:)",
        // Schnorr
        "documentation/p256k/p256k/schnorr/nonce/init(datarepresentation:)",
        "documentation/p256k/p256k/schnorr/partialsignature/init(datarepresentation:session:)",
        "documentation/p256k/p256k/schnorr/privatekey/init()",
        "documentation/p256k/p256k/schnorr/privatekey/init(datarepresentation:)",
        "documentation/p256k/p256k/schnorr/privatekey/partialsignature(for:pubnonce:securenonce:publicnonceaggregate:publickeyaggregate:)",
        "documentation/p256k/p256k/schnorr/privatekey/partialsignature(for:pubnonce:securenonce:publicnonceaggregate:xonlykeyaggregate:)",
        "documentation/p256k/p256k/schnorr/privatekey/signature(for:)",
        "documentation/p256k/p256k/schnorr/privatekey/signature(for:auxiliaryrand:)",
        "documentation/p256k/p256k/schnorr/privatekey/signature(message:auxiliaryrand:strict:)",
        "documentation/p256k/p256k/schnorr/publickey/init(datarepresentation:format:)",
        "documentation/p256k/p256k/schnorr/schnorrsignature/init(datarepresentation:)",
        // Signing
        "documentation/p256k/p256k/signing/ecdsasignature/init(compactrepresentation:)",
        "documentation/p256k/p256k/signing/ecdsasignature/init(datarepresentation:)",
        "documentation/p256k/p256k/signing/ecdsasignature/init(derrepresentation:)",
        "documentation/p256k/p256k/signing/privatekey/add(_:)",
        "documentation/p256k/p256k/signing/privatekey/init(_:format:)",
        "documentation/p256k/p256k/signing/privatekey/init(datarepresentation:format:)",
        "documentation/p256k/p256k/signing/privatekey/init(format:)",
        "documentation/p256k/p256k/signing/privatekey/multiply(_:)",
        "documentation/p256k/p256k/signing/publickey/add(_:format:)",
        "documentation/p256k/p256k/signing/publickey/combine(_:format:)",
        "documentation/p256k/p256k/signing/publickey/init(datarepresentation:format:)",
        "documentation/p256k/p256k/signing/publickey/init(x963representation:)",
        "documentation/p256k/p256k/signing/publickey/multiply(_:format:)",
        "documentation/p256k/p256k/signing/xonlykey/parity",
        // Extensions & utility types
        "documentation/p256k/sha256/taggedhash(tag:data:)",
        "documentation/p256k/swift/string/bytes",
        "documentation/p256k/uint256/addmod(_:modulus:)",
        "documentation/p256k/uint256/mulmod(_:modulus:)",

        // --- Pages with authored Parameters/Return Value/aside (30 entries, audit 2025-04-06) ---
        // KeyAgreement
        "documentation/p256k/p256k/keyagreement/publickey/init(derrepresentation:)",
        // MuSig
        "documentation/p256k/p256k/musig/publickey/init(xonlykey:)",
        "documentation/p256k/p256k/musig/xonlykey/init(datarepresentation:keyparity:cache:)",
        "documentation/p256k/p256k/musig/xonlykey/isvalid(_:for:)",
        "documentation/p256k/p256k/musig/xonlykey/isvalidsignature(_:for:)",
        // Recovery
        "documentation/p256k/p256k/recovery/privatekey/signature(for:)-1eroz",
        "documentation/p256k/p256k/recovery/privatekey/signature(for:)-pcnn",
        "documentation/p256k/p256k/recovery/publickey/init(_:signature:format:)-4311g",
        "documentation/p256k/p256k/recovery/publickey/init(_:signature:format:)-5frmm",
        // Schnorr
        "documentation/p256k/p256k/schnorr/privatekey/add(_:)",
        "documentation/p256k/p256k/schnorr/publickey/init(xonlykey:)",
        "documentation/p256k/p256k/schnorr/xonlykey/add(_:)",
        "documentation/p256k/p256k/schnorr/xonlykey/init(datarepresentation:keyparity:cache:)",
        "documentation/p256k/p256k/schnorr/xonlykey/isvalid(_:for:)",
        "documentation/p256k/p256k/schnorr/xonlykey/isvalidsignature(_:for:)",
        // Signing
        "documentation/p256k/p256k/signing/privatekey/init(derrepresentation:)",
        "documentation/p256k/p256k/signing/privatekey/init(pemrepresentation:)",
        "documentation/p256k/p256k/signing/privatekey/signature(for:)-3h6ut",
        "documentation/p256k/p256k/signing/privatekey/signature(for:)-4qs1k",
        "documentation/p256k/p256k/signing/publickey/init(derrepresentation:)",
        "documentation/p256k/p256k/signing/publickey/init(pemrepresentation:)",
        "documentation/p256k/p256k/signing/publickey/init(xonlykey:)",
        "documentation/p256k/p256k/signing/publickey/isvalidsignature(_:for:)-7sttb",
        "documentation/p256k/p256k/signing/publickey/isvalidsignature(_:for:)-8lxch",
        "documentation/p256k/p256k/signing/xonlykey/init(datarepresentation:keyparity:)",
        // Extensions & utility types
        "documentation/p256k/foundation/data/copytounsafemutablebytes(of:)",
        "documentation/p256k/sha256/hash(data:)",
        "documentation/p256k/sharedsecret/==(_:_:)-7g0c5",
        "documentation/p256k/swift/string/init(bytes:)",

        // --- Event llms.txt (10 entries) ---
        // ## Documentation
        "documentation/event/gettingstarted",
        "documentation/event/productionconsiderations",
        "documentation/event/backendandplatforms",
        "documentation/event/choosinglibeventvsevent",
        "documentation/event",
        // ## Symbols
        "documentation/event/eventloop",
        "documentation/event/socket",
        "documentation/event/serversocket",
        "documentation/event/socketaddress",
        // ## Optional
        "documentation/event/socketerror",

        // --- OpenSSL llms.txt (12 entries) ---
        // ## Documentation
        "documentation/openssl/gettingstarted",
        "documentation/openssl/securityconsiderations",
        "documentation/openssl/choosinglibcryptovsopenssl",
        "documentation/openssl",
        // ## Symbols
        "documentation/openssl/sha256",
        "documentation/openssl/base64url",
        "documentation/openssl/rsa",
        "documentation/openssl/ssl",
        // ## Optional
        "documentation/openssl/sha256/sha256digest",
        "documentation/openssl/rsa/privatekey",
        "documentation/openssl/rsa/publickey",
        "documentation/openssl/opensslerror",

        // --- ZKP-unique authored articles (2 entries) ---
        // Sourced from upstream Sources/ZKP/ZKP.docc/*.md (swift-secp256k1).
        // ZKP symbol pages re-export P256K and stay noindex'd; only authored
        // articles unique to the ZKP product are allowlisted here.
        "documentation/zkp",
        "documentation/zkp/choosingp256kvszkp",
    ]

    /// Normalizes an HTML file's relative path for allowlist comparison.
    ///
    /// Strips trailing `/index.html` or `.html`, lowercases, and removes
    /// leading/trailing slashes to produce a canonical path fragment.
    ///
    /// Examples:
    /// - `documentation/p256k/p256k/signing/index.html` → `documentation/p256k/p256k/signing`
    /// - `documentation/p256k/int256.html` → `documentation/p256k/int256`
    static func normalizePathForAllowlist(_ relativePath: String) -> String {
        var path = relativePath.lowercased()
        if path.hasSuffix("/index.html") {
            path = String(path.dropLast("/index.html".count))
        } else if path.hasSuffix(".html") {
            path = String(path.dropLast(".html".count))
        }
        while path.hasPrefix("/") { path = String(path.dropFirst()) }
        while path.hasSuffix("/") { path = String(path.dropLast()) }
        return path
    }

    /// Whether a page should be indexed by search engines.
    ///
    /// Returns `true` if the page's normalized path is in `indexablePages`.
    public static func shouldIndex(relativePath: String) -> Bool {
        indexablePages.contains(normalizePathForAllowlist(relativePath))
    }

    /// Known display names for DocC URL segments.
    ///
    /// Maps lowercased URL segments to their proper-cased display names.
    /// Single-word segments use capitalize-first fallback; only multi-word
    /// compounds that would fail under fallback need explicit entries.
    ///
    /// Implementation step: After building locally, scan BOTH modules:
    ///   find Websites/docs-21-dev/documentation -name index.html | \
    ///     sed 's|.*/documentation/||; s|/index.html||' | \
    ///     tr '/' '\n' | sort -u
    /// Compare unique segments against knownNames keys.
    /// This covers both P256K and ZKP (including ZKP's re-exported P256K symbols).
    ///
    /// Future contributors: when new symbols are added to P256K or ZKP,
    /// run the scan command above and add any new multi-word compounds to this map.
    static let knownNames: [String: String] = [
        // Modules
        "p256k": "P256K",
        "zkp": "ZKP",
        // Compound names (capitalize-first fallback would be wrong)
        "int256": "Int256",
        "keyagreement": "KeyAgreement",
        "privatekey": "PrivateKey",
        "publickey": "PublicKey",
        "xonlypublickey": "XonlyPublicKey",
        "sharedsecret": "SharedSecret",
        "sha256digest": "SHA256Digest",
        "partialsignature": "PartialSignature",
        "surjectionproof": "SurjectionProof",
        "rangeproof": "RangeProof",
        "cryptokitasn1error": "CryptoKitASN1Error",
        "cryptokitmetaerror": "CryptoKitMetaError",
        // Articles
        "gettingstarted": "GettingStarted",
        // Top-level documentation root
        "documentation": "API Reference",
    ]

    /// Resolves a URL segment to its display name using knownNames, with fallback.
    ///
    /// Rules (in order):
    /// 1. If segment is in `knownNames`, use the mapped value
    /// 2. If segment contains `(` (Swift symbol like `init(rawrepresentation:)`), keep as-is
    /// 3. Otherwise, capitalize the first letter (fallback for single-word segments)
    static func resolveName(for segment: String) -> String {
        if let known = knownNames[segment] {
            return known
        }
        if segment.contains("(") {
            return segment
        }
        return segment.prefix(1).uppercased() + segment.dropFirst()
    }

    /// Derives breadcrumb items and page name from a documentation-relative path.
    ///
    /// Uses an interleaved dedup + URL construction algorithm that preserves
    /// canonical DocC URLs (with doubled segments) in breadcrumb item URLs.
    ///
    /// - Parameters:
    ///   - relativePath: File path relative to output directory (from HTMLFileWalker,
    ///     always includes `index.html` — never a bare directory)
    ///   - baseURL: Site base URL (e.g., `https://docs.21.dev/`)
    /// - Returns: Tuple of (breadcrumb items for BreadcrumbList, page display name)
    public static func deriveBreadcrumbs(
        from relativePath: String,
        baseURL: URL
    ) -> (items: [BreadcrumbItemSchema], pageName: String) {
        // Step 0: Strip trailing /index.html or .html
        var stripped = relativePath
        if stripped.hasSuffix("/index.html") {
            stripped = String(stripped.dropLast("/index.html".count))
        } else if stripped.hasSuffix(".html") {
            stripped = String(stripped.dropLast(".html".count))
        }

        // Step 1: Extract segments after "documentation/" prefix
        let prefix = "documentation/"
        let segments: [String]
        if stripped.hasPrefix(prefix) {
            let remainder = String(stripped.dropFirst(prefix.count))
            segments = remainder.split(separator: "/").map(String.init)
        } else {
            // Path is just "documentation" (no trailing slash) → zero segments
            segments = []
        }

        // Zero segments: top-level documentation/index.html
        if segments.isEmpty {
            return (items: [], pageName: resolveName(for: "documentation"))
        }

        // Step 2: Walk original segments, building cumulative URLs AND deduplicating.
        // Each candidate stores (name, url) for a breadcrumb item.
        // Dedup-consecutive collapses ALL consecutive runs — safe because DocC
        // never generates triple-or-more consecutive identical segments.
        var candidates: [(name: String, url: String)] = []
        var cumulativePath = "documentation/"
        var previousSegment: String?

        for segment in segments {
            cumulativePath += segment + "/"

            if segment == previousSegment {
                // Consecutive duplicate — skip (dedup) but URL path still extends
                previousSegment = segment
                continue
            }

            let name = resolveName(for: segment)
            let url = baseURL.appendingPathComponent(cumulativePath).absoluteString
            candidates.append((name: name, url: url))
            previousSegment = segment
        }

        // Step 3: Pop the last candidate as the leaf (becomes WebPage.name)
        guard let leaf = candidates.popLast() else {
            return (items: [], pageName: resolveName(for: "documentation"))
        }

        // Step 4: Remaining candidates become BreadcrumbItemSchema entries
        let items = candidates.enumerated().map { index, candidate in
            BreadcrumbItemSchema(
                position: index + 1,
                name: candidate.name,
                item: candidate.url
            )
        }

        return (items: items, pageName: leaf.name)
    }

    /// Builds the agent directive tags for injection into `<head>`.
    ///
    /// Produces up to three tags:
    /// 1. `<link rel="llms-txt">` — llms.txt discovery (always present)
    /// 2. `<link rel="alternate" type="text/markdown">` — markdown alternate (when available)
    /// 3. `<script type="application/ld+json">` — JSON-LD `@graph` with:
    ///    - `WebSite` node (always — intentionally on every page, docs subdomain has no homepage)
    ///    - `Organization` publisher node (always — anchored to the marketing
    ///      site's canonical `@id`, providing a cross-domain identity link)
    ///    - `BreadcrumbList` node (only when breadcrumb items exist)
    ///    - `WebPage` node with `isPartOf → WebSite` and (when applicable)
    ///      `mainEntity → TechArticle`
    ///    - `TechArticle` node when the DocC sidecar's `metadata.role` is
    ///      `article`, `symbol`, or `collection`. The article-vs-reference
    ///      distinction is encoded via `articleSection` ("Guides" for prose,
    ///      "API Reference" for symbol/collection); the `@type` is uniform
    ///      `TechArticle` across both — see Schema.org guidance and
    ///      Vercel/Pulumi peer practice.
    ///
    /// When `sidecar` is `nil` (no DocC metadata available — top-level
    /// `documentation/index.html`, generation-time loader failure, or a
    /// non-DocC page), the renderer falls back to the slug-derived `pageName`
    /// and emits `WebPage` only (no Article-class node).
    ///
    /// - Parameters:
    ///   - markdownURL: The markdown URL for this specific page, or `nil` if none exists
    ///   - relativePath: File path relative to the output directory
    ///   - baseURL: Site base URL (e.g., `https://docs.21.dev/`)
    ///   - shouldIndex: When `false`, prepends the canonical noindex meta tag
    ///   - sidecar: Optional DocC page-data sidecar driving title, abstract,
    ///     and Article-class node selection. Defaults to `nil` for source
    ///     compatibility with existing call sites.
    /// - Returns: Combined HTML string for injection before `</head>`
    public static func buildDirective(
        markdownURL: URL?,
        relativePath: String,
        baseURL: URL,
        shouldIndex: Bool = true,
        sidecar: DocCSidecar? = nil
    ) throws -> String {
        var baseURLString = baseURL.absoluteString
        if !baseURLString.hasSuffix("/") {
            baseURLString += "/"
        }

        // Derive breadcrumbs and a slug-cased fallback page name. When the
        // sidecar provides an authoritative title, prefer that.
        let (breadcrumbItems, pageName) = deriveBreadcrumbs(from: relativePath, baseURL: baseURL)
        let resolvedPageName = sidecar?.metadata.title ?? pageName
        let resolvedDescription = sidecar?.concatenatedAbstract

        // Derive page URL from relativePath
        var pagePathComponent = relativePath
        if pagePathComponent.hasSuffix("/index.html") {
            pagePathComponent = String(pagePathComponent.dropLast("index.html".count))
        } else if pagePathComponent.hasSuffix(".html") {
            pagePathComponent = String(pagePathComponent.dropLast(".html".count)) + "/"
        }
        let pageURL = baseURL.appendingPathComponent(pagePathComponent).absoluteString

        // Build @graph nodes
        var schemas: [any Schema] = []

        // 1. WebSite — always present on every page
        let websiteId = "\(baseURLString)#website"
        let website = WebSiteSchema(
            id: websiteId,
            name: "docs.21.dev",
            url: baseURLString
        )
        schemas.append(website)

        // 2. Organization (publisher) — always present, anchored to the
        //    marketing site's canonical `@id` so docs and 21.dev resolve to
        //    the same Organization entity for AI/LLM crawlers.
        schemas.append(SiteIdentity.organizationSchema)

        // 3. BreadcrumbList — only when items exist
        let breadcrumbId = "\(pageURL)#breadcrumb"
        let breadcrumbRef: SchemaReference?
        if !breadcrumbItems.isEmpty {
            let breadcrumbList = BreadcrumbListSchema(
                id: breadcrumbId,
                items: breadcrumbItems
            )
            schemas.append(breadcrumbList)
            breadcrumbRef = SchemaReference(id: breadcrumbId)
        } else {
            breadcrumbRef = nil
        }

        // 4. TechArticle node, driven by the DocC sidecar's `metadata.role`.
        //    Both authored prose (.article) and reference pages
        //    (.symbol / .collection) emit a uniform `@type: "TechArticle"`,
        //    differentiated by `articleSection` ("Guides" vs "API Reference").
        //    Symbol/collection pages additionally carry `about: <ModuleName>`.
        //    We compute the article node before the WebPage so the WebPage
        //    can carry a `mainEntity` back-reference.
        let webPageId = "\(pageURL)#webpage"
        let publisherRef = SchemaReference(id: SiteIdentity.schemaID)
        let articleNode: (any Schema)?
        let mainEntityRef: SchemaReference?

        switch sidecar?.semanticRole {
        case .article:
            let articleId = TechArticleSchema.canonicalID(forPageURL: pageURL)
            articleNode = TechArticleSchema(
                id: articleId,
                headline: sidecar?.metadata.title ?? resolvedPageName,
                description: resolvedDescription,
                url: pageURL,
                isPartOf: SchemaReference(id: websiteId),
                mainEntityOfPage: SchemaReference(id: webPageId),
                publisher: publisherRef,
                articleSection: "Guides"
            )
            mainEntityRef = SchemaReference(id: articleId)
        case .symbol, .collection:
            let articleId = TechArticleSchema.canonicalID(forPageURL: pageURL)
            // Prefer the sidecar's own module assignment; fall back to the
            // path-derived slug (uppercased to match DocC's bundle name).
            let module = sidecar?.moduleName
                ?? extractModule(from: relativePath)?.uppercased()
            articleNode = TechArticleSchema(
                id: articleId,
                headline: sidecar?.metadata.title ?? resolvedPageName,
                description: resolvedDescription,
                url: pageURL,
                isPartOf: SchemaReference(id: websiteId),
                mainEntityOfPage: SchemaReference(id: webPageId),
                publisher: publisherRef,
                articleSection: "API Reference",
                about: module
            )
            mainEntityRef = SchemaReference(id: articleId)
        case .landingPage, .other, .unknown, .none:
            articleNode = nil
            mainEntityRef = nil
        }

        // 5. WebPage — always present, now enriched with sidecar fields and
        //    a back-reference to the Article-class node (when present).
        let webPage = WebPageSchema(
            id: webPageId,
            isPartOf: SchemaReference(id: websiteId),
            name: resolvedPageName,
            url: pageURL,
            description: resolvedDescription,
            breadcrumb: breadcrumbRef,
            mainEntity: mainEntityRef
        )
        schemas.append(webPage)

        if let articleNode {
            schemas.append(articleNode)
        }

        // Build output tags
        var parts: [String] = []

        // 0. Robots noindex (for non-allowlisted pages)
        if !shouldIndex {
            parts.append(noindexTag)
        }

        // 1. <link rel="llms-txt"> — module-specific when under a module, root otherwise
        let module = extractModule(from: relativePath)
        let llmsTxtURL: String
        if let module {
            llmsTxtURL = baseURL.appendingPathComponent("data/documentation/\(module)/llms.txt").absoluteString
        } else {
            llmsTxtURL = baseURL.appendingPathComponent("llms.txt").absoluteString
        }
        parts.append("<link \(llmsTxtMarker) href=\"\(llmsTxtURL)\" />")

        // 2. <link rel="alternate"> for markdown (when available)
        if let markdownURL {
            parts.append("<link \(alternateMarker) href=\"\(markdownURL.absoluteString)\" />")
        }

        // 3. JSON-LD @graph
        let json = try SchemaGraph(schemas).renderCompact()
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
        let hasLlmsTxt = html.contains(llmsTxtMarker)
        let hasLegacy = html.contains("class=\"\(legacyMarkerClass)\"")
        let hasNoindex = html.contains(noindexMarker)

        if (hasExisting || hasAlternate || hasLlmsTxt || hasLegacy || hasNoindex) && !force {
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

        // Remove existing <link rel="llms-txt"> if forcing
        if hasLlmsTxt && force {
            content = removeSelfClosingTag(from: content, marker: llmsTxtMarker)
        }

        // Remove existing noindex meta tag if forcing — use exact string match,
        // NOT removeSelfClosingTag (search-order bug for void elements).
        if hasNoindex && force {
            content = removeExactTag(from: content, tag: noindexTag)
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

    /// Removes an exact tag string from HTML content, including surrounding whitespace/newlines.
    ///
    /// Unlike `removeSelfClosingTag` (which parses open/close markers and can mis-match
    /// void elements), this method matches the exact tag string. Use when the injected
    /// tag is a known constant.
    private static func removeExactTag(from content: String, tag: String) -> String {
        var result = content
        guard let tagRange = result.range(of: tag) else {
            return result
        }

        var removeStart = tagRange.lowerBound
        var removeEnd = tagRange.upperBound

        // Include surrounding newlines/whitespace
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
            // Tolerant sidecar lookup. A missing or malformed sidecar must
            // not abort the directory walk — we record the status on the
            // per-file `InjectionResult` so the caller can apply a
            // failure-rate threshold at the summary level.
            let sidecarOutcome = DocCSidecarLoader.loadIfPresent(
                relativePath: entry.relativePath,
                in: directoryPath
            )
            let sidecar: DocCSidecar?
            let sidecarStatus: SidecarStatus
            let sidecarFailureMessage: String?
            switch sidecarOutcome {
            case .loaded(let parsed):
                sidecar = parsed
                sidecarStatus = .loaded
                sidecarFailureMessage = nil
            case .missing:
                sidecar = nil
                sidecarStatus = .missing
                sidecarFailureMessage = nil
            case .failed(_, let message):
                sidecar = nil
                sidecarStatus = .failed
                sidecarFailureMessage = message
            }

            do {
                let html = try String(contentsOfFile: entry.absolutePath, encoding: .utf8)
                let mdRelPath = deriveMarkdownRelativePath(from: entry.relativePath)
                let mdLocalPath = (directoryPath as NSString).appendingPathComponent(mdRelPath)
                let markdownURL: URL? = FileManager.default.fileExists(atPath: mdLocalPath)
                    ? deriveMarkdownURL(baseURL: baseURL, relativePath: entry.relativePath)
                    : nil
                let isIndexable = Self.shouldIndex(relativePath: entry.relativePath)
                let directive = try buildDirective(
                    markdownURL: markdownURL,
                    relativePath: entry.relativePath,
                    baseURL: baseURL,
                    shouldIndex: isIndexable,
                    sidecar: sidecar
                )

                let (fixedHTML, action) = inject(html: html, directive: directive, force: force)

                if !dryRun && (action == .injected) {
                    try fixedHTML.write(toFile: entry.absolutePath, atomically: true, encoding: .utf8)
                }

                results.append(InjectionResult(
                    filePath: entry.absolutePath,
                    relativePath: entry.relativePath,
                    action: action,
                    noindexed: !isIndexable,
                    errorMessage: nil,
                    sidecarStatus: sidecarStatus,
                    sidecarFailureMessage: sidecarFailureMessage
                ))
            } catch {
                results.append(InjectionResult(
                    filePath: entry.absolutePath,
                    relativePath: entry.relativePath,
                    action: .failed,
                    noindexed: !Self.shouldIndex(relativePath: entry.relativePath),
                    errorMessage: error.localizedDescription,
                    sidecarStatus: sidecarStatus,
                    sidecarFailureMessage: sidecarFailureMessage
                ))
            }
        }

        return InjectionReport(results: results)
    }

    /// Verifies that all documentation HTML files contain an agent directive
    /// and have correct noindex status based on the allowlist.
    ///
    /// Detects the current combined format (JSON-LD marker or alternate link),
    /// and also accepts the legacy `<p class="agent-directive">` format.
    ///
    /// Noindex assertion rules:
    /// - If `shouldIndex(relativePath:)` is **false**: file **must** contain `noindexMarker`
    /// - If `shouldIndex(relativePath:)` is **true**: file **must NOT** contain `noindexMarker`
    ///
    /// - Parameter directoryPath: Path to the output directory
    /// - Returns: Tuple of (total files, files with directive, missing directive paths, noindex issue descriptions)
    public static func verify(
        at directoryPath: String
    ) throws -> (total: Int, present: Int, missing: [String], noindexIssues: [String]) {
        let entries = try HTMLFileWalker.findHTMLFiles(
            in: directoryPath,
            pathPrefix: "documentation/"
        )

        var present = 0
        var missing: [String] = []
        var noindexIssues: [String] = []

        for entry in entries {
            let html = try String(contentsOfFile: entry.absolutePath, encoding: .utf8)
            // Dual-marker check: both isPartOf AND llms-txt must be present.
            // This distinguishes new format from old (AgentDirectiveWebPage had
            // isPartOf but no llms-txt link). Old-format pages fail this check,
            // which is intentional — forces complete migration via --force.
            if html.contains(marker) && html.contains(llmsTxtMarker) {
                present += 1
            } else {
                missing.append(entry.relativePath)
            }

            // Noindex correctness check
            let isIndexable = shouldIndex(relativePath: entry.relativePath)
            let hasNoindex = html.contains(noindexMarker)
            if !isIndexable && !hasNoindex {
                noindexIssues.append("\(entry.relativePath) (missing noindex)")
            } else if isIndexable && hasNoindex {
                noindexIssues.append("\(entry.relativePath) (unexpected noindex)")
            }
        }

        return (total: entries.count, present: present, missing: missing, noindexIssues: noindexIssues)
    }
}
