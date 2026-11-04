# Agent guide — `Tests/TestUtils/`

Shared test helpers for every test target. Root `AGENTS.md` rules apply.

## Policy

- `TestUtils` is a **regular target**, not a test target — this is deliberate
  (see `Development/ADRs/0007`).
- **Never `@testable import`** — anywhere. Tests exercise public APIs; if a
  test needs internals, the API is the thing to fix.
- Prefer existing helpers (`renderHTML`, `assertValidHTMLDocument`, …) over
  ad-hoc `#expect` assertions; grep for `#expect(html.contains(` to find
  legacy patterns worth migrating.
- Helpers must stay generic and site-agnostic — no 21.dev-specific fixtures
  here; those live in that site's test target.
- All tests are `swift-testing` (`#expect`, `@Test`) — never XCTest; keep them
  deterministic and independent.
