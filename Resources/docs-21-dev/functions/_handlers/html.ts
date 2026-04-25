/**
 * Default HTML pass-through with edge-cache opt-out.
 *
 * Forwards the request to Cloudflare Pages' static asset pipeline via
 * `context.next()` and, for `text/html` responses only, sets
 * `CDN-Cache-Control: no-store` so Cloudflare's edge cache does NOT
 * retain the response.
 *
 * ## Why edge cache must be disabled for HTML
 *
 * The markdown negotiation handler relies on running on every request.
 * Cloudflare Pages' default cache key is URL-only — it does not include
 * the `Accept` request header, even when the response carries `Vary:
 * Accept`. (`Vary` is a *browser*-cache directive, not a CDN cache-key
 * input.) Without this opt-out, the first response cached at an edge —
 * typically HTML — would be served to subsequent requests regardless of
 * `Accept`, breaking content negotiation for AI agents.
 *
 * ## What is preserved
 *
 *   - **Browser caching**: the response's `Cache-Control: public,
 *     max-age=300, stale-while-revalidate=86400` is unchanged. Browsers
 *     ignore `CDN-Cache-Control` and continue to honour the main header
 *     for their own cache, so repeat visits are still instant.
 *   - **End-to-end ETag / 304**: Cloudflare Pages emits a strong ETag for
 *     every static-asset response. With the edge cache disabled, the
 *     middleware runs every request, but the conditional-GET round trip
 *     still terminates at Pages' origin and returns `304 Not Modified`
 *     when `If-None-Match` matches.
 *   - **All response headers** (CSP, HSTS, security headers, etc.) flow
 *     through unmodified — only `CDN-Cache-Control` is added.
 *
 * ## Trade-off
 *
 * Each cold HTML view incurs one origin fetch per edge location instead
 * of an edge cache hit (~20-50 ms additional latency). For a docs site
 * this is acceptable; the AI-agent traffic that motivated negotiation
 * would have been a cache miss on `Accept` anyway.
 *
 * ## Industry alignment
 *
 * The pattern matches Cloudflare's own "Markdown for Agents" feature
 * (https://blog.cloudflare.com/markdown-for-agents/) — a server-side
 * implementation must opt out of edge caching for the negotiated paths
 * to function correctly.
 *
 * Non-HTML responses (CSS, JS, JSON, .md, etc.) are returned untouched
 * and remain edge-cacheable.
 */
export async function handleHtmlPassthrough(
  context: EventContext<unknown, string, unknown>
): Promise<Response> {
  try {
    const response = await context.next();
    const contentType = response.headers.get("Content-Type") || "";
    if (!contentType.startsWith("text/html")) {
      return response;
    }

    const headers = new Headers(response.headers);
    headers.set("CDN-Cache-Control", "no-store");
    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    });
  } catch (err) {
    console.error("HTML pass-through failed:", err);
    return new Response("Internal Server Error", { status: 500 });
  }
}
