# Agent guide — `Sources/DesignSystem/`

Shared UI components, foundations, icons, layouts, models, and tokens used by
every site target. The rules in the root `AGENTS.md` apply; these are
additional.

## Component rules

- Components are simple and composable; no site-specific styling or content —
  `DesignSystem` stays agnostic of any single site.
- Layout logic lives inside the component; don't depend on parent wrappers
  for core structure.
- **Slipstream first.** Before `RawHTML`, search Slipstream's API surface
  (`W3C/Elements/`, `TextLevelSemantics/`, `Forms/`) and the typed Tailwind
  modifiers under `.build/checkouts/slipstream/`. `RawHTML` only when
  Slipstream can't express the markup — and comment why.
- Prefer typed modifiers (`.fontSize(...)`, `.display(.flex)`, `.frame(...)`)
  over raw class strings; avoid arbitrary values like `[height:123px]` unless
  tokens can't express it.
- Subfolders carry meaning: `Components/`, `Foundations/`, `Icons/`,
  `Layouts/`, `Models/`, `Tokens/`. New code goes in the right one — not
  beside it.
- Each component gets at least one integration test in a page context; render
  through `TestUtils` helpers, not ad-hoc assertions.
- Update sitemap/routing only after component tests pass.

## RawHTML audit

Periodically: `grep -r "RawHTML(" Sources/DesignSystem/`. For each hit —
replace basic elements (`Linebreak`, `Span`, `Input`, `Label`) immediately,
extract a Slipstream API for recurring patterns, and document any remaining
dynamic-HTML use with a why-comment; rebuild and test after replacements.

## Procedures

Deeper how-tos live in `Development/Workflows/` — component lifecycle (`43`),
DesignSystem management (`44`), Slipstream API development (`45`), icon
creation (`48`).
