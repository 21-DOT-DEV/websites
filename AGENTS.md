# AGENTS.md — websites

Guidance for coding agents working in this repository. Human-facing overview
lives in `README.md`; deeper scoped guidance lives in `AGENTS.md` files closer
to the code — the nearest file governs.

## What this is

A SwiftPM monorepo that builds static sites — `21.dev` renders from the
`21-dev` executable target; `docs.21.dev` assembles from `Resources/` +
generator workflows. Slipstream v2 renders pages; Tailwind compiles CSS;
shared libraries are `DesignSystem` (UI), `UtilLib`/`util` (CI utilities:
`sitemap`, `headers`, `canonical`, `comment`, `search-console`,
`agent-directive`, `links`), `SchemaLib`, and `SiteIdentity`. Output goes to
`Websites/<SiteName>/` — git-ignored, never committed.

## Commands

In zsh, prefix `swift` commands with `nocorrect` (autocorrect mangles them).

Run executables through `swift run` — never `.build/` binaries directly.

```text
nocorrect swift build                                 # build all targets
nocorrect swift test                                  # swift-testing suite
nocorrect swift test --filter DesignSystemTests       # one test target
nocorrect swift run <SiteName>                        # generate a site → Websites/<SiteName>/
nocorrect swift run util <subcommand>                 # CI utilities CLI
swift package --disable-sandbox tailwindcss \
  --input Resources/<Site>/static/style.input.css \
  --output Websites/<Site>/static/style.css \
  --config Resources/<Site>/tailwind.config.cjs      # identical to CI

vale Development/ADRs Development/Specs              # docs style rules
swift run --package-path Development/Tools plans --check   # docs index check
git diff --cached | jury --diff-file -               # AI-jury panel review (staged diff)
```

## Rules that apply everywhere

- **Clarify first.** Ambiguous input (which site, file, or environment) → ask
  before editing. Confirm the target site before site-specific changes.
- **Limit scope.** No unrelated edits, no formatting-only churn, no refactors
  unless asked.
- **Swift 6.1+ / SPM only** — the Xcode-bundled toolchain, no managers.
- **swift-testing only** — never XCTest; shared helpers live in `TestUtils`.
- **DesignSystem first** — reusable UI goes in `Sources/DesignSystem/`;
  Slipstream structured APIs before `RawHTML` (see `Sources/DesignSystem/`).
- **Tailwind baseline** — plugin-free; shared `Tailwind/preset.js`; content
  globs cover generated HTML only; `style.input.css` is the fixed entry name.
- **Stylesheets are relative** — always `./static/style.css`, never absolute.
- **Pages are structs** with a static `page` property; `@main` lives on the
  site's `SiteGenerator`; routing stays out of page content.
- **Generated files are not edited** — deployed `_headers` is selected and
  copied by the build pipeline from `_headers.<env>` sources; `sitemap.xml`
  and `style.css` are emitted by `util`/Tailwind. Edit the sources, rerun the
  generator.
- **Tests live beside their domain** — unit tests in `Tests/<Domain>Tests/`
  (`DesignSystemTests`, `UtilLibTests`, `SchemaLibTests`, `SiteIdentityTests`,
  `MiddlewareTests`); site-level integration in `IntegrationTests` /
  `UtilIntegrationTests`.
- **Monorepo migration rule** — move code directly; `grep -r` all consumers in
  `Sources/` and `Tests/` before deleting; update imports first.
- **Public APIs get `///` doc comments**; file/type names stay descriptive.
- **`Websites/` and `.build/` are never committed.** Deploy only from a clean
  `main`.
- **No linter/formatter is configured** — don't invent a SwiftFormat/swiftlint/
  stylelint step; the gate is build + tests, not lint output.
- **Dependency failures** → `swift package resolve`; stale pins →
  `swift package update`.
- **Pre-PR full check**: build → test → Tailwind compile → generate and verify
  site output → RawHTML audit. All five steps pass before opening a PR.
- **AI-jury gate**: `git diff --cached | jury --diff-file -` convenes the
  `jury.toml` panel (`.jury/policy.toml` steers it). Surviving critical/major
  findings block — fix them, or the maintainer waives with written
  justification in the commit message or PR body.

## Where deeper guidance lives

| Path | Covers |
|---|---|
| `Sources/DesignSystem/AGENTS.md` | Component and styling rules |
| `Sources/21-dev/AGENTS.md` | The 21.dev site target |
| `Tests/TestUtils/AGENTS.md` | Shared-test-helper policy |
| `Resources/AGENTS.md` | Per-site assets, headers, middleware |
| `.github/AGENTS.md` | Workflow and CI conventions |
| `Development/AGENTS.md` | Plans, ADRs, workflows docs |

Plans, roadmap, and durable decisions live in `Development/`; the few
procedures worth keeping are playbooks in `Development/Workflows/` — component
lifecycle, DesignSystem management, Slipstream API development, icon creation,
troubleshooting.
