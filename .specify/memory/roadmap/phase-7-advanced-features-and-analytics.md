# Phase 7 — Advanced Features & Analytics

**Status:** Not Started
**Priority:** Future
**Last Updated:** 2025-11-20

## Phase Goal

Layer in advanced analytics, legal foundations, sitemap enhancements, and internationalization groundwork once the core site experience is mature.

## Features

### Feature 1 — Plausible Analytics Migration
- **Name:** Plausible Analytics Migration
- **Purpose & user value:** Replace Cloudflare Analytics with self-hosted Plausible for cookie-free, privacy-respecting analytics with better insights into conversion funnels and user journeys.
- **Success metrics:**
  - Self-hosted Plausible instance deployed and operational
  - Cookie-free tracking active on all three subdomains
  - Custom event goals configured (GitHub clicks, docs visits, CTA interactions)
  - Outbound link tracking for conversion measurement
  - Zero GDPR consent popups required (privacy-first design)
- **Dependencies:** Privacy Policy & Legal Pages (required before collecting analytics data).
- **Notes:** Currently Cloudflare-only; future goal for better conversion insights.

### Feature 2 — Privacy Policy & Legal Pages
- **Name:** Privacy Policy & Legal Pages
- **Purpose & user value:** Provide transparent privacy policy explaining data collection practices, meeting GDPR requirements even for cookie-free analytics, building user trust through clear communication.
- **Success metrics:**
  - Privacy policy page deployed at /privacy/
  - Explains what data is collected (IP, page views, referrer)
  - Data retention policy documented (Plausible defaults)
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
- **Notes:** Enhancement to basic sitemap behavior; not critical but improves crawl efficiency.

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

- Privacy Policy & Legal Pages → Plausible Analytics Migration.
- Sitemap Infrastructure Overhaul → Documentation Versioning, Sitemap Index Generation, Sitemap Priority & Change Frequency Optimization.
- HTML `<head>` Hygiene & SEO → Internationalization Foundation.

## Phase Metrics

This phase primarily contributes to product-level metrics for **Privacy & Compliance**, **Analytics & Insights**, **Search & Discoverability**, and **Infrastructure Reliability**, especially:
- Privacy compliance without consent banners.
- Richer analytics for conversion and usage.
- Improved crawl efficiency and content discovery.
