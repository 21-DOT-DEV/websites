# Phase 5 — Content & Accessibility

**Status:** Not Started
**Priority:** Medium
**Last Updated:** 2025-11-20

## Phase Goal

Improve content discovery, documentation usability, and accessibility through feeds, search, structured changelogs, and WCAG-compliant experiences.

## Features

### Feature 1 — RSS Feed Implementation
- **Name:** RSS Feed Implementation
- **Purpose & user value:** Enable developers to subscribe to blog updates via RSS readers, increasing return visits and reducing reliance on social media for content distribution.
- **Success metrics:**
  - Valid Atom/RSS 2.0 feed at /blog/feed.xml
  - Feed validates with W3C Feed Validator
  - All blog posts appear in feed with full content or excerpts
  - Feed auto-updates on new post publication
  - 20%+ of regular blog readers subscribe via RSS within 90 days
- **Dependencies:** None.
- **Notes:** Blog infrastructure exists (tags, excerpts, metadata); RSS just needs generation.

### Feature 2 — Blog Enhancement - Tags & Filtering
- **Name:** Blog Enhancement - Tags & Filtering
- **Purpose & user value:** Surface existing tag metadata on blog posts and provide tag-based filtering/archives to help developers find relevant content faster.
- **Success metrics:**
  - Tags displayed on all blog posts
  - Tag archive pages (/blog/tags/{tag}/) functional
  - Tag cloud or list on blog index page
  - Related posts by tag shown on individual posts
  - 30%+ increase in pages-per-session for blog visitors
- **Dependencies:** None.
- **Notes:** Tags already exist in frontmatter and BlogMetadata; just need frontend display.

### Feature 3 — Search Functionality
- **Name:** Search Functionality
- **Purpose & user value:** Implement instant client-side search for documentation to enable developers to quickly find specific APIs, methods, and concepts without slow server queries or leaving the page.
- **Success metrics:**
  - Search deployed on docs.21.dev with < 200ms query response time
  - Search index builds automatically during site generation
  - Keyboard shortcut (⌘K / Ctrl+K) launches search modal
  - 30%+ of docs visitors use search within 90 days
  - Zero search downtime (client-side, no server dependency)
- **Dependencies:** None (use Pagefind or lunr.js - zero-dependency, static).
- **Notes:** Critical missing feature for docs.21.dev; documentation without search is effectively unusable.

### Feature 4 — Changelog & Release Notes
- **Name:** Changelog & Release Notes
- **Purpose & user value:** Provide structured changelog for swift-secp256k1 releases distinct from blog, following Keep a Changelog format for easy version upgrade planning.
- **Success metrics:**
  - Changelog page at /changelog/ with all versions
  - Structured format (Added/Changed/Deprecated/Removed/Fixed/Security)
  - RSS feed for changelog (separate from blog)
  - Link from package page to changelog
  - Users can quickly understand what changed between versions
- **Dependencies:** None.
- **Notes:** Keep a Changelog format (keepachangelog.com); industry standard for package managers.

### Feature 5 — Automated Accessibility Testing
- **Name:** Automated Accessibility Testing
- **Purpose & user value:** Integrate automated WCAG checks in CI to prevent new accessibility violations from being introduced, maintaining high accessibility standards continuously.
- **Success metrics:**
  - axe-core integrated in CI (automated WCAG checks)
  - PR preview deployments include accessibility report
  - CI blocks PRs introducing new violations
  - Zero new accessibility violations merged to main
  - Accessibility score tracked over time
- **Dependencies:** Accessibility Audit & Remediation (establishes baseline).
- **Notes:** Complements manual audit with ongoing automated checks; used by GOV.UK, BBC, Microsoft.

### Feature 6 — Accessibility Audit & Remediation
- **Name:** Accessibility Audit & Remediation
- **Purpose & user value:** Conduct comprehensive WCAG audit and fix all accessibility issues to ensure developers with disabilities can fully access documentation and site features.
- **Success metrics:**
  - Lighthouse Accessibility score ≥ 95 on all pages
  - Zero WCAG AA violations found by axe DevTools
  - Keyboard navigation works for all interactive elements
  - Screen reader testing passes on macOS (VoiceOver)
  - Color contrast ratios meet WCAG AA minimum (4.5:1 for text)
- **Dependencies:** Mobile Usability Fixes (Phase 1) to avoid duplicate work.
- **Notes:** No audit conducted yet; unknown issue count but medium priority.

## Phase Dependencies & Sequencing

- RSS Feed Implementation, Blog Tags & Filtering, Search Functionality, and Changelog & Release Notes can proceed independently.
- Accessibility Audit & Remediation should precede Automated Accessibility Testing.

## Phase Metrics

This phase primarily contributes to product-level metrics for **Search & Discoverability**, **Accessibility**, **Content Quality**, and **User Experience**, especially:
- RSS subscribers as share of regular readers.
- Pages-per-session increases via better navigation and tagging.
- Accessibility scores and zero new violations in CI.
