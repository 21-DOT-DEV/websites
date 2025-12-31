# Tasks: Canonical URL Management

**Input**: Design documents from `/specs/005-canonical-url/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: TDD approach — test tasks precede implementation tasks (per constitution)

**Organization**: Tasks grouped by user story. MVP = US1 + US2 (Check + Basic Fix)

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: User story label (US1, US2, US3, US4)
- Paths follow plan.md structure

---

## Phase 1: Setup

**Purpose**: Add SwiftSoup dependency and create directory structure

- [x] T001 Add SwiftSoup dependency to Package.swift (version 2.8.8 matching Slipstream)
- [x] T002 Add SwiftSoup to Utilities target dependencies in Package.swift
- [x] T003 Create directory structure: Sources/Utilities/Canonical/
- [x] T004 [P] Create directory structure: Tests/UtilitiesTests/CanonicalTests/
- [x] T005 Verify build succeeds with `swift build`

**Checkpoint**: Dependencies configured, directories created, build passes

---

## Phase 2: Foundational (Shared Models)

**Purpose**: Core data types used by all user stories

**⚠️ CRITICAL**: All user stories depend on these models

### Tests for Foundational

- [x] T006 [P] Write tests for CanonicalStatus enum in Tests/UtilitiesTests/CanonicalTests/CanonicalStatusTests.swift
- [x] T007 [P] Write tests for CanonicalResult struct in Tests/UtilitiesTests/CanonicalTests/CanonicalResultTests.swift
- [x] T008 [P] Write tests for CanonicalURLDeriver in Tests/UtilitiesTests/CanonicalTests/CanonicalURLDeriverTests.swift

### Implementation for Foundational

- [x] T009 [P] Implement CanonicalStatus enum in Sources/Utilities/Canonical/CanonicalStatus.swift
- [x] T010 [P] Implement CanonicalResult struct in Sources/Utilities/Canonical/CanonicalResult.swift
- [x] T011 Implement CanonicalURLDeriver in Sources/Utilities/Canonical/CanonicalURLDeriver.swift (URL derivation from paths)
- [x] T012 Verify foundational tests pass with `swift test --filter CanonicalStatus && swift test --filter CanonicalResult && swift test --filter CanonicalURLDeriver`

**Checkpoint**: Core models implemented and tested. User story implementation can begin.

---

## Phase 3: User Story 1 - Audit Canonical URLs (Priority: P1) 🎯 MVP

**Goal**: `util canonical check` command to scan HTML files and report canonical URL status

**Independent Test**: Run `swift run util canonical check --path ./test-fixtures --base-url https://test.dev` and verify categorized output

### Tests for User Story 1

- [x] T013 [P] [US1] Write tests for CheckReport struct in Tests/UtilitiesTests/CanonicalTests/CheckReportTests.swift
- [x] T014 [P] [US1] Write tests for CanonicalChecker in Tests/UtilitiesTests/CanonicalTests/CanonicalCheckerTests.swift
- [x] T015 [US1] Write CLI integration tests for check command in Tests/UtilitiesCLITests/CanonicalCheckCLITests.swift

### Implementation for User Story 1

- [x] T016 [P] [US1] Implement CheckReport struct in Sources/Utilities/Canonical/CheckReport.swift
- [x] T017 [US1] Implement CanonicalChecker in Sources/Utilities/Canonical/CanonicalChecker.swift (HTML parsing with SwiftSoup, file scanning, categorization)
- [x] T018 [US1] Implement CanonicalCommand.Check subcommand in Sources/util/Commands/CanonicalCommand.swift (--path, --base-url, --verbose flags)
- [x] T019 [US1] Add human-readable output formatting with emoji indicators (✅ ⚠️ ❌) in CanonicalCommand.swift
- [x] T020 [US1] Implement exit code logic (0 for all valid, 1 for issues) in CanonicalCommand.swift
- [x] T021 [US1] Register CanonicalCommand in Sources/util/Util.swift subcommands array
- [x] T022 [US1] Verify US1 tests pass and manual test: `swift run util canonical check --path ./Websites/21-dev --base-url https://21.dev -v`

**Checkpoint**: Check command functional. Can audit any site for canonical URL issues.

---

## Phase 4: User Story 2 - Add Missing Canonicals (Priority: P2) 🎯 MVP

**Goal**: `util canonical fix` command to add missing canonical tags (without overwriting existing)

**Independent Test**: Run `swift run util canonical fix --path ./test-fixtures --base-url https://test.dev --dry-run` and verify preview output

### Tests for User Story 2

- [x] T023 [P] [US2] Write tests for FixResult and FixAction in Tests/UtilitiesTests/CanonicalTests/FixReportTests.swift
- [x] T024 [P] [US2] Write tests for CanonicalFixer in Tests/UtilitiesTests/CanonicalTests/CanonicalFixerTests.swift
- [x] T025 [US2] Write CLI integration tests for fix command in Tests/UtilitiesCLITests/CanonicalFixCLITests.swift

### Implementation for User Story 2

- [x] T026 [P] [US2] Implement FixResult and FixAction in Sources/Utilities/Canonical/FixResult.swift
- [x] T027 [P] [US2] Implement FixReport struct in Sources/Utilities/Canonical/FixReport.swift
- [x] T028 [US2] Implement CanonicalFixer in Sources/Utilities/Canonical/CanonicalFixer.swift (tag insertion at end of head)
- [x] T029 [US2] Implement CanonicalCommand.Fix subcommand in Sources/util/Commands/CanonicalCommand.swift (--path, --base-url, --dry-run flags)
- [x] T030 [US2] Add dry-run preview output in CanonicalCommand.swift (show what would change)
- [x] T031 [US2] Verify US2 tests pass and manual test: `swift run util canonical fix --path ./test-fixtures --base-url https://test.dev --dry-run`

**Checkpoint**: MVP Complete! Check + Fix commands functional. Can audit and remediate canonical URLs.

---

## Phase 5: User Story 3 - Force Update All Canonicals (Priority: P3)

**Goal**: `--force` flag to overwrite all existing canonical tags (for domain migrations)

**Independent Test**: Run fix with `--force` on files with existing canonicals and verify all are updated

### Tests for User Story 3

- [x] T032 [US3] Write tests for force-update behavior in Tests/UtilitiesTests/CanonicalTests/CanonicalFixerTests.swift (extend existing)

### Implementation for User Story 3

- [x] T033 [US3] Implement --force flag handling in CanonicalFixer.swift (overwrite existing canonicals)
- [x] T034 [US3] Update CanonicalCommand.Fix to pass force flag to fixer in Sources/util/Commands/CanonicalCommand.swift
- [x] T035 [US3] Verify US3 tests pass and manual test: `swift run util canonical fix --path ./test-fixtures --base-url https://new-domain.dev --force`

**Checkpoint**: Force update functional. Domain migration use case supported.

---

## Phase 6: User Story 4 - CI Pipeline Integration (Priority: P2)

**Goal**: Reliable exit codes and output suitable for CI automation

**Independent Test**: Simulate CI environment and verify exit codes match expected behavior

### Tests for User Story 4

- [x] T036 [US4] Write CI-focused integration tests in Tests/UtilitiesCLITests/CanonicalCICLITests.swift (exit codes, error handling)

### Implementation for User Story 4

- [x] T037 [US4] Ensure consistent exit codes in error scenarios in Sources/util/Commands/CanonicalCommand.swift
- [x] T038 [US4] Add input validation with clear error messages (--path exists, --base-url valid scheme)
- [x] T039 [US4] Verify US4 tests pass

**Checkpoint**: CI-ready. Commands work reliably in automated pipelines.

---

## Phase 7: Polish & Documentation

**Purpose**: Final quality improvements and documentation

- [x] T040 [P] Update README or add CLI documentation for canonical commands
- [x] T041 [P] Add edge case handling tests (no `<head>`, multiple canonicals, binary files) in Tests/UtilitiesTests/CanonicalTests/
- [x] T042 Run full test suite: `swift test`
- [x] T043 Run quickstart.md validation: manually execute all example commands
- [x] T044 Performance validation: test with 1000+ HTML files completes in < 5 seconds

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundational) → Phases 3-6 (User Stories) → Phase 7 (Polish)
                                          ↓
                              US1 → US2 (MVP complete)
                                    ↓
                              US3, US4 (can parallel after US2)
```

### User Story Dependencies

| Story | Depends On | Can Start After |
|-------|------------|-----------------|
| US1 (Check) | Foundational | Phase 2 complete |
| US2 (Fix) | US1 (uses CanonicalChecker) | T022 complete |
| US3 (Force) | US2 (extends Fix) | T031 complete |
| US4 (CI) | US1, US2 | T022 complete (can parallel with US3) |

### Within Each Phase

1. Tests MUST be written and FAIL before implementation
2. Models/enums before services
3. Library code before CLI code
4. Core implementation before polish

### Parallel Opportunities

**Phase 2 (Foundational)**:
- T006, T007, T008 can run in parallel (different test files)
- T009, T010 can run in parallel (different source files)

**Phase 3 (US1)**:
- T013, T014 can run in parallel (different test files)

**Phase 4 (US2)**:
- T023, T024 can run in parallel (different test files)
- T026, T027 can run in parallel (different source files)

**After MVP**:
- US3 and US4 can run in parallel (different concerns)

---

## Parallel Example: Phase 2 Foundational

```bash
# Run all foundational tests in parallel:
swift test --filter CanonicalStatusTests &
swift test --filter CanonicalResultTests &
swift test --filter CanonicalURLDeriverTests &
wait

# Implement models in parallel (different files):
# T009: CanonicalStatus.swift
# T010: CanonicalResult.swift
```

---

## Implementation Strategy

### MVP First (US1 + US2)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: Foundational (T006-T012)
3. Complete Phase 3: User Story 1 - Check (T013-T022)
4. Complete Phase 4: User Story 2 - Fix (T023-T031)
5. **STOP and VALIDATE**: Test both commands independently
6. Deploy/demo if ready — MVP complete!

### Incremental Delivery

1. Setup + Foundational → Core models ready
2. Add US1 (Check) → Can audit sites → Demo
3. Add US2 (Fix) → Can remediate issues → Demo (MVP!)
4. Add US3 (Force) → Domain migration support → Demo
5. Add US4 (CI) → Automation ready → Demo

---

## Task Summary

| Phase | Tasks | Parallel |
|-------|-------|----------|
| Setup | 5 | 1 |
| Foundational | 7 | 6 |
| US1 (Check) | 10 | 3 |
| US2 (Fix) | 9 | 4 |
| US3 (Force) | 4 | 0 |
| US4 (CI) | 4 | 0 |
| Polish | 5 | 2 |
| **Total** | **44** | **16** |

**MVP Scope**: T001-T031 (31 tasks)

---

## Notes

- All tests use swift-testing framework (not XCTest)
- SwiftSoup version 2.8.8 must match Slipstream
- Canonical tag insertion: append to end of `<head>` for compatibility
- Human-readable output with emoji (✅ ⚠️ ❌) per CLI contract
- Exit code 0 = success, 1 = issues found or errors
