// Analytics Engine schema: see formatAnalyticsPayload() in logic.js

import {
  CACHE_TTL_SECONDS,
  resolveCountry,
  resolveRedirect,
  resolveMarkdownPath,
  isValidMarkdownResponse,
  wantsMarkdown,
  buildMarkdownHeaders,
  formatAnalyticsPayload,
  estimateTokens,
  etagHeader,
  etagMatches,
  buildNotModifiedHeaders,
} from "./logic.js";

function writeAnalytics(
  env: { MD_ANALYTICS?: AnalyticsEngineDataset },
  data: Parameters<typeof formatAnalyticsPayload>[0]
) {
  try {
    env.MD_ANALYTICS?.writeDataPoint(formatAnalyticsPayload(data));
  } catch (e) {
    console.error("Analytics write failed:", e);
  }
}

/**
 * Truncated SHA-1 hex digest. 16 hex chars = 64 bits, sufficient against
 * collisions across this site's pages. SHA-1 is cryptographically broken
 * but ETags are not security-sensitive; this is the de-facto industry
 * standard for edge-side content fingerprinting.
 */
async function sha1Hex(buf: BufferSource, length = 16): Promise<string> {
  const hashBuf = await crypto.subtle.digest("SHA-1", buf);
  const hex = Array.from(new Uint8Array(hashBuf))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return hex.slice(0, length);
}

/** Materialize a Headers instance into a plain object for the pure helpers. */
function headersToObject(headers: Headers): Record<string, string> {
  const out: Record<string, string> = {};
  headers.forEach((value, key) => {
    out[key] = value;
  });
  return out;
}

export async function onRequest(context: EventContext<unknown, string, unknown>) {
  const url = new URL(context.request.url);

  // --- 1. Redirect pages.dev traffic to custom domain ---
  const redirect = resolveRedirect(url.hostname);
  if (redirect.redirect) {
    url.hostname = redirect.target;
    url.port = "";
    return new Response(null, {
      status: 301,
      headers: { Location: url.toString() },
    });
  }

  // --- 2. Markdown content negotiation for AI agents ---
  const accept = context.request.headers.get("Accept") || "";
  const userAgent = context.request.headers.get("User-Agent") || "";
  const ifNoneMatch = context.request.headers.get("If-None-Match");
  if (wantsMarkdown(accept)) {
    const mdPath = resolveMarkdownPath(url.pathname);

    try {
      const mdUrl = new URL(mdPath, url.origin);
      const mdResponse = await fetch(mdUrl, {
        headers: { "User-Agent": userAgent },
        cf: { cacheEverything: true, cacheTtl: CACHE_TTL_SECONDS },
      });

      if (mdResponse.ok) {
        const contentType = mdResponse.headers.get("Content-Type") || "";
        if (!isValidMarkdownResponse(contentType)) {
          // SPA fallback served HTML — not a real markdown file
          // Fall through to miss logging
        } else {
          const body = await mdResponse.text();
          const tokens = estimateTokens(body);
          const chars = body.length;

          // Hash the markdown body for conditional-GET support. The body
          // is already buffered above for token estimation, so this is
          // essentially free.
          const bodyBytes = new TextEncoder().encode(body);
          const hash = await sha1Hex(bodyBytes);
          const etag = etagHeader(hash);
          const baseHeaders = buildMarkdownHeaders(tokens);

          context.waitUntil(writeAnalytics(context.env as any, {
            requestedPath: url.pathname,
            normalizedPath: url.pathname.toLowerCase(),
            resolvedPath: mdPath,
            outcome: "served",
            accept,
            userAgent,
            country: resolveCountry(context.request.headers.get("CF-IPCountry")),
            tokens,
            chars,
          }));

          // Conditional GET → 304 Not Modified
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
        }
      }

      // Markdown file not found — log miss, fall through to HTML
      context.waitUntil(writeAnalytics(context.env as any, {
        requestedPath: url.pathname,
        normalizedPath: url.pathname.toLowerCase(),
        resolvedPath: mdPath,
        outcome: "miss",
        accept,
        userAgent,
        country: resolveCountry(context.request.headers.get("CF-IPCountry")),
        tokens: 0,
        chars: 0,
      }));
    } catch {
      // Fetch for markdown failed — fall through to normal serving
    }
  }

  // --- 3. Default: serve normally, with ETag for HTML responses ---
  try {
    const response = await context.next();

    // ETag only applies to 200 OK HTML pages. Static assets (CSS, JSON,
    // sitemap.xml, llms.txt, etc.) already get auto-ETagged by Cloudflare
    // Pages, and tagging error/redirect responses provides no caching value.
    if (response.status !== 200) return response;
    const contentType = response.headers.get("content-type") || "";
    if (!contentType.toLowerCase().startsWith("text/html")) return response;

    const body = await response.arrayBuffer();
    const hash = await sha1Hex(body);
    const etag = etagHeader(hash);

    if (etagMatches(etag, ifNoneMatch)) {
      return new Response(null, {
        status: 304,
        headers: buildNotModifiedHeaders(etag, headersToObject(response.headers)),
      });
    }

    const newHeaders = new Headers(response.headers);
    newHeaders.set("ETag", etag);
    if (!newHeaders.has("Vary")) {
      newHeaders.set("Vary", "Accept-Encoding");
    }
    return new Response(body, {
      status: 200,
      statusText: response.statusText,
      headers: newHeaders,
    });
  } catch (err) {
    return new Response("Internal Server Error", { status: 500 });
  }
}