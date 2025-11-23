# Phase 1 — Foundation & Discoverability

**Status:** In Progress
**Priority:** High
**Last Updated:** 2025-11-20

## Phase Goal

Ensure all content across 21.dev, docs.21.dev, and md.21.dev is discoverable, mobile-friendly, and search-optimized with a solid foundation for future roadmap work.

## Features

### Feature 1 — Sitemap Infrastructure Overhaul
- **Name:** Sitemap Infrastructure Overhaul
- **Status:** Completed
- **Purpose & user value:** Ensure all content across 21.dev, docs.21.dev, and md.21.dev is discoverable by search engines and properly indexed, with automated submission eliminating manual maintenance burden.
- **Success metrics:**
  - All three subdomains generate valid sitemaps with 100% URL coverage
  - Sitemap index (or per-subdomain equivalent) properly references all subdomain sitemaps
  - Google Search Console and Bing Webmaster receive automated submissions within 5 minutes of deployment
  - Zero manual sitemap submission required
  - Coverage report shows 95%+ indexed pages within 7 days
- **Dependencies:** None
- **Notes:** Critical blocker currently preventing proper indexing; manual submission process is error-prone and unsustainable.

### Feature 2 — robots.txt Standardization
- **Name:** robots.txt Standardization
- **Status:** Completed
- **Purpose & user value:** Provide consistent, optimized crawl directives across all subdomains to guide search engines effectively and prevent wasted crawl budget on non-indexable content.
- **Success metrics:**
  - All three subdomains have properly configured robots.txt files
  - md.21.dev correctly disallows search engines (LLM-only access)
  - 21.dev and docs.21.dev allow full indexing with correct sitemap references
  - Zero crawl errors reported in Search Console related to robots.txt
  - Proper Content-Signal headers for AI training policies
- **Dependencies:** Sitemap Infrastructure Overhaul (for sitemap URLs)
- **Notes:** md.21.dev already has LLM-only robots.txt; need to standardize others.

## Phase Dependencies & Sequencing

- Sitemap Infrastructure Overhaul → robots.txt Standardization → Search Engine Submission Automation

### Feature 3 — Cloudflare _headers for All Subdomains
- **Name:** Cloudflare _headers Optimization
- **Purpose & user value:** Implement baseline caching strategies, security headers, and performance optimizations via Cloudflare's `_headers` file across 21.dev, docs.21.dev, and md.21.dev to improve load times and Core Web Vitals scores.
- **Success metrics:**
  - Browser cache hit rate increases to 80%+
  - P75 LCP improves from 1,288ms to < 1,000ms
  - P90 LCP improves from 2,180ms to < 1,500ms
  - Security headers (CSP, X-Frame-Options) present on all pages
  - Immutable caching for static assets (CSS, images)
- **Dependencies:** None
- **Notes:** Current `_headers` only has basic content-type rules; this establishes a cross-subdomain baseline for performance and security early in the roadmap.

### Feature 4 — Cloudflare _redirects for All Subdomains
- **Name:** Cloudflare _redirects Implementation
- **Purpose & user value:** Handle URL redirects efficiently at the edge (not requiring manual Cloudflare Rules) for cleaner migrations, short URLs, and legacy path support without performance penalty across all subdomains.
- **Success metrics:**
  - All redirects execute in < 10ms at edge
  - Zero manual Cloudflare Page Rules needed for redirects
  - 301 redirects properly preserve SEO value
  - Redirect configuration lives in version control
  - Support for 50+ redirect rules without performance impact
- **Dependencies:** None
- **Notes:** Currently no `_redirects` file exists; using manual Cloudflare Rules (harder to maintain). Moving this into Phase 1 ensures URL hygiene and canonicalization are in place alongside sitemaps and robots.txt.

## Phase Metrics

This phase primarily contributes to product-level metrics for **Search & Discoverability**, **User Experience**, and **Content Quality**, especially:
- Organic search traffic increases 50%+ within 90 days of Phase 1 completion.
- Google Search Console indexed pages reaches 95%+ coverage.
- Zero sitemap submission errors across all subdomains.
