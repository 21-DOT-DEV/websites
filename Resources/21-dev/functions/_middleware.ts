import { resolveRedirect } from "./logic.js";

// NOTE on ETags / conditional GETs:
//
// We deliberately do NOT compute custom ETags for HTML responses here.
// Cloudflare Pages auto-emits a strong ETag for every static-asset 200 OK
// response (HTML included) and natively handles `If-None-Match` → 304:
//   https://developers.cloudflare.com/pages/configuration/serving-pages/
//
// An earlier revision of this middleware tried to buffer the response body
// via `await response.arrayBuffer()` and emit a weak SHA-1 ETag, but for
// static assets CF Pages serves the body via its asset pipeline AFTER the
// function returns — `arrayBuffer()` returns 0 bytes, producing the constant
// SHA-1-of-empty-string `da39a3ee…` for every page. That actively broke
// revalidation (every page hashed identically). Trusting CF's native ETag
// is both correct and simpler.
//
// The pure ETag helpers in `./logic.js` remain because they are still used
// by docs-21-dev's markdown content-negotiation path (where the response
// body is materialized via `fetch()` and is genuinely hashable in JS).

export async function onRequest(context: EventContext<unknown, string, unknown>) {
  const url = new URL(context.request.url);

  const result = resolveRedirect(url.hostname);
  if (result.redirect) {
    url.hostname = result.target;
    url.port = "";
    return new Response(null, {
      status: 301,
      headers: { Location: url.toString() },
    });
  }

  try {
    return await context.next();
  } catch (err) {
    return new Response("Internal Server Error", { status: 500 });
  }
}