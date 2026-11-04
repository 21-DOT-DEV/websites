---
adr: 0001
title: One package, multiple site targets, shared design system
status: Accepted
date: 2025-11-13
supersedes: []
superseded_by: null
---

# One package, multiple site targets, shared design system

## Context

The project hosts several sites — 21.dev, docs.21.dev, and future subdomains —
that share a design language and toolchain but deploy independently. The
options were repo-per-site, a single-site repo with forks, or one package with
multiple targets.

## Decision

A single SwiftPM package where page-generating sites are executable targets
under `Sources/<SiteName>/` (currently `21-dev`), each with assets in
`Resources/<SiteName>/`; documentation sites like `docs.21.dev` assemble from
`Resources/` + generator workflows instead of a site target. Shared UI lives
in `Sources/DesignSystem/`, domain libraries in `Sources/SchemaLib/` and
`Sources/SiteIdentity/`, CI-facing logic in `Sources/UtilLib/` +
`Sources/util/`, and shared test helpers in `Tests/TestUtils/`.

## Alternatives considered

- **Repo per site** — rejected: component fixes would need N PRs and versions
  would drift apart.
- **One site per package, shared package for DesignSystem** — rejected at this
  scale: dependency pinning overhead for a solo maintainer.

## Consequences

- New sites are added as a new target + resources directory, not a new repo.
- A DesignSystem change can ship all sites at once — and can break all sites
  at once, so site-level integration tests are required.
- Agents and contributors must confirm the target site before touching
  site-specific code or resources (see `AGENTS.md`).
