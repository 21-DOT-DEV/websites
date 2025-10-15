---
trigger: always_on
description: >
  Technology stack and command-line conventions for all Swift-based static sites
  in this repository, ensuring consistent tooling, commands, and build behavior.
---

# Stack and Commands

## Technology Stack
- **Swift** 6.1+ with Swift Package Manager (SPM) — no alternate build systems.
- **Slipstream** v2 for static site rendering.
- **Tailwind CSS** via `swift-plugin-tailwindcss` for styling.
- **swift-testing** package for all tests (no XCTest).
- **TestUtils** target for shared test helpers across all test targets.

## Command Conventions
- In `zsh`, **prefix all build/test commands** with `nocorrect` to avoid shell autocorrect:
  - `nocorrect swift build`
  - `nocorrect swift test`
- Keep local and CI **exactly** aligned on Tailwind CLI commands and flags.
- Use `swift run` for executable targets; **never** run compiled binaries directly from `.build`.
- Always commit with a clean build (`/85-local-full-check` workflow passing) before opening a PR.

## Anti-Churn & Clarity
- Do **not** modify unrelated files or perform refactors unless explicitly requested.
- If unsure about a command, environment, or target — **ask clarifying questions before execution**.

## Related Workflows
- **`/85-local-full-check`** — Complete build, test, compile CSS, and site generation.
- **`/32-site-generate-and-verify`** — Build site HTML/CSS/JS outputs with verification.
