# Implementation Tasks: Sitemap Infrastructure Overhaul

**Feature**: 001-sitemap-infrastructure  
**Branch**: `001-sitemap-infrastructure`  
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)  
**Strategy**: Hybrid layered implementation with gated testing, single complete deployment

## Overview

**Total Estimated Tasks**: 54 tasks  
**Implementation Approach**: Build in horizontal layers (P1 → P2 → P3) with test checkpoints, deploy complete feature  
**Testing Strategy**: Selective testing (Swift unit tests, shellcheck, integration tests per constitution IaC exemption)

**Phase Summary**:
- Phase 1: Setup & Initialization (T001-T002) - 2 tasks
- Phase 2: Foundational Utilities (T006-T010) - 5 tasks
- Phase 3: Layer 1 - Basic Sitemap Generation (T011-T018) - 8 tasks
- Phase 4: Layer 2 - Lastmod Preservation (T019-T034) - 16 tasks
- Phase 5: Layer 3 - API Submission (T035-T046) - 12 tasks
- Phase 6: Integration & Polish (T047-T057) - 11 tasks (includes T057: refactor utilities to proper library target)

**Layer Checkpoints**:
- ✅ Layer 1 Complete: All subdomains generate valid sitemap.xml files with 100% URL coverage
- ✅ Layer 2 Complete: All sitemaps use accurate lastmod dates (git/package version); lefthook-plugin automation working
- ✅ Layer 3 Complete: All subdomain sitemaps submitted immediately on deployment
- ✅ Feature Complete: End-to-end workflow validated with immediate sitemap submissions

---

## Phase 1: Setup & Project Initialization

**Goal**: Prepare project structure, create shared utilities, establish foundation

- [X] T001 Review specification and implementation plan to understand requirements
- [X] T002 Create initial sitemap state file at `Resources/sitemap-state.json` with current swift-secp256k1 version

**Checkpoint**: Foundation ready for Layer 1 implementation (IaC-heavy feature - tests written per TDD for Swift code only)

---

## Phase 2: Foundational Utilities (Blocking Prerequisites)

**Goal**: Build shared components needed by all layers

- [X] T006 Implement XML escaping utility function in `Sources/DesignSystem/Utilities/SitemapUtilities.swift`
- [X] T007 [P] Create sitemap XML header/footer generation functions (reusable across subdomains)
- [X] T008 [P] Implement URL validation logic (HTTPS enforcement, length limits, format checks)
- [X] T009 Write unit tests for XML escaping function in `Tests/DesignSystemTests/SitemapUtilsTests.swift`
- [X] T010 Write unit tests for URL validation logic in `Tests/DesignSystemTests/SitemapUtilsTests.swift`

**Checkpoint**: Shared utilities tested and ready for use in Layer 1

---

## Phase 3: Layer 1 - Basic Sitemap Generation (User Story 1 - P1)

**Goal**: Generate valid sitemap.xml files for all three subdomains with 100% URL coverage

**User Story**: Search Engine Discovery Across All Subdomains  
**Independent Test Criteria**: All three subdomains generate valid sitemap.xml files containing 100% of their URLs

### 21.dev Sitemap Generation

- [X] T011 [P] [US1] Write unit test in `Tests/DesignSystemTests/SitemapGenerationTests.swift` for sitemap XML generation (verify protocol 0.9 structure, URL inclusion), implement `generateSitemapXML` function in `Sources/21-dev/SiteGenerator.swift` to generate sitemap.xml (TDD: 7/7 tests passing)
- [X] T012 [US1] Modified `SiteGenerator.swift` to generate `sitemap.xml`, added verification to `build-slipstream.yml` workflow (IaC: validate via PR preview)
- [X] T013 [US1] Verified `Resources/21-dev/robots.txt` already includes `Sitemap: https://21.dev/sitemap.xml` reference

### docs.21.dev Sitemap Generation

- [X] T014 [P] [US1] Add "Generate sitemap" step to `generate-docc.yml` after documentation build using `find Websites/docs-21-dev/documentation/ -name '*.html'` to discover URLs and generate sitemap.xml
- [X] T015 [P] [US1] Create `Resources/docs-21-dev/robots.txt` with `Sitemap: https://docs.21.dev/sitemap.xml` reference and add copy step to workflow

### md.21.dev Sitemap Generation

- [X] T016 [P] [US1] Add "Generate sitemap" step to `generate-markdown.yml` after markdown export using `find Websites/md-21-dev/ -name '*.md'` to discover URLs and generate sitemap.xml
- [X] T017 [P] [US1] Update robots.txt generation in `generate-markdown.yml` to include `Sitemap: https://md.21.dev/sitemap.xml` reference

### Layer 1 Validation

- [X] T018 [US1] Validate all generated sitemaps with online XML validator (sitemaps.org protocol 0.9 compliance) and confirm 100% URL coverage (IaC: validate via PR preview)

**✅ Layer 1 Checkpoint**: All subdomains generate valid sitemap.xml files with 100% URL coverage

---

## Phase 4: Layer 2 - Lastmod Preservation (User Story 2 - P2)

**Goal**: Implement accurate lastmod dates using git history (21.dev) and package version tracking (docs/md)

**User Story**: SEO-Optimized Modification Dates  
**Independent Test Criteria**: Verify git commit dates match lastmod for 21.dev; verify lastmod only changes when swift-secp256k1 package version changes for docs/md

### 21.dev Git-Based Lastmod

- [ ] T019 [P] [US2] Write unit tests for git lastmod extraction in `Tests/DesignSystemTests/GitLastModTests.swift` (mock git responses), then implement `getGitLastModDate(filePath:)` function in `Sources/21-dev/SiteGenerator.swift` using `git log -1 --format=%cI`
- [ ] T020 [P] [US2] Update `generateSitemapXML` function to call `getGitLastModDate` for each page's source file
- [ ] T021 [P] [US2] Add fallback logic: if git history unavailable, use current timestamp
- [ ] T022 [P] [US2] Verify unit tests pass and refactor if needed (red-green-refactor cycle complete)

### docs/md Package Version Tracking

- [ ] T023 [P] [US2] Update docs sitemap generation step in `generate-docc.yml` to read `Resources/sitemap-state.json` using `jq -r '.generated_date'` and use as lastmod for all URLs
- [ ] T024 [P] [US2] Update md sitemap generation step in `generate-markdown.yml` to read `Resources/sitemap-state.json` using `jq -r '.generated_date'` and use as lastmod for all URLs
- [ ] T025 [US2] Add version comparison logic to both workflows: compare Package.resolved swift-secp256k1 version with state file version, fail build with clear error if mismatch (forces lefthook-plugin to run)
- [ ] T026 [US2] Write integration test to verify lastmod preservation when package version unchanged

### Lefthook State File Automation

- [ ] T027 [US2] Add `lefthook-plugin` Swift package dependency to Package.swift (https://github.com/csjones/lefthook-plugin)
- [ ] T028 [US2] Configure `lefthook.yml` with post-checkout hook to run Swift command that updates `Resources/sitemap-state.json` when Package.resolved changes (using `jq` to compare swift-secp256k1 versions)
- [ ] T029 [US2] Test Lefthook integration: modify Package.resolved, verify state file updates automatically via Swift plugin
- [ ] T030 [US2] Document Lefthook + lefthook-plugin setup in `README.md` and `specs/001-sitemap-infrastructure/plan.md`

### Layer 2 Validation

- [ ] T031 [US2] Test git-based lastmod: modify 21.dev page, commit, rebuild, verify lastmod matches git timestamp
- [ ] T032 [US2] Test package version preservation: regenerate docs/md without version change, verify lastmod preserved
- [ ] T033 [US2] Test package version update: bump swift-secp256k1 version, verify all docs/md lastmod values update
- [ ] T034 [US2] Test state file version mismatch: manually edit state file version, trigger docs/md build, verify build fails with clear error

**✅ Layer 2 Checkpoint**: All sitemaps use accurate lastmod dates, state file automation working

---

## Phase 5: Layer 3 - API Submission (User Story 3 - P3)

**Goal**: Automate sitemap submission to Google Search Console and Bing Webmaster Tools

**User Story**: Automated Search Engine Notification  
**Independent Test Criteria**: API calls succeed with HTTP 200, submissions logged, deployments complete within 5 minutes

### Subdomain Sitemap API Submissions

- [ ] T035 [P] [US3] Add "Submit to Google" step to `build-slipstream.yml` for 21.dev sitemap using `curl -X POST https://indexing.googleapis.com/v3/urlNotifications:publish`
- [ ] T036 [P] [US3] Add "Submit to Bing" step to `build-slipstream.yml` for 21.dev sitemap using `curl -X POST https://ssl.bing.com/webmaster/api.svc/json/SubmitUrlBatch`
- [ ] T037 [P] [US3] Add "Submit to Google" step to `generate-docc.yml` for docs.21.dev sitemap
- [ ] T038 [P] [US3] Add "Submit to Bing" step to `generate-docc.yml` for docs.21.dev sitemap
- [ ] T039 [P] [US3] Add "Submit to Google" step to `generate-markdown.yml` for md.21.dev sitemap
- [ ] T040 [P] [US3] Add "Submit to Bing" step to `generate-markdown.yml` for md.21.dev sitemap
- [ ] T041 [US3] Add error handling and logging to all submission steps: capture HTTP status codes, parse responses, use `::warning::` annotations for failures, structured logs for successes, ensure non-blocking on error
- [ ] T042 [US3] Add production-only conditional `if: inputs.deploy-to-production == true` to all subdomain API submission steps in workflows
- [ ] T043 [US3] Configure GitHub Actions secrets: `GOOGLE_SEARCH_CONSOLE_API_KEY` and `BING_WEBMASTER_API_KEY` (document setup process in specs/001-sitemap-infrastructure/README.md)

### Layer 3 Validation

- [ ] T044 [US3] Test subdomain API submission with actual credentials in staging environment (verify HTTP 200 responses for all sitemaps)
- [ ] T045 [US3] Verify non-blocking behavior: simulate API failure for subdomain submission, confirm deployment continues successfully
- [ ] T046 [US3] Validate subdomain timing: confirm submissions complete within 5 minutes of each deployment

**✅ Layer 3 Checkpoint**: All sitemaps automatically submitted to Google/Bing APIs

---

## Phase 6: Integration, Polish & Cross-Cutting Concerns

**Goal**: End-to-end validation, documentation, edge case handling

### End-to-End Integration Testing

- [ ] T047 Run complete deployment workflow for all subdomains (docs, md, 21-dev)
- [ ] T048 Verify all URLs across all sitemaps are accessible (no 404s)
- [ ] T049 Check Google Search Console and Bing Webmaster Tools for successful submissions and indexed URLs

### Error Handling & Edge Cases

- [ ] T050 Test state file missing scenario: delete sitemap-state.json, regenerate docs/md, verify build fails with clear error message
- [ ] T051 Test uncommitted file scenario: create new 21.dev page without committing, verify fallback lastmod to current timestamp
- [ ] T052 Validate preview deployment behavior: trigger preview deployment with `deploy-to-production: false`, confirm subdomain sitemaps NOT submitted to APIs

### Documentation & Cleanup

- [ ] T053 Update main `README.md` with sitemap infrastructure overview and Lefthook setup instructions
- [ ] T054 Document API credential setup process in `specs/001-sitemap-infrastructure/README.md`
- [ ] T055 Create monitoring checklist: verify sitemap submission logs, check Search Console coverage reports
- [ ] T056 Final code review: check all inline comments, ensure naming consistency, verify no hardcoded values
- [ ] T057 Refactor sitemap utilities: Create new `Utilities` library target in `Package.swift`, move `Sources/DesignSystem/Utilities/SitemapUtilities.swift` to `Sources/Utilities/SitemapUtilities.swift`, update imports in tests and `21-dev` (architectural cleanup - separate infrastructure from design system)

**✅ Feature Complete**: All layers validated, documentation updated, architecture cleaned, ready for production deployment

---

## Dependency Graph

### Story Completion Order

```
Foundational (Phase 2)
    ↓
Layer 1 - P1: Basic Sitemap Generation (Phase 3)
    ↓ (all subdomains must have basic sitemaps)
Layer 2 - P2: Lastmod Preservation (Phase 4)
    ↓ (accurate dates required before notifying search engines)
Layer 3 - P3: API Submission (Phase 5)
    ↓
Integration & Polish (Phase 6)
```

**Key Dependencies**:
- Layer 2 depends on Layer 1 (can't add lastmod without basic sitemaps)
- Layer 3 depends on Layer 1 (need deployed sitemaps to submit URLs)
- Layer 3 should follow Layer 2 (don't notify search engines until lastmod is accurate)

### Parallel Execution Opportunities

**Within Layer 1** (after T010 complete):
- T011-T013 (21.dev) can run in parallel with:
- T014-T015 (docs.21.dev) can run in parallel with:
- T016-T017 (md.21.dev)

**Within Layer 2** (after T018 complete):
- T019-T021 (21.dev git lastmod) can run in parallel with:
- T022-T025 (docs/md state file logic)
- T026-T030 (Lefthook setup) depends on T022-T025

**Within Layer 3** (after T034 complete):
- T035-T040 (subdomain API submissions) can run in parallel across all workflows

**Total Parallel Tasks**: ~18 tasks (marked with [P])

---

## Implementation Strategy

### MVP Scope (Single Deployment)
All three layers (P1 + P2 + P3) deployed together as complete feature. No intermediate deployments.

### Development Flow
1. **Week 1**: Setup + Foundational + Layer 1 (T001-T018)
   - Checkpoint: All sitemaps valid with 100% URL coverage
2. **Week 2**: Layer 2 Lastmod Preservation (T019-T034)
   - Checkpoint: Accurate lastmod dates, lefthook-plugin working
3. **Week 3**: Layer 3 API Submission (T035-T046)
   - Checkpoint: All subdomain API submissions working
4. **Week 3-4**: Integration + Polish (T047-T050)
   - Checkpoint: All tests passing, edge cases handled, documentation complete, architecture refactored
5. **Deployment**: Single production deployment with complete feature

### Testing Checkpoints
- After T010: Foundational utilities tested
- After T018: Layer 1 complete - all sitemaps valid with 100% URL coverage
- After T034: Layer 2 complete - lastmod accurate, lefthook-plugin working
- After T046: Layer 3 complete - all API submissions working
- After T050: Feature complete - architecture cleaned, ready for production

### Success Criteria
- ✅ All 54 tasks completed
- ✅ All test checkpoints passed
- ✅ Constitution compliance verified
- ✅ Meets all functional requirements (FR-001 to FR-039)
- ✅ Achieves all success criteria (SC-001 to SC-008)

---

## Task Execution Notes

### Format Key
- `[P]` = Parallelizable (can run concurrently with other [P] tasks in same phase)
- `[US#]` = User Story label (US1=P1, US2=P2, US3=P3)
- File paths in task descriptions for easy execution

### Testing Approach
- Swift code: Unit tests with swift-testing framework
- Inline workflow bash: Manual review + PR preview validation (actionlint planned as future enhancement)
- Workflows: Integration tests via PR previews and deployment validation
- End-to-end: Complete workflow execution with validation

### Blocked/Unblocked Logic
- Setup (T001-T003): Can all run immediately
- Foundational (T004-T010): Can run after T003
- Layer 1 (T011-T032): Can run after T010
- Layer 2 (T019-T034): Can run after T032 (Layer 1 checkpoint)
- Layer 3 (T035-T050): Can run after T034 (Layer 2 checkpoint)
- Integration (T047-T067): Can run after T050 (Layer 3 checkpoint)

---

## Next Steps

1. Review and approve this task breakdown
2. Set up feature branch: `001-sitemap-infrastructure`
3. Begin with Setup phase (T001-T003)
4. Progress through layers sequentially with checkpoints
5. Deploy complete feature after all tests pass

**Estimated Timeline**: 4 weeks (15-20 hours per week)  
**Risk Level**: Low (infrastructure feature, well-scoped, incremental validation)  
**Deployment Strategy**: Single complete deployment after all layers validated
