---
trigger: always_on
description: >
  Testing standards for all Swift-based static sites in this repository.
---

# Test Guidelines

## Framework
- All tests use `swift-testing` package.
- No XCTest dependencies.

## Structure
- Unit tests in `Tests/DesignSystemTests/`.
- Integration/site tests in `Tests/IntegrationTests/`.

## Practices
- Prefer `TestUtils` helpers over ad-hoc assertions.
- Test public APIs and critical workflows.
- Keep tests deterministic and independent.
