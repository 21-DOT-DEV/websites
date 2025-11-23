# Feature Specification: Cloudflare _headers Optimization

**Feature Branch**: `002-cloudflare-headers`  
**Created**: 2025-11-21  
**Status**: Draft  
**Input**: User description: "Cloudflare _headers Optimization for 21.dev, docs.21.dev, and md.21.dev to implement baseline caching, security headers, and performance improvements."

## Clarifications

- All three subdomains (21.dev, docs.21.dev, md.21.dev) must participate.  
- Existing `_headers` rules live in `Resources/21-dev/_headers`; docs/md equivalents do not yet exist.  
- Recommended header set should follow industry best practices (strict CSP, HSTS preload, immutable caching for assets, short-lived HTML caching, permissions policy to disable unused APIs).
- Preview deployments MUST disable HSTS entirely so temporary preview URLs never enter preload lists (production-only HSTS).
- Advanced automation (HeadersValidator CLI, environment-aware scaffolding) is deferred to Phase 2 “Utilities Library Refactoring” and is intentionally out of scope here.

### Session 2025-11-21

- Q: Should preview deployments emit HSTS headers? → A: No. Preview builds disable HSTS entirely; only production domains ship `max-age=63072000; includeSubDomains; preload`.
- Q: Which origins must CSP allow by default? → A: `self` plus Cloudflare Web Analytics endpoints (e.g., `https://static.cloudflareinsights.com`) across all subdomains.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Security Baseline for Every Page (Priority: P1)

Visitors to any 21.dev property should automatically receive strong security headers (HSTS, CSP, X-Frame-Options, Referrer-Policy, Permissions-Policy) on every response so browsers block downgrade, clickjacking, or data-leak attempts without requiring manual Cloudflare Rules.

**Why this priority**: Missing security headers leave gaps in the existing foundation work (sitemaps + robots). Establishing a uniform baseline is required before expanding traffic because it mitigates direct risk to all visitors.

**Independent Test**: Deploy only the header definitions and validate via automated scans (e.g., securityheaders.com, curl) that each page on all subdomains returns the mandated headers with correct values.

**Acceptance Scenarios**:

1. **Given** a request to `https://21.dev/`, **When** Cloudflare serves the page, **Then** the response includes HSTS (`max-age=63072000; includeSubDomains; preload`), CSP, X-Frame-Options, Referrer-Policy, X-Content-Type-Options, and Permissions-Policy headers.
2. **Given** a request to `https://docs.21.dev/documentation/index.html`, **When** the response is returned, **Then** a CSP tailored for DocC assets is present with the same baseline security headers as 21.dev.
3. **Given** a request to `https://md.21.dev/index.md`, **When** the file is served, **Then** the markdown download is protected by the same header set even though it is not HTML.

---

### User Story 2 - Performance-Focused Edge Caching (Priority: P2)

Anonymous readers should experience faster loads because Cloudflare caches static assets for a year, HTML for five minutes, and avoids caching API-like endpoints, resulting in higher cache-hit rates and improved Core Web Vitals.

**Why this priority**: Performance improvements drive SEO gains and justify the roadmap metric targets (LCP, cache hit rate). Once the security baseline exists, caching is the next most impactful effort.

**Independent Test**: With caching headers applied, observe Cloudflare analytics or synthetic tests to confirm TTLs and `Cache-Control` directives match the targeted policies for HTML, assets, and API responses.

**Acceptance Scenarios**:

1. **Given** `https://21.dev/static/style.css` is requested, **When** Cloudflare responds, **Then** it includes `Cache-Control: public, max-age=31536000, immutable` and Cloudflare reports a cache hit on subsequent requests.
2. **Given** `https://docs.21.dev/documentation/tutorials/index.html` is requested, **When** served, **Then** HTML responses include `Cache-Control: public, max-age=300, must-revalidate` so fresh deployments propagate quickly.
3. **Given** any JSON or API-style endpoint introduced later, **When** `_headers` rules are evaluated, **Then** those endpoints return `Cache-Control: no-store` to prevent stale data.

---

### User Story 3 - Operational Consistency & Monitoring (Priority: P3)

The site owner needs `_headers` to be version-controlled, automatically copied by each subdomain workflow, and validated during CI so regressions (missing file, header drift, preview vs. production differences) are caught before deployment.

**Why this priority**: Maintains the foundation once delivered. Without governance, headers can drift per subdomain, degrading over time.

**Independent Test**: Run CI workflows that check `_headers` presence, lint header values, and fail builds when inconsistencies are found, without requiring the caching/security behavior to be implemented simultaneously.

**Acceptance Scenarios**:

1. **Given** a developer removes `_headers` for docs.21.dev accidentally, **When** the docs workflow runs, **Then** it fails with a clear error before publishing to Cloudflare Pages.
2. **Given** `_headers` are updated for 21.dev, **When** the Slipstream build executes, **Then** the file is copied into `Websites/21-dev/_headers` and deployed without manual Cloudflare configuration.
3. **Given** the production deployment completes, **When** smoke tests run, **Then** curl-based checks confirm all targeted headers exist and emit metrics (e.g., header presence, TTL) for observability.

### Edge Cases

- What happens when a preview deployment should not send HSTS (preload list risk)? → Must support preview-specific overrides so only production builds enable preload.
- How does the system handle third-party embeds (e.g., YouTube) that require relaxed CSP directives? → Need scoped CSP entries per path with documentation for allowed origins.
- What if a new asset type (fonts, wasm) is introduced? → `_headers` must provide wildcard coverage so new file extensions inherit safe defaults until explicit rules are added.
- How are redirects handled when both `_redirects` and `_headers` modify the same path? → Headers must still apply post-redirect (final response) and cannot conflict with future Feature 4 work.

## Requirements *(mandatory)*

### Functional Requirements

#### Repository Structure & Propagation

- **FR-001**: Each subdomain MUST have a dedicated `_headers` file stored under `Resources/<subdomain>/_headers` and version-controlled with the site content.
- **FR-002**: Build workflows for 21.dev, docs.21.dev, and md.21.dev MUST copy their `_headers` file into the corresponding `Websites/<subdomain>/_headers` output folder prior to deployment (similar to the existing 21.dev static copy step).
- **FR-003**: Cloudflare Pages deploy steps MUST reference the committed `_headers` files; no manual dashboard overrides are allowed.

#### Security Header Policy

- **FR-004**: All HTML responses MUST include `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload` when deployed to production domains.
- **FR-004.1**: Preview deployments MUST omit HSTS headers entirely to avoid browsers caching non-production domains in preload lists.
- **FR-005**: All responses MUST include `X-Content-Type-Options: nosniff` and `X-Frame-Options: DENY` (or SAMEORIGIN if a justified exception is documented).
- **FR-006**: Each subdomain MUST define a Content Security Policy (CSP) that blocks inline scripts/styles by default, permits only required origins (`self` plus Cloudflare Web Analytics endpoints such as `https://static.cloudflareinsights.com`), and includes `upgrade-insecure-requests`.
- **FR-007**: Responses MUST include `Referrer-Policy: strict-origin-when-cross-origin` to prevent data leakage while enabling analytics.
- **FR-008**: Responses MUST include a Permissions Policy explicitly disabling unused browser features (`geolocation=(), microphone=(), camera=(), payment=()`, etc.).
- **FR-009**: `_headers` MUST allow subdomain-specific CSP extensions (e.g., DocC search bundle, markdown downloads) without weakening other domains.

#### Performance & Caching Policy

- **FR-010**: Static assets (CSS, JS, fonts, images, SVG, wasm) MUST return `Cache-Control: public, max-age=31536000, immutable` using wildcard rules (`/static/*`, `/documentation/**/static/*`, etc.).
- **FR-011**: HTML documents across all subdomains MUST return `Cache-Control: public, max-age=300, must-revalidate` to balance freshness and caching.
- **FR-012**: Download or API-style endpoints (e.g., `.well-known/llms.txt`, future JSON APIs) MUST return `Cache-Control: no-store` to avoid stale data in intermediaries.
- **FR-013**: `_headers` MUST include `Vary: Accept-Encoding` for compressible resources to maintain correct cache segmentation between gzip and brotli.

#### Governance, Testing, and Monitoring

- **FR-014**: CI workflows (`.github/workflows/*`) MUST add validation steps that fail the build if `_headers` is missing, malformed, or omits any mandatory header for the target subdomain.
- **FR-015**: Deployment workflows MUST emit structured logs summarizing applied header policies (e.g., which patterns map to which headers) for auditing.
- **FR-016**: A documented smoke test (curl or security scanner) MUST run after each production deploy to verify header presence on at least one URL per subdomain, failing the workflow on mismatch.
- **FR-017**: `_headers` definitions MUST be documented in README or spec appendix so future contributors know how to extend policies safely.

### Key Entities

- **Header Profile**: A logical grouping of header directives (security baseline, long-lived cache, no-store) applied to URL patterns; determines which headers appear on final responses.
- **Subdomain Deployment Workflow**: The GitHub Actions pipeline responsible for building and uploading a subdomain, now extended to consume `_headers`, run validations, and emit observability data.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All three subdomains score A (or equivalent "secure") on securityheaders.com scans thanks to the mandated header set.
- **SC-002**: Cloudflare analytics report ≥80% cache-hit ratio for static assets within 30 days of launch.
- **SC-003**: P75 Largest Contentful Paint decreases from 1,288 ms to <1,000 ms and P90 LCP decreases from 2,180 ms to <1,500 ms (measured via Cloudflare or synthetic monitoring) after caching policies launch.
- **SC-004**: CI/CD workflows block deployments if `_headers` is missing or invalid, evidenced by at least one failing test run prior to completion during validation.
- **SC-005**: All production responses (sampled monthly) include the specified security headers with correct values, documented via smoke-test reports stored with deployment artifacts.

## Assumptions

- Cloudflare Pages honors `_headers` consistently across production and preview builds (with the option to override values for previews if needed).
- No additional third-party scripts beyond existing analytics are required; any new integrations will update the CSP matrix before deployment.
- GitHub Actions already deploys each subdomain independently, so updating workflows to copy `_headers` and run validations is feasible without architectural changes.
- Cloudflare analytics and synthetic monitoring data are available to confirm cache-hit and LCP metrics.
