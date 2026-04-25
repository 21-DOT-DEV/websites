import { handleHostnameRedirect } from "./_handlers/redirect.js";
import { handleMarkdownNegotiation } from "./_handlers/markdown.js";
import { handleHtmlPassthrough } from "./_handlers/html.js";

/**
 * Request pipeline for `docs.21.dev`.
 *
 * Each handler returns a `Response` when it claims ownership of the
 * request, or `null` to delegate to the next handler. The orchestrator
 * stays linear and free of business logic; all policy lives in
 * `./logic.js` (pure, unit-tested via JavaScriptCore) and all I/O lives
 * in the individual handler modules.
 *
 *   1. **Hostname redirect** — canonicalise `*.pages.dev` aliases to the
 *      production custom domain.
 *   2. **Markdown negotiation** — serve markdown to AI agents that opt
 *      in via `Accept: text/markdown`. Aligns with Cloudflare's
 *      "Markdown for Agents" convention while serving the project's
 *      authored DocC markdown rather than auto-converting from HTML.
 *   3. **HTML pass-through** — default static-asset serving with edge
 *      cache disabled for HTML so step 2 runs on every request.
 *
 * Analytics Engine schema: see `formatAnalyticsPayload` in `./logic.js`.
 */
export async function onRequest(
  context: EventContext<unknown, string, unknown>
): Promise<Response> {
  return (
    (await handleHostnameRedirect(context)) ??
    (await handleMarkdownNegotiation(context)) ??
    (await handleHtmlPassthrough(context))
  );
}