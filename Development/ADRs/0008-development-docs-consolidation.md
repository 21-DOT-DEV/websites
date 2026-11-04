---
adr: 0008
title: Planning artifacts consolidated under Development/ with a checked index
status: Accepted
date: 2026-11-02
supersedes: []
superseded_by: null
---

# Planning artifacts consolidated under Development/ with a checked index

## Context

Process knowledge was scattered: `.specify/` held the constitution, roadmap,
and spec-kit templates; `specs/` held feature folders with index tables
maintained by hand; `.devin/` held agent rules bound to one tool's format.
Nothing validated any of it — stale indexes, dangling references, and
frontmatter drift were invisible. Sibling repos (`swift-secp256k1`,
`swift-bitcoinkernel`) had already solved this with an identical layout.

## Decision

Adopt the siblings' model: a `Development/` tree (constitution, `Roadmap/`,
`Specs/`, `ADRs/`, `Workflows/`) plus `Development/Tools` — a standalone
SwiftPM checker that validates frontmatter, cross-references, and supersession
chains and regenerates index tables. Agent guidance moves into a nested
`AGENTS.md` hierarchy. CI lints and checks the tree via an advisory
`development-docs.yml` workflow; Vale enforces plan style. The migration
landed as one change (the additive and subtractive stages collapsed once the
new guidance proved live in-session) — see `Specs/001-development-docs`.

## Alternatives considered

- **Fold the checker into the root package's `util` target** — rejected:
  SwiftPM resolves the whole root manifest (Slipstream on a moving branch,
  SwiftSoup, Subprocess, the Tailwind plugin) before building any target, and
  `swift-yaml` would drag C++ interop into the site build.
- **Keep spec-kit alongside** — rejected: two systems is the failure mode this
  migration exists to end.

## Consequences

- `plans --check` is the single source of truth for doc validity.
- Agent guidance is repository-owned and tool-agnostic.
- `.devin/`, `.specify/`, and `specs/` are removed in the same change; their
  durable content is mined into `AGENTS.md` files, plans, and these ADRs
  rather than carried as parallel docs.
