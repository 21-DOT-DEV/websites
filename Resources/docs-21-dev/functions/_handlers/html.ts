import {
  buildHtmlLinkHeader,
  isHtmlContentType,
  mergeLinkHeaders,
  AGENT_DISCOVERY,
} from "../logic.js";

/**
 * Default HTML pass-through.
 *
 * Forwards the request to Cloudflare Pages' static asset pipeline via
 * `context.next()` and merges agent-discovery headers (`Link`, `X-Llms-Txt`)
 * onto HTML responses before returning. Non-HTML responses (images, JSON,
 * markdown assets, etc.) are returned unmodified. Cloudflare Pages emits a
 * strong ETag for every static-asset response, so conditional GETs still
 * terminate with `304 Not Modified` when `If-None-Match` matches.
 *
 * ## Headers added on HTML responses
 *
 * Sets the full `Link` header value via `buildHtmlLinkHeader` in `../logic.js`,
 * which emits five link entries (RFC 8288 §3 comma-joined):
 *   - rel="llms-txt" — catalog index `/llms.txt`
 *   - rel="llms-full-txt" — catalog full context `/llms-full.txt`
 *   - rel="sitemap" — catalog URL list `/sitemap.xml`
 *   - rel="alternate" type="text/markdown" — per-page markdown URL
 *   - rel="canonical" — cleaned self-URL (strips trailing `/index.html`)
 *
 * Also sets `X-Llms-Txt: /llms.txt` (Mintlify-pair convention: a simpler,
 * single-value alternative for tooling that doesn't parse RFC 8288 Link
 * headers).
 *
 * ## Why headers are NOT in `_headers /*`
 *
 * The catalog Link relations and X-Llms-Txt were previously set by the
 * `_headers` catch-all `/*` rule. That leaked them onto markdown asset
 * responses (`/data/documentation/**\/*.md`) which agents fetch via
 * `Accept: text/markdown` content negotiation, creating an inconsistent
 * agent contract. Cloudflare Pages does NOT honor the documented
 * `! HeaderName` detach syntax to remove them (verified Apr 2026), so the
 * only clean fix is to not set them on `/*` at all. This handler runs only
 * on paths included in `_routes.json` (HTML pages), so markdown assets
 * naturally don't receive these headers.
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
    if (!isHtmlContentType(response.headers.get("Content-Type"))) {
      return response;
    }
    const url = new URL(context.request.url);
    const merged = new Response(response.body, response);
    merged.headers.set(
      "Link",
      mergeLinkHeaders(
        merged.headers.get("Link"),
        buildHtmlLinkHeader(url.pathname)
      )
    );
    merged.headers.set("X-Llms-Txt", AGENT_DISCOVERY.X_LLMS_TXT_VALUE);
    return merged;
  } catch (err) {
    console.error("HTML pass-through failed:", err);
    return new Response("Internal Server Error", { status: 500 });
  }
}
