import { buildHtmlLinkHeader } from "../logic.js";

/**
 * Default HTML pass-through.
 *
 * Forwards the request to Cloudflare Pages' static asset pipeline via
 * `context.next()` and merges per-page `Link` headers onto HTML responses
 * before returning. Non-HTML responses (images, JSON, etc.) are returned
 * unmodified. Cloudflare Pages emits a strong ETag for every static-asset
 * response, so conditional GETs still terminate with `304 Not Modified`
 * when `If-None-Match` matches.
 *
 * ## Per-page Link headers
 *
 * For HTML responses, this handler appends two link relations (per
 * `buildHtmlLinkHeader` in `../logic.js`):
 *   - rel="alternate" type="text/markdown" — corresponding markdown URL.
 *   - rel="canonical" — cleaned self-URL (strips trailing `/index.html`).
 *
 * Static catalog-style links (`llms-txt`, `llms-full-txt`, `sitemap`) come
 * from the `_headers` catch-all rule and are concatenated by Cloudflare
 * Pages into the final wire value (RFC 8288 §3 comma-joined).
 *
 * Mirrors Vercel docs' agent-friendly content-negotiation pattern; HTTP and
 * markup (injected at build time by `AgentDirectiveInjector`) advertise the
 * same alternate + canonical URLs so HTTP-only audit tools and HTML-parsing
 * agents both see consistent values.
 *
 * ## Cache-key / content negotiation note
 *
 * This handler does NOT set `CDN-Cache-Control: no-store`. Correct
 * content negotiation between HTML and markdown variants relies on the
 * edge cache key differing per `Accept` value, which Cloudflare's
 * default URL-only cache key does not provide. That split is now
 * expected to come from a Cloudflare Transform Rule (configured in the
 * dashboard) that rewrites the query string on
 * `Accept: text/markdown` requests, producing distinct cache keys for
 * HTML and markdown variants without a runtime edge-cache opt-out.
 *
 * If that Transform Rule is ever removed, HTML responses will begin
 * shadowing markdown responses at the edge and negotiation for AI
 * agents will silently break — re-introduce `CDN-Cache-Control:
 * no-store` here (or keep the Transform Rule in place) to restore
 * correctness.
 */
export async function handleHtmlPassthrough(
  context: EventContext<unknown, string, unknown>
): Promise<Response> {
  try {
    const response = await context.next();
    const contentType = response.headers.get("Content-Type") || "";
    if (!contentType.includes("text/html")) {
      return response;
    }
    const url = new URL(context.request.url);
    const linkValue = buildHtmlLinkHeader(url.pathname);
    const merged = new Response(response.body, response);
    const existing = merged.headers.get("Link");
    merged.headers.set(
      "Link",
      existing ? `${existing}, ${linkValue}` : linkValue
    );
    return merged;
  } catch (err) {
    console.error("HTML pass-through failed:", err);
    return new Response("Internal Server Error", { status: 500 });
  }
}
