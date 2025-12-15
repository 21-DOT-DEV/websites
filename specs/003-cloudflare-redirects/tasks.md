# Tasks: Cloudflare _redirects Implementation

**Input**: Design documents from `/specs/003-cloudflare-redirects/`  
**Prerequisites**: plan.md (complete), spec.md (complete), research.md (complete), quickstart.md (complete)

**Tests**: IaC exemption applies per constitution. Smoke tests are automated in CI workflows (post-deployment curl verification).

**Organization**: Tasks grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This feature uses:
- **Config files**: `Resources/<SiteName>/_redirects`
- **Workflows**: `.github/workflows/generate-docc.yml`, `.github/workflows/generate-markdown.yml`
- **Output**: `Websites/<SiteName>/_redirects` (copied during CI)

---

## Phase 1: Setup

**Purpose**: No setup required — this feature uses existing project structure and workflows.

- [x] T001 [P] Verify `Resources/docs-21-dev/` directory exists
- [x] T002 [P] Verify `Resources/md-21-dev/` directory exists

**Checkpoint**: Directories confirmed — proceed to user story implementation.

---

## Phase 2: User Story 1 - Documentation Root Redirect (Priority: P1) 🎯 MVP

**Goal**: Redirect `docs.21.dev/` and `docs.21.dev/p256k` to `/documentation/`

**Independent Test**: `curl -I https://docs.21.dev/` returns 301 with `location: https://docs.21.dev/documentation/`

### Implementation for User Story 1

- [x] T003 [US1] Create `_redirects` file in `Resources/docs-21-dev/_redirects` with inline comments (FR-002, FR-003, FR-006)
- [x] T004 [US1] Add `cp` step to copy `_redirects` to output in `.github/workflows/generate-docc.yml` (FR-005)
- [x] T005 [US1] Add smoke test step with 30-second wait in `.github/workflows/deploy-cloudflare.yml` (FR-011, SC-007)

**Checkpoint**: docs.21.dev redirects functional. Deploy and verify via CI smoke test.

---

## Phase 3: User Story 2 - Markdown Site Root Redirect (Priority: P2)

**Goal**: Redirect `md.21.dev/` to `/index.md`

**Independent Test**: `curl -I https://md.21.dev/` returns 301 with `location: https://md.21.dev/index.md`

### Implementation for User Story 2

- [x] T006 [P] [US2] Create `_redirects` file in `Resources/md-21-dev/_redirects` with inline comments (FR-004, FR-006)
- [x] T007 [US2] Add `cp` step to copy `_redirects` to output in `.github/workflows/generate-markdown.yml` (FR-005)
- [x] T008 [US2] Add smoke test step with 30-second wait in `.github/workflows/deploy-cloudflare.yml` (FR-011, SC-007)

**Checkpoint**: md.21.dev redirects functional. Deploy and verify via CI smoke test.

---

## Phase 4: User Story 3 - Version-Controlled Redirect Configuration (Priority: P3)

**Goal**: Maintainers can add/modify redirects via git without Cloudflare dashboard access

**Independent Test**: Add test redirect to `_redirects`, push, verify redirect works after deployment

### Implementation for User Story 3

- [x] T009 [US3] Verify inline comments in both `_redirects` files document syntax and examples for future additions
- [x] T010 [US3] Test adding a temporary redirect rule, deploying, and verifying it works (automated via preview smoke tests)

**Checkpoint**: Documentation complete. Maintainers can self-serve redirect additions.

---

## Phase 5: Polish & Verification

**Purpose**: Final validation and cleanup

- [x] T011 Run full deployment to both subdomains and verify all smoke tests pass (automated via PR preview deployments)
- [x] T012 Verify no manual Cloudflare Page Rules needed for path-based redirects (SC-002) ✓ All path-based redirects in _redirects files
- [x] T013 Remove test redirect from T010 if added (N/A - used automated smoke tests instead)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — verification only
- **US1 (Phase 2)**: Depends on Setup
- **US2 (Phase 3)**: Depends on Setup — can run in parallel with US1
- **US3 (Phase 4)**: Depends on US1 and US2 completion (needs working `_redirects` files to document)
- **Polish (Phase 5)**: Depends on all user stories

### User Story Dependencies

- **User Story 1 (P1)**: Independent — docs.21.dev only
- **User Story 2 (P2)**: Independent — md.21.dev only (can parallelize with US1)
- **User Story 3 (P3)**: Depends on US1 + US2 (documentation of existing files)

### Within Each User Story

1. Create `_redirects` file with documented rules
2. Update workflow to copy file
3. Add smoke test to workflow
4. Deploy and verify

### Parallel Opportunities

- **T006 [P]**: Can run in parallel with T003-T005 (different subdomain, different files)
- US1 and US2 can be implemented simultaneously by different developers

---

## Parallel Example

```bash
# Developer A works on docs.21.dev (US1):
T003: Create Resources/docs-21-dev/_redirects
T004: Update .github/workflows/generate-docc.yml (copy step)
T005: Update .github/workflows/generate-docc.yml (smoke test)

# Developer B works on md.21.dev (US2) in parallel:
T006: Create Resources/md-21-dev/_redirects
T007: Update .github/workflows/generate-markdown.yml (copy step)
T008: Update .github/workflows/generate-markdown.yml (smoke test)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete T001-T002 (Setup verification)
2. Complete T003-T005 (US1: docs.21.dev)
3. **STOP and VALIDATE**: Deploy, verify curl returns 301
4. Merge if ready — docs.21.dev redirects live

### Incremental Delivery

1. US1 → Deploy → docs.21.dev working
2. US2 → Deploy → md.21.dev working
3. US3 → Verify documentation complete
4. Polish → Final verification

### Single Developer Strategy

Execute sequentially: T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008 → T009 → T010 → T011 → T012 → T013

---

## Task Decisions

Captured from pre-generation clarification:

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Task granularity | Separate per user story | Enables parallel execution, independent testability |
| Smoke test timing | 30-second wait | Reliable for Cloudflare edge propagation |
| Documentation scope | Inline comments only | FR-006 satisfied; quickstart.md exists |

---

## File Manifest

| File | Action | User Story |
|------|--------|------------|
| `Resources/docs-21-dev/_redirects` | CREATE | US1 |
| `Resources/md-21-dev/_redirects` | CREATE | US2 |
| `.github/workflows/generate-docc.yml` | MODIFY | US1 |
| `.github/workflows/generate-markdown.yml` | MODIFY | US2 |

---

## Notes

- IaC exemption applies: workflow changes validated via PR deployment, not unit tests
- All smoke tests use `curl -sI -o /dev/null -w "%{http_code}"` pattern
- 30-second sleep before smoke tests accounts for Cloudflare edge propagation
- Inline comments use `#` prefix per Cloudflare `_redirects` syntax
