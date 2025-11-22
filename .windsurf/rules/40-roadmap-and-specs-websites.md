# Roadmap & Specs – Websites

## Roadmap Structure
- **MUST** keep `.specify/memory/roadmap.md` as a slim index (table of contents).
- **MUST** put detailed phase content in `.specify/memory/roadmap/phase-*.md`.
- **SHOULD** record roadmap structural changes (e.g. phase renumbering, multi-file split) in the roadmap change log.

## Spec & Plan Patterns
- **MUST** create `spec.md` + `plan.md` + `tasks.md` for each major feature.
- **SHOULD** create supporting `data-model.md` and `contracts/*.md` when touching external APIs or non-trivial schemas.
- **MUST** avoid combining cross-cutting refactors into unrelated feature specs; instead create a dedicated feature (e.g. `002-utilities-library` for Utilities/`util`).

## IaC & Utilities
- **SHOULD** treat complex bash in workflows as a temporary implementation.
- **SHOULD** migrate repeated/complex workflow logic into Swift utilities/CLIs (e.g. `Utilities` + `util`) under their own specs.


## Rule Maintenance via Terminal (Windsurf Limitation)

- **MUST NOT** edit or create files under `.windsurf/rules/` using code-edit tools.
- **MUST** propose changes to `.windsurf/rules/*` via a terminal command (for user approval) rather than applying them directly.
- **MUST** clearly state in chat when a rules update requires a user-approved terminal command.
- **SHOULD** keep rules files small, focused, and scoped to a single concern (e.g., roadmap/spec patterns for the websites repo).

