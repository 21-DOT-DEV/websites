# Spec — Core Web Vitals baseline (synthetic + edge)

Defines WHAT the feature delivers. Mechanism lives in `plan.md`; evidence in
`research.md`; wire formats in `contracts/`.

## Requirements

- **FR-001 — Observatory collection.** `util vitals baseline` checks
  `availabilities` for remaining quota and allowed regions, then triggers a
  Cloudflare Observatory test per key page per selected site (`--region`
  overrides the default test region), polls to completion, and records
  mobile + desktop lab metrics: LCP, CLS, FCP, Speed Index, TBT (the lab
  proxy for INP), TTFB, and the Lighthouse performance score. Failed or
  unreachable tests record an error entry — they never silently drop.
- **FR-002 — PSI collection (second instrument).** For every page, the
  command also queries the PageSpeed Insights API once per form factor and
  records the same metric set, so the two instruments sit side-by-side in
  the baseline.
- **FR-003 — CrUX eligibility probe.** The command queries the CrUX API per
  origin. A "record not found / insufficient data" response is recorded as
  the field-data finding (expected at current traffic); a successful
  response records origin p75 values for LCP, INP, CLS, FCP, and TTFB.
- **FR-004 — Edge TTFB (server-side field data).** Per host, the command
  queries Cloudflare's GraphQL Analytics API for `edgeTimeToFirstByteMs` and
  `originResponseDurationMs` quantiles over a trailing 28-day window,
  clamped to the dataset's per-plan `maxDuration`/`notOlderThan` limits
  (`windowDays` records the window actually used). If the plan or token
  scope doesn't expose the fields, the section records `unavailable` with
  the reason — never a hard failure.
- **FR-005 — Credential resolution.** Secrets resolve in order: explicit
  `--…-file` flag (e.g., `--cloudflare-api-token-file`) → environment
  variable → macOS Keychain
  (`dev.21.websites.util` service) → file store
  (`~/.config/util/credentials.json` — file enforced mode 0600, containing
  directory enforced mode 0700). The encrypted store outranks the
  plaintext one; a Keychain that can't answer — locked on a headless run —
  degrades to the file layer rather than failing. `util vitals credentials
  store|show|delete` manages both stores; secret values are never accepted
  as command-line arguments (stdin/`--from-file`/prompt only) and never
  printed.
- **FR-006 — Artifacts.** The command writes `baseline.json`
  (`schemaVersion`-stamped) and `baseline.md` to `--out-dir` (default: this
  spec folder); `--json` additionally prints the JSON to stdout.
  `--dry-run` writes the pending-structure artifacts with zero
  network calls and refuses to overwrite non-pending artifacts — the
  offline check can never clobber a real baseline.
- **FR-007 — Manual readings recorded, not automated.** Search Console's CWV
  report status and the Ahrefs Site Audit configuration state are recorded
  in `baseline.md` as maintainer-maintained fields — neither exposes a
  usable API.
- **FR-008 — Page set.** Default page set per site is the origin root
  followed by the sitemap's remaining URLs in document order, capped at
  `--max-pages` (default 10) total — the root is promoted because it must
  always be measured and sitemaps need not list it. Any unusable sitemap
  (absent, unreadable, or yielding no `<url>` entries) falls back to the
  origin root alone. `--url` replaces the set; `--site` restricts to one
  site.

## Success criteria

- **SC-001** — `nocorrect swift build` and `nocorrect swift test` pass.
- **SC-002** — `nocorrect swift run util vitals baseline --dry-run` writes a
  `baseline.json` that validates against `contracts/baseline-schema.md` and
  a `baseline.md` showing the pending state — entirely offline.
- **SC-003** — A credentialed run produces complete artifacts: both sites,
  every selected page with both instruments, the CrUX finding, and edge TTFB
  or its unavailability reason; committed to the repo.
- **SC-004** — Credential precedence is proven in tests: each layer wins
  over the one below it — the Keychain read sits behind an injectable
  seam so unit tests fake it (a manual real-Keychain check covers what a
  fake can't) — and a missing value produces the documented "how to
  provision" error.
- **SC-005** — No client-side JavaScript is added to either site; nothing in
  the feature touches `Resources/` site content.
