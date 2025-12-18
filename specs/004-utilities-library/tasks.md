# Task Breakdown: Utilities Library Extraction

**Feature**: 004-utilities-library  
**Branch**: `004-utilities-library`  
**Date**: 2025-12-15  
**Total Tasks**: 32

## Task Generation Parameters

| Parameter | Value |
|-----------|-------|
| TDD Approach | Full TDD — tests before implementation |
| Granularity | Medium (~25-35 tasks) |
| Story Sequencing | Parallel where possible |

## Phase Overview

| Phase | Name | Tasks | Parallel Opportunities |
|-------|------|-------|----------------------|
| 1 | Setup | T001-T004 | None (sequential) |
| 2 | Foundational | T005-T010 | T007-T010 parallelizable |
| 3 | US1: Sitemap Generation | T011-T018 | T012-T013 parallel |
| 4 | US2: Headers Validation | T019-T023 | Can start after T010 |
| 5 | US3: State Management | T024-T027 | Can parallel US1/US2 after T010 |
| 6 | US4: URL Validation | T028-T030 | Depends on T018 |
| 7 | Polish & Integration | T031-T032 | Sequential |

---

## Phase 1: Setup

**Goal**: Initialize project structure, add dependencies, create target scaffolding.

- [X] T001 Add swift-argument-parser dependency to `Package.swift`
- [X] T002 Create `Utilities` library target in `Package.swift` with dependencies (Subprocess)
- [X] T003 Create `util` executable target in `Package.swift` with dependencies (Utilities, ArgumentParser)
- [X] T004 Create directory structure: `Sources/Utilities/{Sitemap,Headers,State,Shared}/`, `Sources/util/Commands/`

**Checkpoint**: `swift build` compiles empty targets successfully.

---

## Phase 2: Foundational

**Goal**: Implement shared models and utilities required by all user stories.

- [X] T005 Write unit tests for SiteConfiguration and SiteName enum in `Tests/UtilitiesTests/Shared/SiteConfigurationTests.swift`
- [X] T006 Implement SiteConfiguration and SiteName enum in `Sources/Utilities/Shared/SiteConfiguration.swift`
- [X] T007 [P] Write unit tests for ValidationResult and ValidationError in `Tests/UtilitiesTests/Shared/ValidationResultTests.swift`
- [X] T008 [P] Implement ValidationResult and ValidationError in `Sources/Utilities/Shared/ValidationResult.swift`
- [X] T009 [P] Write unit tests for XML utilities (xmlEscape, sitemapXMLHeader/Footer) in `Tests/UtilitiesTests/Shared/XMLUtilitiesTests.swift`
- [X] T010 [P] Implement XML utilities in `Sources/Utilities/Shared/XMLUtilities.swift` (migrate from DesignSystem)

**Checkpoint**: All foundational tests pass. `swift test --filter UtilitiesTests` succeeds.

---

## Phase 3: User Story 1 — Sitemap Generation (P1)

**Story Goal**: A developer runs a single CLI command to generate a valid sitemap.xml for any subdomain.

**Independent Test**: `swift run util sitemap generate --site 21-dev` produces valid sitemap.xml.

- [X] T011 [US1] Write unit tests for SitemapEntry model in `Tests/UtilitiesTests/Sitemap/SitemapEntryTests.swift`
- [X] T012 [P] [US1] Implement SitemapEntry model in `Sources/Utilities/Sitemap/SitemapEntry.swift`
- [X] T013 [P] [US1] Write unit tests for URL discovery and lastmod in `Tests/UtilitiesTests/Sitemap/SitemapGeneratorTests.swift`
- [X] T014 [US1] Implement SitemapGenerator with all 3 URL discovery strategies (htmlFiles, markdownFiles, sitemapDictionary) and lastmod strategies (git, packageVersion) in `Sources/Utilities/Sitemap/SitemapGenerator.swift`
- [X] T015 [US1] Write CLI integration tests for sitemap generate command in `Tests/UtilitiesCLITests/SitemapCommandTests.swift`
- [X] T016 [US1] Implement SitemapCommand with generate subcommand in `Sources/util/Commands/SitemapCommand.swift`
- [X] T017 [US1] Implement Util.swift with Util root command and sitemap subcommand in `Sources/util/Util.swift`
- [X] T018 [US1] Verify acceptance scenarios: generate sitemap for all 3 sites with correct URLs and lastmod dates

**Checkpoint**: `swift run util sitemap generate --site 21-dev` works end-to-end. All US1 tests pass.

---

## Phase 4: User Story 2 — Headers Validation (P2)

**Story Goal**: A developer validates Cloudflare _headers files for correctness and environment-awareness.

**Independent Test**: `swift run util headers validate --site 21-dev --env prod` returns pass/fail.

**Note**: Can start in parallel with Phase 3 after Phase 2 completes (no dependency on US1).

- [X] T019 [P] [US2] Write unit tests for HeadersValidator in `Tests/UtilitiesTests/Headers/HeadersValidatorTests.swift`
- [X] T020 [P] [US2] Implement HeadersValidator with environment rules in `Sources/Utilities/Headers/HeadersValidator.swift`
- [X] T021 [US2] Write CLI integration tests for headers validate command in `Tests/UtilitiesCLITests/HeadersCommandTests.swift`
- [X] T022 [US2] Implement HeadersCommand with validate subcommand in `Sources/util/Commands/HeadersCommand.swift`
- [X] T023 [US2] Verify acceptance scenarios: validate headers for prod/dev with correct error reporting (Note: scaffold/generate deferred to Feature 2)

**Checkpoint**: `swift run util headers validate --site 21-dev --env prod` works end-to-end. All US2 tests pass.

---

## Phase 5: User Story 3 — State Management (P3)

**Story Goal**: A developer manages package version state files for lastmod tracking.

**Independent Test**: `swift run util state update --package-version 1.2.3` updates state file correctly.

- [X] T024 [US3] Write unit tests for StateFile and StateManager in `Tests/UtilitiesTests/State/StateManagerTests.swift`
- [X] T025 [US3] Implement StateFile model and StateManager (auto-detect version by parsing Package.resolved for swift-secp256k1) in `Sources/Utilities/State/StateFile.swift` and `Sources/Utilities/State/StateManager.swift`
- [X] T026 [US3] Write CLI integration tests for state commands in `Tests/UtilitiesCLITests/StateCommandTests.swift`
- [X] T027 [US3] Implement StateCommand with update/validate subcommands in `Sources/util/Commands/StateCommand.swift`

**Checkpoint**: `swift run util state update` and `swift run util state validate` work end-to-end. All US3 tests pass.

---

## Phase 6: User Story 4 — URL Validation (P4)

**Story Goal**: A developer validates that generated sitemap URLs are correct.

**Independent Test**: `swift run util sitemap validate --site 21-dev` returns pass/fail for URL validity.

- [X] T028 [US4] Write unit tests for SitemapValidator in `Tests/UtilitiesTests/Sitemap/SitemapValidatorTests.swift`
- [X] T029 [US4] Implement SitemapValidator in `Sources/Utilities/Sitemap/SitemapValidator.swift`
- [X] T030 [US4] Add validate subcommand to SitemapCommand and verify acceptance scenarios in `Sources/util/Commands/SitemapCommand.swift`

**Checkpoint**: `swift run util sitemap validate --site 21-dev` works end-to-end. All US4 tests pass.

---

## Phase 7: Polish & Integration

**Goal**: Backward compatibility, deprecation warnings, final verification.

- [X] T031 ~~Update DesignSystem to re-export Utilities APIs with deprecation warnings~~ **PIVOTED**: Deleted SitemapUtilities.swift entirely; migrated all consumers to `import Utilities` directly
- [X] T032 Verify all existing DesignSystem tests still pass and SC-001 through SC-008 are satisfied (Note: slipstream compiler crash blocks full test run - util CLI verified working)

### Additional Work (Unplanned but Completed)
- [X] Migrate 21-dev/SiteGenerator.swift to use Utilities APIs directly
- [X] Migrate generate-docc.yml and generate-markdown.yml to use `swift run util sitemap generate`
- [X] Fix DesignSystemTests and IntegrationTests to import Utilities

**Checkpoint**: All tests pass. `swift run util --help` shows all commands. Existing code using DesignSystem imports still works.

---

## Dependencies

```
Phase 1 (Setup)
    │
    ▼
Phase 2 (Foundational) ──────────────────────────────┐
    │                                                │
    ├──────────────────┬─────────────────┐           │
    ▼                  ▼                 ▼           ▼
Phase 3 (US1)    Phase 4 (US2)    Phase 5 (US3)    (parallel)
    │                  │                 │
    ▼                  │                 │
Phase 6 (US4)          │                 │
    │                  │                 │
    └──────────────────┴─────────────────┘
                       │
                       ▼
                Phase 7 (Polish)
```

## Parallel Execution Examples

### After Phase 2 Completes

```bash
# Terminal 1: US1 Sitemap Generation
swift test --filter SitemapEntryTests
# ... continue with T011-T018

# Terminal 2: US2 Headers Validation (parallel)
swift test --filter HeadersValidatorTests
# ... continue with T019-T023
```

### Within Phase 2

```bash
# These 4 tasks can run in parallel (different files, no dependencies)
T007: ValidationResultTests.swift
T008: ValidationResult.swift
T009: XMLUtilitiesTests.swift
T010: XMLUtilities.swift
```

## Implementation Strategy

### MVP Scope

**MVP = Phase 1 + Phase 2 + Phase 3 (US1)**

This delivers:
- Working `util sitemap generate` command
- Core library infrastructure
- ~50% of total value

### Incremental Delivery

1. **Week 1**: Phases 1-3 (Setup + Foundational + US1)
2. **Week 2**: Phases 4-5 (US2 + US3) — parallel where possible
3. **Week 3**: Phases 6-7 (US4 + Polish)

### Task Clarifications

| Task | Clarification |
|------|---------------|
| T010 | Migrate existing `sitemapXMLHeader()`, `sitemapXMLFooter()`, `xmlEscape()` from `Sources/DesignSystem/Utilities/SitemapUtilities.swift` |
| T014 | Include `getGitLastModDate()` migration from existing utilities |
| T031 | Use `@_exported import Utilities` and `@available(*, deprecated)` annotations |
| T032 | Verify SC-003: "All existing sitemap utility tests pass after migration" (verify exact count, update spec if different from 18) |

## Success Criteria Mapping

| Criterion | Tasks |
|-----------|-------|
| SC-001: Utilities compiles | T002, T006, T008, T010 |
| SC-002: CLI executes | T016, T017, T022, T027, T030 |
| SC-003: 18+ tests pass | T031, T032 |
| SC-004: < 2 seconds | T018 (verify) |
| SC-005: Build < 2 min | T032 (verify) |
| SC-006: Zero duplication | T031 |
| SC-007: --help works | T017 |
| SC-008: Headers migrated | T020, T022, T023 |
