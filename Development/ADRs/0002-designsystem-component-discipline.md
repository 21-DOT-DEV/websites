---
adr: 0002
title: DesignSystem-first components, Slipstream APIs before RawHTML
status: Accepted
date: 2025-11-13
supersedes: []
superseded_by: null
---

# DesignSystem-first components, Slipstream APIs before RawHTML

## Context

Slipstream renders HTML from Swift with typed Tailwind modifiers, but it also
exposes `RawHTML` as an escape hatch. Without a rule, escape hatches become
the default and the type-safe layer gets bypassed.

## Decision

Reusable UI lives in `Sources/DesignSystem/` with simple composable APIs and
no site-specific styling. Slipstream's structured components and typed
modifiers are always tried first — check `W3C/Elements` before reaching for
`RawHTML`. `RawHTML` is permitted only when Slipstream cannot express the
markup, and every use gets a comment explaining why. Each component carries at
least one integration test in a page context.

## Alternatives considered

- **Free-form `RawHTML` where convenient** — rejected: loses Tailwind type
  safety, accessibility defaults, and a consistent audit trail.

## Consequences

- `RawHTML` sites are greppable and reviewed (audit procedure in
  `Sources/DesignSystem/AGENTS.md`).
- Consult `.build/checkouts/slipstream/.../TailwindCSS/` for the modifier
  surface before writing class strings by hand.
