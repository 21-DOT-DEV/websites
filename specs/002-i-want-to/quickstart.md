# Quickstart: MD.21.DEV Deployment

**Feature**: LLM-Optimized Markdown Documentation Subdomain  
**Audience**: Implementation team, reviewers, maintainers

## Prerequisites

### Required Before Implementation

1. **Constitution Amendment** (BLOCKING)
   - Update `.specify/memory/constitution.md`
   - Add DocC4LLM to approved dependencies list (Principle II)
   - Version bump: 1.1.0 → 1.2.0 (MINOR - new approved dependency)
   - Commit with message: `chore: Add DocC4LLM to constitution approved dependencies (v1.2.0)`

2. **Cloudflare Pages Project**
   - Project `md-21-dev` exists ✅ (confirmed during planning)
   - Custom domain `md.21.dev` configured
   - DNS CNAME: `md.21.dev` → `md-21-dev.pages.dev`

3. **GitHub Secrets** (Already Configured)
   - `CLOUDFLARE_API_TOKEN` ✅ (shared with docs.21.dev)
   - `CLOUDFLARE_ACCOUNT_ID` ✅ (shared with docs.21.dev)

4. **Repository Setup**
   - Branch `002-i-want-to` exists ✅
   - Feature spec complete ✅
   - Implementation plan complete ✅

## Implementation Steps

### Phase 1: Constitution & Dependencies

**Task 1.1: Update Constitution**
```bash
# Edit constitution
open .specify/memory/constitution.md

# Add to Principle II approved dependencies:
# - DocC4LLM (markdown export tool)

# Update version at bottom:
# Version: 1.1.0 → 1.2.0

# Commit
git add .specify/memory/constitution.md
git commit -m "chore: Add DocC4LLM to constitution approved dependencies (v1.2.0)"
```

**Task 1.2: Update Package.swift**
```bash
# Edit Package.swift
open Package.swift

# Add dependency (after swift-docc-plugin line):
.package(url: "https://github.com/P24L/DocC4LLM.git", exact: "1.0.0"),

# Verify syntax
swift package resolve

# Commit
git add Package.swift Package.resolved
git commit -m "feat: Add DocC4LLM 1.0.0 for markdown export"
```

### Phase 2: External Index Files

**Task 2.1: Create llms.txt**
```bash
# Create llms.txt
cat > Resources/21-dev/llms.txt << 'EOF'
# 21.dev

> Personal website and documentation hub for Swift cryptography packages

## API Documentation

For machine-readable API documentation:
- Swift secp256k1 Library: https://md.21.dev/
  - P256K Module: https://md.21.dev/p256k/
  - ZKP Module: https://md.21.dev/zkp/

Documentation format: Individual markdown files per symbol
Structure: /{target}/{symbol-name}.md pattern
Example: https://md.21.dev/p256k/int128.md

## About

21.dev hosts static sites and documentation for open-source Swift projects.
EOF

# Commit
git add Resources/21-dev/llms.txt
git commit -m "feat: Add llms.txt for LLM discovery"
```

**Task 2.2: Create agents.md Template**
```bash
# Create template
cat > Resources/21-dev/agents-md-template.md << 'EOF'
# Swift secp256k1 - LLM Documentation Guide

## API Documentation

Complete API documentation available in markdown format at:
- https://md.21.dev/

### Modules
- **P256K**: https://md.21.dev/p256k/ - secp256k1 Elliptic Curve operations
- **ZKP**: https://md.21.dev/zkp/ - Zero-Knowledge Proof operations

### Documentation Structure
Each API symbol has its own markdown file:
- Pattern: `/{module}/{symbol-name}.md`
- Example: https://md.21.dev/p256k/sharedsecret.md

Source code links point to exact line numbers in this repository.

## For LLMs

This documentation is optimized for machine parsing:
- No JavaScript required
- Pure markdown format
- Consistent structure
- Predictable file paths

## Usage

1. Start at module overview: https://md.21.dev/p256k.md or https://md.21.dev/zkp.md
2. Navigate to specific symbols via links
3. Extract signatures, parameters, return types, and descriptions
4. Follow source links for implementation context

## Updates

Documentation automatically regenerates when new versions are released.
Always reflects the latest swift-secp256k1 APIs.
EOF

# Commit
git add Resources/21-dev/agents-md-template.md
git commit -m "feat: Add agents.md template for swift-secp256k1 repo"
```

### Phase 3: GitHub Actions Workflows

**Task 3.1: Create generate-markdown.yml**
```bash
# Create reusable workflow
# See: contracts/generate-markdown-workflow-contract.md for full specification

# Key components:
# 1. Generate DocC archive (P256K + ZKP combined)
# 2. Export via DocC4LLM
# 3. Validate delimiter format
# 4. Split into individual files
# 5. Monitor size
# 6. Create root index.md
# 7. Upload artifact

# File: .github/workflows/generate-markdown.yml
# Commit when complete
```

**Task 3.2: Create MD-21-DEV.yml**
```bash
# Create orchestrator workflow
# See: contracts/MD-21-DEV-workflow-contract.md for full specification

# Key components:
# 1. Triggers: PR events + manual
# 2. Job 1: Call generate-markdown.yml
# 3. Job 2: Call deploy-cloudflare.yml (existing)
# 4. Preview vs production logic

# File: .github/workflows/MD-21-DEV.yml
# Commit when complete
```

### Phase 4: Testing

**Task 4.1: Manual Trigger Test**
```bash
# Push branch
git push origin 002-i-want-to

# In GitHub UI:
# 1. Actions → MD-21-DEV.yml → Run workflow
# 2. Select branch: 002-i-want-to
# 3. deploy-to-production: false
# 4. Run

# Verify:
# - Generate job completes (<15 min)
# - Artifact uploaded (markdown-docs-*)
# - Deploy job completes
# - Preview URL accessible
```

**Task 4.2: PR Test**
```bash
# Create test PR
gh pr create \
  --base main \
  --head 002-i-want-to \
  --title "Add md.21.dev LLM documentation subdomain" \
  --body "Implements Feature 002: LLM-optimized markdown documentation"

# Verify:
# - Workflow triggers automatically
# - Preview URL posted in comment
# - md.21.dev loads (preview URL)
# - File structure correct (p256k/*.md, zkp/*.md)
```

**Task 4.3: Production Test**
```bash
# After reviewer approval:
gh pr merge 002-i-want-to --squash

# Verify:
# - Workflow triggers on merge
# - Production deployment to md.21.dev
# - https://md.21.dev/ loads successfully
# - Documentation complete (2,500+ files)
# - Source links work (swift-secp256k1 repo)
```

## Verification Checklist

### After Constitution Amendment
- [ ] `.specify/memory/constitution.md` version bumped to 1.2.0
- [ ] DocC4LLM listed in Principle II approved dependencies
- [ ] Commit message follows semantic convention
- [ ] Constitution Check in plan.md passes

### After Package.swift Update
- [ ] DocC4LLM 1.0.0 in dependencies (exact version)
- [ ] `swift package resolve` succeeds
- [ ] Package.resolved committed
- [ ] No additional dependencies added

### After Index Files
- [ ] `Resources/21-dev/llms.txt` exists
- [ ] llms.txt follows https://llmstxt.org format
- [ ] `Resources/21-dev/agents-md-template.md` exists
- [ ] Template ready for swift-secp256k1 repo

### After Workflow Creation
- [ ] `.github/workflows/generate-markdown.yml` exists
- [ ] `.github/workflows/MD-21-DEV.yml` exists
- [ ] YAML syntax valid (GitHub checks)
- [ ] Path filters match DOCS-21-DEV.yml pattern
- [ ] Secrets referenced correctly

### After Manual Test
- [ ] Workflow runs successfully
- [ ] Artifact uploaded (1.2MB size)
- [ ] Preview URL accessible
- [ ] Markdown files valid
- [ ] File count ~2,570
- [ ] Total time <15 minutes

### After PR Test
- [ ] Workflow triggers automatically
- [ ] Preview URL posted in comment
- [ ] Preview loads documentation
- [ ] File structure correct (target/symbol.md)
- [ ] Root index.md exists

### After Production Deployment
- [ ] https://md.21.dev/ loads
- [ ] https://md.21.dev/p256k.md loads
- [ ] https://md.21.dev/zkp.md loads
- [ ] https://md.21.dev/p256k/int128.md loads
- [ ] Source links navigate to GitHub
- [ ] llms.txt references md.21.dev

## Rollback Procedure

### If Deployment Fails
1. Go to Cloudflare Pages dashboard
2. Select project: md-21-dev
3. View deployment history
4. Click previous successful deployment
5. Click "Rollback to this deployment"
6. Verify https://md.21.dev/ loads previous version

### If CI Breaks
1. Revert problematic commit
2. Push revert to main
3. Workflow re-runs automatically
4. Previous documentation restored

## Troubleshooting

### DocC Generation Fails
**Symptom**: `swift package generate-documentation` exits with error

**Check**:
- `docs-21-dev-P256K` target exists in Package.swift
- `docs-21-dev-ZKP` target exists in Package.swift
- swift-secp256k1 dependency resolved correctly

**Fix**: Verify Package.swift has documentation targets (from Feature 001)

### Markdown Export Fails
**Symptom**: `swift run docc4llm export` exits with error

**Check**:
- DocC4LLM in Package.swift dependencies
- `.doccarchive` exists at expected path
- DocC4LLM version is 1.0.0 (exact)

**Fix**: Run `swift package resolve` and verify Package.resolved

### Format Validation Fails
**Symptom**: "Format validation failed" error

**Check**:
- DocC4LLM version changed?
- Output file exists and is non-empty?
- Delimiter format: `=== START FILE:` / `=== END FILE ===`

**Fix**: Review DocC4LLM output, may need to update split logic

### Split Produces Zero Files
**Symptom**: "File splitting complete (files: 0)"

**Check**:
- awk command syntax correct
- Input file path correct
- Delimiters present in input

**Fix**: Review awk command, validate input file has delimiters

### Deployment Size Warning
**Symptom**: "Approaching file limit" warning

**Action**: This is informational, not an error
- Current: ~2,570 files (13% of limit)
- Monitor growth over time
- Optimize if approaching 15,000 files

## Next Steps After Deployment

1. **Verify LLM Access**
   - Test markdown fetching via HTTP
   - Validate CommonMark parsing
   - Verify source links work

2. **Update swift-secp256k1 Repo**
   - Copy `agents-md-template.md` to swift-secp256k1
   - Rename to `agents.md`
   - Commit to repository root

3. **Monitor First Update**
   - Wait for next swift-secp256k1 release
   - Verify automatic regeneration (FR-011)
   - Confirm deployment within 15 minutes (SC-004)

4. **Document Workflow**
   - Add to project README
   - Document for maintainers
   - Update runbook if needed

## Resources

- **Feature Spec**: `specs/002-i-want-to/spec.md`
- **Implementation Plan**: `specs/002-i-want-to/plan.md`
- **Research**: `specs/002-i-want-to/research.md`
- **Workflow Contracts**: `specs/002-i-want-to/contracts/`
- **Constitution**: `.specify/memory/constitution.md`
- **Reference Implementation**: Feature 001 (docs.21.dev)
