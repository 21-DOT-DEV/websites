/**
 * Determines whether a hostname should be redirected to the custom domain.
 * @param {string} hostname
 * @returns {{ redirect: boolean, target: string }}
 */
export function resolveRedirect(hostname) {
  if (hostname === "21-dev.pages.dev") {
    return { redirect: true, target: "21.dev" };
  }
  return { redirect: false, target: hostname };
}

// ---------------------------------------------------------------------------
// ETag helpers (RFC 9110 / RFC 9111)
//
// These pure functions are unit-tested via Tests/MiddlewareTests using
// JavaScriptCore. The actual SHA-1 hashing call lives in _middleware.ts
// (it requires Web Crypto, which JSContext does not expose).
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
