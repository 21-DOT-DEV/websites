# Phase 2 — Utilities Library Refactoring

**Status:** In Progress
**Priority:** High (Next Priority)
**Last Updated:** 2026-11-04

## Phase Goal

Extract sitemap utilities and reusable workflow logic into a dedicated `Utilities` library and CLI, following the library + executable pattern, to reduce duplication and enable type-safe CI/CD tooling.

## Progress Summary

| Feature | Status | Progress |
|---------|--------|----------|
| Feature 1 — Utilities Library Extraction | ✅ Complete | 100% |
| Feature 2 — Workflow Migration | 🚧 In Progress | 7 commands shipped; `redirects verify` scoped (Specs/007) |
| Feature 3 — Canonical URL Management | ✅ Complete | 100% |
| Feature 4 — Architecture Alignment | ✅ Complete | 100% |

---

## Features

### Feature 1 — Utilities Library Extraction ✅
- **Status:** Complete
- **Purpose & user value:** Extract sitemap utilities and reusable workflow logic from DesignSystem into a dedicated `Utilities` library target, following industry-standard library + executable pattern, reducing code duplication across workflows and enabling type-safe CLI tooling for CI/CD automation.
- **Completed:**
  - ✅ `Utilities` library target created in Package.swift with all sitemap utilities migrated
  - ✅ `util` CLI executable provides type-safe commands for sitemap generation and URL validation
  - ✅ HeadersValidator CLI and environment-aware `_headers` generation commands ship inside `util`
  - ✅ Type-safe sitemap models with compile-time validation
  - ✅ Lastmod tracking via git commit date (`.gitCommitDate`) for 21.dev; explicit `<lastmod>` omission (`.none`) for docs.21.dev aggregated content
  - ✅ Single Swift executable generates sitemaps for all subdomain types (21.dev, docs)
  - ✅ 100% test coverage maintained for migrated utilities (18+ existing tests pass)
  - ✅ Sitemap generation runs in < 2 seconds for all subdomains combined
  - ✅ Build time remains under 2 minutes (no performance regression)
- **Dependencies:** Phase 1 — Sitemap Infrastructure Overhaul (utilities exist to extract).
- **Notes:** Extracted from 001-sitemap-infrastructure T057. Follows subtree pattern (library + executable).

### Feature 2 — Workflow Migration to Utilities CLI 🚧
- **Status:** In Progress (one scoped command remaining)
- **Purpose & user value:** Replace inline bash scripts in workflows with type-safe `swift run util` commands, providing consistent error handling, better debugging, and reduced maintenance burden through centralized logic.
- **Implemented:**
  - ✅ `util sitemap generate --site <site>` (generate-docc.yml)
  - ✅ `util headers validate --site <site> --env <env>`
  - ✅ `util canonical check|fix` (generate-docc.yml)
  - ✅ `util links rewrite` (generate-docc.yml)
  - ✅ `util agent-directive inject|audit` (generate-docc.yml)
  - ✅ `util search-console submit --site <site>` (deploy-cloudflare.yml — covers the former `sitemap submit` item)
  - ✅ `util comment` (deploy-cloudflare.yml PR comments)
- **Retired:**
  - 🗑️ `util state validate` and `util state update` — retired alongside the removal of `Resources/sitemap-state.json` and the lefthook post-checkout automation. The state file was never read by sitemap generation (the `.packageVersionState` strategy was a stub that fell through to `Date()`). docs.21.dev now emits sitemap entries without `<lastmod>` via the `.none` strategy; a future reintroduction (if warranted) should use content-hashing or a git commit date anchored to `Resources/docs-21-dev/external-archives.json`.
- **Remaining:**
  - ❌ `util redirects verify --site <site>` — parse `_redirects` and verify each rule against a deployed URL. Scoped in Specs/007; replaces the hardcoded curl list in `deploy-cloudflare.yml` so new redirect rules can't ship unverified.
- **Decisions (won't be commands):**
  - `util headers select` — stays as inline bash. Selecting `_headers.<env>` is file copying with a branch conditional, inside this feature's own carve-out ("bash remains for simple operations"); the only real cost is ~10 duplicated lines across two workflows.
  - `util build verify` — folded into Phase 3 Feature 8 (Performance Budgets); output verification is the same concern as size-budget enforcement.
  - Pre-built release binary via git LFS — deferred; CI build times remain acceptable.
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

### Feature 4 — Architecture Alignment ✅
- **Status:** Complete
- **Purpose & user value:** Align the `util` CLI architecture with industry-standard library + executable pattern, improving testability by separating unit tests (library internals) from integration tests (black-box CLI execution).
- **Completed:**
  - ✅ `UtilLib` target holds all business logic; `util` is a thin ArgumentParser shell
  - ✅ `UtilLibTests` uses `@testable import UtilLib` for internals
  - ✅ `UtilIntegrationTests` has zero dependency on `UtilLib` — runs the CLI via `Subprocess` only (see `Package.swift`)
- **Dependencies:** Utilities Library Extraction (library must exist first).
- **Notes:** Follows industry-standard CLI testing pattern (library + executable with separate test layers). `TestUtils` remains for DesignSystem HTML rendering tests; `UtilIntegrationTests` uses its own inline `TestHarness`.

## Phase Dependencies & Sequencing

- **Upstream dependency:** Phase 1 — Sitemap Infrastructure Overhaul (utilities must exist before extraction).
- **Internal sequencing:**
  1. ✅ Utilities Library Extraction → 2. 🚧 Workflow Migration → 3. ✅ Canonical URL Management → 4. ✅ Architecture Alignment

## Phase Metrics

This phase primarily contributes to product-level metrics for **Infrastructure**, **Performance**, and **Build Reliability**, especially:
- Zero manual intervention required for sitemap submissions.
- Sitemap generation runs efficiently as part of CI.
- CI build times remain under 5 minutes.
- Zero deployment failures caused by workflow scripting errors after migration.

## Backlog (Future Enhancements)

- **Full Sitemap Protocol Support**: Add optional `<changefreq>` and `<priority>` elements to sitemap generation via CLI flags (e.g., `--include-changefreq`, `--include-priority`). Currently deferred as Google ignores these fields.
