# Tasks — 006 · Internal link checking for generated HTML output

Ordered work for [the plan](./plan.md); requirements cited as `FR-NNN`
from [spec.md](./spec.md); rationale in [research.md](./research.md).

## Phase 0 — The spec itself

- [x] T001 This spec and the regenerated specs index ·
  `Development/Specs/006-internal-link-check/{plan,spec,research,tasks}.md`,
  `Development/Specs/README.md`

**Checkpoint:** `swift run --package-path Development/Tools plans --check`
is green; the index lists feature 006.

## Phase 1 — The implementation, restored

The implementation was written and green before this spec existed; it
lives uncommitted in the `UPDATED-STUFF` git stash. Restore, don't
reimplement — `git checkout "stash@{0}^3" -- <paths>` for the new files,
`git checkout stash@{0} -- <paths>` for the modified ones. If the stash
is gone, reimplement per [spec.md](spec.md) — FR-001..008 describe the
same behavior.

- [ ] T002 Restore `Sources/UtilLib/Links/` — `ExtractedLink.swift`,
  `BrokenLink.swift`, `LinkCheckReport.swift`, `InternalLinkChecker.swift`,
  `RedirectRule.swift` (the shared `_redirects` parser — **lands here,
  and 007 reuses it**; if 007's code ships first, this file comes from
  that PR instead) — covers FR-001..FR-006 · `Sources/UtilLib/Links/`
- [ ] T003 Restore the `check` subcommand (FR-007, FR-008) ·
  `Sources/util/Commands/LinksCommand.swift`
- [ ] T004 Restore the test suites — `verifies FR-001..FR-008` ·
  `Tests/UtilLibTests/Links/InternalLinkCheckerTests.swift`,
  `Tests/UtilIntegrationTests/LinksCheckCLITests.swift`

**Checkpoint:** `swift build` and `swift test` pass;
`swift run util links check --path Websites/<site>` exits 0 on real
generated output for all three sites.

## Phase 2 — The gate

- [ ] T005 Restore the two post-generation workflow steps that run the
  check (SC-001) · `.github/workflows/build-slipstream.yml`,
  `.github/workflows/generate-docc.yml`

**Checkpoint (owner: maintainer):** a real `build-slipstream` and
`generate-docc` run executes `util links check` and goes green —
the only step that can't be proven without a live CI run. This is the
plan's single remaining `## Tasks` item.
