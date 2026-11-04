---
adr: 0004
title: CI logic lives in UtilLib + the util executable, not workflow scripts
status: Accepted
date: 2025-12-17
supersedes: []
superseded_by: null
---

# CI logic lives in UtilLib + the util executable, not workflow scripts

## Context

Workflows accumulated inline shell for sitemap generation, header selection,
state tracking, and PR comments — untyped, duplicated across workflows, and
untestable. The same pattern is documented in
`Specs/004-utilities-cli/util-architecture.md`.

## Decision

`Sources/UtilLib/` is a regular library holding the logic; `Sources/util/` is
a thin executable exposing it as subcommands (`sitemap`, `headers`,
`canonical`, `comment`, `search-console`, `agent-directive`, `links`).
Workflows call `swift run util <subcommand>`;
the same commands run locally. New CI-facing capability lands in UtilLib
first, then gets a `util` subcommand — never inline workflow shell.

## Alternatives considered

- **Keep inline shell** — rejected: it was the problem being solved.
- **Subcommands on a site executable** — rejected: couples CI utilities to a
  site build and blurs the site-vs-tooling boundary.

## Consequences

- CI logic is covered by `swift-testing` tests like any other code.
- Workflow YAML shrinks to orchestration; behavior changes land in Swift.
