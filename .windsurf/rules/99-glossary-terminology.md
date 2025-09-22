---
trigger: always_on
description: >
---

# Glossary & Terminology

## Sites & Targets
- **21.dev** — primary developer-focused site.
- **21-dev** — Swift executable target name for 21.dev site.

## DesignSystem Structure
- **DesignSystem** — shared UI components and layout code.
- **Components/** — reusable UI components (SiteHeader, SiteFooter, etc.).
- **Icons/** — icon system and SVG components (SocialIcon, etc.).
- **Layouts/** — page-level layout containers.
- **Models/** — data models for components (FooterModels, NavigationModels, etc.).
- **Tokens/** — design tokens and shared styling constants (StyleTokens, LayoutTokens).

## Technology Stack
- **Slipstream** — Swift-based static site framework.
- **TestUtils** — shared testing helpers module.
- **swift-testing** — testing framework (not XCTest).
- **swift-plugin-tailwindcss** — Tailwind CSS integration for Swift.

## Commands & Tools
- **nocorrect** — zsh prefix to disable autocorrect for commands.
- **SPM** — Swift Package Manager.

## Configuration
- **Tailwind preset** — shared configuration file: `Tailwind/preset.js`.
- **Site config** — per-site Tailwind config: `Resources/<SiteName>/tailwind.config.cjs`.

## Workflow References
- **`/85-local-full-check`** — complete build, test, CSS, and site generation cycle.
- **`/32-site-generate-and-verify`** — generate and verify site output.
- **`/43-component-full-cycle`** — complete component development workflow.

## Output & Build
- **Websites/** — git-ignored build output directory.
- **style.css** — compiled Tailwind CSS output file.