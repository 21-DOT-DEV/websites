# Tasks — 009 · Core Web Vitals baseline (synthetic + edge)

Ordered work for [the plan](./plan.md); requirements cited as `FR-NNN` from
[spec.md](./spec.md); rationale in [research.md](./research.md).

Format: `- [ ] TNNN [P?] what lands · files`. Groups are review slices — the
section of diff a reviewer reads in one pass. A draft implementation already
exists as a git stash ("009-cwv-baseline: draft implementation (pending spec
review)"); these tasks decompose it into reviewable chunks, and each slice
lands only after the maintainer reviews the spec. A second stash —
"009-cwv-baseline: convention + guide edits (held for separate commit)" —
holds the four guide edits this spec's conventions depend on (`AGENTS.md`,
`Development/AGENTS.md`, `Development/README.md`, `Development/constitution.md`);
it ships as a separate maintainer commit, not part of this doc set. Reference
stashes by name via `git stash list` — indices shift as new stashes land.
The implementation stash predates two contract corrections — Google keys
travel in the `X-Goog-Api-Key` header
(never `?key=` query params, which can leak into recorded error text) and
the Keychain layer sits behind an injectable seam — and carries known
draft-state compile errors (a `json` flag shadowing, an internal
`readSecretFile` call, an Observatory result shape that predates the
per-form-factor `{metrics, error}` contract); apply all on restore.
Tests ride with their code (red → green per constitution II).

## The spec itself — ships as one coherent doc set

- [x] T001 [P] This spec + companions + regenerated specs index ·
  `Development/Specs/009-cwv-baseline/{plan,spec,research,tasks}.md`,
  `contracts/{api,baseline-schema}.md`, `baseline.{json,md}`,
  `Development/Specs/README.md`
- [x] T002 [P] Convention alignment this spec adopts — `tasks.md` template
  (lands in this doc set); the `Development/AGENTS.md` review-slice rule and
  `constitution.md` §II Design-Diagrams / spec-review-gate edits live in the
  conventions stash named above, held for a separate commit ·
  `Development/Specs/_template/tasks.md`

**Checkpoint:** `swift run --package-path Development/Tools plans --check`
green; spec approved by maintainer. (Doc-set exemption: one coherent
document set lands together — named in the PR description.)

## The artifact model — ~250 authored lines

- [x] T003 [P] Vitals artifact models — `LabMetrics` / `FormFactorResult` /
  `PageLabResult` / `ObservatoryPageResult` / `CruxOriginResult` /
  `EdgeTtfbResult` / `VitalsBaseline` Codable types matching
  `contracts/baseline-schema.md` (FR-006); `null` for failed metrics,
  never zero; both instruments carry per-form-factor `{metrics, error}`
  so a failed call/report is attributable ·
  `Sources/UtilLib/Vitals/Models/` (one file per type)
- [ ] T004 [P] `SitemapPageSet` — `<loc>` extractor for the top-N page
  set (FR-008; same regex approach as `SitemapValidator`) ·
  `Sources/UtilLib/Vitals/SitemapPageSet.swift`
- [ ] T005 Extractor tests — sitemap `<loc>` order and cap (model
  suites landed with T003 under `Tests/UtilLibTests/Vitals/`) ·
  `Tests/UtilLibTests/Vitals/SitemapPageSetTests.swift`

**Checkpoint:** `nocorrect swift test --filter Vitals` green; the committed
`baseline.json` placeholder round-trips through the model.

## The credential store — ~260 authored lines

- [ ] T006 [P] `CredentialStore` — `resolve()` chain explicit-file → env →
  file store → Keychain (FR-005); `~/.config/util/credentials.json` with
  0600 enforced (containing directory 0700) and insecure-permission
  refusal; generic-password
  Keychain CRUD under `#if canImport(Security)`; `notFound` error names
  the provisioning path · `Sources/UtilLib/Vitals/CredentialStore.swift`
- [ ] T007 Store tests — each layer wins over the next, env override
  injection, file permissions refused, malformed file, missing key error
  text (SC-004); the Keychain read sits behind an injectable seam so unit
  tests fake it and prove file-over-Keychain precedence (a manual
  real-Keychain check covers what a fake can't — unsigned `swift run`
  binaries re-prompt, documented) ·
  `Tests/UtilLibTests/Vitals/CredentialStoreTests.swift`

**Checkpoint:** precedence proven layer by layer; no secret ever logged;
non-0600 file refused.

## Cloudflare services — ~285 authored lines

- [ ] T008 `ObservatoryService` — availabilities / start-test / poll
  request builders, test-result and error-envelope parsers, GraphQL
  `httpRequestsAdaptiveGroups` edge-TTFB query + parse with graceful
  `unavailable` on plan-gated fields (FR-001, FR-004) ·
  `Sources/UtilLib/Vitals/ObservatoryService.swift`
- [ ] T009 Service tests — builders emit the wire shapes pinned in
  `contracts/api.md`; parse success / `FAILED` / error-envelope /
  plan-gated fixtures; zero network ·
  `Tests/UtilLibTests/Vitals/ObservatoryServiceTests.swift`

**Checkpoint:** every built request matches `contracts/api.md`; FAILED
tests surface as per-page errors, not thrown failures.

## Google services — ~170 authored lines

- [ ] T010 `PageSpeedService` + `CruxService` — PSI `runPagespeed`
  request/parse (lab audits + score only; `loadingExperience` ignored by
  design) and CrUX `queryRecord` with HTTP 404 → `.insufficient`
  (FR-002, FR-003) · `Sources/UtilLib/Vitals/GoogleVitalsServices.swift`
- [ ] T011 Tests — PSI numeric-value mapping incl. score×100; CrUX
  available / insufficient / error / malformed paths ·
  `Tests/UtilLibTests/Vitals/GoogleVitalsServicesTests.swift`

**Checkpoint:** a 404 CrUX response produces the recorded finding, not an
exception; PSI response maps all seven `LabMetrics` fields.

## The report writer — ~130 authored lines

- [ ] T012 `BaselineReportWriter` — deterministic JSON (sorted keys,
  ISO8601 date) and the `baseline.md` generated-section body below the
  `<!-- GENERATED -->` marker, preserving the maintainer fields above it
  (FR-006, FR-007); pending body when no data ·
  `Sources/UtilLib/Vitals/BaselineReportWriter.swift`
- [ ] T013 Writer tests — deterministic output across runs, populated
  tables, pending body, marker splicing preserves the maintainer top ·
  `Tests/UtilLibTests/Vitals/BaselineReportWriterTests.swift`

**Checkpoint:** rendered output reproduces `contracts/baseline-schema.md`;
maintainer-maintained `baseline.md` fields survive regeneration.

## The command — two slices (~250 + ~100 authored lines)

- [ ] T014 `VitalsCommand` (`baseline` subcommand) + `Util.swift`
  registration — `--site`/`--url`/`--max-pages`/`--region`/`--out-dir`/
  `--…-file`/`--dry-run`/`--json`; secrets via `--from-file`/stdin, never
  arguments (FR-005–FR-008) · `Sources/util/Commands/VitalsCommand.swift`,
  `Sources/util/Util.swift`
- [ ] T015 `credentials store|show|delete` subcommands — separate file,
  `show` masks values · `Sources/util/Commands/VitalsCredentialsCommand.swift`
- [ ] T016 CLI validation tests — invalid site/keys, missing-credential
  error names `credentials store`, `--dry-run` writes schema-valid
  pending artifacts entirely offline and refuses to overwrite a
  non-pending baseline (SC-002, SC-004, FR-006) ·
  `Tests/UtilIntegrationTests/VitalsCommandTests.swift` (command tests
  live with the other `util` CLI suites there)

**Checkpoint:** `nocorrect swift run util vitals baseline --dry-run`
emits valid pending artifacts; `credentials show` prints no values.
(T014+T015 land as separate commits, each under the ~300-line ceiling.)

## Gates & annotations — the live slice

- [ ] T017 Roadmap/backlog pointer annotations — backlog row + phase-3
  Feature-3 note pointing at spec 009 (minimal, per convention) ·
  `Development/Roadmap/backlog.md`,
  `Development/Roadmap/phase-3-performance-delivery-optimization.md`
- [ ] T018 **Maintainer** — provision CF token + Google key →
  `util vitals credentials store` → `util vitals baseline` → review +
  commit generated artifacts; the writer owns everything below the
  GENERATED marker, including the status line — the maintainer drops the
  "(not yet in the tree)" note above it (SC-003) ·
  `baseline.json`, `baseline.md`

**Checkpoint:** all plan `## Tasks` tick or move to backlog; `vale` and
`plans --check` green; first live baseline committed.
