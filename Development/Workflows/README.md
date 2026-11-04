# Workflows

Step-by-step procedures for recurring multi-step work — the files that
survived the guidance mining. Everything that could be expressed as a rule
moved into the `AGENTS.md` files beside the code it governs; what remains here
is genuinely procedural: sequences worth following in order, not facts worth
memorizing.

They are **read, not checked** — no frontmatter, no generated index, no CI
validation. Add a file only when a procedure is too long to be a rule; retire
one when the process it describes no longer exists.

## Index

- `43-component-full-cycle.md` — scaffold → implement → verify → integrate a
  DesignSystem component, end to end
- `44-designsystem-management.md` — icons, models, and tokens: where shared
  building blocks live and how they change
- `45-slipstream-api-development.md` — working with Slipstream's component
  and modifier APIs (structure, type safety, common patterns)
- `48-icon-creation-workflow.md` — creating an icon component, gallery
  registration, rounded corners, verification
- `90-troubleshooting-common-issues.md` — diagnosis flow for build, test,
  Tailwind, and site-generation failures

The always-on rules that used to live alongside these are now in the
`AGENTS.md` files (see the root file's map); doc conventions for this folder
live in `Development/AGENTS.md`.
