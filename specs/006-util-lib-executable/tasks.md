# Tasks: Util CLI Architecture Alignment

**Input**: Design documents from `/specs/006-util-lib-executable/`  
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/TestHarness.md, quickstart.md

**Tests**: Explicit test tasks included per TDD requirement (clarification Q3: Option A)

**Organization**: Milestone-based phases with user story tags (clarification Q2: Option B)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions

- **Sources**: `Sources/UtilLib/`, `Sources/util/`
- **Tests**: `Tests/UtilLibTests/`, `Tests/UtilIntegrationTests/`
- **Docs**: `.windsurf/rules/`

---

## Phase 1: TestHarness Foundation (User Story 4 - P2)

**Purpose**: CLI execution infrastructure for integration testing

**Goal**: TestHarness validated and ready for integration test migration

### Tests for TestHarness (Write FIRST, verify FAIL)

- [X] T001 [P] [US4] Write test for TestHarness basic execution in Tests/UtilitiesCLITests/TestHarnessTests.swift
- [X] T002 [P] [US4] Write test for stdout capture in Tests/UtilitiesCLITests/TestHarnessTests.swift
- [X] T003 [P] [US4] Write test for stderr capture in Tests/UtilitiesCLITests/TestHarnessTests.swift
- [X] T004 [P] [US4] Write test for exit code handling in Tests/UtilitiesCLITests/TestHarnessTests.swift
- [X] T005 [P] [US4] Write test for argument passing in Tests/UtilitiesCLITests/TestHarnessTests.swift

**Checkpoint**: All TestHarness tests written and FAILING (no implementation yet)

### Implementation for TestHarness

- [X] T006 [US4] Create CommandResult struct in Tests/UtilitiesCLITests/TestHarness.swift
- [X] T007 [US4] Implement TestHarness struct with executablePath property in Tests/UtilitiesCLITests/TestHarness.swift
- [X] T008 [US4] Implement TestHarness.init() using FileManager.currentDirectoryPath in Tests/UtilitiesCLITests/TestHarness.swift
- [X] T009 [US4] Implement TestHarness.init(executablePath:) custom initializer in Tests/UtilitiesCLITests/TestHarness.swift
- [X] T010 [US4] Implement TestHarness.run(arguments:workingDirectory:) using swift-subprocess in Tests/UtilitiesCLITests/TestHarness.swift
- [X] T011 [US4] Add exit code extraction from termination status in Tests/UtilitiesCLITests/TestHarness.swift

**Checkpoint**: TestHarness tests pass, existing tests unchanged

**Validation**: `nocorrect swift test --filter TestHarness && nocorrect swift test`

---

## Phase 2: Library Rename + Consumer Updates (User Stories 1 & 2 - P1) 🎯 ATOMIC

**Purpose**: Rename Utilities→UtilLib with atomic consumer updates

**Goal**: All targets renamed, all consumers updated, all tests passing

**⚠️ CRITICAL**: All tasks in this phase must be completed in ONE commit

### Tests for Library Rename (Write FIRST, verify FAIL)

- [X] T012 [US1] Write test verifying UtilLib target exists in Package.swift validation test
- [X] T013 [US1] Write test verifying util depends on UtilLib in Package.swift validation test
- [X] T014 [US2] Write test verifying UtilLibTests uses @testable import UtilLib in test import validation
- [X] T015 [US2] Write test verifying all consumers import UtilLib in import validation test

**Checkpoint**: Validation tests written and FAILING (old structure still exists)

### Implementation for Library Rename

- [X] T016 [US1] Rename directory Sources/Utilities/ to Sources/UtilLib/ using git mv
- [X] T017 [US1] Update Package.swift: rename Utilities target to UtilLib
- [X] T018 [US1] Update Package.swift: update util dependency from Utilities to UtilLib
- [X] T019 [P] [US1] Update Sources/21-dev/*.swift: change import Utilities to import UtilLib
- [X] T020 [P] [US1] Update Sources/DesignSystem/*.swift: change import Utilities to import UtilLib
- [X] T021 [P] [US1] Update Tests/IntegrationTests/*.swift: change import Utilities to import UtilLib
- [X] T022 [P] [US1] Update Tests/DesignSystemTests/*.swift: change import Utilities to import UtilLib
- [X] T023 [US2] Rename directory Tests/UtilitiesTests/ to Tests/UtilLibTests/ using git mv
- [X] T024 [US2] Update Package.swift: rename UtilitiesTests target to UtilLibTests
- [X] T025 [US2] Update Package.swift: update UtilLibTests dependency from Utilities to UtilLib
- [X] T026 [US2] Update Tests/UtilLibTests/*.swift: change @testable import Utilities to @testable import UtilLib

**Checkpoint**: All targets renamed, all consumers updated, ALL tests pass

**Validation**: `nocorrect swift build && nocorrect swift test && nocorrect swift build --target 21-dev --target DesignSystem --target IntegrationTests --target DesignSystemTests`

---

## Phase 3: Integration Test Migration (User Story 3 - P2)

**Purpose**: Migrate to black-box UtilIntegrationTests with zero UtilLib coupling

**Goal**: Integration tests use TestHarness, no imports of UtilLib or util

### Tests for Integration Test Migration (Write FIRST, verify FAIL)

- [X] T027 [US3] Write test verifying UtilIntegrationTests has zero UtilLib dependency in Package.swift validation
- [X] T028 [US3] Write test verifying UtilIntegrationTests has zero util dependency in Package.swift validation
- [X] T029 [US3] Write test verifying no import UtilLib statements in Tests/UtilIntegrationTests/ files
- [X] T030 [US3] Write test verifying no import util statements in Tests/UtilIntegrationTests/ files

**Checkpoint**: Validation tests written and FAILING (old structure still exists)

### Implementation for Integration Test Migration

- [X] T031 [US3] Rename directory Tests/UtilitiesCLITests/ to Tests/UtilIntegrationTests/ using git mv
- [X] T032 [US3] Update Package.swift: rename UtilitiesCLITests target to UtilIntegrationTests
- [X] T033 [US3] Update Package.swift: remove UtilLib dependency from UtilIntegrationTests
- [X] T034 [US3] Update Package.swift: remove util dependency from UtilIntegrationTests
- [X] T035 [US3] Update Package.swift: remove TestUtils dependency from UtilIntegrationTests
- [X] T036 [US3] Update Package.swift: ensure only Subprocess dependency in UtilIntegrationTests
- [X] T037 [P] [US3] Update Tests/UtilIntegrationTests/CanonicalCICLITests.swift: remove import Utilities, use TestHarness
- [X] T038 [P] [US3] Update Tests/UtilIntegrationTests/HeadersCommandTests.swift: remove import Utilities, use TestHarness
- [X] T039 [P] [US3] Update Tests/UtilIntegrationTests/SitemapCommandTests.swift: remove import Utilities, use TestHarness
- [X] T040 [P] [US3] Update Tests/UtilIntegrationTests/StateCommandTests.swift: remove import Utilities, use TestHarness

**Checkpoint**: Integration tests black-box via TestHarness, zero UtilLib/util coupling, ALL tests pass

**Validation**: `nocorrect swift test --filter UtilIntegrationTests && ! grep -r "import UtilLib" Tests/UtilIntegrationTests/ && ! grep -r "import util" Tests/UtilIntegrationTests/`

---

## Phase 4: Documentation & CI Validation (User Story 5 - P3)

**Purpose**: Document actual patterns and verify production readiness

**Goal**: Architecture documented with real examples, all CI workflows pass, all success criteria satisfied

### Documentation (Write AFTER implementation with real examples)

- [X] T041 [US5] Write architecture guide in .windsurf/rules/util-architecture.md (reference actual UtilLib/, UtilLibTests/, UtilIntegrationTests/)
- [X] T042 [US5] Document ArgumentParser placement rationale with code examples from Sources/util/
- [X] T043 [US5] Document when to use UtilLibTests vs UtilIntegrationTests with actual test examples
- [X] T044 [US5] Cross-reference util architecture in .windsurf/rules/01-stack-and-commands.md

### Tests for CI Validation (Write FIRST, verify FAIL)

- [X] T045 [US5] Write test verifying no old target name references in .github/workflows/
- [X] T046 [US5] Write test verifying all 8 success criteria from spec.md satisfied
- [X] T047 [US5] Write test verifying util executable is minimal wrapper (<10 lines per SC-008)

**Checkpoint**: CI validation tests written

### Implementation for CI Validation

- [X] T048 [US5] Run full test suite: nocorrect swift test
- [X] T049 [US5] Build all targets: nocorrect swift build
- [X] T050 [US5] Verify util executable is minimal (<10 lines in Sources/util/Util.swift per SC-008)
- [X] T051 [US5] Check for old target name references in .github/workflows/ files
- [X] T052 [US5] Update any CI references to old target names (if found in DOCS-21-DEV.yml)
- [ ] T053 [US5] Push to GitHub and monitor CI status
- [ ] T054 [US5] Verify macOS-15 runner succeeds
- [ ] T055 [US5] Verify all success criteria satisfied per quickstart.md final validation

**Checkpoint**: Feature complete, documentation with real examples, all CI workflows passing

**Validation**: `test -f .windsurf/rules/util-architecture.md && gh run list --branch 006-util-lib-executable --limit 1` shows success

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (TestHarness)**: No dependencies - can start immediately
- **Phase 2 (Library Rename)**: Depends on Phase 1 TestHarness validated
- **Phase 3 (Integration Migration)**: Depends on Phase 2 library rename complete
- **Phase 4 (Documentation & CI)**: Depends on Phase 3 integration tests migrated (document actual patterns)

### User Story Dependencies

- **US4 (TestHarness - P2)**: Independent, started first (enables black-box testing)
- **US1 (Library Separation - P1)**: Depends on US4 TestHarness (enables validation)
- **US2 (Unit Test Migration - P1)**: Happens atomically with US1 in Phase 2
- **US3 (Integration Test Architecture - P2)**: Depends on US1, US2, US4 all complete
- **US5 (Documentation - P3)**: Depends on US1, US2, US3 complete (documents actual patterns)

### Within Each Phase

- Tests written FIRST, verified to FAIL
- Implementation follows tests
- Validation commands from quickstart.md run after each phase
- All tests must pass before moving to next phase

### Parallel Opportunities

**Phase 1 Tests**: All TestHarness tests can be written in parallel (T001-T005)

**Phase 2 Consumer Updates**: Consumer import updates can run in parallel (T019-T022)

**Phase 3 Integration Test Updates**: All test file updates can run in parallel (T037-T040)

**Phase 4 Documentation**: All documentation tasks can be written in parallel (T041-T044)

---

## Parallel Example: Phase 2 Consumer Updates

```bash
# After T016-T018 (structure changes), launch consumer updates in parallel:
Task T019: "Update Sources/21-dev/*.swift: change import Utilities to import UtilLib"
Task T020: "Update Sources/DesignSystem/*.swift: change import Utilities to import UtilLib"
Task T021: "Update Tests/IntegrationTests/*.swift: change import Utilities to import UtilLib"
Task T022: "Update Tests/DesignSystemTests/*.swift: change import Utilities to import UtilLib"
```

---

## Implementation Strategy

### Sequential Milestone Execution

**This refactoring is inherently sequential** - each milestone depends on the previous:

1. **Complete Phase 1**: TestHarness (~1.5 hours with tests)
   - Checkpoint: TestHarness validated, existing tests unchanged
   
2. **Complete Phase 2**: Library Rename (ATOMIC ~2.5 hours with tests)
   - Checkpoint: All consumers updated, all tests pass
   
3. **Complete Phase 3**: Integration Migration (~2 hours with tests)
   - Checkpoint: Black-box integration tests, zero coupling
   
4. **Complete Phase 4**: Documentation & CI (~1.5 hours with documentation + tests)
   - Checkpoint: Architecture documented with real examples, CI green, feature complete

**Total Estimated Time**: ~7.5 hours including all tests, documentation, and validation

### Commit Strategy (Per Clarification Q5)

This maps to 4 logical commits:

- **Commit 1**: Phase 1 complete (TestHarness)
- **Commit 2**: Phase 2 complete (library rename - ATOMIC)
- **Commit 3**: Phase 3 complete (integration migration)
- **Commit 4**: Phase 4 complete (documentation + CI)

Each commit has passing tests (per clarification Q2).

---

## Task Summary

**Total Tasks**: 55 tasks
- Phase 1 (TestHarness): 11 tasks (5 tests + 6 implementation)
- Phase 2 (Library Rename): 15 tasks (4 tests + 11 implementation)
- Phase 3 (Integration Migration): 14 tasks (4 tests + 10 implementation)
- Phase 4 (Documentation & CI): 15 tasks (4 documentation + 3 tests + 8 implementation)

**Parallel Opportunities**: 15 tasks marked [P] (27% of tasks)

**User Story Mapping**:
- US1 (Library Separation): 13 tasks
- US2 (Unit Test Migration): 6 tasks
- US3 (Integration Test Architecture): 14 tasks
- US4 (TestHarness Implementation): 11 tasks
- US5 (Documentation & CI): 9 tasks

**Test Coverage**: 20 test tasks (36% of total) ensuring TDD compliance + SC-008 validation

---

## Notes

- [P] tasks = different files, no dependencies, can run in parallel
- [Story] label maps task to specific user story for traceability
- Tests written FIRST and verified to FAIL before implementation (TDD)
- Phase 3 (Library Rename) is ATOMIC - all tasks in one commit
- Each phase has validation checkpoint from quickstart.md
- Commit after each phase with all tests passing
- Stop at any checkpoint to validate independently
- Avoid: breaking Phase 3 atomicity, skipping test tasks, moving to next phase with failing tests
