---
trigger: always_on
description: >
  Repository structure for all Swift-based static sites in this repository.
  Defines placement of targets, shared code, tests, utilities, and build output.
---

# Repository Layout

## Target Layout
- **CREATE** each site as a standalone Swift executable target in `Sources/<SiteName>/`.
- **CURRENT TARGETS**: 21-dev.
- **PLACE** shared code in `Sources/DesignSystem/` (with subfolders: Components/, Icons/, Layouts/, Models/, Tokens/, Utilities/).
- **PLACE** shared test utilities in `Tests/TestUtils/` (used across all test targets).

## Test Organization
- **UNIT TESTS** go in `Tests/DesignSystemTests/`.
- **INTEGRATION TESTS** go in `Tests/IntegrationTests/` for site-level tests.

## Build Output
- **OUTPUT** generated HTML to `Websites/<SiteName>/`.
- The `Websites/` directory is git-ignored and should never be committed.

## Multi-Site Awareness
- Structure must support multiple independent sites.
- Shared code and assets should remain decoupled from site-specific targets.
