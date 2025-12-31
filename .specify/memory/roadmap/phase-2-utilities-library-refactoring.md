# Phase 2 — Utilities Library Refactoring

**Status:** In Progress
**Priority:** High (Next Priority)
**Last Updated:** 2025-12-29

## Phase Goal

Extract sitemap utilities and reusable workflow logic into a dedicated `Utilities` library and CLI, following the library + executable pattern, to reduce duplication and enable type-safe CI/CD tooling.

## Progress Summary

| Feature | Status | Progress |
|---------|--------|----------|
| Feature 1 — Utilities Library Extraction | ✅ Complete | 100% |
| Feature 2 — Workflow Migration | 🚧 In Progress | 4/9 commands |
| Feature 3 — Canonical URL Management | ✅ Complete | 100% |
| Feature 4 — Architecture Alignment | ❌ Not Started | 0% |

---

## Features

### Feature 1 — Utilities Library Extraction ✅
- **Status:** Complete
- **Purpose & user value:** Extract sitemap utilities and reusable workflow logic from DesignSystem into a dedicated `Utilities` library target, following industry-standard library + executable pattern, reducing code duplication across workflows and enabling type-safe CLI tooling for CI/CD automation.
- **Completed:**
  - ✅ `Utilities` library target created in Package.swift with all sitemap utilities migrated
  - ✅ `util` CLI executable provides type-safe commands for sitemap generation, state management, URL validation
  - ✅ HeadersValidator CLI and environment-aware `_headers` generation commands ship inside `util`
  - ✅ Type-safe sitemap models with compile-time validation
  - ✅ Unified lastmod tracking logic (git, package version, fallback) across all subdomain types
  - ✅ Single Swift executable generates sitemaps for all subdomain types (21.dev, docs, md)
  - ✅ 100% test coverage maintained for migrated utilities (18+ existing tests pass)
  - ✅ Sitemap generation runs in < 2 seconds for all subdomains combined
  - ✅ Build time remains under 2 minutes (no performance regression)
- **Dependencies:** Phase 1 — Sitemap Infrastructure Overhaul (utilities exist to extract).
- **Notes:** Extracted from 001-sitemap-infrastructure T057. Follows subtree pattern (library + executable).

### Feature 2 — Workflow Migration to Utilities CLI 🚧
- **Status:** In Progress (4/9 commands implemented)
- **Purpose & user value:** Replace inline bash scripts in workflows with type-safe `swift run util` commands, providing consistent error handling, better debugging, and reduced maintenance burden through centralized logic.
- **Implemented:**
  - ✅ `util sitemap generate --site docs-21-dev` (generate-docc.yml migrated)
  - ✅ `util sitemap generate --site md-21-dev` (generate-markdown.yml migrated)
  - ✅ `util headers validate --site <site> --env <env>`
  - ✅ `util state validate` and `util state update`
- **Remaining:**
  - *Sitemap:*
    - ❌ `util sitemap submit --site <site>` — submit sitemap to Google/Bing
  - *Validation:*
    - ❌ `util redirects verify --site <site>` — verify redirect rules
    - ❌ `util headers select --site <site> --env <env>` — environment-specific header selection
    - ❌ `util build verify --site <site>` — verify build output
  - *Infrastructure:*
    - ❌ Pre-built release binary via git LFS — avoids rebuilding util on every CI run
- **Deferred:**
  - ⏸️ `util headers scaffold` — not needed for current workflows
- **Quality gates:**
  - All workflow changes maintain 100% backward compatibility (no deployment disruption)
  - CI build times remain under current baseline (< 5 min total)
  - Zero production incidents during migration
- **Dependencies:** Utilities Library Extraction (library must exist first).
- **Notes:** Gradual migration strategy: one workflow at a time with rollback capability. Bash remains for simple operations (file copying, directory creation).

### Feature 3 — Canonical URL Management ✅
- **Status:** Complete
- **Purpose & user value:** Provide type-safe CLI tooling to check and fix canonical URL `<link rel="canonical">` tags across all generated HTML output, ensuring proper SEO and preventing duplicate content issues across subdomains.
- **Completed:**
  - ✅ `util canonical check --path <dir> --base-url <url>` — reports missing, valid, and mismatched canonicals
  - ✅ `util canonical fix --path <dir> --base-url <url>` — adds missing canonicals (skips mismatches by default)
  - ✅ `util canonical fix --force` — overwrites all canonicals to match derived URLs
  - ✅ Works site-agnostically on any HTML output directory (21.dev, docs.21.dev, md.21.dev)
  - ✅ Canonical URL derived from `base-url + relative path` (normalizes `index.html` → `/`)
  - ✅ Check mode outputs three categories: ✅ Valid, ⚠️ Mismatch (shows both URLs), ❌ Missing
  - ✅ CI integration: exit code 1 when canonicals are missing (fails builds)
  - ✅ Processes 1000+ HTML files in < 2 seconds (exceeds 5s requirement)
  - ✅ Integrated into `generate-docc.yml` workflow for docs.21.dev
- **Dependencies:** Utilities Library Extraction (library must exist first).
- **Notes:** Post-generation injection approach works for all subdomains including DocC-generated docs.21.dev. Two-mode design (check/fix) follows industry best practice for safe automation.

### Feature 4 — Architecture Alignment ❌
- **Status:** Not Started
- **Purpose & user value:** Align the `util` CLI architecture with industry-standard library + executable pattern, improving testability by separating unit tests (library internals) from integration tests (black-box CLI execution).
- **Planned changes:**
  - Rename `Utilities` → `UtilLib` (library containing all business logic)
  - Rename `UtilitiesTests` → `UtilLibTests` (unit tests with `@testable import`)
  - Rename `UtilitiesCLITests` → `UtilIntegrationTests` (black-box CLI tests)
  - Remove `UtilLib` dependency from `UtilIntegrationTests` (tests only via `Subprocess`)
  - Add `TestHarness` to `UtilIntegrationTests` for CLI execution and output capture
- **Success criteria:**
  - `UtilLibTests` tests library internals via `@testable import UtilLib`
  - `UtilIntegrationTests` has zero dependency on `UtilLib` (pure black-box testing)
  - `TestHarness` provides CLI execution with stdout/stderr/exit code capture
  - All existing tests continue to pass after migration
  - Clear separation: unit tests for logic, integration tests for CLI behavior
- **Dependencies:** Utilities Library Extraction (library must exist first).
- **Notes:** Follows industry-standard CLI testing pattern (library + executable with separate test layers). `TestUtils` remains for DesignSystem HTML rendering tests; `UtilIntegrationTests` uses its own inline `TestHarness`.

## Phase Dependencies & Sequencing

- **Upstream dependency:** Phase 1 — Sitemap Infrastructure Overhaul (utilities must exist before extraction).
- **Internal sequencing:**
  1. ✅ Utilities Library Extraction → 2. 🚧 Workflow Migration → 3. ✅ Canonical URL Management → 4. ❌ Architecture Alignment

## Phase Metrics

This phase primarily contributes to product-level metrics for **Infrastructure**, **Performance**, and **Build Reliability**, especially:
- Zero manual intervention required for sitemap submissions.
- Sitemap generation runs efficiently as part of CI.
- CI build times remain under 5 minutes.
- Zero deployment failures caused by workflow scripting errors after migration.

## Backlog (Future Enhancements)

- **Full Sitemap Protocol Support**: Add optional `<changefreq>` and `<priority>` elements to sitemap generation via CLI flags (e.g., `--include-changefreq`, `--include-priority`). Currently deferred as Google ignores these fields.
