# Product Roadmap

**Version:** v1.4.0  
**Last Updated:** 2026-11-05

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

This roadmap is now split into a **slim index** (this file) and detailed per-phase documents in this directory. Treat this file as the navigation table of contents; all feature descriptions, metrics, and sequencing live in the phase files referenced below.

| Phase | Name / Goal                                | Priority          | Status       | Phase File Path                                                                 |
|-------|--------------------------------------------|-------------------|-------------|-------------------------------------------------------------------------------|
| 1     | Foundation & Discoverability               | High              | Completed   | `phase-1-foundation-discoverability.md`              |
| 2     | Utilities Library Refactoring              | High (Next)       | In Progress | `phase-2-utilities-library-refactoring.md`           |
| 3     | Performance & Delivery Optimization        | Medium-High       | In Progress | `phase-3-performance-delivery-optimization.md`       |
| 4     | DesignSystem Foundation & Refactoring      | Medium            | Not Started | `phase-4-designsystem-foundation-refactoring.md`     |
| 5     | Content & Accessibility                    | Medium            | Not Started | `phase-5-content-accessibility.md`                   |
| 6     | Dark Mode & Theme Support                  | Medium            | Not Started | `phase-6-dark-mode-and-theming.md`                   |
| 7     | Advanced Features & Analytics              | Medium            | Not Started | `phase-7-advanced-features-and-analytics.md`         |
| 8     | Advanced DesignSystem & Community          | Low / Future      | Not Started | `phase-8-advanced-designsystem-and-community.md`     |
| 9     | Swift WASM Demos                           | Medium-High       | Not Started | `phase-9-swift-wasm-demos.md`                        |

Detailed feature descriptions, metrics, and sequencing for each phase now live in the corresponding phase files.

## Priority Tiers (authoritative ordering)

Phase numbers are **stable identifiers, not ordering** — files are never
renumbered (the same convention ADRs, RFCs, and `Specs/NNN` folders follow;
`phase:` values in spec frontmatter point at them). Ordering lives here and
nowhere else. Stated product priorities, in order: **(1) SEO/GEO
(generative-engine optimization — being citable in AI answers) and
AI-crawler optimization, (2) high performance on any device with minimal
overhead, (3) private-by-design server-side analytics, (4) Swift WASM demos,
(5) the DesignSystem.**

| Tier | Items | Sources |
|---|---|---|
| **Now** — phase closure + priorities 1–2 | `util links check` (spec'd) · `util redirects verify` (closes Phase 2) · security.txt · Core Web Vitals field baseline → performance budgets (`build verify` folds in) · 21.dev asset hashing → `immutable` caching · AI/GEO readiness verification · 103 Early Hints | `Specs/006` · `Specs/007` · Phase 3 F3/F7/F8/F11 · `backlog.md` |
| **Next** — priorities 3–5 + quick wins | Server-side edge analytics + privacy policy · WASM pipeline → P256K in-browser demo · 21.dev Pagefind (static-site search) · `util links check --external` scan · FR/SC (requirement/criterion) citation checks · actionlint · mobile-usability audit · uptime + client-error monitoring · a11y quick wins (skip-nav, reduced-motion, focus) · `development-docs.yml` required check | Phase 7 F1/F2/F7 · Phase 9 · Phase 5 F4/F6 · `backlog.md` |
| **Later** — foundation + community | Token system → layout library (gates dark mode) · a11y audit + axe CI · RSS feed · changelog · blog tags · dark mode · documentation versioning · i18n · sitemap index · social proof metrics · Phase 8 components & community · Plausible (contingent only — see Phase 7 F1) | Phase 3 remainder · Phase 4 · Phase 5 · Phase 6 · Phase 7 remainder · Phase 8 · `backlog.md` |

**Tier rules:** items move between tiers by editing this table (that's the
cheap part); a feature that no longer earns its place gets demoted or marked
Won't-Do in its phase file, not silently carried. When an item is picked up it
gets a `Specs/NNN` plan before implementation.

## Feature Areas (capability map)

- **Build Infrastructure** - **Utilities library + CLI**, sitemap generation utilities, state file management, workflow automation, type-safe CI/CD tooling
- **Search & Discovery** - Sitemaps, robots.txt, automated submissions, meta tags, structured data, **site search (21.dev-scoped)**, changelog
- **Performance & Delivery** - Caching headers, Core Web Vitals, edge optimizations, asset delivery, **performance budgets**, broken link detection
- **Security & Trust** - **CSP headers**, **security.txt**, vulnerability disclosure, XSS prevention
- **Mobile & Accessibility** - Responsive design, WCAG compliance, keyboard navigation, screen reader support, dark mode, **automated a11y testing**
- **Content Management** - Blog infrastructure, RSS feeds, tag filtering, metadata, changelog, **editorial workflow**
- **Brand & Identity** - Favicons, app icons, Open Graph images, theme colors, **social proof metrics**
- **DesignSystem Foundation** - Token system, layout components, theme support, component refactoring, **usage analytics**
- **Advanced Components** - Forms, feedback, media, style guide, visual regression testing, local dev docs
- **Analytics & Insights** - Server-side edge analytics, AI-crawl visibility, **privacy policy**, Plausible (contingent)
- **Infrastructure** - Redirects, headers, CI/CD automation, build optimization
- **Community & Open Source** - **Comments system**, contributor docs, editorial guidelines, local dev setup
- **Interactive Demos** - Swift→WASM build pipeline, **P256K in-browser demo**
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
3. ~~[INVESTIGATE] DocC CSS/JS content-based hashes~~ — **Resolved 2026-11-04.** Confirmed: DocC emits content-hashed filenames for all `/css/*` and `/js/*` assets (verified in generated output). `_headers.prod` already caches them for 1 year (`max-age=31536000, immutable`).
4. 21.dev asset hashing — extend the `?v=` cache-busting pattern (already used for favicons) to `style.css`, images, and SVG, then flip `/static/*` `/assets/*` `/images/*` to `immutable` (the `_headers.prod` comment marks this "daily caching until filenames are hashed" — it is the file's own deferred item)
5. CWV field baseline (CrUX, the Chrome UX Report's real-user data, plus Search Console — `util search-console` already exists) → Performance Budgets → Core Web Vitals optimization work
6. Phase 1 Cloudflare `_redirects` baseline (independent)
7. security.txt (independent)
8. Broken Link Detection (independent, CI integration)
9. AI/GEO Readiness Verification (independent; `agent-directive audit` exists to extend)
10. 103 Early Hints via `rel=preload` Link headers (independent; replaces the retired HTTP/2 Server Push idea)

**DesignSystem Track** (Phase 4 — tokens gate Phase 6 dark mode and Phase 8 components):
1. Token System Expansion → Layout Component Library (spacing tokens needed)
2. Token System Expansion → Dark Mode Support (Phase 6 — color tokens with dark variants required)

**Content & Accessibility Track** (Phase 5):
1. RSS Feed Implementation (independent)
2. Blog Tags & Filtering (independent)
3. ~~**Search Functionality**~~ — rescoped 2026-11-04: DocC ships catalog search on docs.21.dev; only a 21.dev-scoped Pagefind search remains (backlog)
4. Changelog & Release Notes (independent)
5. Mobile-usability audit (Search Console first — hamburger menu already shipped) → Accessibility Audit → Automated Accessibility Testing (CI integration)

**Theme Track** (Phase 6):
1. Token System Expansion (Phase 4) → Dark Mode Support (blocked until color tokens exist)

**Analytics & Platform Track** (Phase 7):
1. Privacy Policy → Server-Side Edge Analytics (policy must describe edge collection before launch)
2. Documentation Versioning (when multiple major versions exist)
3. HTML `<head>` Hygiene → i18n Foundation (lang attributes prerequisite)
4. ~~Sitemap Priority Optimization~~ — likely Won't-Do: Google ignores `<changefreq>`/`<priority>` (see phase file F6 note)
5. actionlint workflow validation (independent)

**Demos Track** (Phase 9):
1. WASM Demo Build Pipeline → P256K In-Browser Demo (pipeline first, demo rides it)

**Advanced Components & Community Track** (Phase 8 - LOW, feature-dependent):
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
- **Token System Expansion (Phase 4) BLOCKS Dark Mode (Phase 6) and most of Phase 8** - Must complete first
- **Privacy Policy (Phase 7) BLOCKS Edge Analytics (Phase 7)** - the policy must describe edge collection before launch
- **Accessibility Audit (Phase 5) → Automated Accessibility Testing (Phase 5)** - Baseline needed
- **WASM Pipeline (Phase 9) → P256K Demo (Phase 9)** - the demo rides the pipeline
- Brand Assets must complete before HTML `<head>` Hygiene (favicons/OG images needed)
- Brand Assets must complete before Social Proof Metrics (badges are visual)
- Mobile Usability Fixes should complete before Accessibility Audit (reduces duplicate effort)
- Sitemap Infrastructure must complete before robots.txt (sitemap URLs required)
- _headers Optimization enables CSP & Security Headers (shares same file)
- Core Web Vitals Optimization needs Performance Budgets (baseline metrics)
- Token System enables ALL Phase 8 components (foundational requirement)
- Living Style Guide enables Visual Regression Testing (test fixtures needed)
- Living Style Guide enables Local Dev Documentation (doc hub needed)

---

## Metrics & Success Criteria (product-level)

**Search & Discoverability**:
- Organic search traffic increases 50%+ within 90 days of Phase 1 completion
- Google Search Console indexed pages reaches 95%+ coverage
- Zero sitemap submission errors across all subdomains
- ~~30%+ of docs visitors use search within 90 days~~ — superseded: DocC ships catalog search; the residual item is a 21.dev-scoped search (`backlog.md`)
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
- **Zero new accessibility violations merged to main** (Phase 5 - Automated Testing)
- **Automated a11y checks in CI** (Phase 5)

**Content Quality**:
- RSS feed subscribers reach 20%+ of regular blog readers within 90 days
- Blog tag filtering increases pages-per-session by 30%+
- **Users can quickly understand what changed between versions** (Phase 5 - Changelog)
- **Changelog RSS feed separate from blog** (Phase 5)

**Engagement & Conversion**:
- Conversion rate on "Get Started" CTA improves by 15%+ (measured via edge pageview ratios — no client beacon)
- **Social proof metrics visible** (GitHub stars, download counts) (Phase 3)
- **10%+ of blog posts receive community comments** (Phase 8 - Comments System)

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
- Zero visual regressions caught in production (Phase 8 goal)
- **Component usage tracked** for data-driven refactoring (Phase 8)
- **New contributor onboarding time < 15 minutes** (Phase 8 - Local Dev Docs)
- P256K demo page runs real crypto client-side via WASM (Phase 9)

**Privacy & Compliance**:
- **Privacy policy deployed before analytics launch** (Phase 7 - GDPR requirement)
- **Zero GDPR consent popups required** (no client-side identifiers — edge collection)
- **Zero client-side analytics JavaScript** (Phase 7 - server-side only)
- **Data retention policy documented** (Phase 7)

---

## Risks & Assumptions

**Assumptions**:
- Current Cloudflare Pages deployment process remains stable
- DocC documentation generation for docs.21.dev/md.21.dev doesn't require breaking changes
- Slipstream SSG supports all required meta tag generation
- Cloudflare edge analytics suffices for traffic/vitals trends; Plausible becomes contingent-only (if custom events are ever needed)
- WASM demo builds can use the swift.org toolchain + WASM SDK as a scoped exception to the Xcode-toolchain rule (demo package lives outside the main build)
- Blog publishing cadence will be bi-weekly to monthly (manageable for solo developer)
- Token System refactor won't require breaking changes to existing components (or migration path is manageable)
- Dark mode can be implemented without performance penalties (< 200ms transition)

**Risks & Mitigations**:
- **Risk**: Sitemap automation may require complex CI/CD changes → **Mitigation**: Start with simple curl/wget submissions; enhance later if needed
- **Risk**: Mobile usability fixes may uncover deeper responsive design issues → **Mitigation**: Conduct thorough audit before starting; may extend timeline
- **Risk**: docs.21.dev performance issues may stem from DocC output (out of our control) → **Mitigation**: Focus on caching and delivery optimization first; escalate DocC issues to Apple if needed
- **Risk**: Brand asset creation (favicons, OG images) may require designer → **Mitigation**: Start with simple programmatic generation; enhance with professional design later
- **Risk**: Accessibility audit may reveal systematic issues requiring DesignSystem refactor → **Mitigation**: Phase fixes incrementally; prioritize by severity (WCAG A → AA → AAA)
- **Risk**: Edge analytics' sampling and ~6-month retention may prove insufficient → **Mitigation**: Plausible stays a recorded contingent fallback; Worker-side event collection is the intermediate step
- **Risk**: WASM toolchain adds a second toolchain + SDK to CI → **Mitigation**: standalone demo package outside the main build; pin toolchain/SDK versions in the spec; artifact can be prebuilt and vendored if CI proves flaky
- **Risk**: Token System refactor may break existing components → **Mitigation**: Start with new ColorTokens/SpacingTokens files; migrate components incrementally with tests; use feature flags if needed
- **Risk**: Dark mode may reveal color contrast issues in existing components → **Mitigation**: Run automated contrast checks during token creation; fix violations before dark mode launch
- **Risk**: Layout Component Library may conflict with Slipstream Grid API timeline → **Mitigation**: Build Container/Stack components first (independent); add Grid wrapper when Slipstream API ships

---

## Change Log

- v1.4.0 (2026-11-05): **Priority-tier ordering + three structural changes.** Added the Priority Tiers table — phase numbers are now explicitly stable identifiers (never renumbered, ADR/RFC convention); this file is the authoritative ordering, tiered by the five stated priorities (SEO/GEO → performance → server-side analytics → WASM demos → DesignSystem). Added **Phase 9 — Swift WASM Demos** (pipeline → P256K in-browser demo). Rescoped **Phase 7 Feature 1** from Plausible migration to Server-Side Edge Analytics (Plausible demoted to contingent fallback; Feature 6 annotated as likely Won't-Do — Google ignores sitemap `changefreq`/`priority`). Added **Phase 3 Feature 11 — AI/GEO Readiness Verification** (verify-first via `agent-directive audit` + Cloudflare AI Crawl Control runbook). Repaired stale pre-v1.3.2 phase numbering throughout Dependencies, Metrics, and Candidates (3.5/4/4.5/5/6 → 4/5/6/7/8). Backlog refreshed: Plausible contingent record, 103 Early Hints, CWV field baseline, 21.dev asset hashing. — **MINOR** (ordering layer + one new phase + one rescoped feature + one new feature)
- v1.3.6 (2026-11-04): **Status reconciliation to shipped reality.** Phase 1 marked Completed (Feature 4 `_redirects` shipped and verified in `deploy-cloudflare.yml`). Phase 2 Feature 4 (architecture alignment) marked Complete; Feature 2 reduced to one scoped command (`util redirects verify`, Specs/007) with `headers select`/`build verify`/LFS decisions recorded. Phase 3 moved to In Progress: OG/Twitter cards, theme-color, brand assets, JSON-LD head hygiene, and CSP all marked Completed; DocC asset-hash [INVESTIGATE] resolved (confirmed hashed, already cached immutable). Phase 5 Feature 3 (Search) rescoped — DocC ships catalog search on docs.21.dev; 21.dev-scoped search moved to backlog. — **PATCH** (factual status corrections, no feature changes)
- v1.3.5 (2025-12-29): **Phase 2 Feature 3 Added** — Canonical URL Management feature added to Phase 2. Provides `util canonical check` and `util canonical fix` commands for SEO validation and remediation across all generated HTML output. Site-agnostic design works on any subdomain post-generation. — **PATCH** (new feature in existing phase)
- v1.3.4 (2025-12-17): **Phase 2 Feature 1 Complete** — Utilities Library Extraction finished (specs/004-utilities-library). Created `Utilities` library target + `util` CLI executable with sitemap, headers, and state subcommands. Migrated sitemap generation in generate-docc.yml and generate-markdown.yml. Feature 2 (full workflow migration) remains in progress — additional commands needed for redirect verification, sitemap submission, header selection, build verification. — **PATCH** (feature 1 completion, phase continues)
- v1.3.3 (2025-12-12): Added **[INVESTIGATE]** item for DocC CSS/JS content-based hashes in Performance & Security Track. If DocC assets use content hashes, enables 1-year cache policy for `/css/*` and `/js/*` in docs.21.dev headers. — **PATCH** (investigation item, potential quick win for cache performance)
- v1.3.2 (2025-11-20): Refactored roadmap into multi-file structure with a slim index and per-phase documents in this directory. Renumbered phases for clarity (DesignSystem foundation promoted to Phase 4) without changing feature intent or priorities. — **PATCH** (structural documentation reorganization)
- v1.3.1 (2025-11-20): Removed duplicate **Phase 5 Feature 4 (Swift-Based Sitemap Generator Utility)** - fully covered by Phase 2 Feature 1 (Utilities Library Extraction). Consolidated unique success metrics (type-safe models, unified lastmod logic, < 2s generation time) into Phase 2. Renumbered Phase 5 features. — **PATCH** (duplicate removal, no new features)
- v1.3.0 (2025-11-20): Added **Phase 2 - Utilities Library Refactoring** as next priority feature after Phase 1 completion. Extracts sitemap utilities and workflow logic from DesignSystem into dedicated `Utilities` library + `util` CLI executable, following industry-standard pattern (matches subtree architecture). Reduces code duplication across GitHub Actions workflows, enables type-safe CLI tooling for CI/CD. Renumbered all subsequent phases (old Phase 2 → Phase 3, old Phase 2.5 → Phase 3.5, etc.). — **MINOR** (new architectural refactoring phase, cross-cutting infrastructure improvement extracted from 001-sitemap-infrastructure T057)
- v1.2.0 (2025-11-13): Added 15 critical missing features based on industry best practices: **Search Functionality** (Phase 3 - CRITICAL for docs), Security features (CSP, security.txt, broken link detection - Phase 2), Changelog & Automated Accessibility Testing (Phase 3), Privacy Policy & Documentation Versioning (Phase 4), Comments System & Editorial Workflow (Phase 5). Elevates security, content quality, and community engagement. — **MINOR** (substantial feature additions, security focus, search capability)
- v1.1.0 (2025-11-13): Added DesignSystem improvements (Token System, Layout Components, Dark Mode) as Phase 2.5/3.5 (MEDIUM priority) and advanced components as Phase 5 (LOW priority, feature-dependent). Reflects focus on foundation refactoring before feature expansion. — **MINOR** (expanded scope, DesignSystem focus)
- v1.0.0 (2025-11-13): Initial roadmap covering search discoverability, performance optimization, mobile experience, accessibility, and analytics migration. Organized into 4 phases prioritized by user impact and current pain points. — **MINOR** (new product roadmap, comprehensive feature planning)

---

---

## Next Steps for Individual Features

To start a feature, copy `../Specs/_template/` to `../Specs/NNN-slug/` with the
next free number and write the plan (conventions in `../Specs/README.md`).
Unphased ideas live in `backlog.md`.

Candidates, in tier order (see Priority Tiers above):

- **Phase 2 — Utilities Library Refactoring**: `util redirects verify`
  (Specs/007 — last remaining command; other leftovers are decided, see phase
  file)
- **Phase 3 — Performance & Delivery**: CWV field baseline → Core Web Vitals
  Optimization; security.txt & Vulnerability Disclosure; Performance Budgets &
  CI Enforcement; Broken Link Detection & Monitoring (spec'd — Specs/006);
  AI/GEO Readiness Verification; Social Proof & Metrics Display. (OG/Twitter,
  theme-color, brand assets, CSP, and head hygiene are shipped.)
- **Phase 7 — Analytics & Platform**: Server-Side Edge Analytics; Privacy
  Policy & Legal Pages; actionlint; Documentation Versioning;
  Internationalization Foundation; Sitemap Index. (Sitemap Priority likely
  Won't-Do; Plausible contingent only — see phase file.)
- **Phase 9 — Swift WASM Demos**: WASM Demo Build Pipeline; P256K In-Browser
  Demo
- **Phase 4 — DesignSystem Foundation**: Token System Expansion; Layout
  Component Library
- **Phase 5 — Content & Accessibility**: RSS Feed; Blog Tags & Filtering;
  Mobile Usability audit; Changelog & Release Notes; Automated Accessibility
  Testing; Accessibility Audit & Remediation. (Search rescoped — DocC ships
  catalog search on docs.21.dev; a 21.dev-scoped search is in `backlog.md`.)
- **Phase 6 — Dark Mode**: Dark Mode Support (blocked on Phase 4 tokens)
- **Phase 8 — Components & Community**: Form Component Library; Feedback
  Component Suite; Media & Content Components; Living Style Guide; Visual
  Regression Testing; Comments System (privacy-friendly); Editorial Workflow &
  Content Guidelines; Local Development Documentation; Component Usage
  Analytics
