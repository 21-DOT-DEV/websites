---
trigger: always_on
description: >
  Rules for the `TestUtils` module and its usage in tests.
---

# TestUtils Policy

## Purpose
- Shared helpers for rendering HTML, validating structure, and common assertions.

## Import Rules
- `TestUtils` is a regular target, not a test target.
- **NEVER** use `@testable import` in `TestUtils`.

## Preferred APIs
- Use `TestUtils.renderHTML`, `assertValidHTMLDocument`, etc., instead of manual `#expect` checks.
- Search for `#expect(html.contains(` to find violations.

## Maintenance
- Keep helpers generic and reusable across all sites.
