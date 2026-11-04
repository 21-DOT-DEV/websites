---
adr: 0006
title: Canonical URLs are checked and fixed post-generation
status: Accepted
date: 2025-11-18
supersedes: []
superseded_by: null
---

# Canonical URLs are checked and fixed post-generation

## Context

Canonical link elements and redirects need to be right in the *served* HTML
regardless of which generator produced it — Slipstream pages, DocC output, or
co-located markdown — and baking the check into one site target would miss the
others. A remediation pass (former specs 003 and 005) settled the approach.

## Decision

Canonical validation and repair run as a post-generation pass over the
`Websites/` output tree — `util canonical check` / `util canonical fix` —
site-agnostic by construction, applied to generated HTML rather than embedded
in any site's page code.

## Alternatives considered

- **Per-site canonical logic** — rejected: duplicates the policy and leaves
  DocC/markdown output unhandled.

## Consequences

- One policy covers every content source, including output we don't control
  the templates of.
- Fixes land on build output; the check can run in CI after any generation
  step.
