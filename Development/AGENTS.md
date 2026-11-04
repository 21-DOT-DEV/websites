# Agent guide — `Development/`

Guidance for any file under this directory. Applies on top of the repository-root
`AGENTS.md`; the closest file wins where two apply.

## Commands

All commands run from the repository root.

```text
vale Development/ADRs Development/Specs            # style rules for plans and ADRs
swift test --package-path Development/Tools        # unit tests for the checker
swift run --package-path Development/Tools plans        # rewrite the index tables
swift run --package-path Development/Tools plans --check  # fail instead of rewriting
```

`Development/Tools` is a second, deliberately small SwiftPM package; see
`Tools/README.md` for why it is separate.

## Plans (`Development/Specs/`)

A feature's state lives in `Specs/<NNN>-<slug>/`, one directory per feature:

- `plan.md` — the living document, with YAML frontmatter the checker validates:
  `feature` (the `NNN`), `title`, `phase` (a roadmap phase or `null`), `status`
  (`Planned`, `In Progress`, `Implemented`), `updated` (`YYYY-MM-DD`, bumped on
  every revision), `adrs` (ADR numbers this plan depends on).
- Everything else in the folder is a companion earned by the feature — a
  `data-model.md` or `contracts/` when the work touches external APIs or
  non-trivial schemas, a runbook when it leaves one behind. Do not add files
  "just in case".
- Cross-cutting refactors get their own plan; they never ride inside an
  unrelated feature's plan.
- Keep `plan.md` a living document: rewrite it as understanding changes rather
  than appending log entries. Never add Status log, Review rounds, Change log,
  Progress log, or Work log sections — history belongs to git.
- A `## Tasks` section lists what remains to reach `Implemented`: unchecked
  items only, each with an owner, a concrete exit condition, and a link to the
  verifying test or command.
- Test counts are stated as deltas (`+7 tests`), never suite totals.
- Link ADRs the plan relies on from its frontmatter `adrs:` list.
- `Specs/README.md` holds the conventions plus a generated index; its table is
  written by the checker, never edited by hand. `Specs/_template/` is the
  starting point for new features.

## Decision records (`Development/ADRs/`)

One durable decision per file: `NNNN-slug.md` with frontmatter `adr`, `title`,
`status` (`Proposed`, `Accepted`, `Superseded`), `date`, `supersedes`,
`superseded_by`. Body sections: Context, Decision, Consequences, and
Alternatives considered where the choice was contested.

- Accepted ADRs are final. A changed decision is a new ADR that supersedes the
  old one; the old file's `status` becomes `Superseded` and `superseded_by`
  points at the replacement.
- Factual corrections (typos, stale details) are edits recorded in the ADR's
  own history section or commit message — the decision itself never mutates.
- `ADRs/README.md`'s index table is generated; never edit it by hand.

## Plan quality (carried from the old checklists)

- Before implementing, re-read the plan for ambiguity: unquantified claims,
  undefined terms, missing edge cases. Clarify in the plan, not mid-build.
- After implementing, reconcile the plan with what shipped: set `status`,
  tick tasks, move leftovers to `Roadmap/backlog.md`.
- Structural roadmap changes (renumbering, splitting, new phases) get a
  change-log entry in `Roadmap/README.md`.

## Playbooks (`Development/Workflows/`)

A deliberately small set of step-by-step procedures (component lifecycle,
DesignSystem management, Slipstream API development, icon creation,
troubleshooting) — the only files that survived mining. They are read, not
checked — no frontmatter, no index. Add one only when a procedure is too long
to be a rule; retire it when the process it describes no longer exists.

## Guidance maintenance

Periodically review `AGENTS.md` files and surviving playbooks for drift —
remove rules agents already follow, fix contradictions, and keep every file
under ~150 lines.

## Style rules (Vale)

`.vale.ini` enables the `Plans` style under `Development/Specs/**`,
`Development/ADRs/**`, and `Development/README.md`:

- `Plans.NoAppendOnlyLogs` — rejects headings for append-only log sections.
- `Plans.NoTestTotals` — rejects suite-total phrasing; use deltas instead.
