# Tasks: Unified PR Deployment Comments

**Input**: Design documents from `/specs/007-pr-deployment-comments/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: TDD approach — test tasks precede implementation tasks.

**Organization**: Tasks grouped by user story. US1 establishes foundation; US2/US3 can run in parallel after US1.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story (US1, US2, US3)
- Exact file paths included

---

## Phase 1: Setup

**Purpose**: Project structure verification and directory setup

- [x] T001 Verify UtilLib/Models/ directory exists at `Sources/UtilLib/Models/`
- [x] T002 Verify UtilLib/Services/ directory exists at `Sources/UtilLib/Services/`

**Checkpoint**: Directory structure ready for new files

---

## Phase 2: Foundational (Models & Error Types)

**Purpose**: Core data models that ALL user stories depend on

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T003 [P] Write tests for DeploymentStatus enum and DeploymentEntry model in `Tests/UtilLibTests/Comment/DeploymentCommentTests.swift`
- [x] T004 [P] Write tests for CommentState model (encoding/decoding) in `Tests/UtilLibTests/Comment/DeploymentCommentTests.swift`
- [x] T005 Implement DeploymentStatus, DeploymentEntry, CommentState models in `Sources/UtilLib/Models/DeploymentComment.swift`
- [x] T006 Define CommentError enum (notAuthenticated, cliNotFound, apiError) in `Sources/UtilLib/Services/CommentService.swift`
- [x] T006b [P] Write tests for CommentError handling (exit codes, error messages) in `Tests/UtilLibTests/Comment/CommentServiceTests.swift`

**Checkpoint**: All models compile, tests pass. Foundation ready for service implementation.

---

## Phase 3: User Story 1 — Single Subdomain Deployment (P1) 🎯 MVP

**Goal**: Post a deployment comment for a single subdomain with status and URLs.

**Independent Test**: Run `swift run util comment --pr 1 --project 21-dev --status success --preview-url "..." --alias-url "..." --commit abc --run-url "..."` and verify comment body format.

### Tests for US1

> **Write tests FIRST, verify they FAIL before implementation**

- [x] T007 [P] [US1] Write tests for `generateCommentBody(from:)` including shared header format (commit, run-url) in `Tests/UtilLibTests/Comment/CommentServiceTests.swift`
- [x] T008 [P] [US1] Write tests for `postComment(pr:body:)` gh CLI invocation in `Tests/UtilLibTests/Comment/CommentServiceTests.swift`

### Implementation for US1

- [x] T009 [US1] Implement `generateCommentBody(from:)` — markdown table with single row in `Sources/UtilLib/Services/CommentService.swift`
- [x] T010 [US1] Implement `postComment(pr:body:)` — invoke `gh issue comment --edit-last` via Subprocess in `Sources/UtilLib/Services/CommentService.swift`
- [x] T011 [US1] Create CommentCommand with ArgumentParser flags in `Sources/util/Commands/CommentCommand.swift`
- [x] T012 [US1] Register CommentCommand in util subcommands array in `Sources/util/Util.swift`

**Checkpoint**: `swift run util comment` posts a single-subdomain comment. US1 complete and testable.

---

## Phase 4: User Story 2 — Multiple Subdomain Deployments (P1)

**Goal**: Aggregate multiple deployments into one unified comment by merging state.

**Independent Test**: Run command twice with different `--project` values, verify both appear in single comment.

**Depends on**: US1 complete (needs postComment working)

### Tests for US2

- [x] T013 [P] [US2] Write tests for `fetchExistingComments(pr:)` in `Tests/UtilLibTests/Comment/CommentServiceTests.swift`
- [x] T014 [P] [US2] Write tests for `mergeDeployment(_:into:)` in `Tests/UtilLibTests/Comment/CommentServiceTests.swift`

### Implementation for US2

- [x] T015 [US2] Implement `fetchExistingComments(pr:)` — invoke `gh issue view --json comments` in `Sources/UtilLib/Services/CommentService.swift`
- [x] T016 [US2] Implement `mergeDeployment(_:into:)` — upsert by project key in `Sources/UtilLib/Services/CommentService.swift`
- [x] T017 [US2] Update CommentCommand to fetch → merge → post flow in `Sources/util/Commands/CommentCommand.swift`

**Checkpoint**: Multiple subdomains aggregate into single comment. US2 complete.

---

## Phase 5: User Story 3 — Comment State Persistence (P2)

**Goal**: Embed/extract JSON state in hidden HTML comment for robust parsing.

**Independent Test**: Verify generated comment contains `<!-- util-deployments:{...} -->` with valid JSON.

**Can run in parallel with**: US2 (after US1 foundation complete)

### Tests for US3

- [x] T018 [P] [US3] Write tests for `parseCommentState(from:)` — extract JSON from marker in `Tests/UtilLibTests/Comment/CommentServiceTests.swift`
- [x] T019 [P] [US3] Write tests for malformed/missing JSON handling in `Tests/UtilLibTests/Comment/CommentServiceTests.swift`

### Implementation for US3

- [x] T020 [US3] Implement `parseCommentState(from:)` — string range extract `<!-- util-deployments:(...) -->` in `Sources/UtilLib/Services/CommentService.swift`
- [x] T021 [US3] Update `generateCommentBody(from:)` to embed JSON marker at start in `Sources/UtilLib/Services/CommentService.swift`
- [x] T022 [US3] Integrate parsing into fetch → parse → merge → generate → post flow in `Sources/util/Commands/CommentCommand.swift`

**Checkpoint**: JSON state persists across comment updates. US3 complete.

---

## Phase 6: Polish & Integration

**Purpose**: Workflow update and final validation

- [x] T023 Update `deploy-cloudflare.yml` — replace bash comment logic with `swift run util comment` call in `.github/workflows/deploy-cloudflare.yml`
- [x] T024 Remove old bash comment generation steps (lines 92-127) from `.github/workflows/deploy-cloudflare.yml`
- [x] T025 [P] Add CLI usage documentation to README or inline help in `Sources/util/Commands/CommentCommand.swift`
- [ ] T026 Run quickstart.md validation — manual test with real PR

**Checkpoint**: Feature complete. Workflow simplified, all tests pass.

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup) → Phase 2 (Foundational) → Phase 3 (US1) → Phase 4 (US2)
                                                        ↘ Phase 5 (US3) [parallel with US4]
                                          All stories → Phase 6 (Polish)
```

### User Story Dependencies

| Story | Depends On | Can Parallel With |
|-------|------------|-------------------|
| US1 | Foundational (Phase 2) | — |
| US2 | US1 (needs postComment) | US3 |
| US3 | US1 (needs generateCommentBody) | US2 |

### Within Each Story

1. Write tests (verify they FAIL)
2. Implement until tests pass
3. Verify story works independently

### Parallel Opportunities

**Phase 2** (can run together):
- T003 + T004 (different test cases)

**Phase 3** (can run together):
- T007 + T008 (different test cases)

**Phase 4 + 5** (can interleave after US1):
- T013 + T014 + T018 + T019 (all test tasks)
- US2 impl + US3 impl (different service methods)

---

## Parallel Example: After US1 Complete

```bash
# Developer A works on US2:
T013: Write tests for fetchExistingComments
T015: Implement fetchExistingComments
T014: Write tests for mergeDeployment
T016: Implement mergeDeployment
T017: Update command flow

# Developer B works on US3 (in parallel):
T018: Write tests for parseCommentState
T020: Implement parseCommentState
T019: Write tests for malformed JSON
T021: Update generateCommentBody with marker
T022: Integrate parsing
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational models
3. Complete Phase 3: US1 — single deployment works
4. **STOP and VALIDATE**: Test with real PR
5. Can deploy/demo with single-subdomain support

### Full Feature

1. Setup + Foundational → Foundation ready
2. US1 → Single deployment works (MVP!)
3. US2 + US3 (parallel) → Multi-subdomain + state persistence
4. Polish → Workflow updated, docs complete

### Estimated Effort

| Phase | Tasks | Est. Time |
|-------|-------|-----------|
| Setup | 2 | 10 min |
| Foundational | 5 | 50 min |
| US1 | 6 | 1.5 hr |
| US2 | 5 | 1 hr |
| US3 | 5 | 1 hr |
| Polish | 4 | 30 min |
| **Total** | **27** | **~5.25 hr** |

---

## Notes

- TDD: Write tests first, verify failure, then implement
- IaC Exemption: Workflow YAML changes (T023-T024) validated via PR execution, not unit tests
- Commit after each task or logical group
- Stop at any checkpoint to validate independently
