/** Cache TTL in seconds, shared between response headers and fetch options. */
export const CACHE_TTL_SECONDS = 3600;

/**
 * Resolves the visitor country from the CF-IPCountry header value.
 * Returns "unknown" when the header is absent or empty.
 * @param {string|null|undefined} header
 * @returns {string}
 */
export function resolveCountry(header) {
  return header || "unknown";
}

/**
 * Determines whether a hostname should be redirected to the custom domain.
 * @param {string} hostname
 * @returns {{ redirect: boolean, target: string }}
 */
export function resolveRedirect(hostname) {
  if (hostname === "docs-21-dev.pages.dev") {
    return { redirect: true, target: "docs.21.dev" };
  }
  return { redirect: false, target: hostname };
}

/**
 * Resolves a URL pathname to the corresponding markdown file path.
 * Index paths map to llms.txt; other paths map to /data/.../*.md.
 * @param {string} pathname
 * @returns {string}
 */
export function resolveMarkdownPath(pathname) {
  const indexPaths = new Set(["/", "/documentation", "/documentation/"]);

  if (indexPaths.has(pathname)) {
    return "/llms.txt";
  } else if (pathname.endsWith("/index.html")) {
    return "/data" + pathname.replace(/\/index\.html$/, ".md");
  } else if (pathname.endsWith(".html")) {
    return "/data" + pathname.replace(/\.html$/, ".md");
  } else {
    const stripped = pathname.endsWith("/") ? pathname.slice(0, -1) : pathname;
    return "/data" + stripped + ".md";
  }
}

/**
 * Checks whether a Content-Type header indicates a valid markdown response.
 * Returns false for text/html (SPA fallback), true for everything else.
 * @param {string} contentType
 * @returns {boolean}
 */
export function isValidMarkdownResponse(contentType) {
  return !contentType.includes("text/html");
}

/**
 * Determines whether the Accept header indicates a preference for markdown.
 * @param {string} accept
 * @returns {boolean}
 */
export function wantsMarkdown(accept) {
  return accept.includes("text/markdown");
}

/**
 * Builds the response headers for a served markdown file.
 * @param {number} tokens
 * @returns {Record<string, string>}
 */
export function buildMarkdownHeaders(tokens) {
  return {
    "Content-Type": "text/markdown; charset=utf-8",
    "X-Markdown-Tokens": String(tokens),
    "Content-Signal": "ai-input=yes, search=yes, ai-train=yes",
    "Cache-Control": `public, max-age=${CACHE_TTL_SECONDS}`,
    "Vary": "Accept",
  };
}

/**
 * Formats analytics data into the Analytics Engine wire format.
 *
 * Schema (dataset: "markdown_serves"):
 *   blob1=requestedPath, blob2=resolvedPath, blob3=outcome,
 *   blob4=accept (max 256), blob5=userAgent (max 512), blob6=country
 *   double1=1 (counter), double2=tokens, double3=chars
 *   index=requestedPath
 *
 * @param {{ requestedPath: string, resolvedPath: string, outcome: string,
 *           accept: string, userAgent: string, country: string,
 *           tokens: number, chars: number }} data
 * @returns {{ blobs: string[], doubles: number[], indexes: string[] }}
 */
export function formatAnalyticsPayload(data) {
  return {
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
  };
}

/**
 * Estimates token count from text using whitespace splitting.
 * @param {string} text
 * @returns {number}
 */
export function estimateTokens(text) {
  const trimmed = text.trim();
  if (trimmed.length === 0) {
    return 0;
  }
  return Math.ceil(trimmed.split(/\s+/).length * 0.75);
}
