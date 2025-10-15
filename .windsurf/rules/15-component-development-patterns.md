---
trigger: always_on
description: >
  Standards for creating, testing, and integrating DesignSystem components.
---

# Component Development Patterns

## Design
- Build components with simple, composable APIs.
- Avoid embedding site-specific styling or content.

## Implementation
- Use Slipstream idioms and Tailwind utilities for styling.
- Keep layout logic in the component; do not rely on parent wrappers for core structure.

## Testing
- Use `TestUtils` for rendering and assertions.
- Include at least one integration test showing the component in a page context.

## Integration
- Update sitemap or routing only after component tests pass.
