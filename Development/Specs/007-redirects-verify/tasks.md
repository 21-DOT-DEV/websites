# Tasks — 007 · Verify _redirects rules against deployed URLs

Ordered work for [the plan](./plan.md); requirements cited as `FR-NNN`
from [spec.md](./spec.md); rationale in [research.md](./research.md).

## Phase 0 — The spec itself

- [x] T001 This spec and the regenerated specs index ·
  `Development/Specs/007-redirects-verify/{plan,spec,research,tasks}.md`,
  `Development/Specs/README.md`

**Checkpoint:** `swift run --package-path Development/Tools plans --check`
is green; the index lists feature 007.

## Phase 1 — The parser

- [ ] T002 `_redirects` parser — `source target status` columns,
  comments, `*` splat sources, `:placeholder` targets (FR-001).
  **`RedirectRule.swift` already exists in the `UPDATED-STUFF` stash**
  under `Sources/UtilLib/Links/` — if 006's code lands first it is
  already on `main`; otherwise restore it here (`git checkout
  "stash@{0}^3" -- Sources/UtilLib/Links/RedirectRule.swift`). Whichever
  PR ships first carries it; the other reuses. ·
  `Sources/UtilLib/Redirects/` or `Sources/UtilLib/Links/`
- [ ] T003 Parser unit tests — every field shape in both sites' real
  `_redirects` files: literal, splat, placeholder, absolute external
  target, 200-rewrite — `verifies FR-001` ·
  `Tests/UtilLibTests/Redirects/`

**Checkpoint:** parser tests green; both real `_redirects` files parse
with zero errors.

## Phase 2 — The verifier

- [ ] T004 `RedirectsVerifier` — fetch `base-url + source`, assert
  status and (for 3xx) `Location` after normalization (FR-002); fixed
  probe-token substitution for 3xx wildcard rules (FR-003); non-3xx
  wildcard rules reported skipped with reason (FR-004); HEAD with GET
  fallback, per-request timeout (FR-006). Transport injected so tests
  need no server. · `Sources/UtilLib/Redirects/`
- [ ] T005 Verifier unit tests — stubbed transport covering pass,
  wrong-status, wrong-`Location`, probe expansion, skip reporting —
  `verifies FR-002..FR-004, FR-006` · `Tests/UtilLibTests/Redirects/`

**Checkpoint:** stubbed-transport suite green; no network anywhere.

## Phase 3 — The command

- [ ] T006 `util redirects verify --site <site> --base-url <url>` —
  site resolves to `Resources/<site>/_redirects`; per-rule pass/fail/
  skip reporting; non-zero exit on failure (FR-005, FR-007) ·
  `Sources/util/Commands/RedirectsCommand.swift`
- [ ] T007 CLI integration tests — argument validation, clean-fixture
  exit 0, failing-fixture exit non-zero naming the rule — `verifies
  FR-005, FR-007` · `Tests/UtilIntegrationTests/`

**Checkpoint:** the command verifies a recorded fixture of both sites'
rules.

## Phase 4 — The gate

- [ ] T008 Replace the two "Verify redirects" curl blocks with the
  `util` invocation — no literal URL or status code remains in the
  workflow (SC-001, SC-002) · `.github/workflows/deploy-cloudflare.yml`

**Checkpoint (owner: maintainer):** a real preview deploy runs
`util redirects verify` and verifies every rule in under a minute
(SC-003) — the plan's single remaining `## Tasks` item.
