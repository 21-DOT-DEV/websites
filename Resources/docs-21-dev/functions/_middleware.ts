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

          context.waitUntil(writeAnalytics(context.env as any, {
            requestedPath: url.pathname,
            resolvedPath: mdPath,
            outcome: "served",
            accept,
            userAgent,
            country: resolveCountry(context.request.headers.get("CF-IPCountry")),
            tokens,
            chars,
          }));

          return new Response(body, {
            status: 200,
            headers: buildMarkdownHeaders(tokens),
          });
        }
      }

      // Markdown file not found — log miss, fall through to HTML
      context.waitUntil(writeAnalytics(context.env as any, {
        requestedPath: url.pathname,
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

  // --- 3. Default: serve normally with error handling ---
  try {
    return await context.next();
  } catch (err) {
    return new Response("Internal Server Error", { status: 500 });
  }
}