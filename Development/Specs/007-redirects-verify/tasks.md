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

- [x] T002 `_redirects` parser — `source target status` columns,
  comments, `*` splat sources, `:placeholder` targets (FR-001).
  **Shipped on `main` via 006's `util links check` (#86)** —
  `Sources/UtilLib/Links/RedirectRule.swift` provides `RedirectsParser`
  and `RedirectMatcher`; its edge-semantics machinery backs the
  verifier's dedicated refusal reason (T004 — narrower than the
  checker's `isAppliedByEdge` exemption flag, which also refuses
  edge-served SPA shells). This feature consumes it as-is; nothing to
  build. · `Sources/UtilLib/Links/`
- [x] T003 Parser unit tests — every field shape in both sites' real
  `_redirects` files: literal, splat, placeholder, absolute external
  target, 200-rewrite — `verifies FR-001`. Shipped with the parser in
  `InternalLinkCheckerTests` (`redirectsParsing`,
  `malformedLinesDropped`, `realSiteFiles`, `redirectsMatching`, plus
  splat/placeholder/classification cases — `realSiteFiles` loads both
  real files verbatim) · `Tests/UtilLibTests/Links/`

**Checkpoint:** satisfied — parser tests are green; both real
`_redirects` files parse with zero errors.

## Phase 2 — The verifier

- [ ] T004 `RedirectsVerifier` — rules the edge ignores (unsupported
  status, uncompilable source, self-referencing target — a dedicated
  refusal reason, not `isAppliedByEdge` verbatim) fail with the named
  refusal before any request (FR-005); fetch `base-url + source`,
  assert status and (for 3xx) `Location` verbatim (FR-002); fixed
  probe-token substitution for 3xx wildcard rules (FR-003); non-3xx
  wildcard rules probed through a real target that exists under the
  deployed output root (`Websites/<site>/`, or the `--file` parent)
  when the probed source path isn't itself a deployed asset, else
  reported skipped with reason (FR-004); HEAD with GET fallback,
  per-request timeout (FR-006). Transport injected so tests need no
  server. · `Sources/UtilLib/Redirects/`
- [ ] T005 Verifier unit tests — stubbed transport covering pass,
  wrong-status, wrong-`Location`, probe expansion, edge-refused
  failures, real-target rewrite probes, skip reporting —
  `verifies FR-002..FR-006` · `Tests/UtilLibTests/Redirects/`

**Checkpoint:** stubbed-transport suite green; no network anywhere.

## Phase 3 — The command

- [ ] T006 `util redirects verify --site <site> --base-url <url>` —
  site reads rules from `Resources/<site>/_redirects` after `SiteName`
  validation and real-target existence from `Websites/<site>/`;
  `--file <path>` accepts an explicit `_redirects` file (existence
  under its parent directory) — mutually exclusive, one required
  (`search-console`'s `--site`/`--sitemap-url` precedent); per-rule
  pass/fail/skip reporting; non-zero exit on failure (FR-005, FR-007) ·
  `Sources/util/Commands/RedirectsCommand.swift`
- [ ] T007 CLI integration tests — argument validation (exclusivity,
  unknown site), clean-fixture exit 0, failing-fixture exit non-zero
  naming the rule — fixtures via `--file`, base-url on loopback —
  `verifies FR-005, FR-007` · `Tests/UtilIntegrationTests/`

**Checkpoint:** the command verifies a recorded fixture of both sites'
rules.

## Phase 4 — The gate

- [ ] T008 Replace the two "Verify redirects" curl blocks with the
  `util` invocation — no literal URL or status code remains in the
  workflow (SC-001, SC-002) · `.github/workflows/deploy-cloudflare.yml`

**Checkpoint (owner: maintainer):** a real preview deploy runs
`util redirects verify` and verifies every rule in under a minute
(SC-003) — the plan's single remaining `## Tasks` item.
