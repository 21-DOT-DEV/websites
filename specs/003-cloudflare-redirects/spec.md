# Feature Specification: Cloudflare _redirects Implementation

**Feature Branch**: `003-cloudflare-redirects`  
**Created**: 2025-12-14  
**Status**: Draft  
**Input**: User description: "Cloudflare _redirects Implementation for All Subdomains"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Documentation Root Redirect (Priority: P1)

A developer visits `https://docs.21.dev/` or `https://docs.21.dev/p256k` and is automatically redirected to the documentation landing page at `/documentation/`.

**Why this priority**: Most common entry point for documentation users. Without this redirect, users see a 404 or blank page, creating immediate friction.

**Independent Test**: Visit `https://docs.21.dev/` in browser; should redirect to `https://docs.21.dev/documentation/` with 301 status.

**Acceptance Scenarios**:

1. **Given** a user visits `https://docs.21.dev/`, **When** the request is processed, **Then** they are redirected to `https://docs.21.dev/documentation/` with a 301 status code
2. **Given** a user visits `https://docs.21.dev/p256k`, **When** the request is processed, **Then** they are redirected to `https://docs.21.dev/documentation/` with a 301 status code
3. **Given** a user visits `https://docs.21.dev/documentation/`, **When** the request is processed, **Then** no redirect occurs and the page loads normally

---

### User Story 2 - Markdown Site Root Redirect (Priority: P2)

A developer or LLM visits `https://md.21.dev/` and is automatically redirected to the main index file at `/index.md`.

**Why this priority**: Ensures LLM consumers and developers land on the correct entry point for markdown documentation.

**Independent Test**: Visit `https://md.21.dev/` in browser or via curl; should redirect to `https://md.21.dev/index.md` with 301 status.

**Acceptance Scenarios**:

1. **Given** a user or LLM visits `https://md.21.dev/`, **When** the request is processed, **Then** they are redirected to `https://md.21.dev/index.md` with a 301 status code
2. **Given** a user visits `https://md.21.dev/index.md`, **When** the request is processed, **Then** no redirect occurs and the file is served normally

---

### User Story 3 - Version-Controlled Redirect Configuration (Priority: P3)

A maintainer adds a new redirect rule by editing the `_redirects` file in the repository and deploying, without needing to access the Cloudflare dashboard.

**Why this priority**: Enables redirect management through standard git workflows, improving maintainability and auditability.

**Independent Test**: Add a test redirect to `_redirects`, deploy, and verify the redirect works.

**Acceptance Scenarios**:

1. **Given** a maintainer adds `/test-redirect /documentation/ 301` to the `_redirects` file, **When** the site is deployed, **Then** visiting `/test-redirect` redirects to `/documentation/`
2. **Given** a `_redirects` file exists in the deployed output, **When** Cloudflare Pages processes it, **Then** all redirect rules are applied at the edge

---

### Edge Cases

- What happens when a redirect source path doesn't exist? → Redirect still applies (Cloudflare processes `_redirects` before file lookup)
- What happens when a redirect source conflicts with an existing file? → Redirect takes precedence per Cloudflare Pages behavior
- What happens with query strings? → Query strings are preserved by default for 301 redirects
- What happens with trailing slashes in redirect sources? → Both `/path` and `/path/` should be handled consistently (Cloudflare normalizes trailing slashes)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST create `_redirects` files for docs.21.dev and md.21.dev subdomains
- **FR-002**: docs.21.dev MUST redirect `/` to `/documentation/` with 301 status
- **FR-003**: docs.21.dev MUST redirect `/p256k` to `/documentation/` with 301 status
- **FR-004**: md.21.dev MUST redirect `/` to `/index.md` with 301 status
- **FR-005**: All `_redirects` files MUST be stored in `Resources/<SiteName>/` and copied to the appropriate `Websites/<SiteName>/` output directory during build
- **FR-006**: Redirect rules MUST be documented with inline comments explaining purpose
- **FR-007**: System MUST use consistent trailing slash convention (always add) matching Cloudflare Pages default
- **FR-008**: Redirects MUST execute at edge without performance degradation
- **FR-009**: Same `_redirects` files MUST be used for both production and preview deployments
- **FR-010**: Canonical domain redirect (non-canonical hosts to 21.dev) MUST remain in Cloudflare Rules (requires dynamic expressions not supported by `_redirects`)
- **FR-011**: CI workflow MUST include post-deployment smoke test verifying redirect responses return 301 status

### Key Entities

- **`_redirects` file**: Cloudflare Pages configuration file containing redirect rules in `source destination [status]` format
- **Redirect Rule**: A single line in `_redirects` specifying source path, destination path, and optional HTTP status code

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All redirects execute in < 10ms at Cloudflare edge (verified via response timing)
- **SC-002**: Zero manual Cloudflare Page Rules needed for path-based redirects
- **SC-003**: 301 redirects return proper HTTP status code (verified via curl -I)
- **SC-004**: Redirect configuration lives in version control with full git history
- **SC-005**: `_redirects` syntax is valid and processed by Cloudflare Pages without errors
- **SC-006**: Support for 50+ redirect rules without performance impact (Cloudflare Pages limit is 2000 rules)
- **SC-007**: Automated CI smoke test verifies redirect functionality after each deployment

## Clarifications

### Session 2025-12-14

- Q: Where should `_redirects` source files live in the repository? → A: `Resources/<SiteName>/` (e.g., `Resources/docs-21-dev/_redirects`)
- Q: How should redirects be verified after deployment? → A: Automated smoke test in CI after deployment (curl check for 301 status)

## Assumptions

- Cloudflare Pages is the deployment target for all three subdomains
- Trailing slash normalization is handled by Cloudflare Pages "Add trailing slashes" setting
- The canonical domain redirect (www.21.dev → 21.dev, etc.) will remain in Cloudflare Rules due to requiring dynamic expression matching not supported by `_redirects` files
- 21.dev does not currently need a `_redirects` file (no path-based redirects identified)

## Dependencies

- Existing GitHub Actions workflows for each subdomain (build-slipstream.yml, generate-docc.yml, generate-markdown.yml)
- Cloudflare Pages deployment configuration

## Out of Scope

- Migration of canonical domain redirect from Cloudflare Rules to `_redirects`
- Build-time redirect generation from data files (YAGNI for current 4-5 rules)
- Environment-specific redirect variants (prod vs preview)
