/**
 * Analytics Engine Schema (dataset: "markdown_serves")
 *
 * Blobs:
 *   blob1  — requested path    (e.g. /documentation/p256k or /documentation/p256k/)
 *   blob2  — resolved md path  (e.g. /data/documentation/p256k.md)
 *   blob3  — outcome           ("served" | "miss")
 *   blob4  — accept header     (raw Accept value)
 *   blob5  — user agent        (raw UA string, filter with LIKE at query time)
 *   blob6  — country           (from CF-IPCountry header)
 *
 * Doubles:
 *   double1 — 1                (counter)
 *   double2 — token estimate   (0 on miss)
 *   double3 — content length in chars (0 on miss)
 *
 * Index: requested path
 */

function estimateTokens(text: string): number {
  return Math.ceil(text.split(/\s+/).length * 0.75);
}

function writeAnalytics(
  env: { MD_ANALYTICS?: AnalyticsEngineDataset },
  data: {
    requestedPath: string;
    resolvedPath: string;
    outcome: string;
    accept: string;
    userAgent: string;
    country: string;
    tokens: number;
    chars: number;
  }
) {
  try {
    env.MD_ANALYTICS?.writeDataPoint({
      blobs: [
        data.requestedPath,
        data.resolvedPath,
        data.outcome,
        data.accept.substring(0, 256),
        data.userAgent.substring(0, 512),
        data.country,
      ],
      doubles: [1, data.tokens, data.chars],
      indexes: [data.requestedPath],
    });
  } catch (e) {
    console.error("Analytics write failed:", e);
  }
}

const NON_PAGE_EXT = /\.(css|js|json|png|jpe?g|gif|webp|avif|svg|woff2?|ico|xml|txt|md|map|wasm)$/i;

export async function onRequest(context: EventContext<unknown, string, unknown>) {
  const url = new URL(context.request.url);

  // --- 1. Redirect pages.dev traffic to custom domain ---
  if (url.hostname === "docs-21-dev.pages.dev") {
    url.hostname = "docs.21.dev";
    url.port = "";
    return new Response(null, {
      status: 301,
      headers: { Location: url.toString() },
    });
  }

  // --- 2. Markdown content negotiation for AI agents ---
  const accept = context.request.headers.get("Accept") || "";
  const userAgent = context.request.headers.get("User-Agent") || "";
  const wantsMarkdown = accept.includes("text/markdown");
  const isPage = !NON_PAGE_EXT.test(url.pathname);

  if (wantsMarkdown && isPage) {
    let mdPath: string;
    if (url.pathname.endsWith("/index.html")) {
      mdPath = "/data" + url.pathname.replace(/\/index\.html$/, ".md");
    } else if (url.pathname.endsWith(".html")) {
      mdPath = "/data" + url.pathname.replace(/\.html$/, ".md");
    } else {
      const stripped = url.pathname.endsWith("/") ? url.pathname.slice(0, -1) : url.pathname;
      mdPath = "/data" + stripped + ".md";
    }

    try {
      const mdUrl = new URL(mdPath, url.origin);
      const mdResponse = await fetch(mdUrl, {
        headers: { "User-Agent": userAgent },
        cf: { cacheEverything: true, cacheTtl: 3600 },
      });

      if (mdResponse.ok) {
        const body = await mdResponse.text();
        const tokens = estimateTokens(body);
        const chars = body.length;

        context.waitUntil(writeAnalytics(context.env as any, {
          requestedPath: url.pathname,
          resolvedPath: mdPath,
          outcome: "served",
          accept,
          userAgent,
          country: context.request.headers.get("CF-IPCountry") || "unknown",
          tokens,
          chars,
        }));

        return new Response(body, {
          status: 200,
          headers: {
            "Content-Type": "text/markdown; charset=utf-8",
            "X-Markdown-Tokens": String(tokens),
            "Content-Signal": "ai-input=yes, search=yes, ai-train=yes",
            "Cache-Control": "public, max-age=3600",
            "Vary": "Accept",
          },
        });
      }

      // Markdown file not found — log miss, fall through to HTML
      context.waitUntil(writeAnalytics(context.env as any, {
        requestedPath: url.pathname,
        resolvedPath: mdPath,
        outcome: "miss",
        accept,
        userAgent,
        country: context.request.headers.get("CF-IPCountry") || "unknown",
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