# Phase 7 — Advanced Features & Analytics

**Status:** Not Started
**Priority:** Medium (Features 1–2 elevated to the Next tier — see `README.md` priority tiers)
**Last Updated:** 2026-11-05

## Phase Goal

Layer in privacy-preserving server-side analytics, legal foundations, sitemap enhancements, and internationalization groundwork once the core site experience is mature.

## Features

### Feature 1 — Server-Side Edge Analytics
- **Name:** Server-Side Edge Analytics
- **Purpose & user value:** Collect privacy-preserving traffic and performance analytics at the Cloudflare edge — requests measured at the CDN with zero client-side JavaScript. Aligns with the private-by-design, server-side priority: nothing is downloaded to or executed in the visitor's browser, ad-blockers can't remove the signal, and the `static.cloudflareinsights.com` CSP exception can be dropped (tighter `script-src`).
- **Success metrics:**
  - Cloudflare edge (proxied) analytics enabled on all three subdomains — no JS beacon deployed
  - `static.cloudflareinsights.com` removed from `connect-src`/`script-src` in `_headers.prod` once no beacon remains
  - Optional Worker-side event writer evaluated only if edge data proves insufficient (URL, referrer, country, device class; IP hashed at edge)
  - Zero GDPR consent popups required (no client-side identifiers, no cookies, no fingerprinting)
  - Documented review cadence for the dashboards (traffic + AI Crawl Control overlap with Phase 3 Feature 11)
- **Dependencies:** Privacy Policy & Legal Pages (edge collection still processes IP-derived request data — the policy must describe it).
- **Notes:** Rescoped 2026-11-05 from "Plausible Analytics Migration." Research: self-hosted Plausible is still a client-side beacon — richer (custom events, funnels, unsampled data) but contradicts the server-side/performance/security priorities. **Plausible is demoted to a contingent fallback**, activated only if a concrete need for custom-event/funnel measurement appears; record it in `backlog.md` rather than delete it. Caveat on the free tier: edge analytics is sampled with ~6-month retention — acceptable for traffic trends at current volume.

### Feature 2 — Privacy Policy & Legal Pages
- **Name:** Privacy Policy & Legal Pages
- **Purpose & user value:** Provide transparent privacy policy explaining data collection practices, meeting GDPR requirements even for cookie-free analytics, building user trust through clear communication.
- **Success metrics:**
  - Privacy policy page deployed at /privacy/
  - Explains what data is collected (IP, page views, referrer)
  - Data retention policy documented (edge-collection defaults; update if a beacon is ever added)
  - GDPR compliance statement included
  - Contact information for data deletion requests
- **Dependencies:** None (but must complete before analytics launch).
- **Notes:** GDPR requires privacy policy even for minimal data collection; builds trust with privacy-conscious developers.

### Feature 3 — Documentation Versioning
- **Name:** Documentation Versioning
- **Purpose & user value:** Enable viewing documentation for different swift-secp256k1 versions, allowing developers to find docs matching their installed package version for accurate API reference.
- **Success metrics:**
  - Version selector dropdown on docs.21.dev (e.g., v0.21.x, v0.22.x, v1.0.x)
  - Separate DocC archives generated per major version
  - Canonical URLs point to latest stable version
  - 80%+ of users find docs for their specific version
  - Zero broken links between version switches
- **Dependencies:** Sitemap Infrastructure Overhaul (version-specific sitemaps needed).
- **Notes:** Implement when multiple major versions exist; Rust Docs, Swift.org, React docs all support version switching.

### Feature 4 — Sitemap Index Generation
- **Name:** Sitemap Index Generation
- **Purpose & user value:** Aggregate all subdomain sitemaps into a unified sitemap index at 21.dev/sitemap.xml for centralized search engine discovery, following sitemap protocol 0.9 best practices for multi-subdomain sites.
- **Success metrics:**
  - Daily cron job fetches all subdomain sitemaps (21.dev, docs.21.dev, md.21.dev)
  - SHA-256 content hashing detects changes and regenerates index only when needed
  - Sitemap index properly references all three subdomain sitemaps with lastmod values
  - Graceful degradation if any subdomain sitemap fetch fails
  - Index submitted to Google/Bing APIs when regenerated (24-hour lag acceptable)
- **Dependencies:** Sitemap Infrastructure Overhaul (individual subdomain sitemaps must exist first).
- **Notes:** Deferred from initial sitemap work in favor of simpler per-subdomain approach; kept here as future enhancement.

### Feature 5 — Internationalization Foundation
- **Name:** Internationalization Foundation
- **Purpose & user value:** Lay groundwork for future multi-language support by implementing proper `lang` attributes, hreflang scaffolding, and i18n-ready URL structures without committing to translations yet.
- **Success metrics:**
  - HTML lang attribute set to "en" on all pages
  - Code structure supports future subdirectory i18n (`/en/`, `/zh/`, etc.)
  - Translation file structure documented but not populated
  - Zero breaking changes required to add first non-English language
  - i18n patterns established in DesignSystem components
- **Dependencies:** HTML `<head>` Hygiene & SEO (lang attributes prerequisite).
- **Notes:** English-only for now; i18n-ready structure for future expansion.

### Feature 6 — Sitemap Priority & Change Frequency Optimization
- **Name:** Sitemap Priority & Change Frequency Optimization
- **Purpose & user value:** Add priority hints and change frequency metadata to sitemaps to help search engines crawl and index content more efficiently based on importance and update cadence.
- **Success metrics:**
  - Homepage has priority 1.0, key pages 0.8, blog posts 0.6
  - Change frequency reflects actual update patterns (daily for blog index, weekly for docs)
  - Crawl efficiency improves by 20%+ (measured via Search Console)
  - Important pages indexed within 24 hours of publication
  - lastmod dates accurate and automatically updated
- **Dependencies:** Sitemap Infrastructure Overhaul.
- **Notes:** Enhancement to basic sitemap behavior; not critical but improves crawl efficiency. **Rescoped 2026-11-05:** Phase 2's backlog note records that Google ignores `<changefreq>` and `<priority>` — this feature's measurable value is near-zero as designed. Candidate to close as Won't-Do or reshape around accurate `<lastmod>` (which crawlers do use) — decision deferred to the next roadmap review; do not schedule as written.

### Feature 7 — GitHub Actions Workflow Validation with actionlint
- **Name:** GitHub Actions Workflow Validation with actionlint
- **Purpose & user value:** Implement automated validation of GitHub Actions workflows including embedded bash scripts to catch syntax errors, undefined variables, and shellcheck violations before CI execution, reducing deployment failures.
- **Success metrics:**
  - SPM plugin wrapper for actionlint created and integrated
  - Local validation command: `swift package actionlint` runs on all workflow files
  - CI workflow validates all YAML + embedded bash on every PR
  - 100% of workflow syntax errors caught before merge
  - shellcheck violations in inline bash detected and reported
  - Zero deployment failures due to workflow syntax issues
  - actionlint runs in < 10 seconds for all workflow files
- **Dependencies:** None (standalone infrastructure improvement).
- **Notes:** Industry standard tool; aligns with constitution’s IaC testing exemption by adding static analysis.

## Phase Dependencies & Sequencing

- Privacy Policy & Legal Pages → Server-Side Edge Analytics.
- Phase 1 sitemap infrastructure (shipped) → Documentation Versioning, Sitemap Index Generation, Sitemap Priority & Change Frequency Optimization.
- HTML `<head>` Hygiene & SEO → Internationalization Foundation.

## Phase Metrics

This phase primarily contributes to product-level metrics for **Privacy & Compliance**, **Analytics & Insights**, **Search & Discoverability**, and **Infrastructure Reliability**, especially:
- Privacy compliance without consent banners.
- Traffic and performance visibility with zero client-side code.
- Improved crawl efficiency and content discovery.
