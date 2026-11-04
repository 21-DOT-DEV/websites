---
feature: 003
title: Cloudflare header policy as version-controlled configuration
phase: "1 · Foundation & Discoverability"
status: Implemented
updated: 2026-11-02
adrs: [5]
---

# Cloudflare header policy as version-controlled configuration

## Goal

Cache, security, and content-type headers for both subdomains are declared in
the repo and generated per environment — HSTS in production, never in
previews — with a verifiable post-deploy check.

## Approach

- Canonical policy lives in `Resources/<site>/_headers.dev` and
  `_headers.prod`; the build pipeline selects the environment source and
  copies it to the deployed `_headers`, while `util headers validate` checks
  the result.
- The policy matrix distinguishes HTML responses (HSTS + CSP + security
  baseline, short cache), long-lived static assets (`immutable`, one year),
  and downloads/`.well-known` (`no-store`).
- Preview builds deliberately omit HSTS so preview URLs never poison the
  browser's HSTS cache.

## Companions

- `quickstart.md` — the curl verification matrix used after each deploy
  (linked from the repository `README.md`).
- `contracts/deployment-checks.md` — what a deploy must satisfy.
- `contracts/headers-validator.md` — the validation contract.

## Verification

- Run the curl matrix in `quickstart.md` against a deployed URL (one HTML
  page, one static asset, one download per site).
- Post-ship enhancements (structured deploy logs, smoke-test steps in
  workflows, inline `_headers` annotations) are deferred to
  `../../Roadmap/backlog.md`.
