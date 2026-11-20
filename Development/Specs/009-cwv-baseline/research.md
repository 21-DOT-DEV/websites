# Research — CWV baseline design

Evidence behind the decisions in `plan.md`. Each entry: Decision / Rationale
/ Alternatives considered.

## The field-data finding (drives everything)

- **CrUX has no data for either origin.** The Chrome UX Report only includes
  "publicly discoverable, sufficiently popular" origins (undisclosed
  threshold). Verified 2026-11-18 via Treo (reads the public CrUX dataset):
  `21.dev` and `docs.21.dev` render completely empty. The CrUX API will
  return insufficient-data; Search Console's CWV report — which reads the
  same dataset — shows "No data available."
- **Search Console CWV is dashboard-only.** Google's docs confirm no API
  surface exposes it. The roadmap's "CrUX + Search Console + PSI" trio
  therefore has two APIs — PSI queried as a lab instrument, CrUX probed
  directly — and one dashboard reading.
- **PSI API field data is being deprecated.** Google announced the CrUX
  (`loadingExperience`) sections will be removed; the CrUX API is the
  replacement. The command queries CrUX directly and treats PSI purely as a
  lab instrument.

## Decisions

### D1 — Synthetic instruments: Observatory + PSI (side-by-side), no new first-party JS

- **Rationale:** First-party RUM is ruled out — the maintainer permits no
  new client JS (SC-005; the sites still serve DocC's own bundle and a
  platform-injected Cloudflare beacon — see D2). CrUX is Chrome's own
  telemetry, which needs no page JS, but excludes both origins at current
  traffic. Field CWV is therefore unobtainable *today*, so the baseline is
  what the industry calls *synthetic monitoring*: controlled-lab tests,
  designed for exactly this case (sites below CrUX eligibility).
  Cloudflare Observatory is in open beta — runs real Lighthouse in ~21
  regions on a schedule, has a documented REST API, and uses the vendor
  already in the stack; a beta surface can change under the
  implementation, which the PSI cross-check absorbs. PSI is the second
  instrument — the same API Ahrefs Site Audit consumes — giving
  side-by-side comparison against the Ahrefs crawls the maintainer already
  runs.
- **Alternatives:** WebPageTest API (the depth upgrade — scripted
  interactions yield a *real* INP value, filmstrips, custom throttling;
  kept as the documented escape hatch), paid suites (DebugBear/SpeedCurve/
  Calibre — subscription dashboards, oversized), self-hosted
  `web-vitals` RUM (still client JS — rejected on the same grounds),
  keep-the-beacon (also client JS).

### D2 — Record the Cloudflare beacon history? No (documented option)

- **Rationale:** A Cloudflare Web Analytics RUM beacon was auto-enabled
  (CSP allowlists `static.cloudflareinsights.com`; Phase 7 F1 notes its
  removal path). Its already-collected history is readable once via GraphQL
  `rumWebVitalsEventsAdaptiveGroups` — real field data, injects nothing.
  The maintainer declined; recorded here so the option stays visible.
- **Honest note:** removing the beacon destroys the only channel that can
  measure field CWV *at current traffic* — the quarterly CrUX probe
  re-opens the channel if eligibility arrives (edge servers can't observe
  browser rendering); the privacy objection targeted *tracking* beacons —
  CF WA keeps no client state and discards IPs. Phase 7 F1 owns that
  decision; this spec changes nothing about it.

### D3 — `util` command + committed snapshot, not a dashboard transcription

- **Rationale:** The baseline's purpose is re-measurement with an identical
  method during optimization (the standard baseline→budget ratchet:
  measure → derive thresholds + headroom → tighten-only). A hand-recorded
  snapshot can't re-measure; a command can. Repo rule: behavior lives in
  `util` subcommands (ADR 0004). `--dry-run` keeps an offline-verifiable
  slice.
- **Alternatives:** snapshot doc only (cheap, no ratchet path); scheduled
  CI refresh (belongs to the budgets feature, not a point-in-time baseline).

### D4 — Credentials: flag → env → file (0600) → Keychain

- **Rationale:** Mirrors Apple's own precedent — `notarytool`'s
  `store-credentials` → `--keychain-profile`, and `swift package-registry
  login` (SE-0378): OS credential store by default, `~/.netrc` kept for
  automation where prompts are impossible. The `swift run` binary is
  ad-hoc-signed, so Keychain may re-prompt on rebuild — the 0600 file is the
  guaranteed prompt-free path for unattended/agent runs. Secrets never as
  CLI arguments (shell history/`ps`); never printed (masked).
- **Repo note:** `GoogleAuthService` (the Search Console service-account
  flow) already establishes explicit-argument → env precedence; this chain
  keeps that order and adds the two persistent stores beneath it.

### D5 — Artifact: dated observation in the spec dir, NOT `budget.json`

- **Rationale:** Industry convention separates *measurements* (transient —
  LHCI's `.lighthouseci/` is wiped each run; results live in
  tool/server history) from *budgets* (committed thresholds at repo root).
  `budget.json` semantics are thresholds — naming a measurements file
  `budget.json` misleads tools and readers. The baseline is a dated
  observation: belongs beside its spec like every other earned companion;
  the budgets feature derives the real root-level file later.
- **Alternatives:** root `budget.json` (misuses the format); markdown only
  (nothing machine-readable for re-measurement diffs).

## Recorded gaps (by design, not failure)

| Gap | Why | Recheck |
|---|---|---|
| No real-user LCP/INP/CLS | No CrUX eligibility, no new first-party JS | Quarterly, via `util vitals baseline` CrUX probe |
| INP is a TBT proxy | Passive lab can't measure interaction | WebPageTest scripted run if a page becomes interactive |
| Search Console CWV | No API | Maintainer quarterly dashboard check |
| Edge TTFB | Plan-gated fields (`edgeTimeToFirstByteMs`) | Verify on first credentialed run |
