# Implementation Plan: Cloudflare _redirects Implementation

**Branch**: `003-cloudflare-redirects` | **Date**: 2025-12-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-cloudflare-redirects/spec.md`

## Summary

Implement Cloudflare `_redirects` files for docs.21.dev and md.21.dev subdomains to handle URL redirects at the edge. Files stored in `Resources/<SiteName>/`, copied to output during CI workflow, with automated post-deployment smoke tests verifying 301 responses.

## Technical Context

**Language/Version**: N/A (configuration files only, bash for workflow steps)  
**Primary Dependencies**: Existing GitHub Actions workflows, Cloudflare Pages  
**Storage**: N/A  
**Testing**: curl-based smoke tests in CI (IaC exemption applies)  
**Target Platform**: Cloudflare Pages edge network  
**Project Type**: Infrastructure/configuration  
**Performance Goals**: < 10ms redirect execution at edge  
**Constraints**: Cloudflare `_redirects` syntax, 2000 rule limit  
**Scale/Scope**: 4 redirect rules across 2 subdomains initially, scalable to 50+

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Static-First Architecture | ✅ PASS | `_redirects` are static config files, no runtime |
| II. Spec-First & TDD | ✅ PASS | Spec complete; IaC exemption applies (workflow config validated via execution) |
| III. Accessibility & Performance | ✅ PASS | Redirects improve UX by guiding users to correct URLs |
| IV. Design System Consistency | ✅ N/A | No UI components involved |
| V. Zero-Dependency Philosophy | ✅ PASS | No new dependencies; uses existing Cloudflare Pages + GitHub Actions |
| VI. Security & Privacy | ✅ PASS | 301 redirects are standard HTTP; no data collection |
| VII. Open Source Excellence | ✅ PASS | Config files documented with inline comments |

**Gate Result**: PASSED — No violations. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/003-cloudflare-redirects/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── research.md          # Phase 0 output (minimal - config-only feature)
├── quickstart.md        # Phase 1 output (implementation guide)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

**Note**: `data-model.md` and `contracts/` skipped — not applicable for configuration-only feature.

### Source Code (repository root)

```text
Resources/
├── docs-21-dev/
│   └── _redirects       # NEW: docs.21.dev redirect rules
└── md-21-dev/
    └── _redirects       # NEW: md.21.dev redirect rules

.github/workflows/
├── generate-docc.yml    # MODIFY: add _redirects copy + smoke test
└── generate-markdown.yml # MODIFY: add _redirects copy + smoke test
```

**Structure Decision**: Configuration-only feature. New `_redirects` files in existing `Resources/<SiteName>/` directories. Workflow modifications follow existing `_headers` pattern (cp command + post-deploy verification).

## Planning Decisions

Captured from pre-planning clarification:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Skip data-model.md/contracts/ | Yes | Config-only feature, no data entities or APIs |
| Smoke test location | Existing deploy workflows | Matches IaC exemption; runs in natural deployment context |
| File copy mechanism | `cp` in GitHub Actions | Matches existing `_headers` pattern, no Swift changes needed |
