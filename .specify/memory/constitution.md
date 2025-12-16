<!--
Sync Impact Report:
- Version: 1.0.0 → 1.1.0 (MINOR - Expanded specification guidance)
- Change Type: Enhanced Principle II with detailed specification requirements
- Scope: Websites monorepo only (/Users/csjones/Developer/websites)
- Structure: Two-tier (7 core principles + implementation practices in nested format)
- Core Principles:
  I. Static-First Architecture
  II. Spec-First & Test-Driven Development [EXPANDED - Added small/independent spec requirements]
  III. Accessibility & Performance by Default
  IV. Design System Consistency
  V. Zero-Dependency Philosophy
  VI. Security & Privacy by Design
  VII. Open Source Excellence
- Principle II Changes:
  • Added "Specification Requirements" subsection with 10 specific MUST/MUST NOT rules
  • Added "Test-Driven Development" subsection for clarity
  • Enhanced rationale to include benefits of small, independent specs
  • Added compliance requirement to reject specs with multiple features or dependencies
  • Preserved Infrastructure-as-Code exemption (unchanged)
- Enforcement: Three-tier model (MUST/SHOULD/MAY)
- Governance: Minimal (project owner amendments, community proposals via issues)
- Compliance: Continuous CI + event-driven strategic review
- Templates Status:
  ⚠ spec-template.md - Requires alignment review (now HIGH PRIORITY)
  ⚠ plan-template.md - Requires alignment review
  ⚠ tasks-template.md - Requires alignment review
  ⚠ checklist-template.md - Requires alignment review
- Version History:
  • 1.0.0 (2025-11-13): Initial constitution with 7 core principles
  • 1.1.0 (2025-11-13): Expanded Principle II with detailed specification requirements
-->

# Constitution for Static Sites created by 21.dev

## Preamble

This constitution governs all static websites in the **websites monorepo** (`/Users/csjones/Developer/websites`). Applies to 21.dev and all future sites in this umbrella project.

**Scope**: Websites monorepo only. Does NOT govern Slipstream framework, swift-secp256k1, or other 21.dev repositories.

**Philosophy**: Principles are technology-agnostic where possible. Current technology choices documented separately to enable future migrations without constitutional amendments.

---

## Core Principles

### I. Static-First Architecture

**Statement**: All sites MUST generate pure static HTML/CSS/JS with no server-side rendering, no runtime frameworks, and no client-side routing.

**Rationale**: Static sites deliver superior performance, security, reliability, and deployment simplicity. Pre-rendered content is CDN-friendly, eliminates runtime vulnerabilities, scales infinitely, and works everywhere.

**Practices**:
- **MUST** output static files to `Websites/<SiteName>/`
- **MUST** enforce "zero-JS by default" with optional progressive enhancements
- **MUST** prohibit heavy frameworks (React, Vue, Angular, Svelte) unless explicitly justified
- **MUST** generate deterministic builds (same input → same output)
- **MUST** resolve all dynamic content at build time
- **MUST** optimize for CDN delivery with proper caching headers
- **SHOULD** keep JavaScript bundles minimal (< 50KB gzipped)
- **SHOULD** deploy to static hosts (GitHub Pages, Cloudflare Pages, Netlify)
- **MAY** use progressive enhancement for optional features

**Compliance**: CI scans for framework imports, validates build determinism, measures bundle sizes. Violations MUST block merge.

---

### II. Spec-First & Test-Driven Development

**Statement**: Every feature MUST start with a specification. All application code MUST follow test-driven development: tests written first, verified to fail, then implementation proceeds.

**Rationale**: Specifications ensure alignment with user needs and provide measurable success criteria. Small, independent specs enable parallel work, reduce risk, accelerate feedback cycles, and allow incremental delivery. TDD prevents regressions, enables confident refactoring, and documents expected behavior.

**Practices - Specification Requirements**:
- **MUST** create `spec.md` for every feature before development
- **MUST** represent a single feature or small subfeature (not multiple unrelated features)
- **MUST** be independently testable (no dependencies on incomplete specs)
- **MUST** represent a deployable increment of value
- **MUST** define user scenarios, acceptance criteria, success metrics
- **MUST** focus on behavior, not implementation details
- **MUST** prioritize user stories by importance (P1/P2/P3 or similar)
- **MUST NOT** combine multiple unrelated features in one spec
- **MUST NOT** create dependencies on incomplete specs
- **MUST NOT** describe implementation details instead of user-facing behavior

**Practices - Test-Driven Development**:
- **MUST** write tests before implementation (red → green → refactor)
- **MUST** verify tests fail initially
- **MUST** maintain separate unit, integration, and contract tests
- **SHOULD** develop outside-in (user's perspective first)

**Infrastructure-as-Code Exemption**:  
Configuration files (GitHub Actions workflows, deployment manifests, CI/CD pipelines) exempt from strict TDD but MUST satisfy:
1. Automated syntax/schema validation before commit
2. Integration testing via actual execution (PR previews, staging)
3. Unit tests for extractable business logic (scripts >10 lines)
4. Documented validation procedures

**Compliance**: PRs MUST include tests written first. CI blocks merges if tests missing or immediately passing. Specs combining multiple features or creating spec dependencies MUST be rejected in review.

---

### III. Accessibility & Performance by Default

**Statement**: All sites MUST follow WCAG principles (Perceivable, Operable, Understandable, Robust) and achieve fast, optimized delivery for all users.

**Rationale**: Accessibility is a right, not optional. Performance impacts UX, SEO, and conversions. Building these in from start costs less than retrofitting.

**Practices**:
- **MUST** use semantic HTML elements appropriately
- **MUST** provide alt text for all images (build fails if missing)
- **MUST** ensure sufficient color contrast (WCAG AA minimum)
- **MUST** support keyboard navigation for interactive elements
- **MUST** include proper ARIA roles, labels, live regions
- **MUST** generate responsive images (WebP/AVIF with resized variants)
- **MUST** keep page weight reasonable (HTML < 100KB, CSS < 50KB)
- **SHOULD** achieve Lighthouse scores: Performance ≥ 90, Accessibility ≥ 95
- **SHOULD** test with assistive technologies (VoiceOver, NVDA, JAWS)
- **MAY** progressively enhance advanced features

**Compliance**: Three-tier enforcement:
- **Tier 1 (MUST/Blocking)**: Valid HTML, alt tags, build success
- **Tier 2 (SHOULD/Warning)**: Accessibility < 95, Performance < 90, images > 500KB (requires override justification)
- **Tier 3 (MAY/Advisory)**: SEO recommendations, compatibility warnings

---

### IV. Design System Consistency

**Statement**: All sites MUST use the shared DesignSystem for components, layouts, tokens, and utilities. No ad-hoc site-specific design logic.

**Rationale**: Centralized design systems ensure brand consistency, accelerate development through reuse, reduce maintenance, prevent fragmentation.

**Practices**:
- **MUST** create components in `Sources/DesignSystem/Components/`
- **MUST** define layouts in `Sources/DesignSystem/Layouts/`
- **MUST** store design tokens in `Sources/DesignSystem/Tokens/`
- **MUST** use shared utilities from `Sources/DesignSystem/Utilities/`
- **MUST** ensure site targets depend on DesignSystem
- **MUST NOT** duplicate component logic across sites
- **SHOULD** define global theming at DesignSystem level
- **SHOULD** extract repeated patterns into DesignSystem
- **SHOULD** provide living style guide documentation

**Compliance**: Code reviews MUST reject site-specific design implementations. CI SHOULD warn on duplication patterns.

---

### V. Zero-Dependency Philosophy

**Statement**: Sites MUST NOT introduce dependencies beyond essential static site generation tooling. Every dependency is a liability.

**Rationale**: Minimizing dependencies reduces attack surface, prevents breaking changes, keeps builds fast, ensures long-term maintainability.

**Practices**:
- **MUST** limit dependencies to SSG essentials only
- **MUST** avoid JavaScript frameworks (React, Vue, Angular, Svelte)
- **MUST** avoid CSS frameworks beyond utility-first styling
- **MUST** avoid runtime dependencies in generated sites
- **MUST NOT** add dependencies without constitutional review
- **SHOULD** implement solutions using existing stack first
- **MAY** use build-time tooling (linters, formatters, minifiers, perf testing)
- **MAY** use CDN-hosted resources (analytics/fonts, minimal snippets only)
- **MAY** add npm packages for build-time-only tasks (NOT shipped to production)

**Compliance**: PRs adding dependencies MUST include justification and constitutional review approval. CI blocks unapproved dependencies.

---

### VI. Security & Privacy by Design

**Statement**: Sites MUST incorporate OWASP security guidelines and GDPR privacy principles from the start.

**Rationale**: Static sites have minimal attack surface but remain vulnerable to XSS, misconfiguration, privacy violations. Building security/privacy in prevents costly fixes and legal exposure.

**Practices**:
- **MUST** use HTTPS everywhere (no mixed content)
- **MUST** validate/sanitize user-generated content before rendering
- **MUST** prevent XSS through proper templating and escaping
- **MUST** follow GDPR: lawful, fair, transparent data processing
- **MUST** collect only necessary data for defined purposes
- **MUST** obtain explicit consent before collecting personal data
- **MUST** provide mechanisms for data deletion/export
- **MUST NOT** store sensitive information client-side (no secrets, API keys)
- **MUST NOT** include third-party tracking without consent
- **SHOULD** set security headers (CSP, X-Frame-Options, X-Content-Type-Options)
- **SHOULD** regularly audit dependencies for vulnerabilities
- **MAY** implement privacy-respecting analytics (self-hosted, anonymized)

**Compliance**: CI scans for hardcoded secrets, validates HTTPS, checks vulnerabilities. Privacy policy required if collecting user data.

---

### VII. Open Source Excellence

**Statement**: All development MUST follow open source best practices: comprehensive documentation, welcoming contributions, clear licensing, avoiding over-engineering.

**Rationale**: Open source thrives on transparency, collaboration, accessibility. Good documentation reduces friction, clear decisions preserve knowledge, simplicity encourages contributions.

**Practices**:
- **MUST** document architecture decisions (ADRs or similar)
- **MUST** maintain clear README with setup instructions
- **MUST** provide contribution guidelines (CONTRIBUTING.md)
- **MUST** include LICENSE file (MIT or compatible)
- **MUST** write clear, human-readable code (readability over cleverness)
- **MUST** apply KISS and DRY principles
- **MUST** document public APIs with inline comments
- **SHOULD** maintain living style guide for DesignSystem
- **SHOULD** provide issue/PR templates
- **SHOULD** welcome bug reports and feature requests
- **SHOULD** respond to community contributions promptly and respectfully

**Compliance**: PRs MUST include documentation updates for new features/API changes. Code reviews enforce readability.

---

## Implementation Guidance

### Content & Presentation Separation

**Principle**: Content MUST be separated from presentation logic and stored in versionable, editable formats.

**Current Implementation**:
- Prose content (blog, docs) stored as Markdown with YAML frontmatter in `Resources/<SiteName>/`
- Page structure/layout defined in code (`Sources/<SiteName>/Pages/`)
- Service layer processes content (rendering, indexing, metadata)
- Static assets in `Resources/<SiteName>/static/`

**Requirements**:
- Markdown MUST include required frontmatter (title, date, slug)
- Build MUST fail if required metadata missing
- Folder structure MUST be predictable: `Resources/<SiteName>/{blog|docs|pages}/`

**Rationale**: Separating content from code enables non-developer contributions, simplifies updates, allows tech migrations without content rewrites.

---

### SEO & Metadata Standards

**Requirements**:
- **MUST** generate unique titles for every page
- **MUST** provide meta descriptions (140-160 chars optimal)
- **MUST** include canonical links (prevent duplicate content)
- **MUST** generate sitemap.xml for search indexing
- **MUST** provide robots.txt with crawl directives
- **SHOULD** implement structured data (JSON-LD)
- **SHOULD** generate OpenGraph/Twitter Card metadata for social sharing

**Compliance**: CI validates metadata completeness (Tier 2 warning).

---

### Internationalization (Optional)

For sites requiring multiple languages:
- **SHOULD** provide i18n scaffolding (URL patterns, translation files, locale metadata)
- **SHOULD** use clear URL patterns (`/en/`, `/es/` or subdomains)
- **SHOULD** maintain separate content files per language
- **SHOULD** include `lang` attribute on HTML elements

Current sites may skip until needed.

---

### Build Reliability & Developer Ergonomics

**Build Requirements**:
- **MUST** be deterministic (same input → same output)
- **MUST** clearly indicate failures (missing frontmatter, invalid HTML, broken links)
- **SHOULD** complete in < 2 minutes per site

**Development Experience**:
- **SHOULD** provide hot-reload dev server
- **SHOULD** enable automatic rebuilds on changes
- **SHOULD** display clear error messages for validation failures

---

### Deployment Rules

**Pre-Deployment Quality Gates**:
- **MUST** pass all tests (unit, integration, contract)
- **MUST** pass linting checks
- **MUST** validate accessibility (WCAG AA minimum)
- **MUST** check broken links (internal/external)
- **MUST** validate metadata completeness
- **MUST** verify image sizes meet thresholds
- **MUST** validate HTML structure

**Process**:
- **MUST** deploy only from clean, passing main branch
- **MUST** run full CI pipeline before production
- **MAY** deploy PR previews for validation

---

## Technology Stack (Current Implementation)

**Note**: Constitution defines technology-agnostic principles. This section documents current choices, which may change without constitutional amendments.

### Current Stack (2025-11-13)

**SSG**: Slipstream v2 (Swift-based)  
**Language**: Swift 6.1+  
**Build**: Swift Package Manager (SPM)  
**Styling**: TailwindCSS via swift-plugin-tailwindcss  
**Testing**: swift-testing (NOT XCTest)  
**Documentation**: swift-docc-plugin, DocC4LLM  
**Additional**: swift-subprocess  

**Approved Dependencies**:
- Slipstream v2
- swift-plugin-tailwindcss
- swift-testing
- swift-docc-plugin
- DocC4LLM
- swift-subprocess
- swift-argument-parser (build-time CLI tooling only)

**File Structure**:
- Sites: `Sources/<SiteName>/` (executable targets)
- DesignSystem: `Sources/DesignSystem/` (components, layouts, tokens, utilities)
- Tests: `Tests/DesignSystemTests/`, `Tests/IntegrationTests/`, `Tests/TestUtils/`
- Content: `Resources/<SiteName>/` (Markdown, assets, config)
- Output: `Websites/<SiteName>/` (git-ignored)

**CI/CD**: GitHub Actions (macOS-15, Swift 6.1) → Cloudflare Pages

---

## Governance

### Authority

This constitution supersedes all other development practices. Deviations MUST be explicitly justified and approved.

### Amendment Process

1. Project owner proposes amendment with rationale and impact analysis
2. Version updated (semantic versioning):
   - **MAJOR**: Backward-incompatible changes or principle removals
   - **MINOR**: New principle or materially expanded guidance
   - **PATCH**: Clarifications, wording fixes
3. Update dependent templates in `.specify/templates/`
4. Document changes in Sync Impact Report
5. Commit with descriptive message

**Approval**: Project owner can amend directly (minimal governance). Community proposes via issues.

### Compliance Review

**Continuous Enforcement**: Three-tier CI checks on every PR
- **MUST**: Blocks merge
- **SHOULD**: Warning, requires override justification
- **MAY**: Informational only

**Event-Driven Strategic Review**: Triggered by:
1. Adding new site to monorepo
2. Technology migration (e.g., Slipstream → Hugo)
3. Repeated violations (3+ SHOULD overrides in 30 days)
4. Annual checkpoint (lightweight: "Do principles still serve us?")

**Metrics**: Specific thresholds (Lighthouse scores, bundle sizes, build times) defined in CI config, NOT constitution. Allows adjustment without amendments.

### Enforcement

- PR reviewers verify constitutional alignment
- CI pipeline enforces MUST-level (blocking), SHOULD-level (warnings)
- Windsurf rules (`.windsurf/rules/*.md`) provide AI assistant guidance aligned with principles

---

## Version History

**Version**: 1.1.1  
**Ratified**: 2025-11-13  
**Last Amended**: 2025-12-15

**Changelog**:
- **1.1.1** (2025-12-15): Added swift-argument-parser to approved dependencies for build-time CLI tooling (Feature 004).
- **1.1.0** (2025-11-13): Enhanced Principle II with detailed specification requirements. Added 10 specific MUST/MUST NOT rules for small, independent specs. Split practices into "Specification Requirements" and "Test-Driven Development" subsections for clarity.
- **1.0.0** (2025-11-13): Initial constitution with 7 core principles, technology-agnostic structure, three-tier enforcement, event-driven compliance review.

---

## Appendix: Principle Mapping

This constitution consolidates original principle sources:

**From General Principles (4.1)**:
- Spec-First & Outside-In → Principle II
- Test-Driven Development → Principle II
- Small, Independent Specs → Principle II
- CI & Quality Gates → Principles III, Deployment Rules
- Simplicity & Readability → Principle VII
- Open Source Excellence → Principle VII
- Governance & Amendments → Governance

**From Websites Principles (4.3)**:
- Accessibility-First → Principle III
- Privacy by Design → Principle VI
- Secure Coding → Principle VI
- Progressive Enhancement → Principles I, III
- Documentation & Community → Principle VII

**From Principle Table**:
- Performance → Principles I, III
- Accessibility (WCAG POUR) → Principle III
- Security → Principle VI
- SEO & Metadata → SEO Standards
- Content Workflow → Content/Presentation Separation
- Internationalization → i18n section
- Design Consistency → Principle IV
- Minimal JavaScript → Principle I
- Image Optimization → Principle III
- Build Reliability → Build Reliability section
- Developer Ergonomics → Developer Ergonomics section
- Deployment Rules → Deployment Rules section
