# Phase 0: Research & Technology Decisions

**Feature**: LLM-Optimized Markdown Documentation Subdomain  
**Date**: 2025-10-16  
**Status**: Complete

## Research Questions

###  1. Markdown Export Tool Selection

**Question**: Which tool should export .doccarchive to markdown format?

**Decision**: DocC4LLM v1.0.0 (exact version pinning)

**Rationale**:
- **Only option**: DocC4LLM is the only known tool that exports Apple DocC archives to markdown
- **LLM-optimized**: Specifically designed for LLM consumption (project name indicates intent)
- **Active maintenance**: GitHub repository shows recent activity
- **Proven output**: Testing confirmed 68k-line concatenated markdown with clear delimiters

**Alternatives Considered**:
- **Custom Swift parser**: Rejected - weeks of development to replicate DocC4LLM, scope creep
- **Manual HTML parsing**: Rejected - brittle, unmaintainable, DocC HTML is interactive/JS-heavy
- **Using DocC HTML directly**: Rejected - violates FR-025 (machine-readable), LLMs struggle with HTML/JS

**Implementation**: Add to Package.swift as executable product, invoke via `swift run docc4llm export`

**References**: 
- https://github.com/P24L/DocC4LLM
- FR-003, FR-034, FR-039

---

### 2. File Splitting Strategy

**Question**: How should the monolithic markdown output be split into individual files?

**Decision**: awk-based delimiter parsing

**Rationale**:
- **Proven**: Successfully tested splitting 68k lines → 2,570 files
- **Standard tool**: awk available on macOS-15 GitHub Actions runners
- **Fast**: Processes 1.1MB file in seconds
- **Predictable**: DocC4LLM uses consistent `=== START FILE:` / `=== END FILE ===` delimiters
- **No dependencies**: Shell scripting, no additional tools needed

**Command**:
```bash
awk '/=== START FILE: /{
    gsub(/ ===$/, "", $4)
    path=$4
    sub(/^data\/documentation\//, "", path)
    sub(/\.json$/, ".md", path)
    system("mkdir -p \"$(dirname \"" path "\")\"")}
  /=== END FILE ===/{
    close(path)
    path=""
    next}
  path{
    print > path
}' docs.md
```

**Output Structure**: `{target}/{symbol-name}.md` (e.g., `p256k/int128.md`)

**Alternatives Considered**:
- **Swift script**: Rejected - overkill for simple text splitting, adds complexity
- **jq JSON parsing**: Rejected - delimiter-based format isn't JSON
- **Python script**: Rejected - requires Python dependency, unnecessary

**Validation**: FR-037 requires pre-split validation checking delimiter count/format

**References**: FR-036, FR-037

---

### 3. LLM Discovery Index Strategy

**Question**: How should LLMs discover available documentation?

**Decision**: External indexes (llms.txt + agents.md) instead of in-site generation

**Rationale**:
- **Separation of concerns**: Index logic independent of generated docs
- **Standard compliance**: llms.txt follows https://llmstxt.org standard
- **Multiple entry points**: Discoverability from both 21.dev and swift-secp256k1 repo
- **Easier updates**: Can update index strategy without regenerating docs
- **Cross-package ready**: llms.txt can point to multiple packages in future

**llms.txt Location**: `Resources/21-dev/llms.txt` (deployed to 21.dev root)

**agents.md Location**: Template provided for swift-secp256k1 repository (separate repo, out of direct scope)

**Format** (llms.txt):
```markdown
# 21.dev

> Personal website and documentation hub

## API Documentation

- Swift secp256k1: https://md.21.dev/
  - P256K Module: https://md.21.dev/p256k/
  - ZKP Module: https://md.21.dev/zkp/

Structure: /{target}/{symbol-name}.md
Example: https://md.21.dev/p256k/int128.md
```

**Alternatives Considered**:
- **In-site index generation**: Rejected - couples index logic to doc generation, harder to maintain
- **JSON manifest**: Rejected - adds complexity, markdown sufficient for LLMs
- **Directory traversal only**: Rejected - requires LLMs to know symbol names beforehand

**References**: FR-040, FR-041, https://llmstxt.org

---

### 4. Workflow Architecture Pattern

**Question**: Should workflows be monolithic or reusable?

**Decision**: Reusable workflow pattern (mirror docs.21.dev architecture)

**Rationale**:
- **Proven pattern**: Feature 001 (docs.21.dev) established successful pattern
- **DRY principle**: `deploy-cloudflare.yml` reused without modification
- **Maintainability**: Changes to deployment logic update both docs and md subdomains
- **Consistency**: Same artifact handling, same deployment strategy
- **Testability**: Each workflow unit-testable via workflow_dispatch

**Architecture**:
```
MD-21-DEV.yml (orchestrator)
├── Calls: generate-markdown.yml
│   └── Outputs: markdown-docs artifact
└── Calls: deploy-cloudflare.yml (existing)
    └── Inputs: markdown-docs artifact
```

**Triggers** (synchronized with DOCS-21-DEV.yml):
- Pull request events: opened, synchronize, reopened, closed
- Paths: Package.swift, Package.resolved, .github/workflows/{generate-markdown.yml,deploy-cloudflare.yml,MD-21-DEV.yml}
- Manual: workflow_dispatch

**Alternatives Considered**:
- **Monolithic workflow**: Rejected - duplicates deployment logic, harder to maintain
- **Single workflow for both docs/md**: Rejected - coupling unrelated outputs, harder to debug
- **Separate deployment workflow**: Rejected - unnecessary duplication

**References**: FR-032, Feature 001 implementation

---

### 5. Cloudflare Pages Size Monitoring

**Question**: Should the system enforce Cloudflare Pages limits?

**Decision**: Monitor and warn, but don't fail workflow

**Rationale**:
- **Early warning**: Logs warnings at 15,000 files or 20MB (before hitting 20k/25MB limits)
- **Non-blocking**: Allows deployment to proceed even near limits
- **Manual intervention**: Human decision whether to optimize before hitting hard limit
- **Failure handling**: Cloudflare will reject if limits exceeded (natural failure point)

**Implementation**:
```bash
FILE_COUNT=$(find Websites/md-21-dev -type f | wc -l)
SIZE_MB=$(du -sm Websites/md-21-dev | cut -f1)

if [ "$FILE_COUNT" -gt 15000 ]; then
  echo "::warning::Approaching file limit: $FILE_COUNT files (limit: 20,000)"
fi

if [ "$SIZE_MB" -gt 20 ]; then
  echo "::warning::Approaching size limit: ${SIZE_MB}MB (limit: 25MB)"
fi
```

**Alternatives Considered**:
- **Fail on threshold**: Rejected - false positives block valid deployments
- **No monitoring**: Rejected - surprise failures when limits hit
- **Auto-optimization**: Rejected - complex, premature

**References**: FR-038, SC-007

---

### 6. CI Logging Strategy

**Question**: What level of detail should CI workflows log?

**Decision**: Minimal logging with actionable error context

**Rationale**:
- **Clean output**: Easy to scan for errors
- **Fast diagnosis**: SC-007 requires 5-minute diagnosis
- **No noise**: Verbose logging makes errors harder to find
- **Structured errors**: Each failure identifies stage, error type, affected paths

**Log Structure**:
```
✓ DocC generation complete (5m 23s)
✓ Markdown export complete (2m 14s)
✓ Format validation passed (delimiters: 2570)
✓ File splitting complete (files: 2570)
⚠️ Size warning: 18,234 files (approaching 20k limit)
✓ Artifact upload complete (size: 1.2MB)
```

**Error Example**:
```
❌ Markdown export failed
Stage: DocC4LLM export
Command: swift run docc4llm export Archives/md-21-dev.doccarchive
Exit code: 1
Error: Archive not found at path
Action: Verify DocC generation succeeded and archive path is correct
```

**Alternatives Considered**:
- **Verbose logging**: Rejected - too noisy, violates FR-022 minimal logging requirement
- **Silent success**: Rejected - no confirmation workflows ran
- **Metrics only**: Rejected - harder to debug failures without stage identification

**References**: FR-022, SC-007

---

### 7. Version Pinning Strategy

**Question**: How should DocC4LLM versions be managed?

**Decision**: Exact version pinning with manual upgrades

**Rationale**:
- **Reproducibility**: Same version across all CI runs
- **Format stability**: Prevents unexpected delimiter format changes (FR-037)
- **Controlled upgrades**: Test new versions in preview deployments before production
- **Package.resolved locking**: Exact version committed to repository

**Package.swift Entry**:
```swift
.package(url: "https://github.com/P24L/DocC4LLM.git", exact: "1.0.0")
```

**Upgrade Process**:
1. Create PR updating DocC4LLM version
2. Preview deployment validates new markdown format
3. Reviewer inspects output structure
4. Merge if validation passes

**Alternatives Considered**:
- **Semver range** (`.upToNextMajor`): Rejected - auto-updates risk breaking splits
- **Latest from main**: Rejected - unstable, format could change anytime
- **Dependabot auto-updates**: Rejected - need human validation of format changes

**References**: FR-039, Clarification Question 1

---

## Summary of Technology Stack

**Core Technologies**:
- Swift 6.1+ (GitHub Actions macOS-15 runners)
- swift-docc-plugin 1.4.5 (DocC archive generation)
- DocC4LLM 1.0.0 (markdown export) **[NEW DEPENDENCY - requires constitution amendment]**
- awk (file splitting)
- GitHub Actions (CI/CD orchestration)
- Cloudflare Pages (static hosting)

**Architectural Patterns**:
- Reusable workflows (established by Feature 001)
- Artifact-based job communication (1-day retention)
- External index discovery (llms.txt standard)
- Two-level file hierarchy (target/symbol.md)
- Minimal logging with structured errors

**Constraints Validated**:
- ✅ <15 minutes total time (DocC ~5min, export ~2min, deploy ~3min)
- ✅ <25MB deployment size (1.1MB actual, 95% headroom)
- ✅ <20,000 files (2,570 actual, 87% headroom)
- ✅ Static site architecture (pure markdown files)
- ✅ No runtime dependencies (CDN-served static files)

**Risk Mitigation**:
- Constitution amendment gates implementation (Principle II violation)
- Format validation prevents silent failures (FR-037)
- Size monitoring provides early warnings (FR-038)
- Reusable workflows reduce maintenance burden (FR-032)
- Preview deployments catch issues before production (FR-018)

## Next Phase

**Phase 1 Actions**:
1. Create contracts/ directory with workflow schemas
2. Generate quickstart.md deployment instructions
3. Skip data-model.md (N/A for infrastructure feature)
4. Update agent context files
5. Re-validate Constitution Check post-design

**Blocking Item**: Constitution amendment (Task 1) must complete before workflow implementation begins.
