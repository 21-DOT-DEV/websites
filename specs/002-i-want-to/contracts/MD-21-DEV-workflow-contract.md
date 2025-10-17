# Workflow Contract: MD-21-DEV.yml

**Type**: Orchestrator GitHub Actions Workflow  
**Purpose**: Coordinate markdown generation and Cloudflare Pages deployment  
**Pattern**: Mirrors DOCS-21-DEV.yml architecture (FR-032)

## Triggers

### Pull Request Events
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened, closed]
    paths:
      - 'Package.swift'
      - 'Package.resolved'
      - '.github/workflows/generate-markdown.yml'
      - '.github/workflows/deploy-cloudflare.yml'
      - '.github/workflows/MD-21-DEV.yml'
```
- **Events**: PR opened, updated, reopened, merged/closed
- **Path Filter**: Only runs if documentation dependencies change (FR-015)
- **Rationale**: Prevents unnecessary runs when irrelevant files change (e.g., DesignSystem code)

### Manual Trigger
```yaml
workflow_dispatch:
  inputs:
    deploy-to-production:
      description: 'Deploy to production (true) or preview (false)'
      required: true
      type: boolean
      default: false
```
- **Purpose**: Manual deployments for testing or hotfixes
- **Input**: Boolean to control production vs preview deployment

## Jobs

### Job 1: Generate Markdown Documentation

```yaml
generate:
  runs-on: macos-15
  permissions:
    contents: read
  outputs:
    artifact-name: ${{ steps.generate.outputs.artifact-name }}
  
  steps:
    - name: Generate documentation
      id: generate
      uses: ./.github/workflows/generate-markdown.yml
      with:
        ref: ${{ github.event.pull_request.head.sha || github.sha }}
        swift-version: '6.1'
```

**Responsibilities**:
- Check out code at correct ref
- Generate DocC archive (P256K + ZKP targets)
- Export to markdown via DocC4LLM
- Split into individual files
- Upload markdown-docs artifact

**Outputs**:
- `artifact-name`: Name of artifact for deployment job

**Runs On**: macOS-15 (matches docs.21.dev runner)

### Job 2: Deploy to Cloudflare Pages

```yaml
deploy:
  needs: generate
  runs-on: ubuntu-latest
  permissions:
    contents: read
    deployments: write
    pull-requests: write
  
  steps:
    - name: Deploy markdown docs
      uses: ./.github/workflows/deploy-cloudflare.yml
      with:
        artifact-name: ${{ needs.generate.outputs.artifact-name }}
        project-name: 'md-21-dev'
        deploy-to-production: ${{ github.event.pull_request.merged == true }}
      secrets:
        cloudflare-api-token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
        cloudflare-account-id: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

**Responsibilities**:
- Download markdown-docs artifact
- Deploy to Cloudflare Pages project "md-21-dev"
- Post preview URL in PR comments (if preview deployment)
- Deploy to production if PR merged (FR-014)

**Depends On**: `generate` job (artifact must exist)

**Runs On**: ubuntu-latest (matches docs.21.dev pattern)

## Workflow Logic

### Preview Deployment (PR opened/updated)
```
PR opened/updated
  → generate job runs
    → DocC generation
    → Markdown export
    → File splitting
    → Artifact upload
  → deploy job runs
    → Download artifact
    → Deploy to Cloudflare preview URL
    → Post preview URL in PR comment (FR-018)
```

### Production Deployment (PR merged)
```
PR merged to main
  → trigger: pull_request type=closed, merged=true
  → generate job runs (same as preview)
  → deploy job runs with production flag
    → Download artifact
    → Deploy to md.21.dev production (FR-014)
    → No PR comment (PR already closed)
```

### Manual Deployment
```
workflow_dispatch triggered
  → User selects deploy-to-production: true/false
  → generate job runs
  → deploy job runs with user-selected flag
```

## Environment Variables

### Required Secrets
- `CLOUDFLARE_API_TOKEN`: Cloudflare API token with Pages:Edit permission
- `CLOUDFLARE_ACCOUNT_ID`: Cloudflare account ID

**Note**: Same secrets as DOCS-21-DEV.yml (already configured)

### Derived Values
- `github.event.pull_request.head.sha`: PR commit to build
- `github.sha`: Fallback for workflow_dispatch
- `github.event.pull_request.merged`: Boolean, true only if PR was merged

## Success Criteria

**Preview Deployment Success**:
- ✓ Generate job completes (<15 minutes)
- ✓ Artifact uploaded successfully
- ✓ Deploy job completes
- ✓ Preview URL posted in PR comment
- ✓ Preview URL loads markdown documentation

**Production Deployment Success**:
- ✓ Generate job completes (<15 minutes)
- ✓ Deploy job completes
- ✓ https://md.21.dev/ loads updated documentation
- ✓ Deployment visible in Cloudflare Pages dashboard

## Error Handling

### Generate Job Failure
```
Status: ❌ Generate job failed
Check: generate-markdown.yml workflow logs
Action: Review DocC generation, export, or split errors
Impact: Deploy job skipped (dependency failed)
```

### Deploy Job Failure (Artifact Missing)
```
Status: ❌ Deploy job failed
Error: Artifact 'markdown-docs-abc123' not found
Cause: Generate job didn't upload artifact
Action: Check generate job success and artifact name
```

### Deploy Job Failure (Cloudflare API)
```
Status: ❌ Deploy job failed
Error: Cloudflare Pages deployment rejected
Possible Causes:
  - API token expired/invalid
  - Project 'md-21-dev' doesn't exist
  - Deployment size exceeds limits (>25MB)
Action: Verify Cloudflare secrets and project configuration
```

## Synchronization with DOCS-21-DEV.yml

**Shared Patterns**:
- Triggers: Same path filtering, same PR events
- Jobs: Generate → Deploy sequence
- Artifact: 1-day retention
- Cloudflare: deploy-cloudflare.yml reusable workflow

**Differences**:
- Generator: `generate-docc.yml` (docs) vs `generate-markdown.yml` (md)
- Output: HTML/CSS/JS (docs) vs Markdown (md)
- Project: `docs-21-dev` vs `md-21-dev`
- Domain: `docs.21.dev` vs `md.21.dev`

**Rationale**: Consistent CI/CD experience across both documentation subdomains (FR-032)

## Contract Guarantees

**IF** PR touches Package.swift/Package.resolved **THEN**:
1. Workflow triggers automatically (FR-015)
2. Preview deployment created
3. Preview URL posted in PR comment
4. Reviewers can validate before merge (FR-023)

**IF** PR merged to main **THEN**:
1. Workflow triggers automatically (FR-014)
2. Production deployment to md.21.dev
3. Documentation synchronized with swift-secp256k1 version (SC-006)
4. Deployment completes within 15 minutes (SC-004)

**IF** workflow fails **THEN**:
1. PR marked with failed check
2. Error identifies failed job (generate or deploy)
3. Logs provide diagnostic information (SC-007)
4. Reviewer can diagnose within 5 minutes (SC-007)
