# Product Roadmap

**Version:** v1.2.0  
**Last Updated:** 2025-11-13

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

### Phase 1 — Goal: Foundation & Discoverability (HIGH PRIORITY)

**Key Features**

1. **Sitemap Infrastructure Overhaul**  
   - Purpose & user value: Ensure all content across 21.dev, docs.21.dev, and md.21.dev is discoverable by search engines and properly indexed, with automated submission eliminating manual maintenance burden.
   - Success metrics:  
     - All three subdomains generate valid sitemaps with 100% URL coverage
     - Sitemap index properly references all subdomain sitemaps
     - Google Search Console and Bing Webmaster receive automated submissions within 5 minutes of deployment
     - Zero manual sitemap submission required
     - Coverage report shows 95%+ indexed pages within 7 days
   - Dependencies: none
   - Notes: Critical blocker currently preventing proper indexing; manual submission process is error-prone and unsustainable

2. **robots.txt Standardization**  
   - Purpose & user value: Provide consistent, optimized crawl directives across all subdomains to guide search engines effectively and prevent wasted crawl budget on non-indexable content.
   - Success metrics:  
     - All three subdomains have properly configured robots.txt files
     - md.21.dev correctly disallows search engines (LLM-only access)
     - 21.dev and docs.21.dev allow full indexing with correct sitemap references
     - Zero crawl errors reported in Search Console related to robots.txt
     - Proper Content-Signal headers for AI training policies
   - Dependencies: Sitemap Infrastructure (for sitemap URLs)
   - Notes: md.21.dev already has LLM-only robots.txt; need to standardize others

3. **Mobile Usability Fixes**  
   - Purpose & user value: Eliminate mobile-specific layout issues and navigation problems that currently make the site difficult to use on smartphones and tablets, ensuring seamless experience across all devices.
   - Success metrics:  
     - Zero mobile usability errors in Google Search Console
     - Touch targets meet 48px minimum size requirement
     - Navigation works flawlessly on mobile (hamburger menu, dropdowns)
     - Mobile bounce rate decreases by 30%+
     - 95%+ pass rate on mobile-friendly test
   - Dependencies: none
   - Notes: High priority user experience issue affecting real visitors today

---

### Phase 2 — Goal: Performance & Delivery Optimization (MEDIUM-HIGH PRIORITY)

**Key Features**

1. **Cloudflare _headers Optimization**  
   - Purpose & user value: Implement aggressive caching strategies, security headers, and performance optimizations via Cloudflare's _headers file to dramatically improve load times and Core Web Vitals scores.
   - Success metrics:  
     - Browser cache hit rate increases to 80%+
     - P75 LCP improves from 1,288ms to < 1,000ms
     - P90 LCP improves from 2,180ms to < 1,500ms
     - Security headers (CSP, X-Frame-Options) present on all pages
     - Immutable caching for static assets (CSS, images)
   - Dependencies: none
   - Notes: Current _headers only has basic content-type rules; huge optimization opportunity

2. **Cloudflare _redirects Implementation**  
   - Purpose & user value: Handle URL redirects efficiently at the edge (not requiring manual Cloudflare Rules) for cleaner migrations, short URLs, and legacy path support without performance penalty.
   - Success metrics:  
     - All redirects execute in < 10ms at edge
     - Zero manual Cloudflare Page Rules needed for redirects
     - 301 redirects properly preserve SEO value
     - Redirect configuration lives in version control
     - Support for 50+ redirect rules without performance impact
   - Dependencies: none
   - Notes: Currently no _redirects file exists; using manual Cloudflare Rules (harder to maintain)

3. **Core Web Vitals Optimization**  
   - Purpose & user value: Systematically improve Largest Contentful Paint (LCP), Interaction to Next Paint (INP), and Cumulative Layout Shift (CLS) to provide faster, smoother user experiences and improve search rankings.
   - Success metrics:  
     - LCP: 100% of pages achieve "Good" (< 2.5s)
     - INP: 95%+ achieve "Good" (< 200ms)
     - CLS: 100% achieve "Good" (< 0.1)
     - P99 latency improves from 5,908ms to < 3,000ms
     - Lighthouse Performance score ≥ 95 for all pages
   - Dependencies: _headers Optimization (caching needed for LCP improvement)
   - Notes: docs.21.dev has "needs improvement" segment; P99 latency concerning

4. **HTML `<head>` Hygiene & SEO**  
   - Purpose & user value: Implement comprehensive meta tags, Open Graph markup, structured data, and proper head elements to maximize search visibility, social sharing, and discoverability.
   - Success metrics:  
     - All pages have unique meta descriptions (140-160 chars)
     - Open Graph and Twitter Card tags present on all shareable pages
     - Schema.org JSON-LD structured data for Organization, Website, BlogPosting
     - Canonical URLs prevent duplicate content issues
     - Social media preview images (1200x630px) for key pages
   - Dependencies: Brand Assets (for favicons and OG images)
   - Notes: Currently only has basic charset, title, viewport; missing critical SEO elements

5. **Brand Assets & Favicons**  
   - Purpose & user value: Provide professional favicon suite, app icons, and Open Graph images to improve brand recognition, mobile home screen experience, and social media presence.
   - Success metrics:  
     - Favicons present in all required formats (16x16, 32x32, ico, svg)
     - Apple Touch Icons (180x180) for iOS home screen
     - Open Graph images (1200x630) for social previews
     - Web app manifest with PWA icons (192x192, 512x512)
     - Theme color meta tag for mobile browsers
   - Dependencies: none (can use placeholder assets initially)
   - Notes: Currently zero brand assets exist; all missing

6. **Content Security Policy (CSP) & Security Headers**  
   - Purpose & user value: Implement strict Content Security Policy headers to prevent XSS attacks and other injection vulnerabilities, protecting users and maintaining trust in the platform.
   - Success metrics:  
     - CSP headers deployed via _headers file
     - Report-only mode passes validation (zero legitimate violations)
     - Strict CSP mode enabled after monitoring period
     - Zero XSS vulnerabilities reported
     - Security headers present (X-Frame-Options, X-Content-Type-Options, Referrer-Policy)
   - Dependencies: _headers Optimization (shares same file)
   - Notes: OWASP Top 10 mitigation; critical for security-conscious developer tools

7. **security.txt & Vulnerability Disclosure**  
   - Purpose & user value: Provide RFC 9116 compliant security.txt file for responsible vulnerability disclosure, enabling security researchers to report issues properly.
   - Success metrics:  
     - security.txt deployed at /.well-known/security.txt
     - Contact email, disclosure policy, and expiration date present
     - File passes validation at securitytxt.org
     - Security researchers can find disclosure process easily
     - File renewed annually (expires field updated)
   - Dependencies: none
   - Notes: Industry best practice for open source projects; GitHub, Cloudflare, Mozilla all have this

8. **Performance Budgets & CI Enforcement**  
   - Purpose & user value: Establish and enforce performance budgets in CI to prevent regressions, ensuring fast load times remain consistent across all deployments.
   - Success metrics:  
     - Lighthouse CI integrated with performance budgets
     - HTML < 100KB, CSS < 50KB, JS < 50KB per page (enforced)
     - Bundle size tracking prevents regressions
     - CI fails if performance budgets exceeded
     - Real User Monitoring (RUM) tracks actual user performance
   - Dependencies: Core Web Vitals Optimization (baseline metrics needed)
   - Notes: Ongoing monitoring, not one-time optimization; prevents performance decay

9. **Broken Link Detection & Monitoring**  
   - Purpose & user value: Automatically detect and prevent broken internal/external links through CI checks and scheduled scans, maintaining documentation quality and user trust.
   - Success metrics:  
     - CI blocks PRs with broken internal links (100% catch rate)
     - Weekly scheduled scans for external links
     - Zero broken links across all three subdomains
     - Automated alerts for external link decay
     - Link check runs in < 2 minutes
   - Dependencies: none
   - Notes: Use lychee or htmlproofer; critical for docs site credibility

10. **Social Proof & Metrics Display**  
   - Purpose & user value: Display GitHub stars, download counts, and usage statistics to build trust and social proof, increasing package adoption through visible community validation.
   - Success metrics:  
     - GitHub stars badge displayed on package page
     - "Used by X projects" count with sources cited
     - Metrics update automatically (daily or weekly)
     - Conversion rate improves by 10%+ after metrics added
     - Trust signals visible without JavaScript fallback
   - Dependencies: Brand Assets (badges are visual elements)
   - Notes: Use shields.io or static snapshots; npm, PyPI, crates.io all show download counts

---

### Phase 2.5 — Goal: DesignSystem Foundation & Refactoring (MEDIUM PRIORITY)

**Key Features**

1. **Token System Expansion**  
   - Purpose & user value: Establish comprehensive design token library following industry standards (Material Design, Tailwind) to ensure consistent spacing, colors, shadows, and typography across all components and future sites.
   - Success metrics:  
     - 8-10 token categories implemented (Color, Spacing, Typography, Shadow, Border, ZIndex, Animation, Breakpoint)
     - All existing components refactored to use tokens (zero hardcoded values)
     - Token documentation generated automatically
     - New components default to tokens (enforced in PR reviews)
     - Design-to-code handoff time reduced by 50%
   - Dependencies: none (foundational work)
   - Notes: Currently only 2 token files exist (MaxWidth, ButtonStyle); industry standard requires comprehensive token system. Aligns with Constitution Principle IV (Design System Consistency).

2. **Layout Component Library**  
   - Purpose & user value: Provide reusable layout primitives (Container, Grid, Stack, Spacer) to eliminate ClassModifier workarounds and accelerate page development with consistent spacing patterns.
   - Success metrics:  
     - Container component with responsive max-widths
     - VStack/HStack components for vertical/horizontal layouts
     - Grid component wrapper (once Slipstream API available)
     - Spacer component for flexible spacing
     - Divider component for visual separation
     - 80%+ reduction in ClassModifier usage across codebase
   - Dependencies: Token System Expansion (spacing scale needed), Slipstream Grid APIs (for Grid component)
   - Notes: Memory shows Grid APIs as "NEXT PRIORITY" for Slipstream; will eliminate workarounds in SiteFooter, AboutSection, FeaturedPackageCard

---

### Phase 3 — Goal: Content & Accessibility (MEDIUM PRIORITY)

**Key Features**

1. **RSS Feed Implementation**  
   - Purpose & user value: Enable developers to subscribe to blog updates via RSS readers, increasing return visits and reducing reliance on social media for content distribution.
   - Success metrics:  
     - Valid Atom/RSS 2.0 feed at /blog/feed.xml
     - Feed validates with W3C Feed Validator
     - All blog posts appear in feed with full content or excerpts
     - Feed auto-updates on new post publication
     - 20%+ of regular blog readers subscribe via RSS within 90 days
   - Dependencies: none
   - Notes: Blog infrastructure exists (tags, excerpts, metadata); RSS just needs generation

2. **Blog Enhancement - Tags & Filtering**  
   - Purpose & user value: Surface existing tag metadata on blog posts and provide tag-based filtering/archives to help developers find relevant content faster.
   - Success metrics:  
     - Tags displayed on all blog posts
     - Tag archive pages (/blog/tags/{tag}/) functional
     - Tag cloud or list on blog index page
     - Related posts by tag shown on individual posts
     - 30%+ increase in pages-per-session for blog visitors
   - Dependencies: none
   - Notes: Tags already exist in frontmatter and BlogMetadata; just need frontend display

3. **Search Functionality** ⭐ *Critical for docs.21.dev*  
   - Purpose & user value: Implement instant client-side search for documentation to enable developers to quickly find specific APIs, methods, and concepts without slow server queries or leaving the page.
   - Success metrics:  
     - Search deployed on docs.21.dev with < 200ms query response time
     - Search index builds automatically during site generation
     - Keyboard shortcut (⌘K / Ctrl+K) launches search modal
     - 30%+ of docs visitors use search within 90 days
     - Zero search downtime (client-side, no server dependency)
   - Dependencies: none (use Pagefind or lunr.js - zero-dependency, static)
   - Notes: **CRITICAL MISSING FEATURE** - Documentation without search is unusable. Every major docs site has instant search. Should be highest priority in Phase 3.

4. **Changelog & Release Notes**  
   - Purpose & user value: Provide structured changelog for swift-secp256k1 releases distinct from blog, following Keep a Changelog format for easy version upgrade planning.
   - Success metrics:  
     - Changelog page at /changelog/ with all versions
     - Structured format (Added/Changed/Deprecated/Removed/Fixed/Security)
     - RSS feed for changelog (separate from blog)
     - Link from package page to changelog
     - Users can quickly understand what changed between versions
   - Dependencies: none
   - Notes: Keep a Changelog format (keepachangelog.com); industry standard for package managers

5. **Automated Accessibility Testing**  
   - Purpose & user value: Integrate automated WCAG checks in CI to prevent new accessibility violations from being introduced, maintaining high accessibility standards continuously.
   - Success metrics:  
     - axe-core integrated in CI (automated WCAG checks)
     - PR preview deployments include accessibility report
     - CI blocks PRs introducing new violations
     - Zero new accessibility violations merged to main
     - Accessibility score tracked over time
   - Dependencies: Accessibility Audit (establishes baseline)
   - Notes: Complements manual audit with ongoing automated checks; GOV.UK, BBC, Microsoft use automated a11y in CI

6. **Accessibility Audit & Remediation**  
   - Purpose & user value: Conduct comprehensive WCAG audit and fix all accessibility issues to ensure developers with disabilities can fully access documentation and site features.
   - Success metrics:  
     - Lighthouse Accessibility score ≥ 95 on all pages
     - Zero WCAG AA violations found by axe DevTools
     - Keyboard navigation works for all interactive elements
     - Screen reader testing passes on macOS (VoiceOver)
     - Color contrast ratios meet WCAG AA minimum (4.5:1 for text)
   - Dependencies: Mobile Usability Fixes (some overlap in issues)
   - Notes: No audit conducted yet; unknown issue count but medium priority

---

### Phase 3.5 — Goal: Dark Mode & Theme Support (MEDIUM PRIORITY)

**Key Features**

1. **Dark Mode Support**  
   - Purpose & user value: Implement system-respecting dark mode with automatic switching based on `prefers-color-scheme`, reducing eye strain for developers reading documentation at night and improving accessibility.
   - Success metrics:  
     - All components support light/dark variants
     - Smooth transition between modes (< 200ms)
     - User preference persistence (localStorage)
     - Zero FOUC (flash of unstyled content)
     - Dark mode adoption reaches 40%+ of users within 30 days
     - Color contrast meets WCAG AA in both modes
   - Dependencies: Token System Expansion (color tokens with dark variants required)
   - Notes: Mentioned in "Accessibility Beyond WCAG" recommendations; high user demand for developer-focused sites. Requires comprehensive color token system first.

---

### Phase 4 — Goal: Advanced Features & Analytics (FUTURE)

**Key Features**

1. **Plausible Analytics Migration**  
   - Purpose & user value: Replace Cloudflare Analytics with self-hosted Plausible for cookie-free, privacy-respecting analytics with better insights into conversion funnels and user journeys.
   - Success metrics:  
     - Self-hosted Plausible instance deployed and operational
     - Cookie-free tracking active on all three subdomains
     - Custom event goals configured (GitHub clicks, docs visits, CTA interactions)
     - Outbound link tracking for conversion measurement
     - Zero GDPR consent popups required (privacy-first design)
   - Dependencies: Privacy Policy (required before collecting analytics data)
   - Notes: Currently Cloudflare-only; future goal for better conversion insights

2. **Privacy Policy & Legal Pages**  
   - Purpose & user value: Provide transparent privacy policy explaining data collection practices, meeting GDPR requirements even for cookie-free analytics, building user trust through clear communication.
   - Success metrics:  
     - Privacy policy page deployed at /privacy/
     - Explains what data is collected (IP, page views, referrer)
     - Data retention policy documented (Plausible defaults)
     - GDPR compliance statement included
     - Contact information for data deletion requests
   - Dependencies: none (but must complete before Plausible launch)
   - Notes: GDPR requires privacy policy even for minimal data collection; builds trust with privacy-conscious developers

3. **Documentation Versioning**  
   - Purpose & user value: Enable viewing documentation for different swift-secp256k1 versions, allowing developers to find docs matching their installed package version for accurate API reference.
   - Success metrics:  
     - Version selector dropdown on docs.21.dev (e.g., v0.21.x, v0.22.x, v1.0.x)
     - Separate DocC archives generated per major version
     - Canonical URLs point to latest stable version
     - 80%+ of users find docs for their specific version
     - Zero broken links between version switches
   - Dependencies: Sitemap Infrastructure (version-specific sitemaps needed)
   - Notes: Implement when multiple major versions exist; Rust Docs, Swift.org, React docs all support version switching

4. **Internationalization Foundation**  
   - Purpose & user value: Lay groundwork for future multi-language support by implementing proper `lang` attributes, hreflang scaffolding, and i18n-ready URL structures without committing to translations yet.
   - Success metrics:  
     - HTML lang attribute set to "en" on all pages
     - Code structure supports future subdirectory i18n (`/en/`, `/zh/`, etc.)
     - Translation file structure documented but not populated
     - Zero breaking changes required to add first non-English language
     - i18n patterns established in DesignSystem components
   - Dependencies: HTML `<head>` Hygiene (proper lang attributes needed)
   - Notes: English-only for now; i18n-ready structure for future expansion

3. **Sitemap Priority & Change Frequency Optimization**  
   - Purpose & user value: Add priority hints and change frequency metadata to sitemaps to help search engines crawl and index content more efficiently based on importance and update cadence.
   - Success metrics:  
     - Homepage has priority 1.0, key pages 0.8, blog posts 0.6
     - Change frequency reflects actual update patterns (daily for blog index, weekly for docs)
     - Crawl efficiency improves by 20%+ (measured via Search Console)
     - Important pages indexed within 24 hours of publication
     - lastmod dates accurate and automatically updated
   - Dependencies: Sitemap Infrastructure Overhaul (foundation must exist first)
   - Notes: Enhancement to basic sitemap; not critical but improves crawl efficiency

---

### Phase 5 — Goal: Advanced DesignSystem Components (LOW PRIORITY)

**Note**: These components depend on new features being added to 21-dev site or new sites. Implement only when actual use cases emerge.

**Key Features**

1. **Form Component Library**  
   - Purpose & user value: Enable future contact forms, newsletter signups, and interactive features with accessible, validated form components following WCAG guidelines.
   - Success metrics:  
     - Input, TextArea, Select, Checkbox, Radio components
     - FormField wrapper with label/error/help text
     - Validation state styling (error, success, warning)
     - Keyboard navigation support (Tab, Arrow keys)
     - 100% WCAG AA compliance for all form components
   - Dependencies: Token System Expansion, Accessibility Audit, **actual feature requirement**
   - Notes: Build only when newsletter signup or contact form is added to roadmap

2. **Feedback Component Suite**  
   - Purpose & user value: Provide consistent user feedback mechanisms (toasts, alerts, banners) for future interactive features like newsletter signups or copy-to-clipboard actions.
   - Success metrics:  
     - Toast/Notification component with auto-dismiss
     - Alert component (info, success, warning, error)
     - Banner component for site-wide announcements
     - ProgressBar for async operations
     - ARIA live regions for screen reader announcements
   - Dependencies: Token System Expansion, **actual feature requirement**
   - Notes: Enhances existing Callout component; build when interactive features added

3. **Media & Content Components**  
   - Purpose & user value: Optimize image delivery and provide consistent media presentation with lazy loading, responsive sizing, and proper aspect ratios for Core Web Vitals.
   - Success metrics:  
     - Image component with lazy loading, srcset, WebP/AVIF support
     - Avatar component for author profiles
     - Badge component for notifications/status indicators
     - Video wrapper with poster images
     - LCP improvement via optimized image loading
   - Dependencies: Core Web Vitals Optimization, **multiple authors or video content requirement**
   - Notes: Build when blog expands to multiple authors or adds video content

4. **Living Style Guide**  
   - Purpose & user value: Generate interactive documentation showing all DesignSystem components with usage examples, props, and live previews to accelerate development and onboarding.
   - Success metrics:  
     - Automated component catalog from source code
     - Live interactive examples for each component
     - Props documentation with types and defaults
     - Accessibility notes for each component
     - "Copy code" functionality for examples
     - New contributor onboarding time reduced by 60%
   - Dependencies: Token System Expansion, **community contributor growth**
   - Notes: Constitution Principle VII requires this; build when receiving regular external contributions

5. **Visual Regression Testing**  
   - Purpose & user value: Prevent unintended visual changes to components by automatically capturing and comparing screenshots across all component variants during CI.
   - Success metrics:  
     - Snapshot tests for all components
     - Automated screenshot comparison in CI
     - Test coverage ≥ 90% for component visual states
     - Zero false positives (stable baselines)
     - Visual bugs caught before production (100% catch rate target)
   - Dependencies: Living Style Guide (test fixtures), Accessibility Audit, **DesignSystem stability**
   - Notes: TDD principle applies; implement when DesignSystem matures and changes slow down

6. **Comments System (Privacy-Friendly)**  
   - Purpose & user value: Enable community discussions on blog posts using GitHub Discussions/Issues-backed comments, fostering engagement without requiring separate auth or database.
   - Success metrics:  
     - Giscus or Utterances integrated on blog posts
     - Privacy-friendly (leverages GitHub auth, no tracking)
     - 10%+ of blog posts receive community comments
     - Zero comment moderation issues (GitHub handles spam)
     - Comments load in < 500ms
   - Dependencies: Blog infrastructure, **community growth**
   - Notes: Dev.to, Overreacted, Kent C. Dodds use GitHub-backed comments; build when blog gets regular traffic

7. **Editorial Workflow & Content Guidelines**  
   - Purpose & user value: Document content creation process, style guide, and publishing workflow to maintain consistency and accelerate content production as team grows.
   - Success metrics:  
     - Content style guide published (tone, voice, technical level)
     - Blog post template with frontmatter checklist
     - Editorial review process documented
     - Publishing checklist (images optimized? meta description? tags?)
     - Content production time reduces by 30%
   - Dependencies: Blog infrastructure, **multiple contributors**
   - Notes: Documentation artifact, not code; build when onboarding contributors

8. **Local Development Documentation**  
   - Purpose & user value: Provide comprehensive local setup guide beyond README to reduce contributor friction and onboarding time for external developers.
   - Success metrics:  
     - Local development guide published
     - Hot-reload instructions for Slipstream included
     - Troubleshooting section for common issues
     - Docker/dev container support (optional)
     - New contributor setup time < 15 minutes
   - Dependencies: Living Style Guide (documentation hub)
   - Notes: Part of open source excellence (Principle VII); build when external contributors join

9. **Component Usage Analytics**  
   - Purpose & user value: Track DesignSystem component usage across sites through static analysis to identify unused components and inform refactoring priorities data-driven.
   - Success metrics:  
     - Component usage tracked automatically
     - Unused components identified (candidates for deprecation)
     - Component dependency graph generated
     - Refactoring decisions backed by usage data
     - Zero components deprecated that are actively used
   - Dependencies: Living Style Guide, **DesignSystem maturity**
   - Notes: GitHub Design System, Shopify Polaris track adoption; build when DesignSystem has 50+ components

---

## Feature Areas (capability map)

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
2. Mobile Usability Fixes (independent, parallel track)

**Performance & Security Track** (Phase 2):
1. Brand Assets → HTML `<head>` Hygiene (OG images needed) → Social Proof Metrics
2. _headers Optimization → CSP & Security Headers (shares same file) → Core Web Vitals Optimization
3. Performance Budgets → Core Web Vitals (establishes baseline)
4. _redirects Implementation (independent)
5. security.txt (independent)
6. Broken Link Detection (independent, CI integration)

**DesignSystem Track** (Phase 2.5 - MEDIUM):
1. Token System Expansion → Layout Component Library (spacing tokens needed)
2. Token System Expansion → Dark Mode Support (Phase 3.5 - color tokens with dark variants required)

**Content & Accessibility Track** (Phase 3):
1. RSS Feed Implementation (independent)
2. Blog Tags & Filtering (independent)
3. **Search Functionality** (independent, CRITICAL for docs.21.dev)
4. Changelog & Release Notes (independent)
5. Accessibility Audit (after mobile fixes for efficiency) → Automated Accessibility Testing (CI integration)

**Theme Track** (Phase 3.5 - MEDIUM):
1. Token System Expansion (Phase 2.5) → Dark Mode Support (blocked until color tokens exist)

**Future Track** (Phase 4):
1. Privacy Policy (must complete before Plausible)
2. Plausible Analytics → Privacy Policy (analytics requires policy)
3. Documentation Versioning (when multiple major versions exist)
4. HTML `<head>` Hygiene → i18n Foundation (lang attributes prerequisite)
5. Sitemap Overhaul → Sitemap Priority Optimization (enhancement to foundation)

**Advanced Components & Community Track** (Phase 5 - LOW, feature-dependent):
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
- **Token System Expansion (Phase 2.5) BLOCKS Dark Mode (Phase 3.5)** - Must complete first
- **Privacy Policy (Phase 4) BLOCKS Plausible Analytics (Phase 4)** - GDPR requirement
- **Accessibility Audit (Phase 3) → Automated Accessibility Testing (Phase 3)** - Baseline needed
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
- **30%+ of docs visitors use search within 90 days** (Phase 3 - Search)
- Zero broken links across all three subdomains (Phase 2 - Link Detection)

**Performance**:
- P75 LCP improves from 1,288ms to < 1,000ms
- P90 LCP improves from 2,180ms to < 1,500ms
- Lighthouse Performance score ≥ 95 on all pages
- **Performance budgets enforced in CI** (HTML < 100KB, CSS < 50KB, JS < 50KB)
- **Zero performance regressions merged** (Phase 2 - Performance Budgets)

**Security & Trust**:
- **Zero XSS vulnerabilities reported** (Phase 2 - CSP Headers)
- **CSP headers deployed in strict mode** (Phase 2)
- **security.txt passes validation** at securitytxt.org (Phase 2)
- **Vulnerability disclosure process documented** (Phase 2)
- **Conversion rate improves 10%+ after social proof metrics added** (Phase 2)

**User Experience**:
- Mobile bounce rate decreases by 30%+
- Pages per session increases by 20%+ (better navigation/discoverability)
- Zero mobile usability errors in Search Console

**Accessibility**:
- Lighthouse Accessibility score ≥ 95 on all pages
- Zero WCAG AA violations
- Keyboard navigation works for 100% of interactive elements
- **Zero new accessibility violations merged to main** (Phase 3 - Automated Testing)
- **Automated a11y checks in CI** (Phase 3)

**Content Quality**:
- RSS feed subscribers reach 20%+ of regular blog readers within 90 days
- Blog tag filtering increases pages-per-session by 30%+
- **Users can quickly understand what changed between versions** (Phase 3 - Changelog)
- **Changelog RSS feed separate from blog** (Phase 3)

**Engagement & Conversion**:
- Conversion rate on "Get Started" CTA improves by 15%+ (via Plausible)
- **Social proof metrics visible** (GitHub stars, download counts) (Phase 2)
- **10%+ of blog posts receive community comments** (Phase 5 - Comments System)

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
- Zero visual regressions caught in production (Phase 5 goal)
- **Component usage tracked** for data-driven refactoring (Phase 5)
- **New contributor onboarding time < 15 minutes** (Phase 5 - Local Dev Docs)

**Privacy & Compliance**:
- **Privacy policy deployed before analytics launch** (Phase 4 - GDPR requirement)
- **Zero GDPR consent popups required** (cookie-free design)
- **Data retention policy documented** (Phase 4)

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

- v1.2.0 (2025-11-13): Added 15 critical missing features based on industry best practices: **Search Functionality** (Phase 3 - CRITICAL for docs), Security features (CSP, security.txt, broken link detection - Phase 2), Changelog & Automated Accessibility Testing (Phase 3), Privacy Policy & Documentation Versioning (Phase 4), Comments System & Editorial Workflow (Phase 5). Elevates security, content quality, and community engagement. — **MINOR** (substantial feature additions, security focus, search capability)
- v1.1.0 (2025-11-13): Added DesignSystem improvements (Token System, Layout Components, Dark Mode) as Phase 2.5/3.5 (MEDIUM priority) and advanced components as Phase 5 (LOW priority, feature-dependent). Reflects focus on foundation refactoring before feature expansion. — **MINOR** (expanded scope, DesignSystem focus)
- v1.0.0 (2025-11-13): Initial roadmap covering search discoverability, performance optimization, mobile experience, accessibility, and analytics migration. Organized into 4 phases prioritized by user impact and current pain points. — **MINOR** (new product roadmap, comprehensive feature planning)

---

## Next Steps for Individual Features

Use `/speckit.specify` to create detailed specifications for each feature:

```text
Next: /speckit.specify "Feature: Sitemap Infrastructure Overhaul — Generate comprehensive sitemaps for all subdomains with automated submission to search engines"
Next: /speckit.specify "Feature: robots.txt Standardization — Consistent crawl directives across 21.dev, docs.21.dev, md.21.dev"
Next: /speckit.specify "Feature: Mobile Usability Fixes — Eliminate responsive design issues and navigation problems on mobile devices"
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

# Phase 3 - Content & Accessibility (MEDIUM PRIORITY)
Next: /speckit.specify "Feature: RSS Feed Implementation — Atom/RSS 2.0 feed for blog subscriptions"
Next: /speckit.specify "Feature: Blog Tags & Filtering — Surface tag metadata with archive pages and filtering"
Next: /speckit.specify "Feature: Search Functionality — Instant client-side search for docs.21.dev using Pagefind or lunr.js"
Next: /speckit.specify "Feature: Changelog & Release Notes — Structured changelog for swift-secp256k1 following Keep a Changelog format"
Next: /speckit.specify "Feature: Automated Accessibility Testing — Integrate axe-core in CI to prevent new WCAG violations"
Next: /speckit.specify "Feature: Accessibility Audit & Remediation — WCAG AA compliance across all pages"

# Phase 2.5 - DesignSystem Foundation (MEDIUM PRIORITY)
Next: /speckit.specify "Feature: Token System Expansion — Comprehensive design token library with Color, Spacing, Typography, Shadow, Border, ZIndex, Animation, and Breakpoint tokens"
Next: /speckit.specify "Feature: Layout Component Library — Reusable Container, VStack, HStack, Grid, Spacer, and Divider components"

# Phase 3.5 - Dark Mode (MEDIUM PRIORITY)  
Next: /speckit.specify "Feature: Dark Mode Support — System-respecting dark theme with prefers-color-scheme and localStorage persistence"

# Phase 4 - Future Features
Next: /speckit.specify "Feature: Privacy Policy & Legal Pages — Transparent privacy policy for GDPR compliance and user trust"
Next: /speckit.specify "Feature: Plausible Analytics Migration — Self-hosted, cookie-free analytics with conversion tracking"
Next: /speckit.specify "Feature: Documentation Versioning — Version selector for swift-secp256k1 docs matching installed package versions"
Next: /speckit.specify "Feature: Internationalization Foundation — i18n-ready structure and scaffolding for future multi-language support"

# Phase 5 - Advanced Components & Community (LOW PRIORITY, feature-dependent)
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
