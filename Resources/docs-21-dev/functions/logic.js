/** Cache TTL in seconds, shared between response headers and fetch options. */
export const CACHE_TTL_SECONDS = 3600;

/**
 * Resolves the visitor country from the CF-IPCountry header value.
 * Returns "unknown" when the header is absent or empty.
 * @param {string|null|undefined} header
 * @returns {string}
 */
export function resolveCountry(header) {
  return header || "unknown";
}

/**
 * Determines whether a hostname should be redirected to the custom domain.
 * @param {string} hostname
 * @returns {{ redirect: boolean, target: string }}
 */
export function resolveRedirect(hostname) {
  if (hostname === "docs-21-dev.pages.dev") {
    return { redirect: true, target: "docs.21.dev" };
  }
  return { redirect: false, target: hostname };
}

/**
 * Resolves a URL pathname to the corresponding markdown file path.
 * Index paths map to llms.txt; other paths map to /data/.../*.md.
 * @param {string} pathname
 * @returns {string}
 */
export function resolveMarkdownPath(pathname) {
  // DocC generates all-lowercase URL segments; normalise to match on disk
  pathname = pathname.toLowerCase();
  const indexPaths = new Set(["/", "/documentation", "/documentation/"]);

  if (indexPaths.has(pathname)) {
    return "/llms.txt";
  } else if (pathname.endsWith("/index.html")) {
    return "/data" + pathname.replace(/\/index\.html$/, ".md");
  } else if (pathname.endsWith(".html")) {
    return "/data" + pathname.replace(/\.html$/, ".md");
  } else {
    const stripped = pathname.endsWith("/") ? pathname.slice(0, -1) : pathname;
    return "/data" + stripped + ".md";
  }
}

/**
 * Checks whether a Content-Type header indicates a valid markdown response.
 * Returns false for text/html (SPA fallback), true for everything else.
 * @param {string} contentType
 * @returns {boolean}
 */
export function isValidMarkdownResponse(contentType) {
  return !contentType.includes("text/html");
}

/**
 * Determines whether the Accept header indicates a preference for markdown.
 * @param {string} accept
 * @returns {boolean}
 */
export function wantsMarkdown(accept) {
  return accept.includes("text/markdown");
}

/**
 * Builds the response headers for a served markdown file.
 * @param {number} tokens
 * @returns {Record<string, string>}
 */
export function buildMarkdownHeaders(tokens) {
  return {
    "Content-Type": "text/markdown; charset=utf-8",
    "X-Markdown-Tokens": String(tokens),
    "Content-Signal": "ai-input=yes, search=yes, ai-train=yes",
    "Cache-Control": `public, max-age=${CACHE_TTL_SECONDS}`,
    "Vary": "Accept",
    // Mintlify-aligned: agent-discovery hints on the markdown variant too.
    // Catalog Link relations (no per-page alternate/canonical here — the
    // markdown response is itself the alternate of the HTML page).
    "Link": `</llms.txt>; rel="llms-txt", </llms-full.txt>; rel="llms-full-txt"`,
    "X-Llms-Txt": "/llms.txt",
  };
}

/**
 * Formats analytics data into the Analytics Engine wire format.
 *
 * Schema (dataset: "markdown_serves"):
 *   blob1=normalizedPath (lowercase), blob2=resolvedPath, blob3=outcome,
 *   blob4=accept (max 256), blob5=userAgent (max 512), blob6=country
 *   double1=1 (counter), double2=tokens, double3=chars
 *   index=requestedPath
 *
 * @param {{ requestedPath: string, normalizedPath: string, resolvedPath: string,
 *           outcome: string, accept: string, userAgent: string,
 *           country: string, tokens: number, chars: number }} data
 * @returns {{ blobs: string[], doubles: number[], indexes: string[] }}
 */
export function formatAnalyticsPayload(data) {
  return {
    blobs: [
      data.normalizedPath,
      data.resolvedPath,
      data.outcome,
      data.accept.substring(0, 256),
      data.userAgent.substring(0, 512),
      data.country,
    ],
    doubles: [1, data.tokens, data.chars],
    indexes: [data.requestedPath],
  };
}

/**
 * Estimates token count from text using whitespace splitting.
 * @param {string} text
 * @returns {number}
 */
export function estimateTokens(text) {
  const trimmed = text.trim();
  if (trimmed.length === 0) {
    return 0;
  }
  return Math.ceil(trimmed.split(/\s+/).length * 0.75);
}

// ---------------------------------------------------------------------------
// ETag helpers (RFC 9110 / RFC 9111)
//
// These pure functions are unit-tested via Tests/MiddlewareTests using
// JavaScriptCore. The actual SHA-1 hashing call lives in _middleware.ts
// (it requires Web Crypto, which JSContext does not expose). Kept in sync
// with Resources/21-dev/functions/logic.js so both sites have identical
// caching semantics.
// ---------------------------------------------------------------------------

/**
 * Wraps a content hash in the weak ETag format `W/"<hash>"`.
 *
 * Weak ETags signal "semantically equivalent" rather than byte-identical,
 * which is the correct semantic when Cloudflare applies content encoding
 * (gzip/brotli) on the wire — same body, different bytes per encoding.
 *
 * @param {string} hash
 * @returns {string}
 */
export function etagHeader(hash) {
  return `W/"${hash}"`;
}

/**
 * Compares a current ETag against a client's `If-None-Match` request header
 * using weak comparison per RFC 9110 §13.1.3 (which mandates weak comparison
 * for `If-None-Match`). Supports the `*` wildcard and comma-separated lists.
 *
 * Both sides are normalized by stripping any leading `W/` prefix so that
 * `W/"abc"` matches `"abc"`.
 *
 * @param {string} currentEtag                  Server's current ETag.
 * @param {string|null|undefined} ifNoneMatch   Raw If-None-Match header value.
 * @returns {boolean}                           True if client cache matches.
 */
export function etagMatches(currentEtag, ifNoneMatch) {
  if (!ifNoneMatch) return false;
  const trimmed = ifNoneMatch.trim();
  if (trimmed === "*") return true;
  const normalize = (e) => (e || "").trim().replace(/^W\//, "");
  const target = normalize(currentEtag);
  return trimmed
    .split(",")
    .map(normalize)
    .some((e) => e === target);
}

/**
 * Builds the headers for a `304 Not Modified` response per RFC 9110 §15.4.5.
 *
 * Always includes the ETag. Carries over a small allowlist of metadata
 * headers (Cache-Control, Vary, Last-Modified, Content-Location) when
 * present on the original 200 response. Deliberately excludes entity
 * headers (Content-Type, Content-Length, Content-Encoding) since 304
 * responses have no message body.
 *
 * @param {string} etag
 * @param {Record<string, string>} originalHeaders  Keys may be any case.
 * @returns {Record<string, string>}
 */
export function buildNotModifiedHeaders(etag, originalHeaders = {}) {
  const result = { ETag: etag };
  const allowlist = ["Cache-Control", "Vary", "Last-Modified", "Content-Location"];
  const lower = {};
  for (const key of Object.keys(originalHeaders)) {
    lower[key.toLowerCase()] = originalHeaders[key];
  }
  for (const canonical of allowlist) {
    const value = lower[canonical.toLowerCase()];
    if (value) result[canonical] = value;
  }
  return result;
}

// ---------------------------------------------------------------------------
// HTML Link header helpers
//
// Pure helpers for the HTML pass-through handler to advertise per-page
// markdown-alternate and canonical URLs at the HTTP layer. Companion to the
// markup-level <link> tags injected at build time by AgentDirectiveInjector
// (see Sources/UtilLib/AgentDirective/AgentDirectiveInjector.swift).
//
// Mirrors Vercel docs' agent-friendly content-negotiation pattern: HTTP and
// markup advertise the same alternate + canonical URLs so audit tools that
// only inspect HTTP headers (curl -I, lightweight crawlers) and tools that
// parse rendered HTML both see consistent values.
// ---------------------------------------------------------------------------

/**
 * Computes the canonical URL for a docs.21.dev HTML page.
 *
 * Strips a trailing `/index.html` to match the post-redirect end state
 * established by `_redirects` (`/*\/index.html /:splat/ 301`). Other forms
 * (clean directory paths, `.html` siblings) are returned unchanged.
 *
 * NOTE — defensive strip: in production the `/index.html` form never reaches
 * this function because `_redirects` short-circuits with a 301 before the
 * Pages Function runs. The strip is retained for:
 *   - local development with `wrangler pages dev` (where redirect parity is
 *     not always exact)
 *   - any future routing change that bypasses the redirect
 *   - direct callers of `canonicalUrl` outside the request pipeline.
 *
 * Aligns with the canonical URL emitted in markup by AgentDirectiveInjector
 * via `CanonicalURLDeriver`, so HTTP and markup advertise identical values.
 *
 * @param {string} pathname  URL pathname including leading slash.
 * @returns {string}         Absolute canonical URL.
 */
export function canonicalUrl(pathname) {
  const cleaned = pathname.endsWith("/index.html")
    ? pathname.slice(0, -"index.html".length)
    : pathname;
  return `https://docs.21.dev${cleaned}`;
}

/**
 * Builds the full `Link` header value for HTML responses on docs.21.dev.
 *
 * Emits five link entries (RFC 8288 §3 comma-separated):
 *   - rel="llms-txt" → `/llms.txt` (catalog: agent-discovery index)
 *   - rel="llms-full-txt" → `/llms-full.txt` (catalog: full LLM context)
 *   - rel="sitemap" → `/sitemap.xml` (catalog: machine-readable URL list)
 *   - rel="alternate" type="text/markdown" → per-page markdown URL via
 *     `resolveMarkdownPath` (matches the resource agents receive when content-
 *     negotiating with `Accept: text/markdown`).
 *   - rel="canonical" → cleaned self-URL via `canonicalUrl`.
 *
 * NOTE — Pivot rationale (Apr 2026): the catalog relations (`llms-txt`,
 * `llms-full-txt`, `sitemap`) were previously set by the `_headers` catch-all
 * `/*` rule. That leaked them onto markdown asset responses, and Cloudflare
 * Pages did NOT honor the documented `! HeaderName` detach syntax to remove
 * them. Moving the catalog Link relations here ensures they only appear on
 * HTML responses (markdown assets are excluded from this handler via
 * `_routes.json`). Mirrors Vercel's agent-friendly content-negotiation
 * pattern — HTTP and markup advertise the same alternate/canonical URLs.
 *
 * @param {string} pathname  URL pathname including leading slash.
 * @returns {string}         Link header value (no leading "Link: ").
 */
export function buildHtmlLinkHeader(pathname) {
  const mdPath = resolveMarkdownPath(pathname);
  const canonical = canonicalUrl(pathname);
  return [
    `</llms.txt>; rel="llms-txt"`,
    `</llms-full.txt>; rel="llms-full-txt"`,
    `</sitemap.xml>; rel="sitemap"`,
    `<${mdPath}>; rel="alternate"; type="text/markdown"`,
    `<${canonical}>; rel="canonical"`,
  ].join(", ");
}
