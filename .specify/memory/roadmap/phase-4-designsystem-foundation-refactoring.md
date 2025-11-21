# Phase 4 — DesignSystem Foundation & Refactoring

**Status:** Not Started
**Priority:** Medium
**Last Updated:** 2025-11-20

## Phase Goal

Strengthen the DesignSystem foundation with comprehensive tokens and layout primitives to reduce ClassModifier usage and prepare for theming and dark mode.

## Features

### Feature 1 — Token System Expansion
- **Name:** Token System Expansion
- **Purpose & user value:** Establish comprehensive design token library following industry standards (Material Design, Tailwind) to ensure consistent spacing, colors, shadows, and typography across all components and future sites.
- **Success metrics:**
  - 8-10 token categories implemented (Color, Spacing, Typography, Shadow, Border, ZIndex, Animation, Breakpoint)
  - All existing components refactored to use tokens (zero hardcoded values)
  - Token documentation generated automatically
  - New components default to tokens (enforced in PR reviews)
  - Design-to-code handoff time reduced by 50%
- **Dependencies:** None (foundational work).
- **Notes:** Currently only 2 token files exist (MaxWidth, ButtonStyle); industry standard requires comprehensive token system. Aligns with Constitution Principle IV (Design System Consistency).

### Feature 2 — Layout Component Library
- **Name:** Layout Component Library
- **Purpose & user value:** Provide reusable layout primitives (Container, Grid, Stack, Spacer) to eliminate ClassModifier workarounds and accelerate page development with consistent spacing patterns.
- **Success metrics:**
  - Container component with responsive max-widths
  - VStack/HStack components for vertical/horizontal layouts
  - Grid component wrapper (once Slipstream API available)
  - Spacer component for flexible spacing
  - Divider component for visual separation
  - 80%+ reduction in ClassModifier usage across codebase
- **Dependencies:** Token System Expansion (spacing scale needed), Slipstream Grid APIs (for Grid component).
- **Notes:** Memory shows Grid APIs as "NEXT PRIORITY" for Slipstream; will eliminate workarounds in SiteFooter, AboutSection, FeaturedPackageCard.

## Phase Dependencies & Sequencing

- Token System Expansion → Layout Component Library.
- Token System Expansion also feeds into Phase 6 — Dark Mode Support (after renumbering).

## Phase Metrics

This phase primarily contributes to product-level metrics for **DesignSystem Quality**, **Developer Ergonomics**, and **Accessibility**, especially:
- Token adoption reaches 100% across components; ClassModifier usage reduces by 80%+.
- Component development velocity increases significantly (time-to-build new pages drops).
- Dark mode and future theming become feasible without major refactors.
