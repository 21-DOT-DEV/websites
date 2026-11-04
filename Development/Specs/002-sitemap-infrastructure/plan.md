---
feature: 002
title: Sitemap generation and automated search-engine submission
phase: "1 · Foundation & Discoverability"
status: Implemented
updated: 2026-11-02
adrs: [4, 6]
---

# Sitemap generation and automated search-engine submission

## Goal

Every subdomain ships a complete, accurate `sitemap.xml` with real `lastmod`
dates, plus matching `robots.txt` and automated submission to Google Search
Console on production deploys — no manual steps.

## Approach

- Sitemap generation lives in `UtilLib`/`util` (`util sitemap generate`),
  run by CI during documentation and markdown deploys rather than inside any
  site target — the same generator covers Slipstream pages, DocC output, and
  co-located markdown.
- `lastmod` values come from git history per page, not build time.
- A `sitemap-state.json` tracks what was submitted so re-submissions are
  incremental, not a full re-ping every deploy.
- Google Search Console credentials are provided through CI secrets; setup
  and monitoring instructions live in this folder's `README.md` (linked from
  the repository `README.md`).

## Companions

- `README.md` — Search Console API credential setup and monitoring.
- `contracts/api-contracts.md` — external submission API surface used.
- `contracts/sitemap-schema.md` — the sitemap document contract.
- `contracts/state-file-schema.md` — the `sitemap-state.json` format.
- `data-model.md` — the sitemap/state model the contracts describe.

## Verification

- `swift run util sitemap generate` regenerates per-site `sitemap.xml`.
- Deploy workflows (`DOCS-21-DEV`, markdown pipeline) run generation and
  submission as steps; production deploys submit automatically.
- `contracts/sitemap-schema.md` defines the canonical output shape.
