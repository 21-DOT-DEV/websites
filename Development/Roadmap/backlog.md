# Backlog

Ideas not yet assigned to a roadmap phase. When one is picked up, write the
plan first (copy `../Specs/_template/` to `../Specs/NNN-slug/`) and set its
`phase` in frontmatter.

## Follow-ups with owners

- **Promote `development-docs.yml` to a required check** — needs an
  always-running wrapper job that decides "did docs change?" inside itself
  and reports success/skipped/failure accordingly. A path-filtered workflow
  cannot be required (skipped required checks stay "Pending" and block
  unrelated PRs). Advisory while the system beds in.
- **Header policy post-ship enhancements** (left over from
  `Specs/003-cloudflare-headers`): annotate `_headers.dev`/`_headers.prod`
  sources with inline guidance for extending CSP allowlists; emit structured
  deploy logs of applied header patterns; add `curl -I` smoke-test steps to
  deployment workflows.
- **PR-comment validation** (left over from `Specs/005-pr-deployment-comments`):
  exercise `util comment` on a real deployment PR — now covered by normal PR
  flow, remove when observed working.
- **`util links check --external`** (follow-up to the planned `util links
  check` — see Phase 3 Feature 9): scheduled, non-blocking external-link
  scan. Needs bot-handling before it can report
  honestly — contact-bearing user agent, HEAD→GET fallback, retries, and
  severity grading (only 404/410/DNX are errors; 403/429/5xx are warnings).
  Never a required check; weekly cron at most.
- **Plausible (contingent fallback)** — self-hosted beacon analytics,
  activated only if a concrete need for custom-event/funnel measurement
  appears that edge analytics can't answer. Demoted from Phase 7 Feature 1
  when analytics was rescoped to server-side edge collection (2026-11-05);
  see `phase-7-advanced-features-and-analytics.md`.
- **21.dev asset hashing → `immutable` caching** — extend the `?v=`
  cache-busting pattern (already used for favicons) to `style.css`, images,
  and SVG, then flip `/static/*` `/assets/*` `/images/*` to `immutable`.
  `_headers.prod`'s own comment marks this "daily caching until filenames
  are hashed"; Now-tier item, see `README.md` Performance Track item 4.
- **FR/SC citation checks in `Development/Tools`**: port the sibling repos'
  cross-reference validation — every `FR-NNN` a `spec.md` defines cited in
  `plan.md`/`tasks.md`, every `SC-NNN` cited in the plan's Verification, no
  dangling cites. Today `spec.md` is an unchecked companion (Specs/006 and
  007 are the first); the format's accuracy rests on writer discipline.

## Unphased ideas (industry-practice survey)

Based on static site infrastructure analysis, here are additional features to consider for future phases:

**Security & Trust**:
- **security.txt** file (RFC 9116) at `/.well-known/security.txt` for vulnerability disclosure
- **Content Security Policy (CSP)** headers to prevent XSS attacks
- **Subresource Integrity (SRI)** hashes for any CDN resources

**Developer Experience**:
- **humans.txt** file crediting contributors and tools used
- **Changelog page** (separate from blog) for package version updates
- **Status page** or uptime badge showing service availability

**SEO Advanced**:
- **Breadcrumb structured data** for documentation navigation
- **FAQ structured data** for common questions pages
- **Video/Article structured data** if adding multimedia content
- **Image sitemaps** if significant visual content exists
- **News sitemap** if publishing news-worthy content frequently

**Performance Advanced**:
- **Resource hints** (preconnect, dns-prefetch, preload) for critical assets
- **Critical CSS inlining** for above-the-fold content
- **WebP/AVIF image formats** with fallbacks
- **Brotli compression** for text assets (Cloudflare serves it automatically — verify, don't build)
- **103 Early Hints** via `rel=preload` Link headers on `/*` — the `_headers.prod` Link infrastructure already exists; enable Early Hints in the Cloudflare dashboard. (Replaces HTTP/2 Server Push — removed from Chrome 106 / Firefox 132 and deprecated by Cloudflare itself.)

**Content Discovery**:
- **Related posts algorithm** based on tags or content similarity
- **21.dev-scoped search** — Pagefind index + search box for the main site only (~a dozen pages; genuinely low effort). Rescoped 2026-11-04: docs.21.dev's catalog search is already covered by DocC's built-in index, and unified cross-site search was deliberately skipped (see `phase-5-content-accessibility.md` Feature 3).
- **Table of contents** auto-generation for long-form content
- **Reading progress indicator** for blog posts

**Analytics & Monitoring**:
- **CWV field baseline** — CrUX (Chrome UX Report real-user data) + Search Console + PSI (PageSpeed Insights) readings before any client beacon (field data beats lab; `util search-console` already exists; aligns with the server-side analytics direction in Phase 7)
- **Error tracking** (client-side JavaScript errors)
- **Uptime monitoring** via external service (e.g., UptimeRobot)
- **Core Web Vitals dashboard** in analytics

**Social & Community**:
- **Newsletter signup** (via privacy-friendly service)
- **GitHub Discussions integration** for community Q&A
- **Social proof widgets** (GitHub stars, package downloads)
- **Testimonials/case studies** from swift-secp256k1 users

**Accessibility Beyond WCAG**:
- **Dark mode** support (prefers-color-scheme)
- **Reduced motion** support (prefers-reduced-motion)
- **Focus indicators** enhancement (beyond default browser styles)
- **Skip navigation links** for keyboard users

Priority for these additional features should be determined based on:
1. **User feedback and requests** (community-driven prioritization)
2. **Traffic/usage patterns** (data-driven decisions via analytics)
3. **Competitive analysis** (what do similar developer tool sites offer?)
4. **Maintenance burden** (stick to zero-dependency philosophy)

## Selection criteria

Ideas above graduate to the roadmap based on user feedback, traffic/usage data, competitive analysis, and maintenance burden (consistent with the zero-dependency philosophy).

