---
adr: 0005
title: Cloudflare config is generated, never hand-edited
status: Accepted
date: 2025-11-10
supersedes: []
superseded_by: null
---

# Cloudflare config is generated, never hand-edited

## Context

`_headers` and `_redirects` need per-environment variants — most visibly HSTS,
which must be present in production and absent in previews. Hand-editing the
deployed files had already produced drift between environments.

## Decision

Canonical policy lives in source files under `Resources/<SiteName>/`
(`_headers.dev`, `_headers.prod`, `_redirects` source). The build pipeline
selects the environment-appropriate source and copies it to the deployed
`_headers` (see `build-slipstream.yml`/`generate-docc.yml`); `util headers
validate` checks the file. Emitted outputs are never edited by hand.

## Consequences

- PR diffs show policy intent, not generated output.
- Environment differences are chosen by the deploy step, not remembered by a
  human.
- Verification is mechanical: the curl matrix in
  `Specs/003-cloudflare-headers/quickstart.md`.
