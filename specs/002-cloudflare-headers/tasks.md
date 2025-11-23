---
description: "Task list template for feature implementation"
---

# Tasks: Cloudflare _headers Optimization

**Input**: Design documents from `/specs/002-cloudflare-headers/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Tests are OPTIONAL for this feature. Per scope alignment, we will rely on manual verification commands (curl/securityheaders) documented in quickstart.md rather than automated test tasks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish baseline `_headers` files for every subdomain directory.

- [X] T001 Create baseline placeholder file `Resources/docs-21-dev/_headers` with descriptive comments for security + caching sections.
- [X] T002 Create baseline placeholder file `Resources/md-21-dev/_headers` with descriptive comments for security + caching sections.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Ensure build/deploy workflows copy `_headers` files for every subdomain.

- [X] T003 Update `.github/workflows/21-DEV.yml` to confirm the Slipstream build copies `Resources/21-dev/_headers` into `Websites/21-dev/_headers` (fail workflow if missing).
- [X] T004 Update `.github/workflows/DOCS-21-DEV.yml` to copy `Resources/docs-21-dev/_headers` into the DocC artifact before publishing to Cloudflare Pages.
- [X] T005 Update `.github/workflows/MD-21-DEV.yml` to copy `Resources/md-21-dev/_headers` into the markdown site output prior to deployment.

**Checkpoint**: `_headers` files are version-controlled and deployed for all three subdomains.

---

## Phase 3: User Story 1 - Security Baseline for Every Page (Priority: P1) 🎯 MVP

**Goal**: Ensure every response across 21.dev, docs.21.dev, and md.21.dev includes the mandated security headers.

**Independent Test**: After deployment, run `curl -I` against representative URLs for each subdomain to confirm HSTS (production only), CSP, X-Frame-Options, Referrer-Policy, X-Content-Type-Options, and Permissions-Policy headers.

### Implementation for User Story 1

- [X] T006 [US1] Expand `Resources/21-dev/_headers` with production security directives (HSTS preload, CSP allowing `self` + Cloudflare analytics, Referrer-Policy, Permissions-Policy, X-Frame-Options, X-Content-Type-Options) and preview-specific blocks that omit HSTS.
- [X] T007 [US1] Author `Resources/docs-21-dev/_headers` with DocC-specific CSP allowances plus the full security header set, ensuring preview deployments disable HSTS.
- [X] T008 [US1] Author `Resources/md-21-dev/_headers` covering markdown downloads and `.well-known` outputs with the same security header set (HSTS only for production HTML paths, not raw downloads).

**Checkpoint**: All three `_headers` files deliver the required security directives.

---

## Phase 4: User Story 2 - Performance-Focused Edge Caching (Priority: P2)

**Goal**: Provide universal caching directives that improve cache-hit ratio without jeopardizing content freshness.

**Independent Test**: Issue `curl -I` for HTML, static assets, and download endpoints on each subdomain to confirm `Cache-Control` matches HTML (public, max-age=300, must-revalidate), assets (public, max-age=31536000, immutable), and download/no-store policies.

### Implementation for User Story 2

- [X] T009 [US2] Add HTML caching rules to each `_headers` file (patterns such as `/*.html`, `/documentation/**/*.html`, `/index.md`) using `Cache-Control: public, max-age=300, must-revalidate` and `Vary: Accept-Encoding`.
- [X] T010 [P] [US2] Add static asset caching rules (`/static/*`, `/documentation/**/static/*`, `/assets/*`) with `Cache-Control: public, max-age=31536000, immutable` plus compression hints.
- [X] T011 [US2] Add download/no-store rules for `.well-known/` and any JSON endpoints across the three `_headers` files using `Cache-Control: no-store` and documenting rationale in file comments.

**Checkpoint**: Cache directives align with success metrics and are applied consistently.

---

## Phase 5: User Story 3 - Operational Consistency & Monitoring (Priority: P3)

**Goal**: Keep `_headers` policies understandable for future contributors and provide lightweight verification instructions without introducing new tooling.

**Independent Test**: Follow quickstart instructions to run `curl -I` for representative URLs and confirm results match the documented header matrix.

### Implementation for User Story 3

- [X] T012 [US3] Update `specs/002-cloudflare-headers/quickstart.md` with explicit curl commands for each subdomain plus expected header snippets.
- [X] T013 [US3] Add a “Header Policy Matrix” section to `README.md` summarizing which directives apply to HTML, static assets, and downloads per subdomain (production vs preview) and linking to the `_headers` files.
- [ ] T014 [US3] Annotate each `_headers` file with inline comments explaining how to extend CSP allowlists or add new patterns so future updates stay consistent.
- [ ] T015 [US3] Enhance `.github/workflows/21-DEV.yml`, `DOCS-21-DEV.yml`, and `MD-21-DEV.yml` to emit structured logs summarizing which `_headers` patterns were applied (JSON payload with pattern + headers) after the copy step.
- [ ] T016 [US3] Add automated smoke-test steps to each deployment workflow that run `curl -I` against representative URLs (one HTML + one asset + one download) and fail the workflow if required headers are missing.

**Checkpoint**: Operators can verify and extend `_headers` without additional tooling.

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Final validation and documentation tidy-up.

- [ ] T015 [P] Re-run the curl-based validation matrix across all subdomains after deployment and attach results to the PR description.
- [ ] T016 Document the new `_headers` baseline in `specs/002-cloudflare-headers/spec.md` “Notes” section (or appendix) to reflect the shipped scope versus future CLI work.
- [ ] T017 [P] Update feature spec/plan references once Phase 2 utilities CLI replaces manual steps, keeping documents in sync.

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup** → **Foundational** → **User Story phases** → **Polish**
- Foundational tasks block all user stories because `_headers` must deploy correctly before content changes matter.

### User Story Dependencies
- **US1 (Security)** must ship first (MVP) before caching or operational work.
- **US2 (Caching)** depends on US1 completion for the same files.
- **US3 (Operational)** depends on US1/US2 so documentation reflects final headers.

### Parallel Opportunities
- Tasks T001 and T002 can run in parallel.
- T004 and T005 modify different workflow files and can run concurrently after T003.
- Within US2, T010 can run in parallel with T009/T011 because it touches different path blocks.
- Polish tasks T015–T016 can run concurrently once all stories complete.

## Implementation Strategy

### MVP First (User Story 1 Only)
1. Complete Setup + Foundational phases (T001–T005).
2. Implement US1 tasks (T006–T008).
3. Deploy and validate headers with curl/securityheaders to confirm MVP.

### Incremental Delivery
1. After MVP, layer on caching rules (US2) without modifying security directives.
2. Finally, improve documentation/operational clarity (US3).
3. CLI-driven automation remains out of scope and moves to Phase 2 roadmap.
