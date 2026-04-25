/**
 * Default HTML pass-through.
 *
 * Forwards the request to Cloudflare Pages' static asset pipeline via
 * `context.next()` and returns the response unmodified. Cloudflare Pages
 * emits a strong ETag for every static-asset response, so conditional
 * GETs still terminate with `304 Not Modified` when `If-None-Match`
 * matches.
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
    return await context.next();
  } catch (err) {
    console.error("HTML pass-through failed:", err);
    return new Response("Internal Server Error", { status: 500 });
  }
}
