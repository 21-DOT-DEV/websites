# Implementation Plan: Sitemap Infrastructure Overhaul

**Branch**: `001-sitemap-infrastructure` | **Date**: 2025-11-14 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-sitemap-infrastructure/spec.md`

**Note**: This plan incorporates clarifications from the specification and clarification phases.

## Summary

Implement comprehensive sitemap infrastructure across all three subdomains (21.dev, docs.21.dev, md.21.dev) with automated search engine submission. Each subdomain generates its own sitemap.xml file with accurate lastmod dates using git history (21.dev) and package version tracking (docs/md). All sitemaps submitted to Google Search Console and Bing Webmaster Tools APIs within 5 minutes of deployment. Update robots.txt files on each subdomain to reference their own sitemap.xml.

## Technical Context

**Language/Version**: Swift 6.1+ (21.dev sitemap generation), Bash (inline workflow steps for docs/md sitemap generation)  
**Primary Dependencies**: Slipstream v2 (already integrated), curl (API submissions), git (lastmod tracking), lefthook-plugin (https://github.com/csjones/lefthook-plugin for state file automation)  
**Storage**: One git-tracked JSON state file: `Resources/sitemap-state.json` (docs/md package version tracking)  
**Testing**: swift-testing for Swift sitemap generation logic, PR preview validation for inline workflow bash, integration tests for workflow execution  
**Target Platform**: GitHub Actions (macOS-15 runners), Cloudflare Pages deployment  
**Project Type**: Static site infrastructure (CI/CD enhancement)  
**Performance Goals**: Subdomain sitemap generation < 5 seconds each, API submission < 5 minutes post-deployment, git log queries < 1 second per file  
**Constraints**: Must conform to sitemap protocol 0.9, 50,000 URL limit per sitemap (current ~10-50 URLs well below), 50MB uncompressed size limit  
**Scale/Scope**: 3 subdomains, ~10-50 URLs total initially (21.dev: ~5 pages, docs.21.dev: ~20-30 documentation pages, md.21.dev: ~20-30 markdown files)

**Existing Workflows to Modify**:
- `.github/workflows/build-slipstream.yml` - Add sitemap generation + API submission for 21.dev
- `.github/workflows/generate-docc.yml` - Add sitemap generation + API submission for docs.21.dev
- `.github/workflows/generate-markdown.yml` - Add sitemap generation + API submission for md.21.dev
- `.github/workflows/deploy-cloudflare.yml` - Add subdomain sitemap deployments

**Key Design Decisions**:
1. **Per-Subdomain Sitemaps**: Each subdomain generates and maintains its own sitemap.xml independently (standard industry practice)
2. **lastmod Strategy**: Hybrid - git history for 21.dev, package version tracking for docs/md via lefthook-plugin SPM package
3. **State Management**: Single state file `Resources/sitemap-state.json` for docs/md package version tracking
4. **API Submission Timing**: All sitemaps submitted immediately on deployment (< 5 min) for fast search engine notification
5. **Deployment Independence**: Each subdomain deployment fully independent; no cross-workflow coordination needed
6. **Workflow Pattern**: Inline bash steps in workflows (no separate script files) for local testability

## Lefthook Automation

**Purpose**: Automatically update sitemap state file when dependencies change

**Setup**:
```bash
swift package --disable-sandbox lefthook install
```

**How it works**:
- Git hook: `post-checkout` (triggers after branch switches, pulls, checkouts)
- Monitors: `Package.resolved` file for changes
- Updates: `Resources/sitemap-state.json` with new `swift-secp256k1` version + timestamp
- Result: Ensures docs/md sitemaps only regenerate lastmod dates when package version actually changes

**Integration**:
- Uses [lefthook-plugin](https://github.com/csjones/lefthook-plugin) Swift package (no separate binary install needed)
- Configuration: `lefthook.yml` at repository root
- Execution: Runs automatically on `git checkout`, `git pull`, etc.
- Developer workflow: Hook updates state file → developer commits updated file alongside version bump

**Benefits**:
- Zero manual maintenance of state file
- Accurate lastmod tracking (only changes when content actually changes)
- Prevents CI failures from version mismatches (workflows validate state file version)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Principle I: Static-First Architecture
✅ **PASS** - Generates pure static XML files (sitemap.xml, robots.txt), no runtime dependencies  
✅ **PASS** - Output to `Websites/<SiteName>/sitemap.xml` as static artifacts  
✅ **PASS** - No JavaScript frameworks or client-side routing involved  
✅ **PASS** - Deterministic builds (same URLs → same sitemap)

### Principle II: Spec-First & Test-Driven Development
✅ **PASS** - Specification created before implementation (spec.md exists)  
✅ **PASS** - Single feature (sitemap infrastructure), independently testable  
✅ **PASS** - User scenarios and acceptance criteria defined  
✅ **PASS** - No dependencies on incomplete specs  
⚠️ **WARNING** - Infrastructure-as-Code (GitHub Actions workflows) - exempt from strict TDD per constitution but must satisfy validation requirements:
  - Will use workflow syntax validation (yamllint)
  - Integration testing via PR preview deployments
  - Bash scripts >10 lines will have unit tests (shellcheck + test framework)
  - Validation procedures documented in plan

### Principle III: Accessibility & Performance by Default
✅ **PASS** - Sitemap XML files are machine-readable (not user-facing UI)  
✅ **PASS** - robots.txt files follow standard format  
N/A - Accessibility requirements don't apply to XML/TXT machine files  
✅ **PASS** - Performance goals defined (< 5 seconds generation, < 1 second git queries)

### Principle IV: Design System Consistency
N/A - No UI components involved (pure infrastructure feature)

### Principle V: Zero-Dependency Philosophy
✅ **PASS** - No new npm/Swift package dependencies required  
✅ **PASS** - Uses existing tooling: git, curl, bash (system utilities)  
✅ **PASS** - Lefthook is build-time tool (SPM plugin, not production dependency)  
✅ **PASS** - No JavaScript frameworks or CSS frameworks

### Principle VI: Security & Privacy by Design
✅ **PASS** - API credentials stored as GitHub Actions secrets (not hardcoded)  
✅ **PASS** - HTTPS-only URLs in sitemaps (protocol enforced)  
✅ **PASS** - No user data collection (sitemaps are static URL lists)  
✅ **PASS** - robots.txt properly configured (md.21.dev disallows search engines)  
N/A - No XSS/CSP concerns (XML files, not HTML)

### Principle VII: Open Source Excellence
✅ **PASS** - Comprehensive documentation in spec.md and plan.md  
✅ **PASS** - Clear architecture decisions documented  
✅ **PASS** - Workflows will include inline comments explaining logic  
✅ **PASS** - Inline bash steps follow readability best practices (multiline, clear variable names)

### Additional Requirements
✅ **PASS** - SEO & Metadata: Implements required sitemap.xml and robots.txt  
✅ **PASS** - Build Reliability: Deterministic, clear failure messages  
✅ **PASS** - Deployment Rules: Only production deployments generate sitemaps  

**OVERALL STATUS**: ✅ **PASS** with Infrastructure-as-Code exemption noted

**Post-Phase 1 Re-check**: Inline workflow bash validated through PR preview deployments (IaC exemption applies). Future actionlint integration (Phase 4 roadmap) will provide static analysis.

## Project Structure

### Documentation (this feature)

```text
specs/001-sitemap-infrastructure/
├── spec.md               # Feature specification (COMPLETED)
├── plan.md              # This file (IN PROGRESS)
├── checklists/
│   └── requirements.md  # Specification quality checklist (COMPLETED)
├── research.md          # Phase 0 output (TODO via /speckit.plan)
├── data-model.md        # Phase 1 output (TODO via /speckit.plan)
├── contracts/           # Phase 1 output (TODO via /speckit.plan)
│   ├── sitemap-schema.md      # Sitemap XML structure
│   ├── state-file-schema.md  # JSON state file format
│   └── api-contracts.md       # Google/Bing API specs
└── tasks.md             # Phase 2 output (TODO via /speckit.tasks)
```

### Source Code & Configuration (repository root)

**Structure Decision**: Infrastructure feature - modifies existing Swift code and GitHub Actions workflows, no new source directories.

```text
# Modified Files
Sources/21-dev/
└── SiteGenerator.swift         # MODIFY - Enhance sitemap generation with git lastmod

Resources/
├── sitemap-state.json          # CREATE - Shared state for docs/md lastmod tracking
├── sitemap-index-hashes.json   # CREATE - Content hashes for cron job change detection
├── 21-dev/
│   └── robots.txt              # MODIFY - Add sitemap index reference
├── docs-21-dev/
│   └── robots.txt              # CREATE - Add docs sitemap reference  
└── md-21-dev/
    └── robots.txt              # MODIFY - Update with sitemap reference

.github/workflows/
├── build-slipstream.yml        # MODIFY - Add sitemap-main.xml generation + git lastmod logic + API submission
├── generate-docc.yml           # MODIFY - Add sitemap.xml generation for docs (inline bash) + API submission
├── generate-markdown.yml       # MODIFY - Add sitemap.xml generation for md (inline bash) + API submission
├── deploy-cloudflare.yml       # MODIFY - Deploy subdomain sitemaps (no index generation, delegated to cron)
└── update-sitemap-index.yml    # CREATE - Daily cron job: fetch sitemaps, hash comparison, index regeneration, API submission

Package.swift                   # MODIFY - Add lefthook-plugin dependency

lefthook.yml                    # CREATE/MODIFY - Configure post-checkout hook via lefthook-plugin

Tests/IntegrationTests/
└── SitemapGenerationTests.swift # CREATE - Integration tests for sitemap generation

.specify/memory/
└── roadmap.md                   # MODIFIED - Added Swift-based sitemap generator to Phase 4
```

### Generated Artifacts (git-ignored)

```text
Websites/
├── 21-dev/
│   ├── sitemap-main.xml        # Generated by build-slipstream workflow
│   └── sitemap.xml             # Generated by update-sitemap-index cron workflow (index)
├── docs-21-dev/
│   └── sitemap.xml             # Generated by generate-docc workflow
└── md-21-dev/
    └── sitemap.xml             # Generated by generate-markdown workflow
```

**Key Modifications**:
1. **Swift**: Enhance existing `SiteGenerator.swift` with git-based lastmod calculation
2. **Workflows**: Add inline bash steps to 3 subdomain workflows + create new cron workflow (no separate script files)
3. **Dependencies**: Add lefthook-plugin to Package.swift for state file automation
4. **State Files**: Two JSON files - `Resources/sitemap-state.json` (package versions), `Resources/sitemap-index-hashes.json` (content hashes for change detection)
5. **Lefthook**: Configure post-checkout hook via lefthook-plugin to auto-update state file on Package.resolved changes
6. **Cron Job**: New daily workflow for sitemap index regeneration with hash-based change detection

## Complexity Tracking

✅ **No constitutional violations** - Feature aligns with all principles. Infrastructure-as-Code exemption applies (workflows validated through integration testing).

## Phase 0: Research & Technical Decisions

### Research Tasks

1. **Sitemap Protocol 0.9 Specification**
   - Review official sitemap.org protocol documentation
   - Understand `<url>`, `<loc>`, `<lastmod>`, `<sitemapindex>` structure
   - Validate XML namespace requirements
   - Document size/URL limits (50,000 URLs, 50MB uncompressed)

2. **Google Search Console API**
   - Review IndexingAPI documentation (https://developers.google.com/search/apis/indexing-api/v3/reference/)
   - Identify required scopes and authentication method
   - Document rate limits and error handling
   - Test endpoint: `POST https://indexing.googleapis.com/v3/urlNotifications:publish`

3. **Bing Webmaster Tools API**
   - Review URL Submission API documentation
   - Identify required API key format
   - Document rate limits and error handling  
   - Test endpoint: `POST https://ssl.bing.com/webmaster/api.svc/json/SubmitUrl`

4. **Git Lastmod Extraction Best Practices**
   - Research git log performance for file-by-file queries
   - Identify caching strategies if needed
   - Document ISO 8601 format requirements (`--format=%cI`)
   - Test performance with ~10-50 files

5. **Lefthook Integration**
   - Review Lefthook documentation for SPM plugins
   - Identify appropriate git hooks (post-checkout, post-merge, post-rewrite)
   - Document hook configuration syntax
   - Test Package.resolved change detection

### Technical Decisions

**Decision 1**: XML Generation Approach
- **Chosen**: Direct string interpolation in Swift/Bash with XML escaping
- **Rationale**: Simple, no dependencies, full control over output
- **Alternatives Considered**:
  - XML libraries (rejected: adds dependency)
  - Template files (rejected: unnecessary abstraction for simple structure)

**Decision 2**: HTTP Client for Sitemap Fetching
- **Chosen**: curl command in bash
- **Rationale**: Available on all runners, simple, no dependencies
- **Alternatives Considered**:
  - Swift URLSession (rejected: requires Swift runtime in non-Swift workflows)
  - wget (rejected: curl more ubiquitous)

**Decision 3**: State File Format
- **Chosen**: JSON with package_version and generated_date fields
- **Rationale**: Human-readable, easy to parse in both Swift and Bash, git-diffable
- **Alternatives Considered**:
  - YAML (rejected: requires parser)
  - Property list (rejected: less portable)

**Decision 4**: Sitemap Index Aggregation Timing
- **Chosen**: Generate index during 21.dev deployment (fetch from deployed URLs)
- **Rationale**: Ensures index always reflects deployed state, no artifact dependencies
- **Alternatives Considered**:
  - Artifact chaining (rejected: complex, fragile if artifact missing)
  - Separate workflow (rejected: coordination complexity)

**Decision 5**: Production vs Preview Detection
- **Chosen**: Check `inputs.deploy-to-production` boolean in workflows
- **Rationale**: Already exists in deploy-cloudflare.yml, consistent with current architecture
- **Alternatives Considered**:
  - Branch-based detection (rejected: less explicit)
  - Environment variables (rejected: requires new configuration)

## Phase 1: Data Models & Contracts

### Data Model: Sitemap XML Structure

**Entity**: URL Entry
```xml
<url>
  <loc>https://21.dev/</loc>
  <lastmod>2025-11-14</lastmod>
</url>
```

**Fields**:
- `loc` (required): Absolute URL including protocol and domain
- `lastmod` (required): ISO 8601 date (YYYY-MM-DD format)

**Validation Rules**:
- URL must start with `https://` (no http://)
- URL must not exceed 2,048 characters
- lastmod must be valid ISO 8601 date
- Special characters in URLs must be XML-escaped (&, <, >, ", ')

---

**Entity**: Sitemap Index Entry
```xml
<sitemap>
  <loc>https://docs.21.dev/sitemap.xml</loc>
  <lastmod>2025-11-14T19:30:00-08:00</lastmod>
</sitemap>
```

**Fields**:
- `loc` (required): Absolute URL to subdomain sitemap
- `lastmod` (required): ISO 8601 timestamp with timezone

**Validation Rules**:
- Same as URL entry plus:
- lastmod includes time and timezone (not just date)
- Must reference deployed sitemap files (404 check possible)

---

**Entity**: Sitemap State File
```json
{
  "package_version": "0.22.0",
  "generated_date": "2025-11-14T19:30:00-08:00"
}
```

**Fields**:
- `package_version` (required): Semver string from Package.resolved
- `generated_date` (required): ISO 8601 timestamp when sitemaps were generated

**Storage**: `Resources/sitemap-state.json` (git-tracked)

**Update Triggers**:
- Lefthook post-checkout hook detects Package.resolved changes
- Compares swift-secp256k1 version
- Updates state file if version changed
- Developer commits alongside Package.resolved

### API Contracts

#### Google Search Console IndexingAPI

**Endpoint**: `POST https://indexing.googleapis.com/v3/urlNotifications:publish`

**Authentication**: OAuth 2.0 service account with `https://www.googleapis.com/auth/indexing` scope

**Request Headers**:
```
Authorization: Bearer <ACCESS_TOKEN>
Content-Type: application/json
```

**Request Body**:
```json
{
  "url": "https://21.dev/sitemap.xml",
  "type": "URL_UPDATED"
}
```

**Success Response (200)**:
```json
{
  "urlNotificationMetadata": {
    "url": "https://21.dev/sitemap.xml",
    "latestUpdate": {
      "type": "URL_UPDATED",
      "notifyTime": "2025-11-14T19:30:00Z"
    }
  }
}
```

**Rate Limits**: 100 requests per day per project

---

#### Bing Webmaster Tools API

**Endpoint**: `POST https://ssl.bing.com/webmaster/api.svc/json/SubmitUrlBatch`

**Authentication**: API key in query parameter

**Request URL**:
```
https://ssl.bing.com/webmaster/api.svc/json/SubmitUrlBatch?apikey=<API_KEY>
```

**Request Headers**:
```
Content-Type: application/json
```

**Request Body**:
```json
{
  "siteUrl": "https://21.dev",
  "urlList": ["https://21.dev/sitemap.xml"]
}
```

**Success Response (200)**:
```json
{
  "d": null
}
```

**Rate Limits**: 10 URLs per request, 10,000 submissions per day

### Integration Points

**Workflow Dependencies**:
```
docs.21.dev → deploy-cloudflare (docs) → sitemap uploaded
md.21.dev → deploy-cloudflare (md) → sitemap uploaded  
21.dev → build-slipstream → sitemap-main.xml generated
21.dev → deploy-cloudflare (21-dev) → fetch sitemaps → generate index → submit APIs
```

**Deployment Sequence** (per FR-001):
1. docs.21.dev deployment (includes sitemap.xml)
2. md.21.dev deployment (includes sitemap.xml)
3. 21.dev build (includes sitemap-main.xml)
4. 21.dev deployment:
   a. Fetch docs/md/main sitemaps
   b. Generate sitemap index
   c. Deploy all files
   d. Submit to Google/Bing APIs

**Error Handling**:
- Sitemap fetch failures → Partial index generation (log warning, omit failed subdomain)
- API submission failures → Log error, continue deployment (non-blocking per FR-038)
- State file missing → Use current timestamp as fallback
- Git history unavailable → Use current timestamp as fallback

---

## Next Steps

✅ Phase 0 research tasks documented  
✅ Phase 1 data models defined  
✅ Phase 1 API contracts specified  
⏭️ **Ready for** `/speckit.tasks` **to generate implementation tasks**

**Post-Planning Actions**:
1. Create `research.md` with findings from research tasks
2. Create `data-model.md` with entity definitions
3. Create `contracts/` directory with API specifications
4. Run `/speckit.tasks` to generate actionable task breakdown
