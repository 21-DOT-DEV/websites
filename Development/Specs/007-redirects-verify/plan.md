---
feature: 007
title: Verify _redirects rules against deployed URLs
phase: 2 · Utilities Library Refactoring
status: Planned
updated: 2026-11-04
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
   is written here but shaped for reuse by the planned `util links
   check` (Phase 3 Feature 9), which needs the same rule model for
   redirect-source resolution.
2. Static rules are verified directly: request `base-url + source`
   (HEAD, GET fallback), assert the response status equals the declared
   status and, for 3xx rules, that `Location` matches the declared
   target after normalization (FR-002).
3. Wildcard rules declaring a 3xx status are verified by substituting a
   fixed probe token for each `*`/`:placeholder` and asserting status +
   `Location` on the probe response (FR-003). Wildcard rules declaring a
   non-3xx status are reported as skipped — a rewrite can't be proven by
   status alone when the probed target may not exist (FR-004).
4. `util redirects verify --site <site> --base-url <url>` resolves the
   site to `Resources/<site>/_redirects`, reports pass/fail/skip per
   rule, and exits non-zero on any failure (FR-005..FR-007).
5. Replace the two "Verify redirects" curl steps in
   `deploy-cloudflare.yml` with this command (SC-001, SC-002).

## Verification

- Unit tests over a `_redirects` fixture: parsing, probe substitution,
  status/`Location` assertion — transport stubbed, no network (covers
  FR-001..FR-004).
- `UtilIntegrationTests` black-box runs: argument validation, a
  clean-fixture pass, a failing-fixture exit code (covers FR-005,
  FR-007).
- Live verification against a preview deployment (covers SC-001..SC-003).

## Test summary

Adds parsing coverage for all `_redirects` field shapes and assertion
coverage for status and `Location` matching, including probed splat
targets and skipped non-3xx rewrites.

## Tasks

- [ ] Live verification against a preview deployment — owner:
  maintainer; exit: `deploy-cloudflare.yml` uses the command and passes
  (`.github/workflows/deploy-cloudflare.yml`).
