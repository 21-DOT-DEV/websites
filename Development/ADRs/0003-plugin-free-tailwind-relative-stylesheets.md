---
adr: 0003
title: Plugin-free Tailwind baseline and relative stylesheet paths
status: Accepted
date: 2025-11-13
supersedes: []
superseded_by: null
---

# Plugin-free Tailwind baseline and relative stylesheet paths

## Context

Tailwind compiles per site via `swift-plugin-tailwindcss`. Plugins would add
expressive power but also dependencies and config surface; absolute stylesheet
paths break when a site is served from a non-root path (preview builds,
subpaths).

## Decision

- Plugin-free baseline: no `@tailwindcss/*` or custom plugins without an ADR
  changing this decision.
- All sites extend the shared `Tailwind/preset.js`; per-site config at
  `Resources/<SiteName>/tailwind.config.cjs` with `content` globs covering
  generated HTML only — never Swift sources.
- `style.input.css` is the fixed entry name holding the three `@tailwind`
  directives; output is `static/style.css`.
- Stylesheets are linked relatively: `Stylesheet(URL(string:
  "./static/style.css"))` — never `/static/style.css`.
- The compile command is identical locally and in CI.

## Consequences

- Preview deploys work under any base path.
- New styling capability arrives via Slipstream utilities or a rule change,
  not by silently adding plugins.
