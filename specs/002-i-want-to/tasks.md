# Implementation Tasks: LLM-Optimized Markdown Documentation Subdomain

**Feature Branch**: `002-i-want-to`  
**Feature Spec**: [spec.md](./spec.md)  
**Implementation Plan**: [plan.md](./plan.md)  
**Status**: Ready for Implementation

## Overview

Deploy LLM-accessible markdown documentation for swift-secp256k1 library at md.21.dev subdomain. This is a CI/CD infrastructure feature that generates DocC archives, exports to markdown via DocC4LLM, splits into individual files, and deploys to Cloudflare Pages.

**User Stories**:
- **US1 (P1)**: LLM Accesses Structured Markdown API Documentation
- **US2 (P2)**: Automatic Documentation Updates
- **US3 (P3)**: Preview Documentation Before Production Deployment

**Implementation Strategy**: Sequential phases with strict blocking for constitution amendment. No user story gets its own phase since this is infrastructure - tasks support multiple stories simultaneously.

**Total Estimated Tasks**: 8 tasks  
**Critical Path**: Constitution amendment (T001) blocks all workflow implementation

---

## Phase 1: Prerequisites & Dependencies (BLOCKING)

**Goal**: Resolve constitutional violation and add required dependencies before any workflow implementation.

**Blocks**: All subsequent phases - workflows cannot be created until DocC4LLM is constitutionally approved and added to Package.swift.

**Independent Test Criteria**:
- ✅ Constitution v1.2.0 references DocC4LLM in approved dependencies
- ✅ `swift package resolve` succeeds with DocC4LLM 1.0.0
- ✅ `swift run docc4llm --help` executes successfully

### Tasks

- [X] T001 Update constitution.md adding DocC4LLM to approved dependencies (v1.1.0 → v1.2.0) in `.specify/memory/constitution.md`
  - Add "DocC4LLM (markdown export tool)" to Principle II approved dependencies list
  - Update version footer: `Version: 1.2.0`
  - Commit message: `chore: Add DocC4LLM to constitution approved dependencies (v1.2.0)`
  - **Completion Criteria**: Constitution Check in plan.md changes from CONDITIONAL PASS to PASS

- [X] T002 Add DocC4LLM 1.0.0 exact dependency to `Package.swift`
  - Add after swift-docc-plugin: `.package(url: "https://github.com/P24L/DocC4LLM.git", exact: "1.0.0")`
  - Run `swift package resolve` to generate Package.resolved
  - Commit both Package.swift and Package.resolved
  - **Completion Criteria**: `swift run docc4llm --help` executes without error

---

## Phase 2: External Discovery Infrastructure

**Goal**: Create index files for LLM discovery following llms.txt standard and provide template for swift-secp256k1 repository.

**Supports**: US1 (LLM discovery and navigation)

**Independent Test Criteria**:
- ✅ llms.txt exists at `Resources/21-dev/llms.txt` and follows https://llmstxt.org format
- ✅ agents.md template exists and is ready to copy to swift-secp256k1 repo
- ✅ Both files reference md.21.dev URLs with correct structure

### Tasks

- [X] T003 [P] Create llms.txt for LLM discovery at `Resources/21-dev/llms.txt`
  - Follow https://llmstxt.org standard format
  - Include sections: site description, API documentation links (md.21.dev/p256k/, md.21.dev/zkp/)
  - Document file structure: `/{target}/{symbol-name}.md` pattern
  - Provide example: `https://md.21.dev/p256k/int128.md`
  - Reference: See quickstart.md for template content
  - **Validation**: Manual review against https://llmstxt.org specification (check structure, required sections, format)
  - **Completion Criteria**: File follows llms.txt standard format and references md.21.dev URLs correctly

- [X] T004 [P] Create agents.md template at `Resources/21-dev/agents-md-template.md`
  - Template for swift-secp256k1 repository (not deployed from this repo)
  - Include: module links (P256K, ZKP), documentation structure, usage instructions
  - Note: "Copy this file to swift-secp256k1 repository root as agents.md"
  - Reference: See quickstart.md for template content
  - **Completion Criteria**: Template is ready to copy with no repo-specific placeholders

---

## Phase 3: CI/CD Workflow Implementation

**Goal**: Create GitHub Actions workflows for automated markdown documentation generation and deployment.

**Supports**: US1 (generation), US2 (automation), US3 (preview)

**Dependencies**: Phase 1 MUST be complete (DocC4LLM in Package.swift)

**Independent Test Criteria**:
- ✅ Workflows pass YAML validation (GitHub Actions validator)
- ✅ Manual trigger test generates preview documentation
- ✅ PR test posts preview URL in comments
- ✅ Markdown output has 2,500+ files in correct structure

### Tasks

- [X] T005 Create generate-markdown.yml reusable workflow at `.github/workflows/generate-markdown.yml`
  - Inputs: ref (required), swift-version (optional, default "6.1")
  - Outputs: artifact-name
  - Steps: checkout, setup Swift, resolve deps, generate DocC, export markdown, validate format, split files, monitor size, create root index, upload artifact
  - Validation: Check delimiter format before splitting (FR-037)
  - Monitoring: Log warnings at 15k files/20MB (FR-038)
  - Reference: See `contracts/generate-markdown-workflow-contract.md` for complete specification
  - **Completion Criteria**: Workflow file passes GitHub Actions YAML validation (automatic when pushed; syntax errors shown in Actions tab)

- [X] T006 Create MD-21-DEV.yml orchestrator workflow at `.github/workflows/MD-21-DEV.yml`
  - Triggers: PR events (opened, synchronize, reopened, closed), workflow_dispatch
  - Path filters: Package.swift, Package.resolved, workflow files
  - Jobs: (1) generate (calls generate-markdown.yml), (2) deploy (calls deploy-cloudflare.yml)
  - Production logic: `github.event.pull_request.merged == true`
  - Secrets: CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID (already configured)
  - Reference: See `contracts/MD-21-DEV-workflow-contract.md` for complete specification
  - **Completion Criteria**: Workflow file passes GitHub Actions YAML validation (automatic when pushed; syntax errors shown in Actions tab)

---

## Phase 4: Integration Testing & Deployment

**Goal**: Validate workflows through actual execution and deploy to production.

**Supports**: US2 (automatic updates), US3 (preview validation)

**Dependencies**: Phase 3 complete (workflows exist)

**Independent Test Criteria**:
- ✅ Manual workflow run generates documentation successfully
- ✅ Preview deployment accessible and contains valid markdown
- ✅ Production deployment at md.21.dev loads successfully
- ✅ All success criteria (SC-001 through SC-010) validated

**Note**: Validation happens through PR preview workflow (constitution IaC exemption - no explicit test tasks per clarification Q1).

### Tasks

- [ ] T007 Execute manual workflow test via GitHub Actions UI
  - Navigate to Actions → MD-21-DEV.yml → Run workflow
  - Select branch: 002-i-want-to, deploy-to-production: false
  - Verify: generate job completes (<15 min), artifact uploaded (~1.2MB), deploy job completes
  - Check preview URL for: file count ~2,570, structure (p256k/*.md, zkp/*.md), root index.md exists
  - Reference: See quickstart.md "Task 4.1: Manual Trigger Test"
  - **Completion Criteria**: Preview URL loads valid markdown documentation with correct structure

- [ ] T008 Create PR and validate preview deployment workflow
  - Create PR: `gh pr create --base main --head 002-i-want-to --title "Add md.21.dev LLM documentation subdomain"`
  - Verify: workflow triggers automatically, preview URL posted in comment
  - Inspect preview: source links work, markdown syntax valid, no broken paths
  - Merge PR after reviewer approval
  - Verify: production deployment to md.21.dev within 15 minutes
  - Validate: https://md.21.dev/ loads, https://md.21.dev/p256k/int128.md loads, source links navigate to GitHub
  - Reference: See quickstart.md "Task 4.2: PR Test" and "Task 4.3: Production Test"
  - **Completion Criteria**: All 10 success criteria (SC-001 through SC-010) validated

---

## Task Dependencies

### Critical Path (Sequential)
```
T001 (Constitution) → T002 (Package.swift) → [GATE] → T005/T006 (Workflows) → T007/T008 (Testing)
```

**Gate**: Constitution amendment and Package.swift update MUST complete before workflow implementation begins.

### Parallel Opportunities

**Phase 2** (after Phase 1 gate):
- T003 [P] and T004 [P] can run in parallel (different files, no dependencies)

**Phase 3** (after Phase 1 gate):
- T005 and T006 technically independent but T006 references T005 output
- Recommend: T005 first (workflow contract is clearer), then T006

**Phase 4**:
- T007 and T008 must be sequential (T008 requires T007 validation)

### Dependency Graph by User Story

**US1: LLM Accesses Structured Markdown API Documentation**
- Prerequisites: T001, T002 (enables DocC4LLM)
- Discovery: T003, T004 (enables LLM navigation)
- Generation: T005 (creates markdown output)
- Validation: T007, T008 (confirms LLM-parseable format)

**US2: Automatic Documentation Updates**
- Prerequisites: T001, T002
- Automation: T006 (orchestrates on PR events)
- Validation: T008 (confirms automatic trigger on Package.swift changes)

**US3: Preview Documentation Before Production Deployment**
- Prerequisites: T001, T002
- Preview Logic: T006 (preview vs production deployment)
- Validation: T007, T008 (preview URL generation and review)

---

## Implementation Strategy

### MVP Scope (Minimum Viable Product)
**Target**: Achieve US1 (P1) - LLM access to markdown documentation

**MVP Tasks**: T001, T002, T003, T004, T005, T006, T007
- Deliver: Manual documentation generation capability
- Defer: T008 (full CI/CD automation via PR workflow)

**MVP Validation**:
- Constitution compliant (T001)
- DocC4LLM integrated (T002)
- LLM discovery enabled (T003, T004)
- Markdown generation works (T005, T007)
- Manual deployment succeeds (T007)

### Full Feature Delivery
**Target**: All user stories (US1, US2, US3)

**Full Tasks**: T001 → T008
- Complete automation via PR workflow (US2)
- Preview deployment validation (US3)
- Production deployment at md.21.dev

### Incremental Milestones

**Milestone 1**: Constitutional Compliance (T001, T002)
- ✅ DocC4LLM approved and integrated
- ✅ `swift run docc4llm` works
- **Unblocks**: All workflow implementation

**Milestone 2**: External Infrastructure (T003, T004)
- ✅ LLM discovery indexes created
- ✅ Ready for llms.txt deployment with 21.dev site

**Milestone 3**: Core Workflows (T005, T006)
- ✅ Documentation generation automated
- ✅ CI/CD orchestration configured
- **Enables**: Manual and automatic generation

**Milestone 4**: Production Deployment (T007, T008)
- ✅ Preview deployments validated
- ✅ Production at md.21.dev live
- ✅ All success criteria met

---

## Execution Guidelines

### Before Starting
1. Review all design documents in `specs/002-i-want-to/`:
   - `spec.md`: Functional requirements and success criteria
   - `plan.md`: Technical decisions and architecture
   - `research.md`: Technology choices and rationale
   - `contracts/`: Workflow specifications
   - `quickstart.md`: Deployment procedures

2. Verify prerequisites:
   - Cloudflare Pages project `md-21-dev` exists ✅
   - GitHub secrets configured ✅
   - Branch `002-i-want-to` active ✅

### Task Execution Order
1. **Start with T001** (constitution) - this gates everything else
2. **Then T002** (Package.swift) - confirms DocC4LLM integration
3. **Checkpoint**: Verify `swift run docc4llm --help` works before continuing
4. **Phase 2 and 3 tasks** can proceed in any order after checkpoint
5. **Phase 4 tasks** must be sequential (test, then deploy)

### Validation Per Phase
- **Phase 1**: Run `swift package resolve && swift run docc4llm --help`
- **Phase 2**: Verify files exist and content matches templates
- **Phase 3**: GitHub Actions validates YAML on push
- **Phase 4**: Full end-to-end testing via actual workflow execution

### Success Criteria Mapping
Each phase contributes to success criteria validation:

**SC-001 to SC-003** (Documentation completeness): T005, T007, T008  
**SC-004** (15-minute deployment): T008  
**SC-005** (15-minute generation): T007, T008  
**SC-006** (Zero manual intervention): T006, T008  
**SC-007** (5-minute diagnosis): T005, T006 (error handling)  
**SC-008** (Valid markdown): T007, T008  
**SC-009** (LLM extraction): T003, T004, T007  
**SC-010** (File organization): T005, T007, T008

---

## Notes

**Constitution Compliance**: This feature violates Principle II (Zero Dependencies) by adding DocC4LLM. T001 resolves this through constitutional amendment (v1.1.0 → v1.2.0).

**Infrastructure-as-Code Exemption**: Per constitution v1.1.0, GitHub Actions workflows (T005, T006) are exempt from strict TDD. Validation happens through PR-based integration testing (T007, T008).

**Reference Implementation**: Feature 001 (docs.21.dev) established the reusable workflow pattern. T005 and T006 follow the same architecture for consistency.

**Critical Path Blocker**: T001 (constitution) is the critical path blocker. No workflow implementation can begin until constitutional approval is granted and documented.

**Parallel Work**: While T001 is in review/approval, implementer can prepare by:
- Reviewing workflow contracts in `contracts/` directory
- Studying Feature 001 workflows (`.github/workflows/DOCS-21-DEV.yml`)
- Preparing T003/T004 content (does not require DocC4LLM)

**Deployment Target**: Cloudflare Pages project `md-21-dev` (pre-existing, confirmed in planning clarification Q1).

**Post-Deployment**: After T008 completes, copy `agents-md-template.md` to swift-secp256k1 repository as `agents.md` (separate repo, out of scope for this feature).

---

## Task Summary

**Total Tasks**: 8  
**Blocking Tasks**: 2 (T001, T002)  
**Parallelizable Tasks**: 2 (T003 [P], T004 [P])  
**Sequential Tasks**: 4 (T005, T006, T007, T008)

**Estimated Time**:
- Phase 1: 30-60 minutes (constitutional amendment + dependency)
- Phase 2: 30-45 minutes (create index files)
- Phase 3: 2-3 hours (workflow implementation)
- Phase 4: 1-2 hours (testing and validation)
- **Total**: 4-6 hours implementation time

**Risk Mitigation**:
- Constitution amendment (T001) may require stakeholder approval - allow extra time
- First workflow run (T007) may reveal edge cases - allocate debugging time
- Cloudflare deployment (T008) depends on external service - have rollback plan ready

**Success Definition**: All 10 success criteria (SC-001 through SC-010) validated in T008, production documentation accessible at https://md.21.dev/
