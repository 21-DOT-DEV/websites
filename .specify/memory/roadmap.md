# Product Roadmap

**Version:** v1.3.4  
**Last Updated:** 2025-12-17

## Vision & Goals

**Vision**: Transform 21.dev's static site infrastructure into a best-in-class developer platform with exceptional discoverability, performance, and user experience across all devices and subdomains.

**Target Users**:
- Bitcoin/Swift developers discovering tools and documentation
- Search engine crawlers indexing technical content
- Mobile users accessing documentation on-the-go
- AI/LLM systems consuming structured documentation

**Top 3 Outcomes**:
1. **Improved Search Visibility** - Automated sitemap submission and proper indexing across all subdomains increases organic discovery by 50%+
2. **Mobile-First Experience** - Responsive design and accessibility fixes reduce mobile bounce rate by 30%+
3. **Performance Excellence** - Optimized caching and delivery achieves 95+ Lighthouse scores and sub-1s P75 load times

---

## Release Plan

### Phases Overview

This roadmap is now split into a **slim index** (this file) and detailed per-phase documents under `.specify/memory/roadmap/`. Treat this file as the navigation table of contents; all feature descriptions, metrics, and sequencing live in the phase files referenced below.

| Phase | Name / Goal                                | Priority          | Status       | Phase File Path                                                                 |
|-------|--------------------------------------------|-------------------|-------------|-------------------------------------------------------------------------------|
| 1     | Foundation & Discoverability               | High              | In Progress | `.specify/memory/roadmap/phase-1-foundation-discoverability.md`              |
| 2     | Utilities Library Refactoring              | High (Next)       | In Progress | `.specify/memory/roadmap/phase-2-utilities-library-refactoring.md`           |
| 3     | Performance & Delivery Optimization        | Medium-High       | Not Started | `.specify/memory/roadmap/phase-3-performance-delivery-optimization.md`       |
| 4     | DesignSystem Foundation & Refactoring      | Medium            | Not Started | `.specify/memory/roadmap/phase-4-designsystem-foundation-refactoring.md`     |
| 5     | Content & Accessibility                    | Medium            | Not Started | `.specify/memory/roadmap/phase-5-content-accessibility.md`                   |
| 6     | Dark Mode & Theme Support                  | Medium            | Not Started | `.specify/memory/roadmap/phase-6-dark-mode-and-theming.md`                   |
| 7     | Advanced Features & Analytics              | Future            | Not Started | `.specify/memory/roadmap/phase-7-advanced-features-and-analytics.md`         |
| 8     | Advanced DesignSystem & Community          | Low / Future      | Not Started | `.specify/memory/roadmap/phase-8-advanced-designsystem-and-community.md`     |

Detailed feature descriptions, metrics, and sequencing for each phase now live in the corresponding phase files.

## Feature Areas (capability map)

- **Build Infrastructure** - **Utilities library + CLI**, sitemap generation utilities, state file management, workflow automation, type-safe CI/CD tooling
- **Search & Discovery** - Sitemaps, robots.txt, automated submissions, meta tags, structured data, **instant search**, changelog
- **Performance & Delivery** - Caching headers, Core Web Vitals, edge optimizations, asset delivery, **performance budgets**, broken link detection
- **Security & Trust** - **CSP headers**, **security.txt**, vulnerability disclosure, XSS prevention
- **Mobile & Accessibility** - Responsive design, WCAG compliance, keyboard navigation, screen reader support, dark mode, **automated a11y testing**
- **Content Management** - Blog infrastructure, RSS feeds, tag filtering, metadata, changelog, **editorial workflow**
- **Brand & Identity** - Favicons, app icons, Open Graph images, theme colors, **social proof metrics**
- **DesignSystem Foundation** - Token system, layout components, theme support, component refactoring, **usage analytics**
- **Advanced Components** - Forms, feedback, media, style guide, visual regression testing, local dev docs
- **Analytics & Insights** - Cookie-free tracking, conversion goals, self-hosted Plausible, **privacy policy**
- **Infrastructure** - Redirects, headers, CI/CD automation, build optimization
- **Community & Open Source** - **Comments system**, contributor docs, editorial guidelines, local dev setup
- **Future-Proofing** - i18n scaffolding, sitemap enhancements, **documentation versioning**

---

## Dependencies & Sequencing

**Critical Path** (Phase 1):
1. Sitemap Infrastructure Overhaul → robots.txt Standardization → Search Engine Submission Automation

**Architectural Refactoring Track** (Phase 2 - NEXT PRIORITY):
1. Sitemap Infrastructure (Phase 1) → Utilities Library Extraction (sitemap utilities exist to extract)
2. Utilities Library Extraction → Workflow Migration to Utilities CLI (library must exist first)

**Performance & Security Track** (Phase 3):
1. Brand Assets → HTML `<head>` Hygiene (OG images needed) → Social Proof Metrics
2. Phase 1 Cloudflare `_headers` baseline → CSP & Security Headers → Core Web Vitals Optimization
3. **[INVESTIGATE]** DocC CSS/JS content-based hashes — Verify whether DocC-generated `/css/*` and `/js/*` assets use content-based hashes (e.g., `app.12345abc.js`). If confirmed, update `Resources/docs-21-dev/_headers.prod` to cache these assets for 1 year (`max-age=31536000, immutable`) instead of current 1-day policy.
4. Hashed asset filenames for all static builds (Slipstream + DocC + Markdown) → enables immutable/year-long Cache-Control policies without stale assets
5. Performance Budgets → Core Web Vitals (establishes baseline)
6. Phase 1 Cloudflare `_redirects` baseline (independent)
7. security.txt (independent)
8. Broken Link Detection (independent, CI integration)

**DesignSystem Track** (Phase 3.5 - MEDIUM):
1. Token System Expansion → Layout Component Library (spacing tokens needed)
2. Token System Expansion → Dark Mode Support (Phase 4.5 - color tokens with dark variants required)

**Content & Accessibility Track** (Phase 4):
1. RSS Feed Implementation (independent)
2. Blog Tags & Filtering (independent)
3. **Search Functionality** (independent, CRITICAL for docs.21.dev)
4. Changelog & Release Notes (independent)
5. Accessibility Audit (after mobile fixes for efficiency) → Automated Accessibility Testing (CI integration)

**Theme Track** (Phase 4.5 - MEDIUM):
1. Token System Expansion (Phase 3.5) → Dark Mode Support (blocked until color tokens exist)

**Future Track** (Phase 5):
1. Privacy Policy (must complete before Plausible)
2. Plausible Analytics → Privacy Policy (analytics requires policy)
3. Documentation Versioning (when multiple major versions exist)
4. HTML `<head>` Hygiene → i18n Foundation (lang attributes prerequisite)
5. Sitemap Overhaul → Sitemap Priority Optimization (enhancement to foundation)

**Advanced Components & Community Track** (Phase 6 - LOW, feature-dependent):
1. Token System → Form Components (when newsletter/contact form added)
2. Token System → Feedback Components (when interactive features added)
3. Core Web Vitals → Media Components (when multi-author blog or video content added)
4. Component maturity → Living Style Guide (when external contributors join)
5. Style Guide → Visual Regression Testing (when DesignSystem stabilizes)
6. Blog traffic → Comments System (when community engagement grows)
7. Multiple contributors → Editorial Workflow & Content Guidelines (documentation)
8. External contributors → Local Development Documentation
9. DesignSystem maturity (50+ components) → Component Usage Analytics

**Critical Cross-Phase Dependencies**:
- **Sitemap Infrastructure (Phase 1) → Utilities Library (Phase 2)** - Utilities must exist before extraction
- **Token System Expansion (Phase 3.5) BLOCKS Dark Mode (Phase 4.5)** - Must complete first
- **Privacy Policy (Phase 5) BLOCKS Plausible Analytics (Phase 5)** - GDPR requirement
- **Accessibility Audit (Phase 4) → Automated Accessibility Testing (Phase 4)** - Baseline needed
- Brand Assets must complete before HTML `<head>` Hygiene (favicons/OG images needed)
- Brand Assets must complete before Social Proof Metrics (badges are visual)
- Mobile Usability Fixes should complete before Accessibility Audit (reduces duplicate effort)
- Sitemap Infrastructure must complete before robots.txt (sitemap URLs required)
- _headers Optimization enables CSP & Security Headers (shares same file)
- Core Web Vitals Optimization needs Performance Budgets (baseline metrics)
- Token System enables ALL Phase 5 components (foundational requirement)
- Living Style Guide enables Visual Regression Testing (test fixtures needed)
- Living Style Guide enables Local Dev Documentation (doc hub needed)

---

## Metrics & Success Criteria (product-level)

**Search & Discoverability**:
- Organic search traffic increases 50%+ within 90 days of Phase 1 completion
- Google Search Console indexed pages reaches 95%+ coverage
- Zero sitemap submission errors across all subdomains
- **30%+ of docs visitors use search within 90 days** (Phase 4 - Search)
- Zero broken links across all three subdomains (Phase 3 - Link Detection)

**Performance**:
- P75 LCP improves from 1,288ms to < 1,000ms
- P90 LCP improves from 2,180ms to < 1,500ms
- Lighthouse Performance score ≥ 95 on all pages
- **Performance budgets enforced in CI** (HTML < 100KB, CSS < 50KB, JS < 50KB)
- **Zero performance regressions merged** (Phase 3 - Performance Budgets)

**Security & Trust**:
- **Zero XSS vulnerabilities reported** (Phase 3 - CSP Headers)
- **CSP headers deployed in strict mode** (Phase 3)
- **security.txt passes validation** at securitytxt.org (Phase 3)
- **Vulnerability disclosure process documented** (Phase 3)
- **Conversion rate improves 10%+ after social proof metrics added** (Phase 3)

**User Experience**:
- Mobile bounce rate decreases by 30%+
- Pages per session increases by 20%+ (better navigation/discoverability)
- Zero mobile usability errors in Search Console

**Accessibility**:
- Lighthouse Accessibility score ≥ 95 on all pages
- Zero WCAG AA violations
- Keyboard navigation works for 100% of interactive elements
- **Zero new accessibility violations merged to main** (Phase 4 - Automated Testing)
- **Automated a11y checks in CI** (Phase 4)

**Content Quality**:
- RSS feed subscribers reach 20%+ of regular blog readers within 90 days
- Blog tag filtering increases pages-per-session by 30%+
- **Users can quickly understand what changed between versions** (Phase 4 - Changelog)
- **Changelog RSS feed separate from blog** (Phase 4)

**Engagement & Conversion**:
- Conversion rate on "Get Started" CTA improves by 15%+ (via Plausible)
- **Social proof metrics visible** (GitHub stars, download counts) (Phase 3)
- **10%+ of blog posts receive community comments** (Phase 6 - Comments System)

**Infrastructure**:
- Browser cache hit rate reaches 80%+
- Zero manual intervention required for sitemap submissions
- All redirects execute in < 10ms at edge

**Brand Recognition**:
- Social media shares include proper Open Graph previews (100% success rate)
- iOS users can add site to home screen with proper icons
- Favicon appears correctly in all browsers

**DesignSystem Quality**:
- Token adoption reaches 100% across all components (zero hardcoded values)
- ClassModifier usage reduces by 80%+ after Layout Component Library
- Dark mode adoption reaches 40%+ of users within 30 days of launch
- Component development velocity increases 50%+ (measured by time to build new pages)
- Zero visual regressions caught in production (Phase 6 goal)
- **Component usage tracked** for data-driven refactoring (Phase 6)
- **New contributor onboarding time < 15 minutes** (Phase 6 - Local Dev Docs)

**Privacy & Compliance**:
- **Privacy policy deployed before analytics launch** (Phase 5 - GDPR requirement)
- **Zero GDPR consent popups required** (cookie-free design)
- **Data retention policy documented** (Phase 5)

---

## Risks & Assumptions

**Assumptions**:
- Current Cloudflare Pages deployment process remains stable
- DocC documentation generation for docs.21.dev/md.21.dev doesn't require breaking changes
- Slipstream SSG supports all required meta tag generation
- Self-hosted Plausible infrastructure can be provisioned within reasonable cost (<$20/month)
- Blog publishing cadence will be bi-weekly to monthly (manageable for solo developer)
- Token System refactor won't require breaking changes to existing components (or migration path is manageable)
- Dark mode can be implemented without performance penalties (< 200ms transition)

**Risks & Mitigations**:
- **Risk**: Sitemap automation may require complex CI/CD changes → **Mitigation**: Start with simple curl/wget submissions; enhance later if needed
- **Risk**: Mobile usability fixes may uncover deeper responsive design issues → **Mitigation**: Conduct thorough audit before starting; may extend timeline
- **Risk**: docs.21.dev performance issues may stem from DocC output (out of our control) → **Mitigation**: Focus on caching and delivery optimization first; escalate DocC issues to Apple if needed
- **Risk**: Brand asset creation (favicons, OG images) may require designer → **Mitigation**: Start with simple programmatic generation; enhance with professional design later
- **Risk**: Accessibility audit may reveal systematic issues requiring DesignSystem refactor → **Mitigation**: Phase fixes incrementally; prioritize by severity (WCAG A → AA → AAA)
- **Risk**: Plausible self-host may have operational complexity → **Mitigation**: Use managed Plausible initially if self-host proves difficult; migrate later
- **Risk**: Token System refactor may break existing components → **Mitigation**: Start with new ColorTokens/SpacingTokens files; migrate components incrementally with tests; use feature flags if needed
- **Risk**: Dark mode may reveal color contrast issues in existing components → **Mitigation**: Run automated contrast checks during token creation; fix violations before dark mode launch
- **Risk**: Layout Component Library may conflict with Slipstream Grid API timeline → **Mitigation**: Build Container/Stack components first (independent); add Grid wrapper when Slipstream API ships

---

## Change Log

- v1.3.4 (2025-12-17): **Phase 2 Feature 1 Complete** — Utilities Library Extraction finished (specs/004-utilities-library). Created `Utilities` library target + `util` CLI executable with sitemap, headers, and state subcommands. Migrated sitemap generation in generate-docc.yml and generate-markdown.yml. Feature 2 (full workflow migration) remains in progress — additional commands needed for redirect verification, sitemap submission, header selection, build verification. — **PATCH** (feature 1 completion, phase continues)
- v1.3.3 (2025-12-12): Added **[INVESTIGATE]** item for DocC CSS/JS content-based hashes in Performance & Security Track. If DocC assets use content hashes, enables 1-year cache policy for `/css/*` and `/js/*` in docs.21.dev headers. — **PATCH** (investigation item, potential quick win for cache performance)
- v1.3.2 (2025-11-20): Refactored roadmap into multi-file structure with a slim index and per-phase documents under `.specify/memory/roadmap/`. Renumbered phases for clarity (DesignSystem foundation promoted to Phase 4) without changing feature intent or priorities. — **PATCH** (structural documentation reorganization)
- v1.3.1 (2025-11-20): Removed duplicate **Phase 5 Feature 4 (Swift-Based Sitemap Generator Utility)** - fully covered by Phase 2 Feature 1 (Utilities Library Extraction). Consolidated unique success metrics (type-safe models, unified lastmod logic, < 2s generation time) into Phase 2. Renumbered Phase 5 features. — **PATCH** (duplicate removal, no new features)
- v1.3.0 (2025-11-20): Added **Phase 2 - Utilities Library Refactoring** as next priority feature after Phase 1 completion. Extracts sitemap utilities and workflow logic from DesignSystem into dedicated `Utilities` library + `util` CLI executable, following industry-standard pattern (matches subtree architecture). Reduces code duplication across GitHub Actions workflows, enables type-safe CLI tooling for CI/CD. Renumbered all subsequent phases (old Phase 2 → Phase 3, old Phase 2.5 → Phase 3.5, etc.). — **MINOR** (new architectural refactoring phase, cross-cutting infrastructure improvement extracted from 001-sitemap-infrastructure T057)
- v1.2.0 (2025-11-13): Added 15 critical missing features based on industry best practices: **Search Functionality** (Phase 3 - CRITICAL for docs), Security features (CSP, security.txt, broken link detection - Phase 2), Changelog & Automated Accessibility Testing (Phase 3), Privacy Policy & Documentation Versioning (Phase 4), Comments System & Editorial Workflow (Phase 5). Elevates security, content quality, and community engagement. — **MINOR** (substantial feature additions, security focus, search capability)
- v1.1.0 (2025-11-13): Added DesignSystem improvements (Token System, Layout Components, Dark Mode) as Phase 2.5/3.5 (MEDIUM priority) and advanced components as Phase 5 (LOW priority, feature-dependent). Reflects focus on foundation refactoring before feature expansion. — **MINOR** (expanded scope, DesignSystem focus)
- v1.0.0 (2025-11-13): Initial roadmap covering search discoverability, performance optimization, mobile experience, accessibility, and analytics migration. Organized into 4 phases prioritized by user impact and current pain points. — **MINOR** (new product roadmap, comprehensive feature planning)

---

## Next Steps for Individual Features

Use `/speckit.specify` to create detailed specifications for each feature:

```text
# Phase 2 - Build Infrastructure (NEXT PRIORITY - HIGH)
Next: /speckit.specify "Feature: Utilities Library Extraction — Extract sitemap utilities and workflow logic from DesignSystem into dedicated Utilities library + util CLI executable following library+executable pattern"

# Phase 1 - Foundation & Discoverability (COMPLETE)
Next: /speckit.specify "Feature: Sitemap Infrastructure Overhaul — Generate comprehensive sitemaps for all subdomains with automated submission to search engines"
Next: /speckit.specify "Feature: robots.txt Standardization — Consistent crawl directives across 21.dev, docs.21.dev, md.21.dev"
Next: /speckit.specify "Feature: Cloudflare _headers Optimization — Implement caching, security, and performance headers"
Next: /speckit.specify "Feature: Cloudflare _redirects Implementation — Version-controlled edge redirects without manual Page Rules"
Next: /speckit.specify "Feature: Core Web Vitals Optimization — Systematic LCP, INP, CLS improvements for 95+ Lighthouse scores"
Next: /speckit.specify "Feature: HTML <head> Hygiene & SEO — Comprehensive meta tags, Open Graph, structured data, canonical URLs"
Next: /speckit.specify "Feature: Brand Assets & Favicons — Professional favicon suite, app icons, Open Graph images"
Next: /speckit.specify "Feature: Content Security Policy (CSP) & Security Headers — Implement strict CSP to prevent XSS attacks and injection vulnerabilities"
Next: /speckit.specify "Feature: security.txt & Vulnerability Disclosure — RFC 9116 compliant security.txt for responsible vulnerability reporting"
Next: /speckit.specify "Feature: Performance Budgets & CI Enforcement — Lighthouse CI with performance budgets to prevent regressions"
Next: /speckit.specify "Feature: Broken Link Detection & Monitoring — Automated link checking in CI and scheduled external link scans"
Next: /speckit.specify "Feature: Social Proof & Metrics Display — Display GitHub stars, download counts, and usage statistics for trust building"

# Phase 3 - Performance & Delivery Optimization (MEDIUM-HIGH PRIORITY)
(Phase 3 features listed above under Phase 1)

# Phase 4 - Content & Accessibility (MEDIUM PRIORITY)
Next: /speckit.specify "Feature: RSS Feed Implementation — Atom/RSS 2.0 feed for blog subscriptions"
Next: /speckit.specify "Feature: Blog Tags & Filtering — Surface tag metadata with archive pages and filtering"
Next: /speckit.specify "Feature: Search Functionality — Instant client-side search for docs.21.dev using Pagefind or lunr.js"
Next: /speckit.specify "Feature: Mobile Usability Fixes — Eliminate responsive design issues and navigation problems on mobile devices"
Next: /speckit.specify "Feature: Changelog & Release Notes — Structured changelog for swift-secp256k1 following Keep a Changelog format"
Next: /speckit.specify "Feature: Automated Accessibility Testing — Integrate axe-core in CI to prevent new WCAG violations"
Next: /speckit.specify "Feature: Accessibility Audit & Remediation — WCAG AA compliance across all pages"

# Phase 3.5 - DesignSystem Foundation (MEDIUM PRIORITY)
Next: /speckit.specify "Feature: Token System Expansion — Comprehensive design token library with Color, Spacing, Typography, Shadow, Border, ZIndex, Animation, and Breakpoint tokens"
Next: /speckit.specify "Feature: Layout Component Library — Reusable Container, VStack, HStack, Grid, Spacer, and Divider components"

# Phase 4.5 - Dark Mode (MEDIUM PRIORITY)  
Next: /speckit.specify "Feature: Dark Mode Support — System-respecting dark theme with prefers-color-scheme and localStorage persistence"

# Phase 5 - Future Features
Next: /speckit.specify "Feature: Privacy Policy & Legal Pages — Transparent privacy policy for GDPR compliance and user trust"
Next: /speckit.specify "Feature: Plausible Analytics Migration — Self-hosted, cookie-free analytics with conversion tracking"
Next: /speckit.specify "Feature: Documentation Versioning — Version selector for swift-secp256k1 docs matching installed package versions"
Next: /speckit.specify "Feature: Internationalization Foundation — i18n-ready structure and scaffolding for future multi-language support"

# Phase 6 - Advanced Components & Community (LOW PRIORITY, feature-dependent)
Next: /speckit.specify "Feature: Form Component Library — Accessible Input, TextArea, Select, Checkbox, Radio components with validation"
Next: /speckit.specify "Feature: Feedback Component Suite — Toast, Alert, Banner, and ProgressBar components with ARIA live regions"
Next: /speckit.specify "Feature: Media & Content Components — Optimized Image, Avatar, Badge, and Video components with lazy loading"
Next: /speckit.specify "Feature: Living Style Guide — Interactive component documentation with props, examples, and copy-to-clipboard"
Next: /speckit.specify "Feature: Visual Regression Testing — Automated screenshot comparison for all component variants in CI"
Next: /speckit.specify "Feature: Comments System (Privacy-Friendly) — GitHub Discussions/Issues-backed comments using Giscus or Utterances"
Next: /speckit.specify "Feature: Editorial Workflow & Content Guidelines — Content style guide, blog templates, and publishing workflow documentation"
Next: /speckit.specify "Feature: Local Development Documentation — Comprehensive local setup guide with troubleshooting for external contributors"
Next: /speckit.specify "Feature: Component Usage Analytics — Track DesignSystem component usage for data-driven refactoring decisions"
```

---

## Additional Industry Best Practices Recommendations

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
