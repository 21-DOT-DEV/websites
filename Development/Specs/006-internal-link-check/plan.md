---
feature: 006
title: Internal link checking for generated HTML output
phase: 3 · Performance & Delivery Optimization
status: In Progress
updated: 2026-11-04
adrs: [0004, 0005]
---

# Internal link checking for generated HTML output

## Goal

`util links check` fails the build when generated HTML references an
internal path that doesn't exist in the site output — pages, images,
stylesheets, and scripts. Broken internal links become commit-blockers
instead of production 404s, matching the Docusaurus
`onBrokenLinks: 'throw'` default and the DocC warnings-as-errors model.
Requirements and observable behavior: [spec.md](spec.md); evidence and
rejected alternatives: [research.md](research.md); ordered work:
[tasks.md](tasks.md).

## Approach

1. `InternalLinkChecker` in `Sources/UtilLib/Links/` walks a site output
   directory via `HTMLFileWalker` (FR-001), extracts `href`/`src`/`srcset`
   values with SwiftSoup (FR-002), and resolves each internal reference
   against the output on disk — no HTTP involved.
2. Resolution covers the Cloudflare Pages serving forms: exact file,
   `path/index.html` (directory index), and `path.html`; percent-decoded
   paths; query strings and fragments stripped; relative references
   resolve against the containing directory (FR-003, FR-004).
3. The checker parses `_redirects` at the output root and treats links
   matching a redirect rule's source (including `*` splats) as valid —
   they resolve at the edge, not on disk (FR-005).
4. Skipped by design: `https?://` and protocol-relative URLs, `mailto:`,
   `tel:`, `data:`, `javascript:`, fragment-only (`#x`) references, and
   fragment existence checks (FR-006).
5. `util links check --path <dir>` reports each broken link with its
   source file and exits non-zero on any failure; `--verbose` lists
   every checked reference (FR-007, FR-008).
6. Wire into `build-slipstream.yml` and `generate-docc.yml` after site
   generation, beside the existing `util canonical` / `util links
   rewrite` / `util agent-directive` steps (SC-001).

## Verification

- `nocorrect swift build` and `nocorrect swift test --filter UtilLibTests`
- `nocorrect swift run util links check --path Websites/21-dev` → clean
  (SC-002, SC-003)
- `nocorrect swift run util links check --path Websites/docs-21-dev` →
  clean (SC-002, SC-003)
- Fixture directory with a deliberately broken link exits non-zero and
  names the source file + href (FR-007).
- SC-001 (both workflows run the check) verifies on a live CI run —
  the maintainer checkpoint in [tasks.md](tasks.md).

## Test summary

Adds unit coverage for resolution variants (exact file, directory index,
`.html` fallback), skip rules (external, mailto, fragment-only),
redirect-source exemption (exact and splat), `srcset` parsing, and
report aggregation.

## Tasks

- [ ] CI wiring verified on a real `build-slipstream` run — owner:
  maintainer; exit: workflow step runs `util links check` and passes
  (`.github/workflows/build-slipstream.yml`).
