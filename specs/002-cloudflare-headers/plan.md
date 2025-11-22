# Implementation Plan: Cloudflare _headers Optimization

**Branch**: `002-cloudflare-headers` | **Date**: 2025-11-21 | **Spec**: [/specs/002-cloudflare-headers/spec.md](spec.md)
**Input**: Feature specification from `/specs/002-cloudflare-headers/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Deliver a unified Cloudflare `_headers` strategy for 21.dev, docs.21.dev, and md.21.dev that applies a production-grade security header baseline, tiered caching directives, and CI/CD enforcement to keep responses fast and safe. The plan leverages Swift-based build tooling plus GitHub Actions to copy per-site `_headers`, validate their contents, and run smoke tests (curl/securityheaders.com) after deployment while emitting observability metrics. Advanced automation (HeadersValidator CLI, env-aware scaffolding) is explicitly deferred to Phase 2 “Utilities Library Refactoring.”

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Swift 6.1 with Slipstream build targets  
**Primary Dependencies**: Slipstream v2, swift-plugin-tailwindcss, swift-testing, GitHub Actions, Cloudflare Pages  
**Storage**: N/A (static files in `Resources/<Site>` and `_headers` text files)  
**Testing**: swift-testing for unit/integration; curl + securityheaders.com smoke checks in CI  
**Target Platform**: Static sites deployed to Cloudflare Pages (21.dev, docs.21.dev, md.21.dev)  
**Project Type**: Multi-site static web monorepo  
**Performance Goals**: ≥80% cache-hit ratio, P75 LCP <1s, P90 LCP <1.5s, zero missing security headers  
**Constraints**: No new runtime dependencies, headers must be version-controlled, preview builds must disable HSTS, automation must run within existing GitHub Actions minutes  
**Scale/Scope**: Three subdomains, dozens of assets/routes per site, executed across all production deployments

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Static-First Architecture | ✅ | Work confined to static headers + build tooling; no runtime services introduced. |
| II. Spec-First & TDD | ✅ | Spec + clarification completed prior to planning; future header-copy helpers will be test-driven (swift-testing). |
| III. Accessibility & Performance | ✅ | Feature explicitly targets performance/security metrics; no regressions expected. |
| IV. Design System Consistency | ✅ | No component work; headers remain site-agnostic. |
| V. Zero-Dependency Philosophy | ✅ | Reuses existing Swift + Actions stack; no new external packages beyond optional curl-based scanners already available. |
| VI. Security & Privacy | ✅ | Adds required security headers; aligns with OWASP guidance. |
| VII. Open Source Excellence | ✅ | Plan produces documentation (plan, research, quickstart) and codifies tooling for future contributors. |

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
Sources/
├── 21-dev/
│   ├── Pages/
│   └── SiteGenerator.swift          # Copies Resources/21-dev/_headers today
├── DesignSystem/
└── ... (docs/md targets share structure)

Resources/
├── 21-dev/
│   ├── _headers                     # Existing baseline to expand
│   └── static/
├── docs-21-dev/
│   └── _headers (to be created)
├── md-21-dev/
│   └── _headers (to be created)

.github/workflows/
├── 21-DEV.yml                       # Main Slipstream deploy pipeline
├── DOCS-21-DEV.yml                  # DocC build/deploy
├── MD-21-DEV.yml                    # Markdown export/deploy

Tests/
├── IntegrationTests/
│   ├── Site21DevTests.swift
│   └── ... (extend with header validation helpers)
└── DesignSystemTests/

specs/002-cloudflare-headers/
├── plan.md
├── research.md (Phase 0 output)
├── data-model.md
├── quickstart.md
└── contracts/
```

**Structure Decision**: Use existing multi-site Swift Package layout. `_headers` live under each `Resources/<site>` directory and are copied via `SiteGenerator.swift` or equivalent resource-copy steps per site. GitHub Actions workflows orchestrate validation + deployment; tests remain under `Tests/IntegrationTests/` for smoke validations.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
