---
trigger: always_on
description: >
  Styling and usage standards for Slipstream and Tailwind CSS in all Swift-based static sites
  within this repository. Covers idiomatic API usage, Tailwind config rules, and utility-first styling principles.
---

# Style and Usage: Slipstream + Tailwind

## Slipstream API Discovery (Prevents RawHTML misuse)
- **BEFORE using RawHTML**, search existing Slipstream APIs:
  - Check `/Sources/Slipstream/W3C/Elements/` for HTML element components
  - Search `/Sources/Slipstream/W3C/Elements/TextLevelSemantics/` for text elements (`Span`, `Linebreak`)
  - Review `/Sources/Slipstream/W3C/Elements/Forms/` for form controls (`Input`, `Label`, `Checkbox`)
- **ONLY use RawHTML** for complex dynamic HTML generation that can't be expressed with Slipstream APIs
- **DOCUMENT** any RawHTML usage with comments explaining why Slipstream APIs weren't sufficient

## Slipstream Idioms
- **ALWAYS** use structured Slipstream APIs instead of raw class strings:
  - Typography: `.fontSize(.sevenXLarge)`, `.textAlignment(.center)`, `.fontDesign(.sans)`
  - Layout: `.display(.flex)`, `.justifyContent(.center)`, `.alignItems(.center)`
  - Sizing: `.frame(height: .screen)`
- Consult local API references under `.build/checkouts/slipstream/Sources/Slipstream/TailwindCSS/` for available modifiers.
- **ALWAYS** link stylesheets using:
  ```swift
  Stylesheet(URL(string: "./static/style.css"))
  ```
  **NEVER** use absolute paths like `/static/style.css`.

## Tailwind Configuration
- All sites extend the shared preset: `Tailwind/preset.js`.
- Per-site config path: `Resources/<SiteName>/tailwind.config.cjs`.
- **Plugin policy**: Plugin-free baseline — no `@tailwindcss/*` or custom plugins unless approved in a future rule.
- Required entry CSS file:
  - Path: `Resources/<SiteName>/static/style.input.css`
  - Contents:
    ```css
    @tailwind base;
    @tailwind components;
    @tailwind utilities;
    ```
  - No alternate names (e.g., `main.css`, `tailwind.css`).

## Content Globs
- `content` must only include generated HTML and optional Markdown/text resources:
  ```javascript
  content: ["./Websites/<SiteName>/**/*.html"]
  ```
- **NEVER** include Swift source files in Tailwind config.

## Utility-First Styling Principles
1. Prefer Tailwind utilities over custom CSS classes.
2. Avoid arbitrary values (e.g., `[height:123px]`) unless tokens/utilities can't express the requirement.
3. Extract repeated class mixes into Tailwind components or use `@apply` only when repetition harms readability.
4. Limit custom CSS to typography resets, third-party embeds, or browser quirks.

## CI Consistency
- Tailwind compilation command must match exactly between local dev and CI:
  ```bash
  swift package --disable-sandbox tailwindcss --input Resources/<SiteName>/static/style.input.css --output Websites/<SiteName>/static/style.css --config Resources/<SiteName>/tailwind.config.cjs
  ```
- Cascade should prompt a fix or abort generation if new files violate path/name rules or introduce disallowed plugins.
