---
feature: 001
title: Consolidate planning artifacts under Development/ with self-checking tooling
phase: null
status: In Progress
updated: 2026-11-02
adrs: [8]
---

# Consolidate planning artifacts under Development/ with self-checking tooling

## Goal

Replace the scattered spec-kit machinery (`.specify/`, root `specs/`) and
tool-specific agent scaffolding (`.devin/`) with a repository-owned
`Development/` tree — constitution, roadmap, plans, decision records, and
playbooks — whose indexes and frontmatter are validated by a small standalone
checker. Model and tool ported from the identical layout already proven in
`21-DOT-DEV/swift-secp256k1` and `21-DOT-DEV/swift-bitcoinkernel`.

## Approach

1. Add `Development/` — constitution, `Roadmap/` (index + phase files +
   `backlog.md`), `Specs/` (this plan plus condensed plans for shipped
   features), `ADRs/` (backfilled durable decisions), `Workflows/` (ported
   playbooks), `Tools/` (the `plans` checker package).
2. Port `Development/Tools` near-verbatim from the sibling repos: a second
   SwiftPM package with two pinned dependencies so docs checks never resolve
   the site's dependency graph.
3. Migrate durable agent guidance from `.devin/rules/` into a nested
   `AGENTS.md` hierarchy; mine the numbered playbooks — rules into the
   scoped `AGENTS.md` files, five genuinely procedural files kept in
   `Workflows/`, the rest deleted.
4. Add `.vale.ini` + `Plans` style rules and the advisory
   `development-docs.yml` workflow (reports failures on PRs, does not block).
5. Delete `.devin/`, `.specify/`, and `specs/` in the same change — the
   additive and subtractive stages collapsed into one commit once the new
   guidance proved live in-session (originally planned as a second PR).

## Verification

- `swift test --package-path Development/Tools` — checker suite passes.
- `swift run --package-path Development/Tools plans --check` — indexes current,
  frontmatter valid, all `adrs:` and supersession references resolve.
- `vale Development/ADRs Development/Specs` — no style violations.
- Nothing outside `Development/` and agent-guidance files changes; the site
  build is untouched.

## Test summary

The checker's own suite (schema decoding, fence parsing, index-table
generation, cross-reference and supersession validation) ships inside
`Development/Tools/Tests/` and is exercised by CI.

## Tasks

- [ ] Land this change and confirm the advisory workflow runs green on its
      own PR — exit: `development-docs` job reports success.
- [ ] Observe the new `AGENTS.md` files in one real work session post-merge —
      exit: scoped files load and govern without regressions.
