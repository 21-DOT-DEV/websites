---
feature: 004
title: UtilLib library and util CLI executable for CI utilities
phase: "2 · Utilities Library Refactoring"
status: Implemented
updated: 2026-11-02
adrs: [4, 5]
---

# UtilLib library and util CLI executable for CI utilities

## Goal

Move CI/CD logic out of inline workflow shell scripts into type-safe,
testable Swift: a `UtilLib` library target plus a thin `util` executable that
workflows invoke via `swift run util <subcommand>`.

## Approach

- `Sources/UtilLib/` holds the logic — sitemap generation/submission,
  `_headers`/`_redirects` generation, canonical-URL checking, state-file
  management — as a plain library with unit tests.
- `Sources/util/` is the thin executable wrapper exposing each capability as
  a subcommand (`sitemap`, `headers`, `canonical`, `comment`,
  `search-console`, `agent-directive`, `links`).
- Deploy and documentation workflows replaced their embedded scripts with
  `swift run util ...` calls; local runs use the same commands.
- This consolidation merged two predecessor efforts — the Utilities library
  extraction and the util-executable workflow migration — which is why the
  folder spans the whole CLI surface.

## Companions

- `contracts/cli-interface.md` — the subcommand contract.
- `contracts/TestHarness.md` — the test-harness contract for `util`.
- `contracts/comment-interface.md` — the `util comment` PR-comment contract.
- `data-model.md` — the UtilLib data model.
- `quickstart.md` — how to run and validate the CLI.
- `util-architecture.md` — the library+executable pattern, carried from the
  former rules docs.

## Verification

- `swift run util --help` lists the subcommand surface.
- `generate-docc`, markdown, and `deploy-cloudflare` workflows invoke `util`
  steps; see the workflow files for the call sites.
- `contracts/TestHarness.md` defines how `util` is exercised in tests.
