# Implementation Plan: LLM-Optimized Markdown Documentation Subdomain

**Branch**: `002-i-want-to` | **Date**: 2025-10-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-i-want-to/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Deploy LLM-accessible markdown documentation for swift-secp256k1 library at md.21.dev subdomain. Generate DocC archive from P256K and ZKP targets, export to markdown via DocC4LLM tool, split concatenated output into 2,500+ individual per-symbol files organized in two-level hierarchy (target/symbol.md), and deploy to Cloudflare Pages. External discovery via llms.txt at 21.dev and agents.md template for swift-secp256k1 repo.

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Swift 6.1+, Shell (bash/awk for splitting), YAML (GitHub Actions)
**Primary Dependencies**: swift-docc-plugin 1.4.5, DocC4LLM 1.0.0 (exact pinning), swift-secp256k1 0.21.1
**Storage**: Cloudflare Pages (static files), GitHub Actions artifacts (1-day retention)
**Testing**: Integration testing via PR preview deployments (IaC exemption per Constitution v1.1.0)
**Target Platform**: macOS-15 GitHub Actions runners, Cloudflare Pages CDN
**Project Type**: CI/CD infrastructure + static site generation (no application code)
**Performance Goals**: Documentation generation + export + deployment within 15 minutes total
**Constraints**: <25MB deployment size, <20,000 files (Cloudflare limits), minimal CI logging
**Scale/Scope**: 2,500+ markdown files, 2 documentation targets (P256K, ZKP), synchronized with docs.21.dev workflow triggers

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Constitution Version**: 1.1.0

### Principle I: Design System First
**Status**: ✅ PASS (Not Applicable)  
**Rationale**: This feature generates documentation infrastructure (CI/CD workflows, markdown files). No UI components being built. DesignSystem not involved.

### Principle II: Zero Dependencies
**Status**: ⚠️ REQUIRES AMENDMENT  
**Issue**: Adding DocC4LLM 1.0.0 to Package.swift dependencies (currently only allows: Slipstream, swift-plugin-tailwindcss, swift-docc-plugin, swift-testing, swift-secp256k1).  
**Justification**: DocC4LLM is essential for markdown export from .doccarchive format. No alternative exists in approved stack.  
**Mitigation**: FR-029 requires constitution amendment to add DocC4LLM to approved list. FR-030 documents planned migration to Swift plugin (build-time only dependency). Task included in implementation to update constitution.md.  
**Gate Action**: BLOCKED until constitution amendment task completes (Task 1 in Phase 0).

### Principle III: Test-First Development (NON-NEGOTIABLE)
**Status**: ✅ PASS (Exempt per v1.1.0)  
**Rationale**: This feature creates Infrastructure-as-Code (GitHub Actions workflows `.github/workflows/generate-markdown.yml`, `.github/workflows/MD-21-DEV.yml`). Constitution v1.1.0 amendment explicitly exempts IaC from strict TDD.  
**Alternative Validation**: Integration testing via PR preview deployments (FR-018, FR-023). Workflows validated through actual execution on GitHub Actions runners with preview URL verification.  
**Syntax Validation**: YAML linting via GitHub Actions workflow validator.  
**Business Logic**: awk split script will have unit tests if extracted to separate file >10 lines (per exemption guidelines).

### Principle IV: Static Site Architecture
**Status**: ✅ PASS  
**Rationale**: Generates pure static markdown files. No server-side rendering, no runtime frameworks, no JavaScript. Output deployed to Cloudflare Pages CDN. Fully compliant with static-first architecture.

### Principle V: Slipstream API Preference
**Status**: ✅ PASS (Not Applicable)  
**Rationale**: No UI implementation in this feature. Only markdown file generation. Slipstream not involved.

### Principle VI: Swift 6 + SPM Standards
**Status**: ✅ PASS  
**Rationale**: Uses Swift 6.1+ toolchain on macOS-15 runners. DocC4LLM added to Package.swift and invoked via `swift run docc4llm export`. Follows SPM conventions.

### Summary
**Overall Status**: ⚠️ **CONDITIONAL PASS** - Blocked on constitution amendment (Task 1)  
**Action Required**: Complete constitution.md update adding DocC4LLM to approved dependencies before proceeding with workflow implementation.

## Project Structure

### Documentation (this feature)

```
specs/002-i-want-to/
├── spec.md              # Feature specification (complete)
├── plan.md              # This file (/speckit.plan output)
├── research.md          # Phase 0: Technology decisions
├── data-model.md        # Phase 1: N/A (no data model for infrastructure)
├── quickstart.md        # Phase 1: Deployment instructions
├── contracts/           # Phase 1: Workflow schemas/validation
│   ├── generate-markdown-schema.yml
│   └── split-validation-spec.md
├── checklists/          # Validation checklists
│   └── requirements.md  # Complete
└── tasks.md             # Phase 2: NOT created by /speckit.plan
```

### Repository Structure (infrastructure files)

```
websites/ (repository root)
├── .github/workflows/
│   ├── generate-docc.yml           # Existing (reused)
│   ├── deploy-cloudflare.yml       # Existing (reused)
│   ├── DOCS-21-DEV.yml            # Existing (reference)
│   ├── generate-markdown.yml       # NEW: Generate + export + split markdown
│   └── MD-21-DEV.yml              # NEW: Orchestrate markdown workflow
│
├── .specify/memory/
│   └── constitution.md             # UPDATED: Add DocC4LLM to approved deps
│
├── Package.swift                   # UPDATED: Add DocC4LLM 1.0.0 exact
│
├── Resources/21-dev/
│   ├── llms.txt                    # NEW: LLM discovery index (llms.txt standard)
│   └── agents-md-template.md       # NEW: Template for swift-secp256k1 repo
│
├── Archives/                       # Temporary (CI only, gitignored)
│   └── md-21-dev.doccarchive       # Generated then exported (auto-cleaned)
│
└── Websites/                       # Build output (gitignored)
    └── md-21-dev/                  # NEW: Markdown documentation output
        ├── index.md                # Root index for human visitors
        ├── p256k.md                # P256K module overview
        ├── p256k/                  # 1,285 symbol files
        │   ├── int128.md
        │   ├── uint256.md
        │   └── ...
        ├── zkp.md                  # ZKP module overview
        └── zkp/                    # 1,285 symbol files
            └── ...
```

**Structure Decision**: CI/CD Infrastructure Feature

This feature does not add application code. It creates GitHub Actions workflows for documentation generation and static file deployment. The workflows follow the reusable pattern established by Feature 001 (docs.21.dev):
- `generate-markdown.yml`: Reusable workflow for DocC generation → markdown export → file splitting
- `MD-21-DEV.yml`: Orchestrator calling generate + deploy workflows
- `deploy-cloudflare.yml`: Existing reusable workflow (unchanged)

Output structure (`Websites/md-21-dev/`) follows two-level hierarchy (FR-026, FR-027) for LLM optimization.

## Complexity Tracking

*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Adding DocC4LLM dependency (Principle II) | Only tool that exports .doccarchive to markdown format. Requirement FR-003 specifies markdown export for LLM consumption. | Manual HTML parsing from DocC output: brittle, unmaintainable, would require custom Swift parser duplicating DocC4LLM functionality. Building custom exporter: scope creep, weeks of work to replicate existing tool. Using DocC HTML directly: violates FR-025 (machine-readable format), LLMs can't effectively parse interactive HTML/JS. |
| Temporary executable dependency in Package.swift | DocC4LLM invoked via `swift run docc4llm` during CI workflows. Enables version pinning (FR-039) and reproducible builds via Package.resolved. | Installing via Homebrew/binary download: version drift risk, no Package.resolved lock, manual version management. Building from source each run: CI time penalty, no version guarantees, complexity in workflow. |

**Mitigation Path**: FR-029 requires constitutional amendment adding DocC4LLM to approved list. FR-030 documents planned migration to Swift plugin (build-time only) when DocC4LLM publishes plugin version. Amendment included as Task 1 (blocking).

---

## Phase 0: Complete ✅

**Research Findings**: All technology decisions documented in `research.md`

Key decisions:
1. **Tool Selection**: DocC4LLM 1.0.0 (only markdown export tool available)
2. **Splitting**: awk-based delimiter parsing (proven, fast, no dependencies)
3. **Discovery**: External indexes (llms.txt + agents.md) over in-site generation
4. **Architecture**: Reusable workflows mirroring docs.21.dev pattern
5. **Monitoring**: Warn on size limits, don't fail workflow
6. **Logging**: Minimal with actionable error context
7. **Versioning**: Exact version pinning with manual upgrades

All NEEDS CLARIFICATION items resolved.

---

## Phase 1: Complete ✅

**Design Artifacts**:
- ✅ `data-model.md`: N/A (infrastructure feature, no persistent data)
- ✅ `contracts/generate-markdown-workflow-contract.md`: Reusable workflow specification
- ✅ `contracts/MD-21-DEV-workflow-contract.md`: Orchestrator workflow specification
- ✅ `quickstart.md`: Deployment guide with verification checklist
- ✅ Agent context updated: Windsurf rules refreshed with new tech stack

**Constitution Check Re-validation**:
- Status: ⚠️ Still CONDITIONAL PASS (blocked on Task 1)
- No design changes affected constitutional compliance
- IaC exemption (Principle III) confirmed applicable
- DocC4LLM dependency still requires amendment

---

## Phase 2: Next Steps

**Ready for Task Generation** (`/speckit.tasks` command):

Task categories expected:
1. **Constitution & Dependencies** (1-2 tasks)
   - Update constitution.md (v1.1.0 → v1.2.0)
   - Update Package.swift with DocC4LLM 1.0.0

2. **External Indexes** (2 tasks)
   - Create llms.txt in Resources/21-dev/
   - Create agents.md template

3. **GitHub Actions Workflows** (2 tasks)
   - Create generate-markdown.yml (reusable)
   - Create MD-21-DEV.yml (orchestrator)

4. **Testing & Validation** (3 tasks)
   - Manual trigger test
   - PR preview test
   - Production deployment test

**Estimated Total**: 8-10 implementation tasks

**Critical Path**: Constitution amendment (Task 1) blocks all workflow implementation tasks.

---

## Implementation Summary

**Feature Scope**: CI/CD infrastructure for LLM-optimized markdown documentation at md.21.dev

**Key Components**:
- DocC archive generation (P256K + ZKP combined)
- Markdown export via DocC4LLM tool
- File splitting (68k lines → 2,500+ individual files)
- Two-level hierarchy (target/symbol.md)
- External discovery indexes (llms.txt, agents.md)
- Preview deployments on PRs
- Production deployment on merge

**Architecture Pattern**: Reusable workflows (mirrors Feature 001 docs.21.dev)

**Deployment Target**: Cloudflare Pages project "md-21-dev" (pre-existing)

**Success Metrics**:
- Documentation generation + deployment < 15 minutes
- 2,500+ individual markdown files
- File organization: `/{target}/{symbol-name}.md`
- LLM-parseable (no HTML/JS required)
- Automatic updates on swift-secp256k1 version changes

**Blocking Requirements**:
1. ⚠️ Constitution amendment adding DocC4LLM (Task 1 - must complete first)
2. ✅ Cloudflare Pages project exists
3. ✅ GitHub secrets configured
4. ✅ Reference implementation (Feature 001) validated pattern

**Risk Mitigation**:
- Format validation prevents silent failures
- Size monitoring provides early warnings
- Preview deployments catch issues before production
- Reusable workflows reduce maintenance burden
- Exact version pinning ensures reproducibility

---

## Branch Status

**Branch**: `002-i-want-to`  
**Planning Status**: ✅ Complete  
**Ready for**: `/speckit.tasks` command to generate implementation tasks  
**Blocking Items**: Constitution amendment (first task in implementation)

**Artifacts Generated**:
- `plan.md` (this file)
- `research.md`
- `data-model.md`
- `contracts/generate-markdown-workflow-contract.md`
- `contracts/MD-21-DEV-workflow-contract.md`
- `quickstart.md`

**Next Command**: `/speckit.tasks` to generate task breakdown from this plan
