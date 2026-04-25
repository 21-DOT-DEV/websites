import {
  CACHE_TTL_SECONDS,
  resolveCountry,
  resolveMarkdownPath,
  isValidMarkdownResponse,
  wantsMarkdown,
  buildMarkdownHeaders,
  formatAnalyticsPayload,
  estimateTokens,
  etagHeader,
  etagMatches,
  buildNotModifiedHeaders,
} from "../logic.js";

/**
 * Truncated SHA-1 hex digest. 16 hex chars = 64 bits — sufficient against
 * collisions across this site's pages. SHA-1 is cryptographically broken
 * but ETags are not security-sensitive; this is the de-facto industry
 * standard for edge-side content fingerprinting.
 *
 * Used only for the markdown negotiation path — that response is built
 * from a `fetch()` body we own in JS, so it is genuinely hashable. Static
 * HTML responses are NOT hashed here; CF Pages auto-emits strong ETags
 * for them and handles `If-None-Match` → 304 natively.
 */
async function sha1Hex(buf: BufferSource, length = 16): Promise<string> {
  const hashBuf = await crypto.subtle.digest("SHA-1", buf);
  return Array.from(new Uint8Array(hashBuf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("")
    .slice(0, length);
}

/**
 * Fire-and-forget Analytics Engine write. Errors are swallowed because the
 * caller will already have produced a valid response by the time we run.
 *
 * Schema is documented in `logic.js#formatAnalyticsPayload`.
 */
function writeAnalytics(
  env: { MD_ANALYTICS?: AnalyticsEngineDataset },
  data: Parameters<typeof formatAnalyticsPayload>[0]
): void {
  try {
    env.MD_ANALYTICS?.writeDataPoint(formatAnalyticsPayload(data));
  } catch (e) {
    console.error("Analytics write failed:", e);
  }
}

/**
 * Handles Accept-based markdown content negotiation for AI agents.
 *
 * Public contract (Cloudflare's Markdown for Agents convention):
 *   `GET /any/path` with `Accept: text/markdown`
 *   → 200 OK, `Content-Type: text/markdown; charset=utf-8`
 *   plus `X-Markdown-Tokens`, `Content-Signal`, weak ETag, Vary: Accept.
 *
 * Returns a `Response` when the request asks for markdown AND a
 * corresponding `.md` file exists at the resolved path. Returns `null`
 * to delegate to the next handler when:
 *
 *   1. The request did not opt in to markdown (no `Accept: text/markdown`).
 *   2. The resolved `.md` file is missing or returns SPA-fallback HTML
 *      (analytics outcome: "miss"). Falling through to HTML preserves
 *      graceful degradation: AI crawlers asking for markdown at a path
 *      without a `.md` variant still get useful content rather than 404.
 *   3. The subrequest threw (logged via console.error).
 *
 * Conditional GETs are honoured: if the client's `If-None-Match` matches
 * the response ETag (weak comparison per RFC 9110 §13.1.3), a `304 Not
 * Modified` is returned with no body and an allowlist of metadata
 * headers (see `buildNotModifiedHeaders`).
 *
 * Cloudflare's edge cache key does NOT include the `Accept` request
 * header by default, so this handler is paired with the HTML handler's
 * `CDN-Cache-Control: no-store` directive — without it a single cached
 * HTML response would be served regardless of `Accept`, breaking
 * negotiation. See `_handlers/html.ts` for the full reasoning.
 */
export async function handleMarkdownNegotiation(
  context: EventContext<unknown, string, unknown>
): Promise<Response | null> {
  const accept = context.request.headers.get("Accept") || "";
  if (!wantsMarkdown(accept)) return null;

  const url = new URL(context.request.url);
  const userAgent = context.request.headers.get("User-Agent") || "";
  const ifNoneMatch = context.request.headers.get("If-None-Match");
  const country = resolveCountry(context.request.headers.get("CF-IPCountry"));
  const mdPath = resolveMarkdownPath(url.pathname);
  const env = context.env as { MD_ANALYTICS?: AnalyticsEngineDataset };

  const logMiss = () =>
    writeAnalytics(env, {
      requestedPath: url.pathname,
      normalizedPath: url.pathname.toLowerCase(),
      resolvedPath: mdPath,
      outcome: "miss",
      accept,
      userAgent,
      country,
      tokens: 0,
      chars: 0,
    });

  try {
    const mdUrl = new URL(mdPath, url.origin);
    const mdResponse = await fetch(mdUrl, {
      headers: { "User-Agent": userAgent },
      cf: { cacheEverything: true, cacheTtl: CACHE_TTL_SECONDS },
    } as RequestInit);

    if (!mdResponse.ok) {
      context.waitUntil(Promise.resolve(logMiss()));
      return null;
    }

    const contentType = mdResponse.headers.get("Content-Type") || "";
    if (!isValidMarkdownResponse(contentType)) {
      // SPA fallback returned HTML — path doesn't actually have markdown.
      context.waitUntil(Promise.resolve(logMiss()));
      return null;
    }

    const body = await mdResponse.text();
    const tokens = estimateTokens(body);
    const chars = body.length;

    // Hash the buffered body for conditional-GET. Body is already
    // materialised above for token estimation, so this is essentially free.
    const hash = await sha1Hex(new TextEncoder().encode(body));
    const etag = etagHeader(hash);
    const baseHeaders = buildMarkdownHeaders(tokens);

    context.waitUntil(
      Promise.resolve(
        writeAnalytics(env, {
          requestedPath: url.pathname,
          normalizedPath: url.pathname.toLowerCase(),
          resolvedPath: mdPath,
          outcome: "served",
          accept,
          userAgent,
          country,
          tokens,
          chars,
        })
      )
    );

    if (etagMatches(etag, ifNoneMatch)) {
      return new Response(null, {
        status: 304,
        headers: buildNotModifiedHeaders(etag, baseHeaders),
      });
    }

    return new Response(body, {
      status: 200,
      headers: { ...baseHeaders, ETag: etag },
    });
  } catch (err) {
    console.error("Markdown negotiation failed:", err);
    return null;
  }
}
