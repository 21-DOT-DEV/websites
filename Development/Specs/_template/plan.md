---
feature: NNN
title: <one line, no trailing period>
phase: null   # roadmap phase, e.g. "1 · Foundation & Discoverability"
status: Planned   # Planned | In Progress | Implemented
updated: YYYY-MM-DD
adrs: []
---

# <Feature title>

## Goal

<What this achieves and for whom — the user-visible or operator-visible outcome.>

## Approach

<Numbered steps the implementation takes.>

## Verification

<Commands that prove the goal was met — build, test, curl matrices, CI runs.>

## Test summary

<What this feature adds to the suite, as deltas (e.g. "+4 tests covering X").>

## Tasks

- [ ] <Remaining work — unchecked items only, each with owner and exit condition>

## Companion files

<Earned, not required — this file alone is indexed. Add a sibling only
when the feature needs it, with a minimal header (title + links to the
siblings); no frontmatter.>

- `spec.md` — the WHAT in user-facing terms: numbered requirements
  (FR-NNN), measurable outcomes (SC-NNN), Given/When/Then acceptance
  scenarios. Add when behavior needs separating from mechanism
  (externally visible contracts, branchable results). See
  `Specs/006-internal-link-check/spec.md` for the format.
- `research.md` — evidence behind contested choices: Decision /
  Rationale / Alternatives considered. Add when real research was done.
- `data-model.md`, `contracts/`, `quickstart.md` — external APIs or
  non-trivial schemas (see `Specs/002-sitemap-infrastructure/`).
- `tasks.md` — ordered work only when the task set has dependency
  waves a flat `## Tasks` list can't express.
