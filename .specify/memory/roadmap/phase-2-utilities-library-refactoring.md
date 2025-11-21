# Phase 2 — Utilities Library Refactoring

**Status:** Not Started
**Priority:** High (Next Priority)
**Last Updated:** 2025-11-20

## Phase Goal

Extract sitemap utilities and reusable workflow logic into a dedicated `Utilities` library and CLI, following the library + executable pattern, to reduce duplication and enable type-safe CI/CD tooling.

## Features

### Feature 1 — Utilities Library Extraction
- **Name:** Utilities Library Extraction
- **Purpose & user value:** Extract sitemap utilities and reusable workflow logic from DesignSystem into a dedicated `Utilities` library target, following industry-standard library + executable pattern, reducing code duplication across workflows and enabling type-safe CLI tooling for CI/CD automation.
- **Success metrics:**
  - `Utilities` library target created in Package.swift with all sitemap utilities migrated
  - `util` CLI executable provides type-safe commands for sitemap generation, state management, URL validation
  - Type-safe sitemap models with compile-time validation
  - Unified lastmod tracking logic (git, package version, fallback) across all subdomain types
  - Single Swift executable generates sitemaps for all subdomain types (21.dev, docs, md)
  - Zero code duplication across GitHub Actions workflows (generate-docc.yml, generate-markdown.yml, deploy-cloudflare.yml)
  - All workflow bash scripts replaced with `swift run util` commands for better error handling
  - 100% test coverage maintained for migrated utilities (18+ existing tests pass)
  - Sitemap generation runs in < 2 seconds for all subdomains combined
  - Build time remains under 2 minutes (no performance regression)
- **Dependencies:** Phase 1 — Sitemap Infrastructure Overhaul (utilities exist to extract).
- **Notes:** Extracted from 001-sitemap-infrastructure T057. Follows subtree pattern (library + executable). Consolidates bash duplication with type-safe Swift CLI.

### Feature 2 — Workflow Migration to Utilities CLI
- **Name:** Workflow Migration to Utilities CLI
- **Purpose & user value:** Replace inline bash scripts in workflows with type-safe `swift run util` commands, providing consistent error handling, better debugging, and reduced maintenance burden through centralized logic.
- **Success metrics:**
  - generate-docc.yml migrates sitemap generation to `util generate-sitemap --docs`
  - generate-markdown.yml migrates sitemap generation to `util generate-sitemap --markdown`
  - State file management migrates to `util state-file validate|update`
  - All workflow changes maintain 100% backward compatibility (no deployment disruption)
  - CI build times remain under current baseline (< 5 min total)
  - Zero production incidents during migration
- **Dependencies:** Utilities Library Extraction (library must exist first).
- **Notes:** Gradual migration strategy: one workflow at a time with rollback capability. Bash remains for simple operations (file copying, directory creation).

## Phase Dependencies & Sequencing

- **Upstream dependency:** Phase 1 — Sitemap Infrastructure Overhaul (utilities must exist before extraction).
- **Internal sequencing:**
  1. Utilities Library Extraction → 2. Workflow Migration to Utilities CLI.

## Phase Metrics

This phase primarily contributes to product-level metrics for **Infrastructure**, **Performance**, and **Build Reliability**, especially:
- Zero manual intervention required for sitemap submissions.
- Sitemap generation runs efficiently as part of CI.
- CI build times remain under 5 minutes.
- Zero deployment failures caused by workflow scripting errors after migration.
