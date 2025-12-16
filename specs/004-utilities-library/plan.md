# Implementation Plan: Utilities Library Extraction

**Branch**: `004-utilities-library` | **Date**: 2025-12-15 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `/specs/004-utilities-library/spec.md`

## Summary

Extract sitemap utilities from `Sources/DesignSystem/Utilities/` into a dedicated `Sources/Utilities/` library target, and create a `util` CLI executable with subcommands for sitemap generation, headers validation, and state management. Uses Swift ArgumentParser for CLI structure. Workflow migration deferred to Feature 2.

## Technical Context

**Language/Version**: Swift 6.1+ with Swift Package Manager  
**Primary Dependencies**: Slipstream, swift-subprocess, swift-argument-parser (NEW - requires constitutional review)  
**Storage**: JSON state files (`Resources/sitemap-state.json`), XML sitemap output  
**Testing**: swift-testing — Unit tests for library, integration tests for CLI  
**Target Platform**: macOS 15+ (CI: GitHub Actions macOS-15)  
**Project Type**: Library + CLI executable (subtree pattern)  
**Performance Goals**: Sitemap generation < 2 seconds for all subdomains combined  
**Constraints**: Build time < 2 minutes, idempotent commands, backward compatible  
**Scale/Scope**: 3 subdomains (21-dev, docs-21-dev, md-21-dev), ~140 lines existing utilities

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Static-First | ✅ PASS | CLI is build-time tooling, not runtime |
| II. Spec-First & TDD | ✅ PASS | Spec complete, TDD for library code |
| III. Accessibility & Performance | ✅ PASS | N/A (CLI tooling) |
| IV. Design System Consistency | ✅ PASS | Utilities extracted TO separate target, not duplicated |
| V. Zero-Dependency | ⚠️ REVIEW | ArgumentParser is NEW dependency — requires justification |
| VI. Security & Privacy | ✅ PASS | No user data, no secrets in code |
| VII. Open Source Excellence | ✅ PASS | Public APIs documented, clear structure |

### Dependency Justification: swift-argument-parser

**Required by**: FR-006 (subcommand-based CLI structure)  
**Justification**: 
- Apple's official CLI library for Swift
- Build-time only (not shipped to production) — satisfies constitution MAY clause (line 163-165)
- Alternative (manual CommandLine.arguments parsing) violates KISS principle (Principle VII)
- Industry standard for Swift CLI tools

**Constitutional Review**: APPROVED (build-time tooling exception)

## Project Structure

### Documentation (this feature)

```text
specs/004-utilities-library/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (CLI interface contracts)
├── checklists/          # Quality checklists
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
Sources/
├── Utilities/                    # NEW library target
│   ├── Sitemap/
│   │   ├── SitemapGenerator.swift
│   │   ├── SitemapEntry.swift
│   │   └── SitemapValidator.swift
│   ├── Headers/
│   │   └── HeadersValidator.swift
│   ├── State/
│   │   ├── StateFile.swift
│   │   └── StateManager.swift
│   └── Shared/
│       ├── SiteConfiguration.swift
│       ├── ValidationResult.swift
│       └── XMLUtilities.swift
├── util/                         # NEW CLI executable target
│   ├── main.swift
│   ├── Commands/
│   │   ├── SitemapCommand.swift
│   │   ├── HeadersCommand.swift
│   │   └── StateCommand.swift
│   └── Shared/
│       └── CommonOptions.swift
├── DesignSystem/
│   └── Utilities/
│       └── SitemapUtilities.swift  # RE-EXPORTS from Utilities (deprecated)
└── 21-dev/
    └── SiteGenerator.swift         # Uses Utilities via DesignSystem re-export

Tests/
├── UtilitiesTests/               # NEW unit tests for Utilities library
│   ├── SitemapTests/
│   ├── HeadersTests/
│   └── StateTests/
├── UtilitiesCLITests/            # NEW integration tests for CLI
│   └── CommandTests.swift
└── DesignSystemTests/            # Existing tests (must still pass)
```

**Structure Decision**: Library + executable subtree pattern. `Utilities` is a library target consumed by `util` CLI and re-exported by `DesignSystem` for backward compatibility.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| New dependency (ArgumentParser) | Type-safe CLI with subcommands, help generation, validation | Manual parsing violates KISS, error-prone, no --help |

## Planning Clarifications (from pre-plan Q&A)

| # | Question | Answer |
|---|----------|--------|
| 1 | Testing strategy | Both unit + integration tests |
| 2 | ArgumentParser dependency | Add it (constitutional review approved above) |
| 3 | Workflow migration scope | Defer to Feature 2 (library + CLI only in this spec) |
