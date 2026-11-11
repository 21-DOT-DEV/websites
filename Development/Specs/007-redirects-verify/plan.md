---
feature: 007
title: Verify _redirects rules against deployed URLs
phase: 2 · Utilities Library Refactoring
status: In Progress
updated: 2026-11-09
adrs: [0004, 0005]
---

# Verify _redirects rules against deployed URLs

## Goal

`util redirects verify` derives its checks from the `_redirects` file
itself instead of the hardcoded curl list in `deploy-cloudflare.yml`, so
a new redirect rule can't ship unverified. Closes Phase 2 Feature 2 —
the last remaining workflow-migration command (`headers select` stays in
bash by decision; `build verify` folds into Phase 3 budgets).
Requirements and observable behavior: [spec.md](spec.md); evidence and
rejected alternatives: [research.md](research.md); ordered work:
[tasks.md](tasks.md).

## Approach

1. Parse `_redirects` — `source target status` columns, `#` comments,
   `*` wildcard sources, and `:placeholder` targets (FR-001). The parser
   is consumed from `Sources/UtilLib/Links/` (`RedirectRule.swift` —
   `RedirectsParser`, `RedirectMatcher`), already on `main` via
   Specs/006's `util links check` (#86); it implements Cloudflare's
   documented source syntax, and its edge-semantics machinery backs the
   verifier's dedicated refusal reason (see step 2).
2. Rules the edge would not apply — a status Cloudflare doesn't
   support, a source that can't compile, or a target looping back
   through its own source — fail with the named refusal reason before
   any request fires (FR-005). The refusal reason is dedicated, not
   the link checker's `isAppliedByEdge` flag: that flag also refuses
   deliberate SPA-shell catch-all proxies as checker policy, and the
   edge does serve those — failing them here would block a deploy over
   valid configuration.
3. Static rules are verified directly: request `base-url + source`
   (HEAD, GET fallback), assert the response status equals the declared
   status and, for 3xx rules, that `Location` matches the declared
   target — the edge echoes targets verbatim, relative or absolute
   (FR-002).
4. Wildcard rules declaring a 3xx status are verified by substituting a
   fixed probe token for each `*`/`:placeholder` and asserting status +
   `Location` on the probe response (FR-003). Wildcard rules declaring a
   non-3xx status get an opportunistic real-target probe — when a
   splat-expanded target resolves to an existing file under the
   deployed output root and the probed source path isn't itself a
   deployed asset, the source form is requested and `200` asserted —
   otherwise skipped with a stated reason (FR-004).
5. `util redirects verify --site <site> --base-url <url>` reads rules
   from `Resources/<site>/_redirects` (`--file <path>` accepts an
   explicit file instead — mutually exclusive, one required) and checks
   real-target existence under `Websites/<site>/` — the generated
   output root, present in the deploy job post-artifact (`--file`
   checks under its parent directory; absent roots degrade probes to
   skips). Reports pass/fail/skip per rule and exits non-zero on any
   failure (FR-005..FR-007). The verifier lands in
   `Sources/UtilLib/Redirects/`; the parser stays in `Links/` where 006
   shipped it.
6. Replace the two "Verify redirects" curl steps in
   `deploy-cloudflare.yml` with this command (SC-001, SC-002).

## Verification

- Unit tests over a `_redirects` fixture: probe substitution,
  status/`Location` assertion, edge-refused failures, real-target
  rewrite probes — transport stubbed, no network (covers FR-002..FR-006;
  parsing itself is covered by the shipped `Links` suite).
- `UtilIntegrationTests` black-box runs: argument validation (`--site`
  vs `--file` exclusivity), a clean-fixture pass, a failing-fixture
  exit code (covers FR-005's reporting and exit behavior, FR-007).
- Live verification against a preview deployment (covers SC-001..SC-003).

## Test summary

Adds assertion coverage for status and `Location` matching — probed
splat targets, edge-refused failures with named reasons, opportunistic
real-target rewrite probes, and skipped non-3xx rewrites with no
derivable target.

## Tasks

- [ ] Live verification against a preview deployment — owner:
  maintainer; exit: `deploy-cloudflare.yml` uses the command and passes
  (`.github/workflows/deploy-cloudflare.yml`).
