---
adr: 0007
title: swift-testing only, with TestUtils as a regular target
status: Accepted
date: 2025-11-13
supersedes: []
superseded_by: null
---

# swift-testing only, with TestUtils as a regular target

## Context

Two test frameworks can't share helpers cleanly, and shared assertions kept
either being duplicated or hidden behind `@testable import` hacks.

## Decision

- All tests use `swift-testing` — no XCTest, ever.
- `Tests/TestUtils/` is a regular (non-test) target exposing helpers like
  `renderHTML` and `assertValidHTMLDocument`; every test target imports it
  normally.
- `@testable import` is forbidden; tests exercise public APIs. Helpers stay
  site-agnostic; tests stay deterministic and independent.

## Consequences

- Assertion style is uniform (`#expect`, `TestUtils` helpers); grep for
  `#expect(html.contains(` finds violations to migrate.
- Public-API testing keeps module boundaries honest — when a test needs
  internals, the API is what needs fixing.
