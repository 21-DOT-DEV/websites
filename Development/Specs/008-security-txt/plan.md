---
feature: 008
title: RFC 9116 security.txt for both sites
phase: 3 · Performance & Delivery Optimization
status: Implemented
updated: 2026-11-17
adrs: [5]
---

# RFC 9116 security.txt for both sites

## Goal

Security researchers find a working disclosure channel on either site:
`/.well-known/security.txt` on 21.dev and docs.21.dev carries the required
`Contact`/`Expires` fields plus `Policy`, `Preferred-Languages`, and
`Canonical` pointers (Phase 3 Feature 7).

## Approach

- `Resources/21-dev/well-known/security.txt` and
  `Resources/docs-21-dev/well-known/security.txt` ship identical field sets —
  `Contact: mailto:security@21.dev` and the GitHub advisories intake,
  `Expires` ~1 year out, `Policy` → this repo's `SECURITY.md`,
  `Preferred-Languages: en`, and both hosts' `Canonical` URIs. RFC 9116 §3.1
  gives no subdomain inheritance, so each host serves its own copy; §2.5.2
  requires the fetch URI to appear in a Canonical field, so both URIs are
  listed in both files.
- `SECURITY.md` at the repo root adapts the `swift-secp256k1` policy format —
  `security@21.dev` or GitHub Security Advisories, no public issues, 7-day
  acknowledgement — with a scope section covering the two sites and this
  repository and routing package findings to each repo's own policy.
- `_redirects`: docs-21-dev gains the `/.well-known/* → /well-known/:splat
  200` rewrite (Cloudflare Pages won't serve dot-directories — the same
  pattern 21-dev already uses); both sites gain `/security.txt →
  /.well-known/security.txt 301` for the legacy top-level path.
- `_headers.{dev,prod}`: docs-21-dev's `/.well-known/*` block moves from
  `max-age=300, stale-while-revalidate` to `no-store`/`no-cache`, matching
  21-dev and the Specs/003 quickstart expectations; both sites pin
  `Content-Type: text/plain; charset=utf-8` on the file defensively.
- `Tests/IntegrationTests/SecurityTxtTests.swift` parses both files and fails
  when `Expires` is under 60 days or over ~400 days out — the "renewed
  annually" success metric enforced by CI rather than a calendar note, with
  the far bound catching year typos. The suite also pins the `_headers`
  policy (`text/plain`, `no-store`) and blocks `.json` under docs'
  `well-known/`, where `/**/*.json` would contradict the no-store rule.
- The file ships unsigned; OpenPGP clearsigning is deferred to
  `Roadmap/backlog.md` — a signature only helps once a verifiable 21.dev key
  is published somewhere researchers already trust.

## Verification

- `nocorrect swift test --filter SecurityTxtTests` — +9 tests.
- `nocorrect swift run 21-dev` → `Websites/21-dev/well-known/security.txt`
  present alongside `nostr.json`.
- Post-deploy curls (Specs/003 quickstart): both hosts return 200,
  `text/plain`, `Cache-Control: no-store`; securitytxt.org validates.

## Test summary

+9 tests in `Tests/IntegrationTests/SecurityTxtTests.swift`: file existence,
Contact URI schemes, exactly-once Expires bounded below (60-day freshness
gate) and above (year-typo guard), Canonical coverage of the fetch URI,
https-only web-URI fields, presence of `Policy` and `Preferred-Languages`,
`_headers` pinning of `text/plain` and `no-store`, no `.json` under docs'
`well-known/`, and identical field sets across the two site copies.

## Tasks

- [ ] Enable private vulnerability reporting on `21-DOT-DEV/websites`
  (Settings → Security advisories) — owner: maintainer; exit:
  `https://github.com/21-DOT-DEV/websites/security/advisories/new` resolves to
  the intake form the second `Contact:` line promises.
- [ ] Post-deploy verification — owner: maintainer; exit: the Specs/003
  quickstart curls return `Cache-Control: no-store` on both hosts and
  securitytxt.org reports both files valid.
