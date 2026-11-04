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
- **Brotli compression** for text assets
- **HTTP/2 Server Push** for critical resources (via Cloudflare)

**Content Discovery**:
- **Related posts algorithm** based on tags or content similarity
- **Search functionality** (client-side with lunr.js or Pagefind, no server required)
- **Table of contents** auto-generation for long-form content
- **Reading progress indicator** for blog posts

**Analytics & Monitoring**:
- **Real User Monitoring (RUM)** for actual performance data
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

