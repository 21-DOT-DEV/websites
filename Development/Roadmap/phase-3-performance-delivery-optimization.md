# Phase 3 — Performance & Delivery Optimization

**Status:** In Progress
**Priority:** Medium-High
**Last Updated:** 2026-11-05

## Phase Goal

Optimize caching, delivery, and site structure to achieve excellent Core Web Vitals, strong security posture, and reliable content delivery.

## Features

### Feature 1 — Open Graph & Twitter Card Meta Tags
- **Name:** Open Graph & Twitter Card Meta Tags
- **Status:** Completed
- **Purpose & user value:** Control how links appear when shared on social media (LinkedIn, Twitter, Facebook) with proper titles, descriptions, and preview images. Increases click-through rates by 2-3x and creates professional appearance in link previews.
- **Success metrics:**
  - 100% of pages have proper Open Graph tags (og:title, og:description, og:url, og:type)
  - og:image present on all pages (1200x630px recommended size)
  - Twitter Card tags properly configured (twitter:card, fallback to Open Graph)
  - Social media link previews render correctly across all platforms
  - Zero missing meta tag warnings in social media debugger tools
- **Dependencies:** Brand Assets & Favicons (for og:image generation)
- **Notes:** Shipped via `OpenGraphConfig` (DesignSystem) + `SiteDefaults.openGraphConfig` with `summary_large_image` cards and `Resources/21-dev/images/og-image.png` (1200×600).

### Feature 2 — Theme Color Meta Tag
- **Name:** Theme Color Meta Tag
- **Status:** Completed
- **Purpose & user value:** Enables mobile browser UI theming to match site branding. Improves mobile UX by coloring browser chrome with brand color (#f97316 orange).
- **Success metrics:**
  - Theme color meta tag present on all pages
  - Mobile browsers (Chrome, Safari, Edge) display correct brand color in UI
  - Consistent brand experience across desktop and mobile
- **Dependencies:** None
- **Notes:** Simple one-line addition to BasePage. Uses existing brand color from Tailwind palette.

### Feature 3 — Core Web Vitals Optimization
- **Name:** Core Web Vitals Optimization
- **Status:** Not Started
- **Purpose & user value:** Systematically improve Largest Contentful Paint (LCP), Interaction to Next Paint (INP), and Cumulative Layout Shift (CLS) to provide faster, smoother user experiences and improve search rankings.
- **Success metrics:**
  - LCP: 100% of pages achieve "Good" (< 2.5s)
  - INP: 95%+ achieve "Good" (< 200ms)
  - CLS: 100% achieve "Good" (< 0.1)
  - P99 latency improves from 5,908ms to < 3,000ms
  - Lighthouse Performance score ≥ 95 for all pages
- **Dependencies:** Cloudflare _headers Optimization (caching needed for LCP improvement).
- **Notes:** docs.21.dev has "needs improvement" segment; P99 latency concerning.

### Feature 4 — HTML `<head>` Hygiene & SEO
- **Name:** HTML `<head>` Hygiene & SEO
- **Status:** Completed
- **Purpose & user value:** Implement comprehensive meta tags, structured data, and proper head elements to maximize search visibility and discoverability.
- **Success metrics:**
  - ✅ All pages have unique meta descriptions (140-160 chars)
  - ✅ Language tag (lang="en") on HTML element
  - ✅ Article metadata (published_time, author, tags) for blog posts
  - ✅ Schema.org JSON-LD structured data for Organization, Website, BlogPosting
  - ✅ Canonical URLs prevent duplicate content issues
- **Dependencies:** Open Graph & Twitter Cards (Features 1-2 handle social meta tags).
- **Completed:**
  - Meta descriptions on all pages (Homepage, P256K, Blog listing, Blog posts)
  - Article metadata using BlogMetadata with adapter pattern
  - Language attribute for accessibility and SEO
  - Schema.org JSON-LD via the `SchemaLib` target (Organization, WebSite, WebPage, BlogPosting, TechArticle, BreadcrumbList, FAQ, SoftwareApplication)

### Feature 5 — Brand Assets & Favicons
- **Name:** Brand Assets & Favicons
- **Status:** Completed
- **Purpose & user value:** Provide professional favicon suite, app icons, and Open Graph images to improve brand recognition, mobile home screen experience, and social media presence.
- **Success metrics:**
  - Favicons present in all required formats (16x16, 32x32, ico, svg)
  - Apple Touch Icons (180x180) for iOS home screen
  - Open Graph images (1200x630) for social previews
  - Web app manifest with PWA icons (192x192, 512x512)
  - Theme color meta tag for mobile browsers
- **Dependencies:** None (can use placeholder assets initially).
- **Notes:** Shipped — `favicon.ico`, `favicon-96x96.png`, `apple-touch-icon.png`, `site.webmanifest` with 192/512 icons, and `og-image.png` all live in `Resources/21-dev/`; `FaviconConfig` emits the tags with cache-busting versions.

### Feature 6 — Content Security Policy (CSP) & Security Headers
- **Name:** Content Security Policy (CSP) & Security Headers
- **Status:** Completed
- **Purpose & user value:** Implement strict Content Security Policy headers to prevent XSS attacks and other injection vulnerabilities, protecting users and maintaining trust in the platform.
- **Success metrics:**
  - CSP headers deployed via _headers file
  - Report-only mode passes validation (zero legitimate violations)
  - Strict CSP mode enabled after monitoring period
  - Zero XSS vulnerabilities reported
  - Security headers present (X-Frame-Options, X-Content-Type-Options, Referrer-Policy)
- **Dependencies:** Cloudflare _headers Optimization (shares same file).
- **Notes:** Shipped in `_headers.prod`/`.dev` for both sites and verified via Google CSP Evaluator (Phase 1 Feature 3 notes).

### Feature 7 — security.txt & Vulnerability Disclosure
- **Name:** security.txt & Vulnerability Disclosure
- **Status:** Not Started
- **Purpose & user value:** Provide RFC 9116 compliant security.txt file for responsible vulnerability disclosure, enabling security researchers to report issues properly.
- **Success metrics:**
  - security.txt deployed at /.well-known/security.txt
  - Contact email, disclosure policy, and expiration date present
  - File passes validation at securitytxt.org
  - Security researchers can find disclosure process easily
  - File renewed annually (expires field updated)
- **Dependencies:** None.
- **Notes:** Industry best practice for open source projects; GitHub, Cloudflare, Mozilla all have this.

### Feature 8 — Performance Budgets & CI Enforcement
- **Name:** Performance Budgets & CI Enforcement
- **Status:** Not Started
- **Purpose & user value:** Establish and enforce performance budgets in CI to prevent regressions, ensuring fast load times remain consistent across all deployments.
- **Success metrics:**
  - Lighthouse CI integrated with performance budgets
  - HTML < 100KB, CSS < 50KB, JS < 50KB per page (enforced)
  - Bundle size tracking prevents regressions
  - CI fails if performance budgets exceeded
  - Real User Monitoring (RUM) tracks actual user performance
- **Dependencies:** Core Web Vitals Optimization (baseline metrics needed).
- **Notes:** Ongoing monitoring, not one-time optimization; prevents performance decay.

### Feature 9 — Broken Link Detection & Monitoring
- **Name:** Broken Link Detection & Monitoring
- **Status:** In Progress (spec'd — Specs/006)
- **Purpose & user value:** Automatically detect and prevent broken internal/external links through CI checks and scheduled scans, maintaining documentation quality and user trust.
- **Success metrics:**
  - CI blocks PRs with broken internal links (100% catch rate)
  - Weekly scheduled scans for external links
  - Zero broken links across all three subdomains
  - Automated alerts for external link decay
  - Link check runs in < 2 minutes
- **Dependencies:** None.
- **Notes:** Approach settled and spec'd (Specs/006), implementation pending — build a `util links check` command rather than adopting lychee: internal links resolve against generated output on disk at build time (no HTTP), matching the DocC warnings-as-errors and Docusaurus `onBrokenLinks: 'throw'` model. External checks are deferred to a `--external` scheduled scan (backlog) — external probes need bot-handling (UA, 429/403 grading, retries) that has no place in a blocking gate.

### Feature 10 — Social Proof & Metrics Display
- **Name:** Social Proof & Metrics Display
- **Status:** Not Started
- **Purpose & user value:** Display GitHub stars, download counts, and usage statistics to build trust and social proof, increasing package adoption through visible community validation.
- **Success metrics:**
  - GitHub stars badge displayed on package page
  - "Used by X projects" count with sources cited
  - Metrics update automatically (daily or weekly)
  - Conversion rate improves by 10%+ after metrics added
  - Trust signals visible without JavaScript fallback
- **Dependencies:** Brand Assets & Favicons (badges are visual elements).
- **Notes:** Use shields.io or static snapshots; npm, PyPI, crates.io all show download counts.

### Feature 11 — AI/GEO Readiness Verification & Gap Closure
- **Name:** AI/GEO Readiness Verification & Gap Closure
- **Status:** Not Started
- **Purpose & user value:** Verify the shipped AI-readiness surface can't regress and close the remaining known gaps, so search and citation agents (Googlebot, OAI-SearchBot, PerplexityBot, ClaudeBot-class crawlers) can reliably reach, parse, and cite the sites. "GEO" here means generative-engine optimization — being citable in AI answers, not keyword SEO.
- **Success metrics:**
  - `util agent-directive audit` extended with GEO assertions: robots.txt declares an explicit retrieval-vs-training crawler policy, `llms.txt` links resolve, JSON-LD present on indexable pages, freshness signals (visible dates / accurate `lastmod`) verified
  - GEO assertions run in CI so the shipped surface can't silently regress
  - Documented Cloudflare AI Crawl Control dashboard review (covers the CDN-layer case file checks can't see: a WAF rule can deny AI bots even when `robots.txt` allows them)
  - `robots.txt` on all three sites explicitly allows retrieval/search agents and declares a training-crawler policy (allow or disallow — the decision is recorded, not implicit)
- **Dependencies:** None (`agent-directive` command already exists).
- **Notes:** Verify-first, extensible by design — newly established conventions (Content Signals, future AI-agent formats) land as added assertions/items here rather than new features. Honest framing: the shipped `llms.txt`/`context7.json`/content-negotiation work is cheap deployed optionality (independent studies show platforms rarely fetch it yet); the proven surface is crawler access + semantic HTML + JSON-LD + speed, which is what the checks emphasize. Schema types worth extracting (HowTo, Review) are gap items, not prerequisites.

## Phase Dependencies & Sequencing

- Brand Assets & Favicons (Feature 5) → Open Graph & Twitter Cards (Feature 1) → Social Proof & Metrics Display (Feature 10).
- Theme Color (Feature 2) can proceed independently (no dependencies).
- Content Security Policy (CSP) & Security Headers (Feature 6) → Core Web Vitals Optimization (Feature 3).
- Performance Budgets & CI Enforcement (Feature 8) builds on Core Web Vitals Optimization (Feature 3) to enforce baselines.
- security.txt (Feature 7) and Broken Link Detection & Monitoring (Feature 9) can proceed independently.
- HTML `<head>` Hygiene (Feature 4) partially complete; JSON-LD can proceed after Open Graph implementation.
- AI/GEO Readiness Verification (Feature 11) is independent — verification builds on the already-shipped `agent-directive` command; gap items land as they're established.

## Phase Metrics

This phase primarily contributes to product-level metrics for **Performance**, **Security & Trust**, **Infrastructure**, and **Brand Recognition**, especially:
- P75 and P90 LCP improvements and Lighthouse ≥ 95.
- Browser cache hit rate reaches 80%+.
- Zero XSS vulnerabilities reported; strict CSP deployed.
- Zero broken links across subdomains.
- Social media shares include correct previews; favicons and icons present on all platforms.
