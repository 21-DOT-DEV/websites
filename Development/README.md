# Development

The repository's memory: why decisions were made, what is planned, and how
recurring work gets done. Everything here is checked, indexed, or linted —
see the commands at the bottom.

## What goes where

| Directory | Holds | Numbering |
|---|---|---|
| `constitution.md` | The core principles that outrank every other doc | — |
| `Roadmap/` | `README.md` index, `phase-N-*.md` detail, `backlog.md` for unphased ideas | Phase order |
| `Specs/` | `NNN-slug/` — one plan per feature, plus companions the feature earned (schemas, interfaces, runbooks) | Next free `NNN` |
| `ADRs/` | `NNNN-slug.md` — one durable decision per file | Next free `NNNN` |
| `Workflows/` | `NN-name.md` — operational playbooks for recurring procedures | Process order |
| `Research/` | Surveys and investigations behind decisions — evidence, not policy | — |
| `Tools/` | `plans` checker package — separate `Package.swift` by design | — |

The split is deliberate: **roadmap** says what and when, **specs** say how a
feature gets built, **ADRs** say why a decision stands, **workflows** say how
to run a procedure, and the **constitution** overrides all of it.

## Authoring rules

- Plans and ADRs carry YAML frontmatter that `Tools` validates; unknown keys
  fail closed, so add a field to the schema before using it.
- `Specs/README.md` and `ADRs/README.md` contain generated index tables —
  regenerate with `plans`, never hand-edit between the markers.
- A plan is a living document: revise in place, never append log-style
  sections (`Status log`, `Review rounds`, `Change log`, `Progress log`,
  `Work log` — Vale rejects these).
- An ADR is immutable once `Accepted`: supersede, don't rewrite.
- Diagrams: one Mermaid sketch per plan at most, only when a flow or component
  relation is clearer drawn than written; every node labeled; render it before
  review (`npx -y @mermaid-js/mermaid-cli` or mermaid.live).

## Status

Checked by `.github/workflows/development-docs.yml` on docs-touching pushes
and pull requests: builds and tests `Tools`, runs `plans --check`, lints with
Vale. The workflow reports failures on the PR but is advisory, not a required
check; promotion to required is tracked in `Roadmap/backlog.md`.

Locally, from the repository root:

```text
vale Development/ADRs Development/Specs Development/README.md
swift test --package-path Development/Tools
swift run --package-path Development/Tools plans --check
```

(In zsh, prefix `swift` commands with `nocorrect`.)
