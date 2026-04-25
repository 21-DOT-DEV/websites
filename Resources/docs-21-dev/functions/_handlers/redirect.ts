import { resolveRedirect } from "../logic.js";

/**
 * Canonicalises the request hostname.
 *
 * Returns a `301 Moved Permanently` response when the incoming hostname is
 * an alias that should redirect to the canonical custom domain (e.g.
 * `docs-21-dev.pages.dev` → `docs.21.dev`). Returns `null` otherwise so the
 * request pipeline can continue to the next handler.
 *
 * Pure policy lives in `logic.js` (`resolveRedirect`) and is unit-tested via
 * JavaScriptCore in `Tests/MiddlewareTests`.
 */
export async function handleHostnameRedirect(
  context: EventContext<unknown, string, unknown>
): Promise<Response | null> {
  const url = new URL(context.request.url);
  const redirect = resolveRedirect(url.hostname);
  if (!redirect.redirect) return null;

  url.hostname = redirect.target;
  url.port = "";
  return new Response(null, {
    status: 301,
    headers: { Location: url.toString() },
  });
}
