import {
  resolveRedirect,
  etagHeader,
  etagMatches,
  buildNotModifiedHeaders,
} from "./logic.js";

/**
 * Truncated SHA-1 hex digest. 16 hex chars = 64 bits, sufficient to make
 * collisions vanishingly unlikely across this site's ~10² pages. SHA-1 is
 * cryptographically broken but ETags are not security-sensitive; this is
 * the de-facto industry standard for edge-side content fingerprinting.
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
  const result = resolveRedirect(url.hostname);
  if (result.redirect) {
    url.hostname = result.target;
    url.port = "";
    return new Response(null, {
      status: 301,
      headers: { Location: url.toString() },
    });
  }

  // --- 2. Default: serve normally, with ETag for HTML responses ---
  try {
    const response = await context.next();

    // ETag only applies to 200 OK HTML pages. Static assets (CSS, sitemap.xml,
    // llms.txt, etc.) already get auto-ETagged by Cloudflare Pages, and
    // tagging error/redirect responses provides no caching value.
    if (response.status !== 200) return response;
    const contentType = response.headers.get("content-type") || "";
    if (!contentType.toLowerCase().startsWith("text/html")) return response;

    // Buffer the body so we can hash it. This sacrifices streaming for
    // ~5ms hashing cost; acceptable since HTML pages here are <200KB.
    const body = await response.arrayBuffer();
    const hash = await sha1Hex(body);
    const etag = etagHeader(hash);

    // Conditional GET → 304 Not Modified (RFC 9110 §13.1.3, §15.4.5)
    const ifNoneMatch = context.request.headers.get("If-None-Match");
    if (etagMatches(etag, ifNoneMatch)) {
      return new Response(null, {
        status: 304,
        headers: buildNotModifiedHeaders(etag, headersToObject(response.headers)),
      });
    }

    // Full 200: copy original headers and inject the ETag
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