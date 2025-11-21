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

### Feature 3 — Mobile Usability Fixes
- **Name:** Mobile Usability Fixes
- **Purpose & user value:** Eliminate mobile-specific layout issues and navigation problems that currently make the site difficult to use on smartphones and tablets, ensuring seamless experience across all devices.
- **Success metrics:**
  - Zero mobile usability errors in Google Search Console
  - Touch targets meet 48px minimum size requirement
  - Navigation works flawlessly on mobile (hamburger menu, dropdowns)
  - Mobile bounce rate decreases by 30%+
  - 95%+ pass rate on mobile-friendly test
- **Dependencies:** None
- **Notes:** High priority user experience issue affecting real visitors today.

## Phase Dependencies & Sequencing

- Sitemap Infrastructure Overhaul → robots.txt Standardization → Search Engine Submission Automation
- Mobile Usability Fixes can proceed in parallel as an independent track.

## Phase Metrics

This phase primarily contributes to product-level metrics for **Search & Discoverability**, **User Experience**, and **Content Quality**, especially:
- Organic search traffic increases 50%+ within 90 days of Phase 1 completion.
- Google Search Console indexed pages reaches 95%+ coverage.
- Zero sitemap submission errors across all subdomains.
- Mobile bounce rate decreases by 30%+.
- Zero mobile usability errors in Search Console.
