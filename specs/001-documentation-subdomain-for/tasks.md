# Implementation Tasks: Documentation Subdomain for 21.dev

**Feature**: Documentation Subdomain for 21.dev  
**Branch**: `001-documentation-subdomain-for`  
**Date**: 2025-10-15  
**Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Task Summary

**Total Tasks**: 15  
**Parallelizable**: 3 tasks  
**User Stories**: 3 (P1, P2, P3)

**Task Breakdown by Phase**:
- Setup: 3 tasks
- User Story 1 (P1): 5 tasks  
- User Story 2 (P2): 2 tasks
- User Story 3 (P3): 2 tasks
- Polish: 3 tasks

**Implementation Approach**: Sequential delivery by user story priority. Each story delivers an independently testable increment.

---

## Phase 1: Setup

**Goal**: Prepare project configuration and infrastructure for documentation feature.

**Tasks**:

- [x] T001 Update constitution to document documentation target exemption in .specify/memory/constitution.md
- [x] T002 [P] Add docs-21-dev executable target to Package.swift importing swift-secp256k1 products
- [x] T003 [P] Create Cloudflare Pages project 'docs-21-dev' with custom domain docs.21.dev

**Completion Criteria**:
- Constitution explicitly allows documentation-only targets (3-4 sentence paragraph under "Zero Dependencies")
- Package.swift includes docs-21-dev target with P256K, ZKP, libsecp256k1, libsecp256k1_zkp dependencies
- Cloudflare Pages project exists and accepts deployments
- docs.21.dev custom domain configured in Cloudflare (DNS not yet propagated)

---

## Phase 2: User Story 1 - Browse Library Documentation (Priority: P1)

**User Story**: As a developer evaluating or using the swift-secp256k1 library, I want to access comprehensive API documentation at docs.21.dev so I can understand available cryptographic functions, their parameters, return types, and usage examples without reading source code.

**Independent Test**: Visit docs.21.dev and verify all four targets (P256K, ZKP, libsecp256k1, libsecp256k1_zkp) are documented with complete API signatures, descriptions, navigation, and working source code links to GitHub.

**Tasks**:

- [x] T004 [US1] Create workflow file skeleton with triggers in .github/workflows/docs-documentation.yml
- [x] T005 [US1] Implement generate-docs job in .github/workflows/docs-documentation.yml
- [x] T006 [US1] Implement deploy-preview job in .github/workflows/docs-documentation.yml
- [x] T007 [US1] Implement deploy-production job in .github/workflows/docs-documentation.yml
- [x] T008 [US1] Test local documentation generation using command from plan.md

**Task Details**:

### T004: Create Workflow Skeleton
**File**: `.github/workflows/docs-documentation.yml`
**Implementation**:
- Add workflow name: "Documentation Generation & Deployment"
- Configure triggers:
  ```yaml
  on:
    pull_request:
      paths:
        - 'Package.swift'
        - 'Package.resolved'
    push:
      branches:
        - main
      paths:
        - 'Package.swift'
        - 'Package.resolved'
    workflow_dispatch:
  ```
- Add env variables for Cloudflare secrets
- Set permissions: `contents: read`, `deployments: write`, `pull-requests: write`

### T005: Implement generate-docs Job
**File**: `.github/workflows/docs-documentation.yml`
**Implementation**:
- Runs on: `macos-15`
- Steps:
  1. Checkout repository
  2. Resolve dependencies: `swift package resolve`
  3. Extract version from Package.resolved:
     ```bash
     SECP256K1_VERSION=$(jq -r '.pins[] | select(.identity == "swift-secp256k1") | .state.version' Package.resolved)
     echo "SECP256K1_VERSION=$SECP256K1_VERSION" >> $GITHUB_ENV
     ```
  4. Generate documentation using full command from plan.md with `$SECP256K1_VERSION` in source URL
  5. Upload artifact: `Websites/docs-21-dev/`, retention-days: 1

### T006: Implement deploy-preview Job  
**File**: `.github/workflows/docs-documentation.yml`
**Implementation**:
- Needs: `generate-docs`
- Runs on: `ubuntu-latest`
- Conditional: `if: github.event_name == 'pull_request'`
- Steps:
  1. Checkout repository
  2. Download artifact from generate-docs
  3. Deploy to Cloudflare Pages using `cloudflare/pages-action@v1`:
     - apiToken: `${{ secrets.cloudflare-api-token }}`
     - accountId: `${{ secrets.cloudflare-account-id }}`
     - projectName: `docs-21-dev`
     - directory: `Websites/docs-21-dev`
     - branch: `preview`
  4. Comment preview URL on PR

### T007: Implement deploy-production Job
**File**: `.github/workflows/docs-documentation.yml`
**Implementation**:
- Needs: `generate-docs`
- Runs on: `ubuntu-latest`
- Conditional: `if: github.event_name == 'push' && github.ref == 'refs/heads/main'`
- Steps:
  1. Checkout repository
  2. Download artifact from generate-docs
  3. Deploy to Cloudflare Pages using `cloudflare/pages-action@v1`:
     - Same config as T006 but branch: `main`

### T008: Test Local Documentation Generation
**Location**: Repository root
**Implementation**:
- Run version extraction: `jq -r '.pins[] | select(.identity == "swift-secp256k1") | .state.version' Package.resolved`
- Run full documentation generation command from plan.md
- Verify output in `Websites/docs-21-dev/`:
  - index.html exists
  - documentation/p256k/, documentation/zkp/, documentation/libsecp256k1/, documentation/libsecp256k1_zkp/ directories exist
  - Search functionality works (js/ directory exists)
  - Open index.html in browser and manually verify navigation

**Completion Criteria for User Story 1**:
- Workflow file exists and is syntactically valid
- Documentation generates successfully locally
- All 4 targets documented with public APIs
- Source code links point to correct GitHub URLs with version tag
- Search functionality works across all targets
- Preview and production deployment jobs are ready (not yet tested end-to-end)

---

## Phase 3: User Story 2 - Automatic Documentation Updates (Priority: P2)

**User Story**: As a library maintainer, I want documentation to automatically regenerate when swift-secp256k1 releases a new version, so that users always see current API information without manual intervention.

**Independent Test**: Trigger a Dependabot PR updating swift-secp256k1 version, verify CI runs documentation generation automatically, then merge and confirm production deployment to docs.21.dev.

**Tasks**:

- [ ] T009 [US2] Push workflow to feature branch and create test PR to trigger CI
- [ ] T010 [US2] Verify Dependabot PR triggers workflow when Package.resolved changes

**Task Details**:

### T009: Test Workflow on Feature Branch PR
**Implementation**:
- Commit workflow file to feature branch
- Create PR to main
- Verify workflow triggers on PR open
- Check generate-docs job completes successfully
- Check deploy-preview job deploys to Cloudflare
- Verify preview URL is posted in PR comments
- Check logs for clear error messages if any step fails

### T010: Verify Dependabot Integration
**Implementation**:
- Wait for next Dependabot PR or manually create one updating swift-secp256k1 version in Package.swift
- Verify workflow automatically triggers when Dependabot updates Package.resolved
- Confirm path filter correctly identifies Package.swift/Package.resolved changes
- Verify only swift-secp256k1 changes trigger docs workflow (not other dependencies)

**Completion Criteria for User Story 2**:
- Workflow triggers on Package.swift/Package.resolved changes
- Documentation regenerates with new swift-secp256k1 version
- CI completes within 10 minutes (SC-005)
- Dependabot PRs automatically trigger test documentation builds
- No manual intervention required

---

## Phase 4: User Story 3 - Verify Documentation Before Merge (Priority: P3)

**User Story**: As a code reviewer, I want to preview generated documentation in pull requests before merging, so I can catch formatting issues, missing docs, or broken links early.

**Independent Test**: Create test PR that updates swift-secp256k1, verify CI generates preview deployment with accessible URL, review preview documentation for quality.

**Tasks**:

- [ ] T011 [US3] Verify preview deployment URL accessibility and functionality
- [ ] T012 [US3] Test PR merge triggers production deployment to docs.21.dev

**Task Details**:

### T011: Validate Preview Deployment
**Implementation**:
- Using PR from T009, access Cloudflare preview URL from PR comment
- Verify all 4 targets are documented
- Test navigation between targets
- Click source code links and verify they navigate to correct GitHub files/lines
- Use search functionality across all targets
- Check styling renders correctly in Chrome, Firefox, Safari
- Verify all links work (no 404s)

### T012: Test Production Deployment
**Implementation**:
- Merge feature branch PR to main
- Verify deploy-production job triggers automatically
- Check deployment completes successfully
- Access docs.21.dev (may require DNS propagation time)
- Verify documentation matches preview
- Check Cloudflare Pages deployment history shows successful deployment
- Verify deployment completed within 15 minutes of merge (SC-004)

**Completion Criteria for User Story 3**:
- Preview URLs accessible and functional for all PRs
- Reviewers can validate documentation before merge
- Preview deployment succeeds and posts URL to PR
- Production deployment succeeds on merge to main
- docs.21.dev serves documentation correctly

---

## Phase 5: Polish & Cross-Cutting Concerns

**Goal**: Complete infrastructure setup and validate all success criteria.

**Tasks**:

- [ ] T013 [P] Configure DNS CNAME record for docs.21.dev → docs-21-dev.pages.dev
- [ ] T014 Verify all success criteria (SC-001 through SC-008)
- [ ] T015 Document workflow in repository README or .github/workflows/README.md

**Task Details**:

### T013: Configure DNS
**Implementation**:
- Add CNAME record in DNS provider:
  - Name: `docs`
  - Target: `docs-21-dev.pages.dev`
  - TTL: Default or 3600
- Wait for DNS propagation (up to 48 hours, typically <1 hour)
- Verify `docs.21.dev` resolves to Cloudflare Pages

### T014: Validate Success Criteria
**Implementation**:
Check each success criterion:
- **SC-001**: Load docs.21.dev and measure time to first contentful paint (<3 seconds on broadband)
- **SC-002**: Verify all public APIs from all 4 targets appear with complete signatures
- **SC-003**: Click 10+ source code links, verify 100% navigate to correct GitHub files/lines
- **SC-004**: Time full cycle from Package.swift update → docs.21.dev update (<15 minutes)
- **SC-005**: Verify Dependabot PR → test build completes (<10 minutes)
- **SC-006**: Confirm no manual steps required after Dependabot PR
- **SC-007**: Review CI error messages for clarity (create intentional failure to test)
- **SC-008**: Run Lighthouse performance test, verify score ≥90

### T015: Document Workflow
**File**: `.github/workflows/README.md` or repository README.md
**Implementation**:
- Document workflow purpose and triggers
- Explain path-based filtering for Package.swift/Package.resolved
- Document version extraction mechanism
- List required secrets (cloudflare-api-token, cloudflare-account-id)
- Provide rollback instructions (Cloudflare Pages UI → Deployments → Rollback)
- Note constitutional exemption for docs-21-dev target

**Completion Criteria for Polish Phase**:
- DNS configured and propagated
- All 8 success criteria validated and passing
- Workflow documented for future maintainers
- Feature complete and ready for merge

---

## Dependencies & Execution Order

### User Story Dependencies

```
Phase 1 (Setup)
    ↓
Phase 2 (US1 - P1) ← Must complete first (core documentation generation)
    ↓
Phase 3 (US2 - P2) ← Depends on US1 (needs working workflow)
    ↓
Phase 4 (US3 - P3) ← Depends on US1 (needs working workflow)
    ↓
Phase 5 (Polish) ← Depends on all user stories
```

**Critical Path**: T001 → T002 → T003 → T004 → T005 → T006 → T007 → T008 → T009 → T012 → T013 → T014

**Parallel Opportunities**:
- T002 and T003 can run in parallel after T001
- T013 can start anytime after T003 (DNS propagation takes time)

### Task Dependencies Graph

```
T001 (Constitution)
  ├─→ T002 (Package.swift) ────┐
  └─→ T003 (Cloudflare setup)  │
         └─→ T013 (DNS) ───────┤
                                ├─→ T004 (Workflow skeleton)
                                      ├─→ T005 (generate-docs job)
                                      ├─→ T006 (deploy-preview job)
                                      └─→ T007 (deploy-production job)
                                            ├─→ T008 (Local test)
                                            └─→ T009 (Feature PR test)
                                                  ├─→ T010 (Dependabot test)
                                                  ├─→ T011 (Preview validation)
                                                  └─→ T012 (Production test)
                                                        └─→ T014 (Success criteria)
                                                              └─→ T015 (Documentation)
```

---

## Parallel Execution Examples

### Setup Phase (Tasks 1-3)
**Parallel**:
- T001: Update constitution
- (After T001) T002 + T003 in parallel:
  - T002: Update Package.swift
  - T003: Create Cloudflare project

### User Story 1 - Workflow Implementation (Tasks 4-8)
**Sequential** (workflow file must be built incrementally):
1. T004: Skeleton
2. T005: Generate job
3. T006: Preview job  
4. T007: Production job
5. T008: Local test

### Polish Phase
**Parallel Start**:
- T013: DNS (long running, start early)
- T014: Begin validation as soon as T012 completes

---

## Implementation Strategy

### MVP Scope (Minimum Viable Product)
**Includes**: Phase 1 + Phase 2 (User Story 1 only)
- Updates constitution and Package.swift
- Creates Cloudflare project
- Implements complete workflow
- Tests local documentation generation
- **Result**: Documentation can be generated and deployed manually

### Full Feature (All User Stories)
**Includes**: All phases (1-5)
- Adds automated Dependabot integration (US2)
- Adds preview deployment validation (US3)
- Completes DNS and documentation
- **Result**: Fully automated documentation pipeline with zero manual intervention

### Incremental Delivery Path
1. **Week 1**: Complete Setup + US1 (T001-T008) → Documentation works locally and via manual workflow trigger
2. **Week 2**: Complete US2 (T009-T010) → Automated Dependabot integration
3. **Week 3**: Complete US3 + Polish (T011-T015) → Full production-ready system

---

## Validation & Testing

### Manual Validation Per Phase

**After Phase 1**:
- Constitution contains documentation exemption paragraph
- Package.swift compiles with docs-21-dev target
- Cloudflare Pages project exists

**After Phase 2 (US1)**:
- `swift package generate-documentation` succeeds locally
- Workflow file syntax is valid (GitHub Actions workflow validator)
- All 4 targets documented
- Source links point to correct version tag

**After Phase 3 (US2)**:
- Dependabot PR triggers workflow automatically
- CI completes in <10 minutes
- Documentation updates without manual intervention

**After Phase 4 (US3)**:
- Preview URL accessible from PR comments
- Preview documentation quality validated by reviewer
- Production deployment succeeds on merge

**After Phase 5 (Polish)**:
- All 8 success criteria pass
- docs.21.dev accessible via custom domain
- Lighthouse score ≥90

### Rollback Testing
- Test Cloudflare Pages rollback via UI
- Verify previous deployment can be restored
- Document rollback procedure in T015

---

## Notes

### Constitutional Compliance
Per FR-026 and FR-027, this feature requires constitutional update before merge. The docs-21-dev target is exempt from the zero-dependency principle as it imports packages solely for documentation generation purposes.

### No New Swift Package Dependencies
This feature adds NO new dependencies beyond swift-docc-plugin (already approved). The docs-21-dev target imports swift-secp256k1 for documentation only, not for runtime execution.

### Preserving Existing Workflows
Per FR-015, this workflow must not interfere with existing 21-DEV.yml or cloudflare-deployment.yml workflows. Path-based triggers ensure only Package.swift/Package.resolved changes trigger documentation workflow.

### jq Dependency
Assumed pre-installed on macOS-15 GitHub runners per FR-028. If workflow fails with "jq: command not found", add installation step: `brew install jq` before version extraction.

### Future Enhancements
- Multi-repository documentation (different --source-service-base-url per target)
- Custom landing page (enhanced branding and navigation)
- Documentation metrics (Cloudflare Analytics integration)
- Automated link checking (detect 404s in generated docs)
