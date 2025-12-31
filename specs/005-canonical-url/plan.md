# Implementation Plan: Canonical URL Management

**Branch**: `005-canonical-url` | **Date**: 2025-12-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/005-canonical-url/spec.md`

## Summary

CLI tooling (`util canonical check` and `util canonical fix`) to audit and remediate canonical URL `<link rel="canonical">` tags across generated HTML output for all subdomains. Uses SwiftSoup for robust HTML parsing, integrates with existing `util` CLI patterns, and supports CI pipeline validation via exit codes.

## Technical Context

**Language/Version**: Swift 6.1+  
**Primary Dependencies**: SwiftSoup 2.8.8 (matching Slipstream), ArgumentParser  
**Storage**: N/A (operates on filesystem HTML files)  
**Testing**: swift-testing (UtilitiesTests for unit, UtilitiesCLITests for integration)  
**Target Platform**: macOS 15+ (CI: macOS-15 GitHub Actions runners)  
**Project Type**: CLI extension to existing `util` executable  
**Performance Goals**: Process 1000+ HTML files in < 5 seconds  
**Constraints**: Zero new runtime dependencies in generated sites; build-time tooling only  
**Scale/Scope**: ~500-1000 HTML files per subdomain (21.dev, docs.21.dev, md.21.dev)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Static-First Architecture | ✅ PASS | CLI is build-time tooling; no runtime impact on generated sites |
| II. Spec-First & TDD | ✅ PASS | Spec complete; TDD required for implementation |
| III. Accessibility & Performance | ✅ PASS | SEO improvement; no accessibility impact |
| IV. Design System Consistency | ✅ PASS | Extends Utilities library, not DesignSystem |
| V. Zero-Dependency Philosophy | ⚠️ REVIEW | SwiftSoup is transitive via Slipstream; adding explicit dependency |
| VI. Security & Privacy | ✅ PASS | No user data; file operations only |
| VII. Open Source Excellence | ✅ PASS | CLI documented; follows existing patterns |

**Dependency Justification (Principle V)**:
SwiftSoup is already a transitive dependency via Slipstream (version 2.8.8). Adding it explicitly to `Utilities` target enables robust HTML parsing without adding net-new dependencies to the build. This aligns with constitution guidance: "SHOULD implement solutions using existing stack first."

## Project Structure

### Documentation (this feature)

```text
specs/005-canonical-url/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (CLI interface contracts)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
Sources/
├── Utilities/
│   ├── Canonical/
│   │   ├── CanonicalChecker.swift    # Core check logic
│   │   ├── CanonicalFixer.swift      # Core fix logic
│   │   ├── CanonicalResult.swift     # Result model
│   │   └── CanonicalURLDeriver.swift # URL derivation from paths
│   └── ... (existing sitemap, headers, state utilities)
├── util/
│   └── Commands/
│       └── CanonicalCommand.swift    # CLI command (check/fix subcommands)
└── ... (existing targets)

Tests/
├── UtilitiesTests/
│   └── CanonicalTests/
│       ├── CanonicalCheckerTests.swift
│       ├── CanonicalFixerTests.swift
│       └── CanonicalURLDeriverTests.swift
└── UtilitiesCLITests/
    ├── CanonicalCheckCLITests.swift  # Check command integration tests
    ├── CanonicalFixCLITests.swift    # Fix command integration tests
    └── CanonicalCICLITests.swift     # CI-focused integration tests
```

**Structure Decision**: Extends existing monorepo structure. New code in `Sources/Utilities/Canonical/` for library logic, `Sources/util/Commands/CanonicalCommand.swift` for CLI. Tests split between `UtilitiesTests` (unit) and `UtilitiesCLITests` (integration).

## Complexity Tracking

> No violations requiring justification. SwiftSoup dependency is pre-approved as transitive dependency via Slipstream.
