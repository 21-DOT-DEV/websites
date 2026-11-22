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

### D4 — Credentials: flag → env → Keychain → file (0600)

- **Rationale:** Mirrors Apple's own precedent — `notarytool`'s
  `store-credentials` → `--keychain-profile`, and `swift package-registry
  login` (SE-0378): OS credential store by default, `~/.netrc` kept for
  automation where prompts are impossible. The encrypted store outranks
  the plaintext one — the ordering python-keyring (priority 5 vs 0.5),
  Docker (`credsStore` → `auths`), and `gh` (secure storage by default,
  `--insecure-storage` to opt out) all take —
  for encryption at rest and OS bookkeeping, not tamper resistance: items
  the `security(1)` backend writes trust `/usr/bin/security`, so any
  same-UID process can read or overwrite them just as it could a 0600
  file (per-app isolation is what this backend trades away for
  prompt-free reads). A Keychain that can't *answer* —
  locked on a headless run — degrades to the file layer (Fastlane's
  rescue-and-continue pattern), so unattended runs still reach their
  provisioned file. Secrets never as CLI arguments (shell history/`ps`);
  never printed (masked).
- **Backend — `security(1)`, not `SecItem*`:** `SecItemAdd` binds an
  item's ACL to the creating binary's cdhash, and the `swift run` binary
  is ad-hoc-signed — every rebuild would re-prompt on read. That wart was
  the original reason the file outranked the Keychain; shelling to
  `/usr/bin/security` removes it, because items written by `security(1)`
  trust the stable Apple-signed binary, not our rebuildable one — reads
  are prompt-free from any parent process. Writes ride `security -i`'s
  stdin command stream since `add-generic-password -w` is argv-visible
  (RubyGems' `Gem::CredentialStore::MacOSBackend` technique; Fastlane
  wraps the same CLI; `nova-workspace` already shells
  `find-generic-password`). The file store keeps the SE-0378 fallback
  role: non-macOS environments and couldn't-answer degradations.
- **Backend edge semantics — verified against `security(1)`
  implementations:**
  - *Delete:* `delete-generic-password` removes only the FIRST matching
    item, so delete loops until exit 44. Same mechanism as RubyGems'
    `MacOSBackend.delete_all` (`lib/rubygems/credential_store/native/
    macos.rb` — "security deletes one entry per call") and
    zalando/go-keyring's `DeleteAll`. Framework-based helpers
    (docker-credential-osxkeychain, aws-vault via 99designs/keyring)
    skip the loop — `SecItemDelete` removes all matches at once. Within
    one keychain a `-a`/`-s` pair is unique (`add-generic-password`
    answers exit 45, `errSecDuplicateItem`, verified), so duplicates
    arise only across the default search list — the case the loop
    exists for.
  - *Can't-answer classification:* a missing keychain file reports exit
    44 with the *item* not-found phrase (verified), indistinguishable
    from an absent item downstream — go-keyring's broad `"could not be
    found"` substring and RubyGems' exit-44-alone check share the same
    misclassification. The `requireKeychainFile` pre-check exceeds the
    cited precedent. aws-vault surfaces raw `OSStatus` (-25300) rather
    than reporting "not set" — the same typed-error direction as
    `exists` throwing on can't-answer.
  - *Write transport:* RubyGems' backend documents both constraints
    verbatim — a newline "would start a second command in the
    `security -i` batch" and `-w` "prints any non-printable byte back as
    a hex string" — and refuses non-transportable secrets at `set`,
    falling back to file: the `--target file` remedy. Every `-i`
    argument (secret, service, keychain path) takes the ASCII guard;
    the cited backends take no keychain path at all — nothing to copy.
  - *File store:* RubyGems' `check_credentials_permissions` requires
    exactly `0600` and aborts; its write is a plain truncating
    `File.open(path, "w", 0600 & ~umask)` — no atomic rename, no lock.
    The `.atomic` write plus post-write mode re-assert already exceeds
    it, and no credential store consulted locks its file — the
    recorded no-`flock` gap has precedent.
  - *Symlinks:* `pass` supports symlinked stores (upstream added
    `find -L`; v1.5 notes "properly follow symlinks"), and a broken
    store link fails loudly rather than reporting absent — the
    resolve-then-check posture plus can't-answer on a dangling link.
- **Repo note:** `GoogleAuthService` (the Search Console service-account
  flow) already establishes explicit-argument → env precedence; this chain
  keeps that order and adds the two persistent stores beneath it.
- **Alternatives:** Security-framework `SecItem*` calls (right for
  stable-signature binaries — git's osxkeychain helper, SwiftPM,
  notarytool; ours is rebuilt per commit), file-first precedence
  (superseded — it only existed to dodge the rebuild re-prompt), warn-only
  on loose permissions (gpg's directory posture; the file rule already
  chose ssh-style refusal).

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
